class CceReportSettingsController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:except=>[:upscale_scores,:save_upscale_scores,:get_course_batch_selector,:get_batches_list,:get_inactive_batches_list],:attribute_check=>true, :load_method => lambda { current_user }
  filter_access_to [:upscale_scores,:save_upscale_scores,:get_course_batch_selector], :attribute_check=>true, :load_method => lambda { params[:batch].present? ? Batch.find(params[:batch][:id]) : Batch.find(params[:batch_id]) }
  filter_access_to [:get_course_batch_selector], :attribute_check=>true, :load_method => lambda { Batch.find(params[:id]) }
  filter_access_to [:get_batches_list,:get_inactive_batches_list], :attribute_check=>true, :load_method => lambda { Course.find(params[:id]) }
  
  def settings
    @student_additional_fields = StudentAdditionalField.find(:all, :conditions=> "status = true and input_type = 'text'", :order=>"priority ASC")
    if request.post?
      CceReportSetting.set_setting_values(params[:cce_report_setting])
      respond_to do |format|
        format.html {
          flash[:notice] = "#{t('flash_msg8')}"
          redirect_to :action => "settings"
        }
        format.js {
          if params[:id] == "1"
            @health_status_rg=RecordGroup.find_by_id(params[:cce_report_setting][:health_status],:include=>:records)
            render :update do |page|
              page.replace_html 'hs_details' ,:partial=>'health_status_details'
              page << "Modalbox.hide();"
            end
          else
            @self_awareness_rg=RecordGroup.find_by_id(params[:cce_report_setting][:self_awareness],:include=>:records)
            @student_additional_fields = StudentAdditionalField.find(:all, :conditions=> "status = true", :order=>"priority ASC")
            render :update do |page|
              page.replace_html 'sa_details' ,:partial=>'self_awareness_details'
              page << "Modalbox.hide();"
            end
          end
        }
      end
    else
      @setting = CceReportSetting.get_multiple_settings_as_hash ["ReportHeader", "Attendance", "HealthStatus", "Height", "Weight", "BloodGroup", "VisionLeft", "VisionRight", "DentalHygiene", "SelfAwareness", "MyGoals", "MyStrengths",
                                                                 "InterestHobbies", "Responsibility", "AffiliationNo","LastPage", "RegistrationNo", "RegistrationNoVal"]
      respond_to do |format|
        format.html {
          @health_status_rg=RecordGroup.find_by_id(@setting[:health_status],:include=>:records)
          @self_awareness_rg=RecordGroup.find_by_id(@setting[:self_awareness],:include=>:records)
        }
        format.js {
          @record_groups=RecordGroup.all
          render :update do |page|
            if params[:id] == "1"
              @health_status_rg=RecordGroup.find_by_id(@setting[:health_status],:include=>:records)
              page.replace_html 'modal-box', :partial => 'settings_form_1'
              page << "Modalbox.show($('modal-box'), {title: 'Health Status - Record Group Setting', width: 650});"
            else
              @self_awareness_rg=RecordGroup.find_by_id(@setting[:self_awareness],:include=>:records)
              page.replace_html 'modal-box', :partial => 'settings_form_2'
              page << "Modalbox.show($('modal-box'), {title: 'Self Awareness - Record Group Setting', width: 650});"
            end
            
          end
        }
      end
    
    end 
  end
  
  def normal_report_settings
    if request.post?
      CceReportSetting.set_setting_values(params[:cce_report_setting])
      respond_to do |format|
        format.html {
          flash[:notice] = "#{t('flash_msg8')}"
          redirect_to :action => "normal_report_settings"
        }
      end
    else
      @setting = CceReportSetting.get_multiple_settings_as_hash CceReportSetting::SETTINGS
      @student_fields=CceReportSetting::SETTINGS_WITH_VALUES
      @student_additional_fields=StudentAdditionalField.all(:conditions=>["input_type in (?) and status = ?",["text","belongs_to"],true])
    end 
  end

  def manage_criteria
    if request.post?
      EiopSetting.save_criteria(params[:eiop_setting])
      render :update do |page|
        page << "Modalbox.hide();"
        page.replace_html 'flash-box',"<p class='flash-msg'>#{t('flash_msg8')}</p>"
      end
    else
      @courses=Course.cce.all(:include=>[{:batches=>:grading_levels},:eiop_settings])
      render :update do |page|
        page.replace_html 'modal-box', :partial => 'manage_criteria'
        page << "Modalbox.show($('modal-box'), {title: 'Final Result Criteria', width: 950});"
      end
    end
   
  end

  def cbse_co_scholastic_settings
    @courses=Course.cce
    if params[:course_id].present?
      @observations=Observation.active.all(:joins=>"INNER JOIN courses_observation_groups cog on cog.observation_group_id = observations.observation_group_id and cog.course_id=#{params[:course_id]}",:select=>"distinct *")
      @cbse_co_scholastic_entries=CbseCoScholasticSetting.find_all_by_course_id(params[:course_id])
    end
  end

  def get_observations
    @observations=Observation.active.all(:joins=>"INNER JOIN courses_observation_groups cog on cog.observation_group_id = observations.observation_group_id and cog.course_id=#{params[:course_id]}",:select=>"distinct *")
    @cbse_co_scholastic_entries=CbseCoScholasticSetting.find_all_by_course_id(params[:course_id])
    render(:update) do |page|
      page.replace_html 'flash-box',""
      page.replace_html 'observations',:partial=>"observations_list"
    end
  end

  def save_cbse_co_scholastic_settings
    entries=CbseCoScholasticSetting.find_all_by_course_id(params[:course_id])
    params[:cbse_co_scholastic_setting].each_value do |value|
      value.each do |k,v|
        entry = entries.find_by_observation_id(k.to_i)
        if entry.present?
          if (entry.code.present? and v.present?) or (entry.code.present? and v.nil?) or (entry.code.nil? and v.present?)
            entry.update_attributes(:code => v)
            flash[:notice] = "Settings updated"
          end
        else
          if v.present?
            CbseCoScholasticSetting.create(:course_id=>params[:course_id],:observation_id=>k.to_i,:code=>v)
            flash[:notice] = "Settings saved"
          end
        end
      end
    end
    @courses=Course.cce
    @observations=Observation.active.all(:joins=>"INNER JOIN courses_observation_groups cog on cog.observation_group_id = observations.observation_group_id and cog.course_id=#{params[:course_id]}",:select=>"distinct *")
    @cbse_co_scholastic_entries=CbseCoScholasticSetting.find_all_by_course_id(params[:course_id])
    redirect_to :action=>'cbse_co_scholastic_settings',:course_id=>params[:course_id]
  end
    

  def upscale_settings
    if request.post?
      CceReportSetting.set_setting_values(params[:cce_report_setting])
      flash[:notice] = "Upscale settings saved"
      redirect_to :action => "upscale_settings"
    else
      @setting = CceReportSetting.get_multiple_settings_as_hash ["TwoSubUpscaleStart", "TwoSubUpscaleEnd", "OneSubUpscaleStart", "OneSubUpscaleEnd"]
    end
  end

  def upscale_scores
    @settings = CceReportSetting.get_multiple_settings_as_hash ["TwoSubUpscaleStart", "TwoSubUpscaleEnd", "OneSubUpscaleStart", "OneSubUpscaleEnd"]
    batch_id =params[:batch_id]||(params[:batch][:id] if params[:batch].present? and params[:batch][:id].present?)
    @batch=Batch.find_by_id(batch_id)
    if @batch.present?
      config = Configuration.find_or_create_by_config_key('StudentSortMethod')
      if config.config_value == "roll_number"
        @students = @batch.is_active ? @batch.students.all(:order=>"#{Student.sort_order}") : Student.previous_records.all(:order=>"soundex(batch_students.roll_number),length(batch_students.roll_number),batch_students.roll_number ASC",:conditions=>["batch_students.batch_id=?",@batch.id])
      else
        @students = @batch.is_active ? @batch.students.all(:order=>"#{Student.sort_order}") : Student.previous_records.all(:order=>"#{Student.sort_order}",:conditions=>["batch_students.batch_id=?",@batch.id])
      end
      @two_sub_eligible = @batch.get_students_eligible_for_2_sub
      @one_sub_eligible = @batch.get_students_eligible_for_1_sub
      @non_eligible = @batch.get_non_eligible_students
      unless params[:student_id].present?
        @student = @two_sub_eligible.present? ? @two_sub_eligible.first : @one_sub_eligible.present? ? @one_sub_eligible.first : @non_eligible.first
      else
        @student=Student.find(params[:student_id])
      end
      @count=params[:count].present? ? params[:count].to_i : @two_sub_eligible.present? ? 2 : @one_sub_eligible.present? ? 1 : 0
      if @student.present?
        @student.batch_in_context_id = @batch.id
        @report=@student.individual_cce_report_cached
        @subjects=@student.all_subjects
      end
    
      if (params[:batch].present? and params[:batch][:id].present?) or request.post?
        render(:update) do |page|
          page.replace_html   'course_batches_section', :partial=>"links_for_change"
          unless @settings.delete_if { |key, value| value.blank? }.count < 4
            page.replace_html   'batch_informer', :partial=>"batch_info"
            page.replace_html   'student_list', :partial=>"student_list" if (params[:batch].present? and params[:batch][:id].present? and @students.present? and @students.count != @non_eligible.count and @student.present?)
            page.replace_html   'student_list', :text=>"" if  @students.blank? or (@students.present? and (@students.count == @non_eligible.count)) or @subjects.blank?
            page.replace_html   'student_record', :partial=>"individual_student_record" if @students.present? and @students.count != @non_eligible.count and @student.present?
            page.replace_html   'student_record', :text=>"" if  @students.blank? or (@students.present? and (@students.count == @non_eligible.count)) or @subjects.blank?
            page.replace_html   'no_data', :text => ""
            page.replace_html   'no_data', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> No students in this batch</p></div>"  unless @students.present?
            page.replace_html   'no_data', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> No students in this batch are eligible for upscaling</p></div>"  if  @students.present? and @students.count == @non_eligible.count
            page.replace_html   'no_data', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> No subjects having exams in this batch</p></div>"  if  @subjects.blank?
          end
        end
      end
    else
      render(:update) do |page|
        page.replace_html   'holder', :text=>"<div class='label-field-pair2' ><p class = 'flash-msg'> No batch selected</p></div>"
      end
    end
  end

  def save_upscale_scores
    params[:upscale_score].each do |key,value|
      score = UpscaleScore.find_by_student_id_and_batch_id_and_subject_id(params[:student_id],value[:batch_id],value[:subject_id])
      if value[:_delete] == "0" and !score.present?
        UpscaleScore.create(:student_id=>params[:student_id],:batch_id=>value[:batch_id],:subject_id=>value[:subject_id],:upscaled_grade=>value[:upscaled_grade],:previous_grade=>value[:previous_grade])
      elsif value[:_delete] == "1" and score.present?
        score.destroy
      end
    end
    @batch=Batch.find(params[:batch_id])
    if @batch.present?
      @student=Student.find(params[:student_id])
      @student.batch_in_context_id=@batch.id
      @student.delete_individual_cce_report_cache
      @settings = CceReportSetting.get_multiple_settings_as_hash ["TwoSubUpscaleStart", "TwoSubUpscaleEnd", "OneSubUpscaleStart", "OneSubUpscaleEnd"]
      if @batch.is_active == true
        @students=@batch.students.all(:order=>'students.first_name asc')
        @two_sub_eligible = @batch.get_students_eligible_for_2_sub
        @one_sub_eligible = @batch.get_students_eligible_for_1_sub
        @non_eligible = @batch.get_non_eligible_students
      else
        @students=Student.all(:joins=>"INNER JOIN batch_students bs on bs.student_id=students.id and bs.batch_id=#{@batch.id}")
        @two_sub_eligible = @batch.get_students_eligible_for_2_sub
        @one_sub_eligible = @batch.get_students_eligible_for_1_sub
        @non_eligible = @batch.get_non_eligible_students
      end
      @report=@student.individual_cce_report_cached
      @subjects=@student.all_subjects
      @count=params[:count].present? ? params[:count].to_i : @two_sub_eligible.present? ? 2 : @one_sub_eligible.present? ? 1 : 0
      render(:update) do |page|
        page.replace_html   'course_batches_section', :partial=>"links_for_change"
        page.replace_html   'batch_informer', :partial=>"batch_info"
        page.replace_html   'student_list', :partial=>"student_list" if (@students.present? and @students.count != @non_eligible.count and @student.present?)
        page.replace_html   'student_list', :text=>"" if  @students.blank? or (@students.present? and (@students.count == @non_eligible.count))
        page.replace_html   'student_record', :partial=>"individual_student_record" if @students.present? and @students.count != @non_eligible.count and @student.present?
        page.replace_html   'student_record', :text=>"" if  @students.blank? or (@students.present? and (@students.count == @non_eligible.count))
        page.replace_html   'no_data', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> No students in this batch</p></div>"  unless @students.present?
        page.replace_html   'no_data', :text => "<div class='label-field-pair2' ><p class = 'flash-msg'> No students in this batch are eligible for upscaling</p></div>"  if  @students.present? and @students.count == @non_eligible.count
        page.replace_html   'flash-box',:text=>"<p class='flash-msg'>Grades Upscaled</p>"

      end
    else
      
    end
  end

  def get_course_batch_selector
    @batch=Batch.find(params[:id])
    @course=@batch.course
    if @batch.is_active
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
        @courses=Course.has_active_batches.all(:conditions=>{:grading_type=>"3"})
      elsif @current_user.is_a_batch_tutor
        @courses=[]
        @courses+=Course.all(:joins=>{:batches=>:employees},:conditions=>{:grading_type=>"3",:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
        @courses+=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:grading_type=>"3",:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
        @courses.uniq!
      elsif @current_user.is_a_subject_teacher
        @courses=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:grading_type=>"3",:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      else
        @courses=[]
      end
    else
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
        @courses=Course.has_inactive_batches.all(:conditions=>{:grading_type=>"3"})
      elsif @current_user.is_a_batch_tutor
        @courses=Course.all(:joins=>{:batches=>:employees},:conditions=>{:grading_type=>"3",:is_deleted=>false,:batches=>{:is_active=>false,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      elsif @current_user.is_a_subject_teacher
        @courses=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:grading_type=>"3",:is_deleted=>false,:batches=>{:is_active=>false,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      else
        @courses=[]
      end
    end
    if @batch.is_active
      get_active_batches
    else
      get_inactive_batches
    end
    render :update do |page|
      page.replace_html 'course_batches_section',:partial=>'course_selector'
    end
  end

  def get_batches_list
    @course=Course.find(params[:id])
    get_active_batches
    render :update do |page|
      page.replace_html 'batches_list',:partial=>'batch_selector'
    end
  end
  
  def get_inactive_batches_list
    @course=Course.find(params[:id])
    get_inactive_batches
    render :update do |page|
      page.replace_html 'batches_list',:partial=>'batch_selector'
    end
  end
  
  def update_record_lists
    @setting = CceReportSetting.get_multiple_settings_as_hash ["ReportHeader", "Attendance", "HealthStatus", "Height", "Weight", "BloodGroup", "VisionLeft", "VisionRight", "DentalHygiene", "SelfAwareness", "MyGoals", "MyStrengths", "InterestHobbies", "Responsibility", "AffiliationNo"]
    if params[:rg_type_id] == "1"
      @health_status_rg=RecordGroup.find_by_id(params[:id],:include=>:records)
      render :update do |page|
        page.replace_html 'record_sections_1', :partial=>'health_status_records'
      end
    else
      @self_awareness_rg=RecordGroup.find_by_id(params[:id],:include=>:records)
      render :update do |page|
        page.replace_html 'record_sections_2', :partial=>'self_awareness_records'
      end
    end
  end

  def get_report_header_info
    @setting = CceReportSetting.get_multiple_settings_as_hash ["AffiliationNo"]
    render :update do |page|
      page.replace_html 'report_desc',:partial=>'report_with_header' if params[:id]=="0"
      page.replace_html 'report_desc',:partial=>'report_without_header' if params[:id]=="1"
    end
  end

  def get_additional_fields
    @setting = CceReportSetting.get_multiple_settings_as_hash ["RegistratioNoField"]
    @student_additional_fields = StudentAdditionalField.find(:all, :conditions=> "status = true and input_type = 'text'", :order=>"priority ASC")
    render :update do |page|
      page.replace_html 'additional_fields',:partial=>'registration_no_field' if params[:id]=="1"
      page.replace_html 'additional_fields', :text=>"" if params[:id]=="0"
    end
  end
  
  
  def get_normal_report_header_info
    @setting = CceReportSetting.get_multiple_settings_as_hash ["HeaderSpace"]
    render :update do |page|
      page.replace_html 'report_desc',:partial=>'report_with_normal_header' if params[:id]=="0"
      page.replace_html 'report_desc',:partial=>'report_without_normal_header' if params[:id]=="1"
    end
  end
  
  def get_report_signature_info
    @setting = CceReportSetting.get_multiple_settings_as_hash ["Signature", "SignLeftText", "SignCenterText", "SignRightText"]
    render :update do |page|
      page.replace_html 'report_sign',:partial=>'report_with_signature' if params[:id]=="0"
      page.replace_html 'report_sign',:text=>'' if params[:id]=="1"
    end
  end
  
  def get_report_grading_levels_info
    @setting = CceReportSetting.get_multiple_settings_as_hash ["GradingLevelPosition"]
    render :update do |page|
      page.replace_html 'report_grade_levels',:partial=>'report_grading_level_positions' if params[:id]=="0"
      page.replace_html 'report_grade_levels',:text=>'' if params[:id]=="1"
    end
  end

  def cancel
    @batch=Batch.find(params[:id])
    render(:update) do |page|
      page.replace_html   'course_batches_section', :partial=>"links_for_change"
    end
  end

  def unlink
    if params[:id] == "1"
      CceReportSetting.unlink ["HealthStatus", "Height", "Weight", "BloodGroup", "VisionLeft", "VisionRight", "DentalHygiene"]
      render :update do |page|
        page.replace_html 'hs_details', :partial=>'health_status_details'
      end
    else
      CceReportSetting.unlink ["SelfAwareness", "MyGoals", "MyStrengths", "InterestHobbies", "Responsibility"]
      render :update do |page|
        page.replace_html 'sa_details', :partial=>'self_awareness_details'
      end
    end
  end

  def preview
    @records=CceReportSetting.result_as_hash
    @batch=Batch.last(:joins=>{:subjects=>:fa_groups})
    @course=Course.last(:joins=>[{:observation_groups=>{:observations=>:descriptive_indicators}}])
    @cce_grade_set=CceGradeSet.last(:joins=>:cce_grades)
    @grading_levels = (@batch.present? ? @batch.grading_level_list : GradingLevel.default)
    @config = Configuration.get_multiple_configs_as_hash ['InstitutionName', 'InstitutionAddress', 'InstitutionPhoneNo','InstitutionEmail','InstitutionWebsite']
    render :pdf =>"preview" ,:header =>{:content=>nil},:margin=>{:left=>10,:right=>10,:top=>10,:bottom=>5}, :show_as_html=>params[:d].present?
  end

  def normal_preview
    @general_records=CceReportSetting.result_as_hash
    @batch=Batch.active.last(:joins=>:students)
    @grading_levels = (@batch.present? ? @batch.grading_level_list : GradingLevel.default)
    @config = Configuration.get_multiple_configs_as_hash ['InstitutionName', 'InstitutionAddress', 'InstitutionPhoneNo','InstitutionEmail','InstitutionWebsite']
    @student= @batch.students.last if @batch.present?
    render :pdf => "Normal Report Preview",:margin=>{:left=>10,:right=>10,:top=>5,:bottom=>5},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end
  
  private
  def get_active_batches
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
      @batches=@course.batches.active
    elsif @current_user.is_a_batch_tutor
      @batches=[]
      @batches+=@current_user.employee_record.batches.all(:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:id=>@course.id,:is_deleted=>false}},:joins=>:course)
      @batches+=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:id=>@course.id,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
      @batches.uniq!
    else
      @batches=[]
    end
  end
  
  def get_inactive_batches
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
      @batches=@course.batches.inactive
    elsif @current_user.is_a_batch_tutor
      @batches=[]
      @batches+=@current_user.employee_record.batches.all(:conditions=>{:is_deleted=>false,:is_active=>false,:courses=>{:id=>@course.id,:is_deleted=>false}},:joins=>:course)
      @batches+=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>false,:courses=>{:id=>@course.id,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
      @batches.uniq!
    else
      @batches=[]
    end
  end
end
