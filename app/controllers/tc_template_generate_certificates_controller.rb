class TcTemplateGenerateCertificatesController < ApplicationController
  before_filter :login_required
  before_filter :template_presence_required
  before_filter :general_settings_required
  before_filter :get_records, :only=>[:index, :list_students, :search_logic_for_archived_students, :search_generated_records]
  before_filter :find_template
  before_filter :find_student, :only=>[:edit, :preview,:show, :regenerate_certificate]
  before_filter :check_presence_of_fields, :only=>[:edit,:index]
  filter_access_to :all
  check_request_fingerprint :create  
  include TcTemplateGenerateCertificatesHelper

    
  def index
    @batches = []
    @courses = Course.active
    get_students_has_records
  end
  
  def list_batches
    @batches = params[:course_id].present? ? Course.find(params[:course_id]).batches : []
  end
  
  def list_students
    get_students_has_records
    if params[:generated_student_tc][:course_id].present?
      if params[:generated_student_tc][:batch_id].present?
        @batch = Batch.find(params[:generated_student_tc][:batch_id])
        @students = @batch.archived_students.paginate(:per_page=>10,:page=>params[:page])
      else
        @errors = true
      end 
    else
      render :update do |page| 
        page.replace_html 'other_details',:text=>"<p class='flash-msg'> #{t('select_a_course')}</p>"
      end
    end
  end
  
  def generated_certificates
    @records = TcTemplateRecord.all.paginate(:per_page=>10,:page=>params[:page])
  end
  
  def search_logic_for_archived_students
    get_students_has_records
    query = params[:query]
    if query.length>= 3
      @students = ArchivedStudent.find(:all,
        :conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR admission_no = ? OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? ) ",
          "#{query}%", "#{query}%", "#{query}%",
          "#{query}", "#{query}"],
        :order => "first_name asc") unless query == ''
    else
      @students = ArchivedStudent.find(:all,
        :conditions => ["admission_no = ? ", query],
        :order => "first_name asc") unless query == ''
    end
    if query == ''
      @students == ''
    end
    render :layout => false
  end
  
  def search_generated_records
    query = params[:query]
    get_students_has_records
    if query.length>= 3
      @students = ArchivedStudent.find(:all,
        :conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR admission_no = ? OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? ) ",
          "#{query}%", "#{query}%", "#{query}%",
          "#{query}", "#{query}"],
        :order => "first_name asc") unless query == ''
    else
      @students = ArchivedStudent.find(:all,
        :conditions => ["admission_no = ? ", query],
        :order => "first_name asc") unless query == ''
    end
    if query == ''
      @students == ''
    end
    unless @students.nil?
      @students = @students.select{|s| @students_has_record.include? s}
    end
    render :layout => false
  end
  
  def edit
    @date_of_issue_labels = current_template.tc_template_fields.find_by_field_name("DateOfIssue").field_info
    @serial_number = TcTemplateRecord.find_serial_no
    @previous_serial_number = TcTemplateRecord.find_previous
    @student_details = TcTemplateFieldStudentDetail.get_current_student_details
    @serial_number_type = TcTemplateField.serial_number_type
    @student_details_ids=current_template.tc_template_field_student_details_main_field_ids
    @preview = false
    if params[:preview].present?
      @student_details = TcTemplateFieldStudentDetail.submitted_values_to_hash(params[:submitted_data])
      @serial_number = params[:certificate_number]
      @date_of_issue = Date.parse(params[:date_of_issue]) if params[:date_of_issue].present?
      @preview = true
    end
  end
  
  def regenerate_certificate
    @record = TcTemplateRecord.find_by_student_id(@student.id)
    if @record.present?
      redirect_to :action => "edit", :id=>@student.id  
    end
  end
  

  def preview
    record = @current_template.tc_template_records.new(params[:generate_report])
    @date_of_issue_labels = current_template.tc_template_fields.find_by_field_name("DateOfIssue").field_info
    @header, @footer = TcTemplateField.get_template_settings(@current_template)
    @tc_data = params[:generate_report]['record_data']
    @student_details = TcTemplateFieldStudentDetail.submitted_values_to_hash(params[:generate_report]['record_data'])
    @serial_number_type = TcTemplateField.serial_number_type
    @student_details_ids=current_template.tc_template_field_student_details_main_field_ids
    @prefix = current_template.tc_template_field_headers.find_by_field_name("SerialPrefix").field_info.value.strip
    @serial_number = params[:generate_report]['certificate_number']
    @date_of_issue = Date.parse(params[:generate_report]['date_of_issue']) if params[:generate_report]['date_of_issue'].present?
    @previous_serial_number = TcTemplateRecord.find_previous
    @id = params[:id].to_i
    unless record.valid?
      @err = ""
      record.errors.full_messages.each do|err|
        @err += "<li>#{err}</li>" 
      end
      flash.now[:notice] = "<div class=\"errorExplanation\" ><p>#{t('following_errors_found')} : </p><ul>" +@err + "</ul></div>"
      render 'edit'
    end
  end
  
  def create
    record = @current_template.tc_template_records.new(params[:generate_report])
    student = ArchivedStudent.find(record.student.id)
    previous_record = TcTemplateRecord.find_by_student_id(student.id)
    if previous_record.present?
      previous_record.destroy
    end
    if record.save
      flash[:notice] = "#{t('transfer_certificate_generated')} #{record.student.full_name}.  <a href='/tc_template_generate_certificates'>Click Here</a> #{t('generate_new_tc')}"
      redirect_to :action=> 'show', :id=>record.student_id
    else
      flash[:notice] = "#{t('flash1')}"
      redirect_to :action=> 'generated_certificates'
    end
  end
  
  def show
    @tc_data = TcTemplateRecord.find_by_student_id(params[:id].to_i)
    if @tc_data.present?
      @serial_number = @tc_data.get_serial_number
      version_id = @tc_data.tc_template_version_id
      @tc_version = TcTemplateVersion.find(version_id)
      @date_of_issue = @tc_data.date_of_issue if @tc_version.doi_enabled?
      @header, @footer = TcTemplateField.get_template_settings(@tc_version)
      @student_details_ids=@tc_version.tc_template_field_student_details_main_field_ids
      @student_details = TcTemplateFieldStudentDetail.submitted_values_to_hash(@tc_data.record_data)
      @current_template = @tc_version
    else
      flash[:notice] = "#{t('transfer_certificate_not_generated')}"
      redirect_to :action => "generated_certificates"
    end
  end


  def transfer_certificate_download
    record = TcTemplateRecord.find_by_student_id(params[:student_id].to_i)
    @tc_data = record.get_tc_data
    render :layout=>'layouts/tc_print'
  end
  def transfer_certificate_download_pdf
    record = TcTemplateRecord.find_by_student_id(params[:id].to_i)
    student = ArchivedStudent.find(params[:id].to_i)
    @tc_data = record.get_tc_data
    render :pdf => "TC_#{student.admission_no}_#{student.batch.full_name}",
      :header => {:html => nil},
      :footer => {:html => nil},
      :show_as_html=>params.key?(:d),
      :margin=> {:top=> 8, :bottom=> 8.5, :left=> 8, :right=> 8},
