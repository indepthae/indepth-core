#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#require 'fedena_setting.rb'
class ParamterMissing < StandardError
end

class ApplicationController < ActionController::Base

  helper :all
  helper_method :can_access_request?
  helper_method :can_access_plugin?
  helper_method :can_access_feature?
  helper_method :currency
  helper_method :change_time_to_local_time
  helper_method :payslip_range
  helper_method :current_financial_year_id, :current_financial_year_name
  protect_from_forgery # :secret => '434571160a81b5595319c859d32060c1'
  filter_parameter_logging :password

  before_filter { |c| Authorization.current_user = c.current_user }
  before_filter :set_user_language
  before_filter :message_user
  before_filter :set_variables
  before_filter :login_check
  before_filter :school_discount_mode
  before_filter :set_translate_options
  before_filter :set_user_financial_year


  before_filter :dev_mode
  after_filter :attach_fingerprint_response
  after_filter :unasign_translate_options
  include CustomInPlaceEditing
  include DateFormater
  include FeatureLock
  include ApplicationDefaultVariables

  def check_status
    unless Configuration.find_by_config_key("SetupAttendance").try(:config_value) == "1"
      flash[:notice] = "System under maintainance. Try the feature after some time."
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def get_respective_batches(course_id=nil)
    if course_id.nil?
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
        @batches=Batch.active
      elsif @current_user.is_a_batch_tutor
        @batches=[]
        @batches+=@current_user.employee_record.batches.all(:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:is_deleted=>false}},:joins=>:course)
        @batches+=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
        @batches.uniq!
      elsif @current_user.is_a_subject_teacher
        @batches=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
      else
        @batches=[]
      end
    else
      course = Course.find(course_id)
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
        @batches=course.batches.active
      elsif @current_user.is_a_batch_tutor
        @batches=[]
        @batches+=@current_user.employee_record.batches.all(:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:id=>course.id,:is_deleted=>false}},:joins=>:course)
        @batches+=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:id=>course.id,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
        @batches.uniq!
      elsif @current_user.is_a_subject_teacher
        @batches=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:id=>course.id,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
      else
        @batches=[]
      end
    end
  end

  def get_respective_cce_batches(course_id=nil)
    if course_id.nil?
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
        @batches=Batch.cce.active
      elsif @current_user.is_a_batch_tutor
        @batches=[]
        @batches+=@current_user.employee_record.batches.all(:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:grading_type=>"3",:is_deleted=>false}},:joins=>:course)
        @batches+=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:grading_type=>"3",:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
        @batches.uniq!
      elsif @current_user.is_a_subject_teacher
        @batches=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:grading_type=>"3",:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
      else
        @batches=[]
      end
    else
      course = Course.find(course_id)
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
        @batches=course.batches.cce.active
      elsif @current_user.is_a_batch_tutor
        @batches=[]
        @batches+=@current_user.employee_record.batches.all(:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:id=>course_id,:grading_type=>"3",:is_deleted=>false}},:joins=>:course)
        @batches+=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:id=>course_id,:grading_type=>"3",:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
        @batches.uniq!
      elsif @current_user.is_a_subject_teacher
        @batches=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:id=>course_id,:grading_type=>"3",:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
      else
        @batches=[]
      end
    end
  end
  
  def get_respective_icse_batches
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
      @batches=Batch.icse.active
    elsif @current_user.is_a_batch_tutor
      @batches=[]
      @batches+=@current_user.employee_record.batches.all(:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:grading_type=>"4",:is_deleted=>false}},:joins=>:course)
      @batches+=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:grading_type=>"4",:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
      @batches.uniq!
    elsif @current_user.is_a_subject_teacher
      @batches=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>true,:courses=>{:grading_type=>"4",:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
    else
      @batches=[]
    end
  end

  def get_respective_courses
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))  or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
      @courses=Course.has_active_batches.uniq.sort_by(&:course_name)
    elsif @current_user.is_a_batch_tutor
      @courses=[]
      @courses+=Course.all(:joins=>{:batches=>:employees},:conditions=>{:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      @courses+=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      @courses.sort_by(&:course_name).uniq!
    elsif @current_user.is_a_subject_teacher
      @courses=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
    else
      @courses=[]
    end
  end
  
  def get_respective_cce_courses
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))  or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
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
  end
  
  def get_respective_icse_courses
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))  or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
      @courses=Course.has_active_batches.all(:conditions=>{:grading_type=>"4"})
    elsif @current_user.is_a_batch_tutor
      @courses=[]
      @courses+=Course.all(:joins=>{:batches=>:employees},:conditions=>{:grading_type=>"4",:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      @courses+=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:grading_type=>"4",:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      @courses.uniq!
    elsif @current_user.is_a_subject_teacher
      @courses=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:grading_type=>"4",:is_deleted=>false,:batches=>{:is_active=>true,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
    else
      @courses=[]
    end
  end

  def get_respective_subjects(id,type)
    if  type == "batch"
      batch=Batch.find id
      if current_user.admin or current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
        @subjects=batch.subjects.active_and_has_exam.uniq
      elsif current_user.is_a_batch_tutor
        @subjects=batch.subjects.active_and_has_exam.uniq
      elsif current_user.is_a_subject_teacher
        @subjects=current_user.employee_record.subjects.active.all(:conditions=>{:batch_id=>batch.id,:no_exams=>false},:joins=>:exams).uniq
      else
        @subjects=[]
      end
    elsif type == "exam_group"
      exam_group=ExamGroup.find(id)
      if current_user.admin or current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
        @subjects=exam_group.batch.subjects.active_and_has_exam.uniq
      elsif current_user.is_a_batch_tutor
        @subjects=exam_group.batch.subjects.active_and_has_exam.uniq
      elsif current_user.is_a_subject_teacher
        @subjects=current_user.employee_record.subjects.active.all(:conditions=>{:batch_id=>exam_group.batch.id,:no_exams=>false},:joins=>:exams).uniq
      else
        @subjects=[]
      end
    elsif type == 'exam_group_exams'
      exam_group=ExamGroup.find(id)
      if current_user.admin or current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
        @exams=exam_group.exams
      elsif current_user.is_a_batch_tutor
        @exams=[]
        sub_ids=current_user.employee_record.subjects.active.all(:conditions=>{:batch_id=>exam_group.batch.id,:no_exams=>false},:joins=>:exams).uniq.collect(&:id)
        @exams+=exam_group.exams.all(:joins=>:subject,:conditions=>["subjects.id in (?)",sub_ids])
      elsif current_user.is_a_subject_teacher
        sub_ids=current_user.employee_record.subjects.active.all(:conditions=>{:batch_id=>exam_group.batch.id,:no_exams=>false},:joins=>:exams).uniq.collect(&:id)
        @exams=exam_group.exams.all(:joins=>:subject,:conditions=>["subjects.id in (?)",sub_ids])
      else
        @exams=[]
      end
    else
      @subjects=[]
      @exams=[]
    end
  end

  def handle_params_failure(check_param,reset_variables=[],option_array=[],flash_text='',redirect_option=false)
    unless check_param.present?
      reset_variables.each {|e| instance_variable_set e,[]}
      if redirect_option == false
        render :update do |page|
          option_array.each do |sub_array|
            flash[:warn_notice] = flash_text
            page.replace_html *sub_array
          end
        end
      else
        flash[:notice] = flash_text
        redirect_to *option_array
      end
    end
  end

  def login_check
    if session[:user_id].present?
      unless (controller_name == "user") and ["first_login_change_password","login","logout","forgot_password"].include? action_name
        user = User.active.find(session[:user_id])
        setting = Configuration.get_config_value('FirstTimeLoginEnable')
        Fedena.present_student_id = session[:student_id] if session[:mobile] and user.parent?
        if setting == "1" and user.is_first_login != false
          return if session[:mobile] == true
          flash[:notice] = "#{t('first_login_attempt')}"
          redirect_to :controller => "user",:action => "first_login_change_password"
        end
      end
    end
  end
  
  def escape_dirty(hash)
    dirty_hash = hash

    dirty_hash.keys.each do |key|
      value = dirty_hash[key]

      if(value.kind_of?Hash)
        dirty_hash[key] = escape_dirty(value)
      else
        if (value && value.kind_of?(String))
          dirty_hash[key] = self.class.helpers.sanitize(value)
        end
      end
    end

    hash = dirty_hash
  end
  
  def escape_dirty_params
    escape_dirty params
  end


  def dev_mode
    if Rails.env == "development"

    end
  end

  def attach_fingerprint_response
    if request.xhr?
      response.headers["session_fingerprint"]="#{session_fingerprint}".to_s
    end
  end

  def set_variables
    unless @current_user.nil?
      @attendance_type = Configuration.get_config_value('StudentAttendanceType') unless @current_user.student?
      @modules = Configuration.available_modules
      FedenaPrecision.set_precision_count
      @currency_code = Configuration.get_config_value('CurrencyCode')
    end    
  end


  def set_language
    session[:language] = params[:language]
    @current_user.clear_menu_cache
    render :update do |page|
      page.reload
    end
  end

  def validate_edit_sms_template
    settings =  MultiSchool.current_school.edit_sms_template || false
    if settings == true
      return true
    else
      flash[:notice] = "#{t('configuration_for_sms_template_edit')}"
      if request.xhr?
        render(:update) do|page|
          page.redirect_to :controller=> "message_templates", :action=> "message_templates"
        end
      else
        redirect_to :controller=> "message_templates", :action=> "message_templates"
      end
    end
  end
    
  
  def validate_application_sms
    settings =  SmsSetting.find_by_settings_key("ApplicationEnabled")
    if settings.is_enabled == true
      return true
    else
      flash[:notice] = "#{t('configuration_for_sms_template_edit')}"
      if request.xhr?
        render(:update) do|page|
          page.reload
        end
      else
        redirect_to :controller=> "assessment_reports", :action=> "generate_exam_reports"
      end
    end
  end
  
  def  validate_application_sms_setting
    settings =  SmsSetting.find_by_settings_key("ApplicationEnabled")
    if settings.is_enabled == true
      return true
    else
      flash[:notice] = "#{t('configuration_for_sms_template_edit')}"
      if request.xhr?
        render(:update) do|page|
          page.reload
        end
      else
        redirect_to :controller=> "assessments", :action=> "show"
      end
    end
  end
  
  def check_sms_settings
    settings =  SmsSetting.find_by_settings_key("ApplicationEnabled")
    if settings.is_enabled == true
      return true
    else
      flash[:notice] = "#{t('configuration_for_sms_template_edit')}"
      redirect_to :controller=> "transport", :action=> "dash_board"
    end
  end
  
  def validate_sms_settings
    settings =  SmsSetting.find_by_settings_key("ApplicationEnabled")
    if settings.is_enabled == true
      return true
    else
      flash[:notice] = "#{t('configuration_for_sms_template_edit')}"
      if request.xhr?
        render(:update) do|page|
          page.redirect_to :controller=> "transport", :action=> "dash_board"
        end
      else
        redirect_to :controller=> "transport", :action=> "dash_board"
      end
    end
  end
  
  def set_financial_year fy_id = nil
    fy_id ||= params[:financial_year]

    if fy_id == '0'
      session[:financial_year] = {:id => fy_id.to_i, :name => t('financial_years.default_financial_year') }
    else
      fy = FinancialYear.find_by_id fy_id
      session[:financial_year] = fy.present? ? {:id => fy.try(:id), :name => fy.try(:name), :obj => fy } : {}
    end
    @current_user.clear_menu_cache

    set_user_financial_year
    render :update do |page|
      page.reload
    end
  end

  def reset_financial_year
    session[:financial_year] = FinancialYear.fetch_and_set_financial_year
  end


  if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound do |exception|
      flash[:notice] = "#{t('flash_msg2')} , #{exception} ."
      logger.info "[FedenaRescue] AR-Record_Not_Found #{exception.to_s}"
      log_error exception
      redirect_to :controller=>:user ,:action=>:dashboard
    end

    rescue_from NoMethodError do |exception|
      flash[:notice] = "#{t('flash_msg3')}"
      logger.info "[FedenaRescue] No method error #{exception.to_s}"
      log_error exception
      redirect_to :controller=>:user ,:action=>:dashboard
    end

    rescue_from SessionFingerprint::DuplicateRequestFingerprint do |exception|
      flash[:notice] = "#{t('request_already_proccesed')}" unless request.xhr?
      redirect_to :back unless request.xhr?
      redirect_to root_url,:status => 409 if request.xhr?
    end

    rescue_from ActionController::InvalidAuthenticityToken do|exception|
      flash[:notice] = "#{t('flash_msg43')}"
      logger.info "[FedenaRescue] Invalid Authenticity Token #{exception.to_s}"
      log_error exception
      if request.xhr?
        render(:update) do|page|
          page.redirect_to :controller => 'user', :action => 'dashboard'
        end
      else
        redirect_to :controller => 'user', :action => 'dashboard'
      end
    end

    rescue_from ActionController::MethodNotAllowed do |exception|
      logger.info "[FedenaRescue] Method Not Allowed #{exception.to_s}"
      log_error exception
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
        format.xml  { head :not_found }
        format.any  { head :not_found }
      end
    end

    rescue_from ActionController::UnknownAction do |exception|
      logger.info "[FedenaRescue] Action Not Found #{exception.to_s}"
      log_error exception
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
        format.xml  { head :not_found }
        format.any  { head :not_found }
      end
    end
    rescue_from ArgumentError do |exception|
      logger.info "[FedenaRescue] Invalid Argument #{exception.to_s}"
      log_error exception
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
        format.xml  { head :not_found }
        format.any  { head :not_found }
      end
    end

    rescue_from ParamterMissing do |exception|
      logger.info "[FedenaRescue] Paramter Missing #{exception.to_s}"
      log_error exception
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
        format.xml  { head :not_found }
        format.any  { head :not_found }
      end
    end
  end


  def restrict_employees_from_exam
    if @current_user.employee?
      @employee_subjects= @current_user.employee_record.subjects
      if @employee_subjects.empty? and !(@current_user.employee_record.batches.find(:all,:conditions=>{:is_deleted=>false,:is_active=>true}).present?) and !@current_user.privileges.map{|p| p.name}.include?("ExaminationControl") and !@current_user.privileges.map{|p| p.name}.include?("EnterResults") and !@current_user.privileges.map{|p| p.name}.include?("ViewResults") and !@current_user.privileges.map{|p| p.name}.include?("StudentsControl") and !@current_user.privileges.map{|p| p.name}.include?("ManageUsers") and !@current_user.privileges.map{|p| p.name}.include?("StudentView")
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to :controller => 'user', :action => 'dashboard'
      else
        @allow_for_exams = true
      end
    end
  end

  def block_unauthorised_entry
    if @current_user.employee?
      @employee_subjects= @current_user.employee_record.subjects
      if @employee_subjects.empty? and !@current_user.privileges.map{|p| p.name}.include?("ExaminationControl")
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to :controller => 'user', :action => 'dashboard'
      else
        @allow_for_exams = true
      end
    end
  end

  def initialize
    @title = FedenaSetting.company_details[:company_name]
  end

  def message_user
    @current_user = current_user
    logger.info("Username : #{@current_user.username} Role : #{@current_user.role_name}") if @current_user.present?
  end

  def current_user
    begin
      User.active.find(session[:user_id]) unless session[:user_id].nil?
    rescue ActiveRecord::RecordNotFound => e
      session[:user_id]=nil
      redirect_to root_path
    end
  end


  def find_finance_managers
    Privilege.find_by_name('FinanceControl').users
  end

  def permission_denied
    if request.xhr?
      redirect_to root_url,:status => 403 if request.xhr?
    else
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def month_date
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
  end
  def date_format_check
    begin
      @start_date= Date.parse(params[:start_date]) if params[:start_date]
      @end_date= Date.parse(params[:end_date]) if params[:end_date]
    rescue ArgumentError
    end

    if (@start_date.nil? or @end_date.nil?)
      flash[:notice]=t('invalid_date_format')
      redirect_to :controller => "user", :action => "dashboard"
      return false
    end
    return true
  end
  def validate_date
    @start_date= Date.parse(params[:start_date]).to_date if params[:start_date]
    @end_date= Date.parse(params[:end_date]).to_date if params[:end_date]
    if (@start_date > @end_date)
      return false
    end
    return true
  end
  
  def render_date_error_partial
    if request.xhr?
      render(:update) do|page|
        page.replace_html "date_error_div", :partial => "date_error"
      end
    end
  end

  protected

  def school_discount_mode
    #####################################################
    # school_discount_mode values can be :                                                             ####
    #                                                                                                                          ####
    # NEW_DISCOUNT_MODE :: new school seeded for new discount mode ONLY       ####
    # NEW_DISCOUNT :: old school opted for new discount mode                              ####
    # OLD_DISCOUNT :: old school opted/fallback to old discount mode                     ####
    #                                                                                                                          ####
    ######################################################
    discount_modes = ['OLD_DISCOUNT', 'NEW_DISCOUNT']
    new_school_check = Configuration.get_config_value('SchoolDiscountMarker')
    if new_school_check.present? and new_school_check == "NEW_DISCOUNT_MODE"
      @school_discount_mode = "NEW_DISCOUNT_MODE"
    else
      discount_mode = Configuration.get_config_value('FinanceDiscountMode') || "OLD_DISCOUNT"
      @school_discount_mode = discount_modes.include?(discount_mode) ? discount_mode : "OLD_DISCOUNT"
    end
  end
  
  def set_precision
    precision_count = Configuration.get_config_value('PrecisionCount')
    @precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count
  end


  def login_required
    unless session[:user_id]
      redirect_to_login
    else
      if user_blocked_check
        flash[:notice] = "#{t('blocked_login_error_message')}"
        redirect_to_login
      end
    end
  end
  
  def configuration_for_auto_leave_reset
    settings = Configuration.get_config_value('LeaveResetSettings') || "0"
    if settings == "1"
      return true
    else
      flash[:notice] = "#{t('configuration_for_auto_leave_reset_msg')}"
      redirect_to :controller=>"employee", :action=>"hr"
    end
  end
  
  def configuration_for_leave_reset
    settings = Configuration.get_config_value('LeaveResetSettings') || "0"
     if settings == "0"
      return true
    else
      flash[:notice] = "#{t('configuration_for_leave_reset_msg')}"
      redirect_to :controller=>"employee", :action=>"hr"
    end
  end
  def user_blocked_check
    if current_user.is_blocked?
      return true
    else
      return false
    end
  end
  
  def redirect_to_login
    session[:back_url] = request.url
    cookies.delete("_fedena_session")
    session[:user_id] = nil
    unless request.xhr?
      redirect_to '/'
    else
      render :js => "window.location = '/'"
    end
  end

  def check_if_loggedin
    if session[:user_id]
      unless current_user.is_blocked?
        redirect_to :controller => 'user', :action => 'dashboard'
      end
    end
  end

  def configuration_settings_for_hr
    hr = Configuration.find_by_config_value("HR")
    if hr.nil?
      redirect_to :controller => 'user', :action => 'dashboard'
      flash[:notice] = "#{t('flash_msg4')}"
    end
  end



  def configuration_settings_for_finance
    finance = Configuration.find_by_config_value("Finance")
    if finance.nil?
      redirect_to :controller => 'user', :action => 'dashboard'
      flash[:notice] = "#{t('flash_msg4')}"
    end
  end

  def only_admin_allowed
    redirect_to :controller => 'user', :action => 'dashboard' unless current_user.admin?
  end

  def protect_other_student_data
    if current_user.student? or current_user.parent?
      student = current_user.student_record if current_user.student?
      student = current_user.parent_record if current_user.parent?
      #      render :text =>student.id and return
      params[:id].nil?? student_id=session[:student_id]: student_id=params[:id]
      unless params[:id].to_i == student.id or params[:student].to_i == student.id or params[:student_id].to_i == student.id or student.siblings.select{|s| s.immediate_contact_id==current_user.guardian_entry.id}.collect(&:id).include?student_id.to_i

        flash[:notice] = "#{t('flash_msg5')}"
        redirect_to :controller=>"user", :action=>"dashboard"
      end
    end
  end

  def protect_user_data
    unless current_user.admin?
      unless params[:id].to_s == current_user.username
        flash[:notice] = "#{t('flash_msg5')}"
        redirect_to :controller=>"user", :action=>"dashboard"
      end
    end
  end

  def precision_label(val)
    @precision_count ||= FedenaPrecision.get_precision_count
    return sprintf("%0.#{@precision_count}f",val)
  end

  def protect_leave_history
    if current_user.employee?
      employee = Employee.find(params[:id])
      employee_user = employee.user
      unless employee_user.id == current_user.id
        unless current_user.role_symbols.include?(:hr_basics) or current_user.role_symbols.include?(:employee_attendance)
          flash[:notice] = "#{t('flash_msg6')}"
          redirect_to :controller=>"user", :action=>"dashboard"
        end
      end
    end
  end
  #  end

  #reminder filters
  def protect_view_reminders
    reminder = Reminder.find(params[:id2])
    unless reminder.recipient == current_user.id
      flash[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller=>"reminder", :action=>"index"
    end
  end

  def protect_sent_reminders
    reminder = Reminder.find(params[:id2])
    unless reminder.sender == current_user.id
      flash[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller=>"reminder", :action=>"index"
    end
  end

  #employee_leaves_filters
  def protect_leave_dashboard
    employee = Employee.find(params[:id])
    employee_user = employee.user
    #    unless permitted_to? :employee_attendance_pdf, :employee_attendance
    unless employee_user.id == current_user.id
      flash[:notice] = "#{t('flash_msg6')}"
      redirect_to :controller=>"user", :action=>"dashboard"
      #    end
    end
  end

  def protect_unauthorized_views
    employee = Employee.find(params[:id])
    employee_user = employee.user
    #    unless permitted_to? :employee_attendance_pdf, :employee_attendance
    unless employee_user.id == current_user.id or current_user.admin?
      flash[:notice] = "#{t('flash_msg6')}"
      render :text => "<p class='flash-msg'>"+flash[:notice]+"</p>"
    end
  end

  def protect_applied_leave
    applied_leave = ApplyLeave.find(params[:id])
    applied_employee = applied_leave.employee
    applied_employee_user = applied_employee.user
    unless applied_employee_user.id == current_user.id
      flash[:notice]="#{t('flash_msg5')}"
      redirect_to :controller=>"user", :action=>"dashboard"
    end
  end


  def render(options = nil, extra_options = {}, &block)
    unless options.nil?
      unless request.xhr?
        if options.class == Hash
          if options[:pdf]
            options ||= {}
            options = options.merge(:zoom => 0.80) if options[:zoom].blank? && options[:orientation] == 'Landscape'
          end
        end
      end
    end
    super(options, extra_options, &block)
  end

  def default_time_zone_present_time
    server_time = Time.now
    server_time_to_gmt = server_time.getgm
    @local_tzone_time = server_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find_by_id(time_zone.config_value)
        if zone.present?
          if zone.difference_type=="+"
            @local_tzone_time = server_time_to_gmt + zone.time_difference
          else
            @local_tzone_time = server_time_to_gmt - zone.time_difference
          end
        end
      end
    end
    return @local_tzone_time
  end

  #  def can_access_request? (action,controller)
  #    permitted_to?(action,controller)
  #  end

  def can_access_request? (privilege, object_or_sym = nil, options = {}, &block)
    permitted_to?(privilege, object_or_sym, options, &block)
  end

  def deliver_plugin_block(name,&block)
    if can_access_plugin? name.to_s
      self.instance_eval &block if block_given?
    end
  end

  def can_access_plugin?(plugin)
    FedenaPlugin.can_access_plugin?(plugin)
  end

  def can_access_feature?(feature)
    if Feature.find_by_feature_key(feature).try(:is_enabled)==false
      return false
    else
      return true
    end
  end

  def currency
    @currency ||= Configuration.currency
  end

  def change_time_to_local_time c_time
    FedenaTimeSet.current_time_to_local_time(c_time)
  end

  def payslip_range(pg, start_date, end_date, payment_period = nil)
    payment = (payment_period||pg.payment_period)
    if payment == 5
      format_date(start_date,:format => :month_year)
    elsif payment == 1
      format_date(start_date,:format => :short)
    else
      format_date(start_date,:format => :short) + " - " + format_date(end_date, :format => :short)
    end
  end

  def validate_parameters(presence = [])
    keys = params
    presence.each do |k|
      raise ParamterMissing unless keys.include? k.to_sym
    end
  end
  
  def set_translate_options
    CustomTranslation.translate_options ||= CustomTranslation.store_cache
  end
  
  def unasign_translate_options
    CustomTranslation.translate_options = nil
  end
  
  private


  def active_account_joins use_alias = false, alias_name = nil
    collection_name = use_alias ? (alias_name.present? ? alias_name : 'ffc') : "finance_fee_collections"
    " LEFT JOIN fee_accounts fa ON fa.id = #{collection_name}.fee_account_id "
  end

  def active_account_conditions use_alias = false, alias_name = nil
    collection_name = use_alias ? (alias_name.present? ? alias_name : 'ffc') : "finance_fee_collections"
    "(fa.id IS NULL OR fa.is_deleted = false)"
  end

  def account_filter filter= true
    return (@accounts_enabled = false) unless filter
    @accounts_enabled = (Configuration.get_config_value("MultiFeeAccountEnabled").to_i == 1)
    @accounts = @accounts_enabled ? FeeAccount.all : []
    filter_by_account = params[:fee_account_id].present? || @account_id.present?
    @account_id ||= params[:fee_account_id]
    @account_name = @account_id.present? ? (@account_id.to_i.zero? ? t('default_account') : 
        @accounts.select {|x| x.id == @account_id.to_i }.try(:last).try(:name)) : t('all_accounts') 
    [filter_by_account, filter_by_account ? (params[:fee_account_id].to_i == 0 ? nil : params[:fee_account_id]) : false]
  end

  # returns name of current financial year
  def current_financial_year_name
    FinancialYear.current_financial_year_name
  end

  def current_financial_year_id
    @current_financial_year[:id].zero? ? nil : @current_financial_year[:id]
  end

  # sets session data for logged user for financial year
  def set_user_financial_year reset = false
    # call this action with true only if needed to reset financial year in session with active financial year
    
    session[:financial_year] = FinancialYear.fetch_and_set_financial_year if reset
    FEDENA_SETTINGS[:current_financial_year] = session[:financial_year] || FinancialYear.current_financial_year
    @current_financial_year = FEDENA_SETTINGS[:current_financial_year]
    @current_financial_year_name = FinancialYear.current_financial_year_name
  end
  
  def find_academic_year
    @academic_year = AcademicYear.active.first
    if @academic_year.nil?
      if can_access_request? :index,:academic_years
        flash[:notice] = "#{t('set_up_academic_year')}"
        redirect_to :controller=>:academic_years ,:action=>:index and return
      else
        flash[:notice] = "#{t('set_up_academic_year_with_admin')}"
        redirect_to :controller => 'user', :action => 'dashboard' and return
      end
    end
  end
    
  def academic_year_id
    find_academic_year
    @academic_year_id = @academic_year.try(:id)
  end

  def financial_year_check
    @financial_year_enabled = FinancialYear.has_valid_transaction_date(@transaction_date)
    flash_text = "financial_year_payment_disabled#{current_user.admin || current_user.employee ? '' : '_admin'}"
    flash.now[:notice] = t(flash_text) unless @financial_year_enabled
  end

  def set_user_language
    lan = Configuration.find_by_config_key("Locale")
    lang = lan.config_value.present? ? lan.config_value : "en"
    institution_type = "ch"
    I18n.default_locale = :en
    Translator.fallback(true)
    if session[:language].nil?
      I18n.locale,@lan = "#{lang}-#{institution_type}",lang
    else
      I18n.locale,@lan = "#{session[:language]}-#{institution_type}",session[:language]
    end
    News.new.reload_news_bar
  end
  def page_not_found
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end
end
