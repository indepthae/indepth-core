class Api::StudentsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @students = Student.search(params[:search])
    
    respond_to do |format|
      unless params[:search].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :students }
      end
    end
  end

  def show
    @xml = Builder::XmlMarkup.new
    @enabled_roll_number = Configuration.enabled_roll_number?
    
    unless current_user.parent?
      @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])
    else
      @student = current_user.guardian_entry.wards.first(:conditions => ["admission_no LIKE BINARY (?)", params[:id]])
    end
    @students = @student.try(:get_profile_data)
    respond_to do |format|
      unless @student.nil?
        format.xml  { render :student }
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
  end

  def fee_dues
    @xml = Builder::XmlMarkup.new
    @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])
    @finance_fee_collections = FinanceFeeCollection.find(:all,:joins=>"INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id INNER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id",:conditions=>"finance_fees.student_id='#{@student.id}'  and finance_fee_collections.is_deleted=#{false} and ((finance_fees.balance > 0 and finance_fees.batch_id<>#{@student.batch_id}) or (finance_fees.batch_id=#{@student.batch_id}) )").uniq
    DependencyHook.check_dependency_for(@student,:only => [:transport_batch_fee_value,:hostel_batch_fee_value]).each do |dependency|
      @hostel_fee_collections = @student.hostel_fee_collections_with_dues if FedenaPlugin.can_access_plugin?('fedena_hostel') and dependency.hook_name == :hostel_batch_fee_value
      @transport_fee_collections = @student.transport_fee_collections_with_dues if FedenaPlugin.can_access_plugin?('fedena_transport') and dependency.hook_name == :transport_batch_fee_value
    end
    respond_to do |format|
      format.xml { render :student_fee_dues}
    end
  end

  def attendance_profile
    @xml = Builder::XmlMarkup.new
    @config = Configuration.find_by_config_key('StudentAttendanceType')
    search_params = params[:search] || Hash.new
    search_params = search_params.merge(:student_admission_no_equals => "#{current_user.username}")
    if @config.config_value == 'Daily'
      @attendances = Attendance.search(search_params).all
    else
      @attendances = SubjectLeave.search(search_params).all
    end
    render :template => 'api/attendances/attendances.xml'
  end

  def fee_dues_profile
    @xml = Builder::XmlMarkup.new
    @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",current_user.username])
    @finance_fee_collections = FinanceFeeCollection.find(:all,:joins=>"INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id INNER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id",:conditions=>"finance_fees.student_id='#{@student.id}'  and finance_fee_collections.is_deleted=#{false} and ((finance_fees.balance > 0 and finance_fees.batch_id<>#{@student.batch_id}) or (finance_fees.batch_id=#{@student.batch_id}) )").uniq
    DependencyHook.check_dependency_for(@student,:only => [:transport_batch_fee_value,:hostel_batch_fee_value]).each do |dependency|
      @hostel_fee_collections = @student.hostel_fee_collections_with_dues if FedenaPlugin.can_access_plugin?('fedena_hostel') and dependency.hook_name == :hostel_batch_fee_value
      @transport_fee_collections = @student.transport_fee_collections_with_dues if FedenaPlugin.can_access_plugin?('fedena_transport') and dependency.hook_name == :transport_batch_fee_value
    end
    respond_to do |format|
      if @student.nil?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml { render :student_fee_dues}
      end
    end
  end

  def exam_report_profile
    @xml = Builder::XmlMarkup.new
    search_params = params[:search] || Hash.new
    search_params = search_params.merge(:student_admission_no_equals => current_user.username) unless search_params[:student_admission_no_equals].present?
    @exam_scores = ExamScore.search(search_params)

    unless search_params.present?
      render "single_access_tokens/500.xml", :status => :bad_request  and return
    else
      render :template => 'api/exam_scores/exam_scores.xml' 
    end
  end

  def student_structure
    @xml = Builder::XmlMarkup.new
    @additional_data = Hash.new
    @additional_fields = StudentAdditionalField.all(:conditions=>"status = true")
    @additional_fields.each do |additional_field|
      detail = StudentAdditionalDetail.find_by_additional_field_id_and_student_id(additional_field.id,@student.try(:id))
      @additional_data[additional_field.name] = detail.try(:additional_info)
    end
    
    respond_to do |format|
      format.xml  { render :student_structure }
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    student_params_main = nil
    begin
      student_params_main = File.read(params[:student].try(:path)).gsub(/\s&\s/,' &amp; ')
    rescue Exception => e
      render "single_access_tokens/500.xml", :status => :bad_request  and return
      puts e.message
    end
    student_params = student_params_main.present? ? Hash.from_xml(student_params_main).inject({}){|memo,(k,v)| memo[k.to_s] = v; memo}["student"].inject({}){|memo,(k,v)| memo[k.to_s] = v; memo} : Hash.new
    student_params ||= Hash.new
    student_additional_details_params = student_params.delete("student_additional_details")
    student_additional_details_params ||= Hash.new
    student_params.keys.each do |key|
      if Student.reflect_on_all_associations.map(&:name).include? key.to_sym
        query_model = Student.reflect_on_association(key.to_sym).options[:class_name].nil? ? key : Student.reflect_on_association(key.to_sym).options[:class_name]
        student_params[key] = query_model.to_s.camelize.constantize.find_by_name(student_params[key]) unless key == "batch"
      end
      if key == "batch"
        batch = Batch.active.find(:first,:conditions => ["CONCAT(courses.code, ' - ',name) LIKE ?",student_params[key]],:joins=>:course)
        student_params[key] = batch
      end
    end
    @student = Student.new(student_params)
    @student.photo = params[:student_photo] if params[:student_photo].present? and params[:student_photo].class.to_s=="Tempfile"
    respond_to do |format|
      if params[:student].present?
        if @student.valid?
          if student_additional_details_params.present?
            additional_datas = student_additional_details_params
            if additional_datas["additional_field"].is_a? Array
              additional_datas["additional_field"].each do |additional_data|
                additional_field = StudentAdditionalField.active.find_by_name(additional_data["name"].squish)
                additional_detail = @student.student_additional_details.build(:additional_field_id => additional_field.try(:id),:additional_info => additional_data["value"]) if additional_field.present?
              end
            else
              additional_field = StudentAdditionalField.active.find_by_name(additional_datas["name"].squish)
              additional_detail = @student.student_additional_details.build(:additional_field_id => additional_field.try(:id),:additional_info => additional_datas["value"]) if additional_field.present?
            end
          end
          @student.student_additional_details.map(&:valid?).join
          if @student.save
            @students = @student.get_profile_data
            format.xml  { render :student, :status => :created }
          else
            format.xml  { render :xml => @student.errors, :status => :unprocessable_entity }
          end
        else
          format.xml  { render :xml => @student.errors, :status => :unprocessable_entity }
        end
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end

  end
  
  def biometric
    @xml = Builder::XmlMarkup.new
    @student = Student.find_student_with_biometric(params[:id])
    respond_to do |format|
      if @student.present?
        @students =  @student.first.get_profile_data
        format.xml  { render :student }
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
  end

  def upload_photo
    @xml = Builder::XmlMarkup.new
    @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])
    if @student.nil?
      render "single_access_tokens/500.xml", :status => :bad_request  and return
    else
      @student.photo = params[:photo] if params[:photo].present? and params[:photo].class.to_s=="Tempfile"
      @student.save
      respond_to do |format|
        format.xml {render :student_photo,:status => :created}
      end
    end
  end


  def destroy
    @xml = Builder::XmlMarkup.new
    @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])

    respond_to do |format|
      unless @student.check_dependency
        @student.guardians.each do|guardian|
          guardian.user.destroy if guardian.user.present?
          guardian.destroy
        end
        @student.user.destroy
        if @student.destroy
          format.xml  { render :delete }
        else
          format.xml  { render :xml => @student.errors }
        end
      else
        format.xml  { render :dependent }
      end
    end
  end
end