#      :page_height => 1000,
      :zoom => 1,:layout => "tc_pdf.html"
#      :show_as_html=> params[:d].present?
      
  end

  def destroy
    record = TcTemplateRecord.find_by_student_id(params[:id].to_i)
    if record.destroy
      flash[:notice] = "#{t('transfer_certificate_deleted')}"
    end
    redirect_to :action => "generated_certificates"
  end
  
  def date_in_words
    @txt =  get_date_in_words(params[:date])
    @id = params[:id]
    render :update do |page| 
      page.replace_html "extra_#{params[:id]}",:partial=>"in_word_view"
    end
  end
  
  
  private
  
  def current_template
    TcTemplateVersion.current
  end 
  
  def find_template
    @current_template = TcTemplateVersion.current
  end
  
  def find_student
    @student = ArchivedStudent.find(params[:id])
  end
  
  def check_presence_of_record
    @record = TcTemplateRecord.find_by_student_id(@student.id)
    if @record
      redirect_to :action=>'generated_certificates'
    end
  end
  
  def check_presence_of_fields
    @student_details = TcTemplateFieldStudentDetail.get_current_student_details
    if @student_details.empty?
      flash[:notice] = "#{t('add_student_details_first')}"
      redirect_to :controller=>'tc_template_student_details'
    end
  end
  
  def template_presence_required
    unless TcTemplateVersion.current
      flash[:notice] = "#{t('no_templates_found')}"
      redirect_to :controller=>"tc_templates", :action=>"index"
    end
  end
  
  def general_settings_required
    unless Configuration.find_by_config_key('DateFormat')
      flash[:notice] = "#{t('no_general_settings_found')}"
      redirect_to :controller=>"tc_templates", :action=>"index"
    end
  end
  
  def get_records
    @records = TcTemplateRecord.all
  end
  
  def get_students_has_records
    @students_has_record = []
    @records.each do |record|
      @students_has_record << record.student
    end
  end
end
