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

class SmsController < ApplicationController
  lock_with_feature  :sms_enhancement, :only => [:settings]
  before_filter :login_required
  before_filter :validate_sms_settings, :only => [:send_sms_to_recipients]
  filter_access_to :index, :settings,:update_general_sms_settings, :send_sms, :birthday_sms, :show_sms_messages

  filter_access_to :students,:batches,:attribute_check => true,
    :load_method => lambda {
    if SmsSetting.find_by_settings_key("ApplicationEnabled").is_enabled?
      if SmsSetting.find_by_settings_key("StudentSmsEnabled").is_enabled?
        SmsSetting.find_by_settings_key("StudentSmsEnabled")
      elsif SmsSetting.find_by_settings_key("ParentSmsEnabled").is_enabled?
        SmsSetting.find_by_settings_key("ParentSmsEnabled")
      end
    else
      SmsSetting.find_by_settings_key("ApplicationEnabled")
    end
  }
  # filter_access_to :students,:batches, :attribute_check => true,:load_method => lambda {SmsSetting.find_by_settings_key("ApplicationEnabled").is_enabled? ? SmsSetting.find_by_settings_key("ParentSmsEnabled") : SmsSetting.find_by_settings_key("ApplicationEnabled")}
  filter_access_to :employees,:departments ,:attribute_check => true,:load_method => lambda {SmsSetting.find_by_settings_key("ApplicationEnabled").is_enabled? ? SmsSetting.find_by_settings_key("EmployeeSmsEnabled") : SmsSetting.find_by_settings_key("ApplicationEnabled")}
  filter_access_to :sms_all, :list_employees,:show_sms_logs ,:attribute_check => true,:load_method => lambda {SmsSetting.find_by_settings_key("ApplicationEnabled")}

  def index
    @sms_setting = SmsSetting.new()
    @parents_sms_enabled = SmsSetting.find_by_settings_key("ParentSmsEnabled")
    @students_sms_enabled = SmsSetting.find_by_settings_key("StudentSmsEnabled")
    @employees_sms_enabled = SmsSetting.find_by_settings_key("EmployeeSmsEnabled")
  end

  def settings
    #old code
    all_sms_settings = SmsSetting.all
    @application_sms_enabled = all_sms_settings.find_by_settings_key("ApplicationEnabled")
    
    @student_admission_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="StudentAdmissionEnabled" && x.user_type=="Student"}
    @student_admission_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="StudentAdmissionEnabled" && x.user_type=="Guardian"}
    
    @employee_admission_sms_enabled_employee = all_sms_settings.find{|x| x.settings_key=="EmployeeAdmissionEnabled" && x.user_type=="Employee"}
    
    @exam_schedule_result_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="ExamScheduleResultEnabled" && x.user_type=="Student"}
    @exam_schedule_result_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="ExamScheduleResultEnabled" && x.user_type=="Guardian"}
    
    @student_attendance_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="AttendanceEnabled" && x.user_type=="Student"}
    @student_attendance_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="AttendanceEnabled" && x.user_type=="Guardian"}
    
    @news_events_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="NewsEventsEnabled" && x.user_type=="Student"}
    @news_events_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="NewsEventsEnabled" && x.user_type=="Guardian"}
    @news_events_sms_enabled_employee = all_sms_settings.find{|x| x.settings_key=="NewsEventsEnabled" && x.user_type=="Employee"}
    
    @fee_submission_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="FeeSubmissionEnabled" && x.user_type=="Student"}
    @fee_submission_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="FeeSubmissionEnabled" && x.user_type=="Guardian"}
    @fee_submission_sms_enabled_employee = all_sms_settings.find{|x| x.settings_key=="FeeSubmissionEnabled" && x.user_type=="Employee"}
    
    @timetable_swap_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="TimetableSwapEnabled" && x.user_type=="Student"} 
    @timetable_swap_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="TimetableSwapEnabled" && x.user_type=="Guardian"} 
    @timetable_swap_sms_enabled_employee = all_sms_settings.find{|x| x.settings_key=="TimetableSwapEnabled" && x.user_type=="Employee"} 
    @delayed_sms_notification_enabled = all_sms_settings.find_by_settings_key("DelayedSMSNotificationEnabled")
    
    if request.post?
      SmsSetting.update(@application_sms_enabled.id,:is_enabled=>params[:sms_settings][:application_enabled])
      flash[:notice] = "#{t('flash1')}"
      redirect_to :action=>"settings"
    end
  end

  def update_general_sms_settings
    all_sms_settings = SmsSetting.all
    @student_admission_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="StudentAdmissionEnabled" && x.user_type=="Student"}
    @student_admission_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="StudentAdmissionEnabled" && x.user_type=="Guardian"}
    
    @employee_admission_sms_enabled_employee = all_sms_settings.find{|x| x.settings_key=="EmployeeAdmissionEnabled" && x.user_type=="Employee"}
    
    @exam_schedule_result_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="ExamScheduleResultEnabled" && x.user_type=="Student"}
    @exam_schedule_result_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="ExamScheduleResultEnabled" && x.user_type=="Guardian"}
    
    @student_attendance_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="AttendanceEnabled" && x.user_type=="Student"}
    @student_attendance_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="AttendanceEnabled" && x.user_type=="Guardian"}
    
    @news_events_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="NewsEventsEnabled" && x.user_type=="Student"}
    @news_events_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="NewsEventsEnabled" && x.user_type=="Guardian"}
    @news_events_sms_enabled_employee = all_sms_settings.find{|x| x.settings_key=="NewsEventsEnabled" && x.user_type=="Employee"}
    
    @fee_submission_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="FeeSubmissionEnabled" && x.user_type=="Student"}
    @fee_submission_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="FeeSubmissionEnabled" && x.user_type=="Guardian"}
    @fee_submission_sms_enabled_employee = all_sms_settings.find{|x| x.settings_key=="FeeSubmissionEnabled" && x.user_type=="Employee"}
    
    @timetable_swap_sms_enabled_student = all_sms_settings.find{|x| x.settings_key=="TimetableSwapEnabled" && x.user_type=="Student"} 
    @timetable_swap_sms_enabled_guardian = all_sms_settings.find{|x| x.settings_key=="TimetableSwapEnabled" && x.user_type=="Guardian"} 
    @timetable_swap_sms_enabled_employee = all_sms_settings.find{|x| x.settings_key=="TimetableSwapEnabled" && x.user_type=="Employee"} 
    @delayed_sms_notification_enabled = all_sms_settings.find_by_settings_key("DelayedSMSNotificationEnabled")
    
    @student_admission_sms_enabled_student.update_attributes(:is_enabled=>params[:general_settings][:student_admission_sms_enabled_student])
    @student_admission_sms_enabled_guardian.update_attributes(:is_enabled=>params[:general_settings][:student_admission_sms_enabled_guardian])
    @employee_admission_sms_enabled_employee.update_attributes(:is_enabled=>params[:general_settings][:employee_admission_sms_enabled_employee])
    
    @exam_schedule_result_sms_enabled_student.update_attributes(:is_enabled=>params[:general_settings][:exam_schedule_result_sms_enabled_student])
    @exam_schedule_result_sms_enabled_guardian.update_attributes(:is_enabled=>params[:general_settings][:exam_schedule_result_sms_enabled_guardian])
    
    @student_attendance_sms_enabled_student.update_attributes(:is_enabled=>params[:general_settings][:student_attendance_sms_enabled_student])
    @student_attendance_sms_enabled_guardian.update_attributes(:is_enabled=>params[:general_settings][:student_attendance_sms_enabled_guardian])
    
    @news_events_sms_enabled_student.update_attributes(:is_enabled=>params[:general_settings][:news_events_sms_enabled_student])
    @news_events_sms_enabled_guardian.update_attributes(:is_enabled=>params[:general_settings][:news_events_sms_enabled_guardian])
    @news_events_sms_enabled_employee.update_attributes(:is_enabled=>params[:general_settings][:news_events_sms_enabled_employee])
    
    @fee_submission_sms_enabled_student.update_attributes(:is_enabled=>params[:general_settings][:fee_submission_sms_enabled_student])
    @fee_submission_sms_enabled_guardian.update_attributes(:is_enabled=>params[:general_settings][:fee_submission_sms_enabled_guardian])
    @fee_submission_sms_enabled_employee.update_attributes(:is_enabled=>params[:general_settings][:fee_submission_sms_enabled_employee])
    
    @timetable_swap_sms_enabled_student.update_attributes(:is_enabled=>params[:general_settings][:timetable_swap_sms_enabled_student])
    @timetable_swap_sms_enabled_guardian.update_attributes(:is_enabled=>params[:general_settings][:timetable_swap_sms_enabled_guardian])
    @timetable_swap_sms_enabled_employee.update_attributes(:is_enabled=>params[:general_settings][:timetable_swap_sms_enabled_employee])
    
    ## we can use below format for new keys, instead of writing seed
    @delayed_sms_notification_enabled = SmsSetting.create_or_update("DelayedSMSNotificationEnabled", params[:general_settings][:delayed_sms_notification_enabled])
    flash[:notice] = "#{t('flash2')}"
    redirect_to :action=>"settings"
  end
  
  def send_sms
  end
  
  
  def user_type_selection
    if params[:user_type] == "group"
      @user_groups = UserGroup.all.sort_by{|x| x.name.downcase}
      render :update do |page|
        page.replace_html "intermediate_selector", :partial => "group_selector"
        page.replace_html "send_portion", ""
      end
    end
    
  end
  
  def user_type_selection_birthday
    @send_type = "birthday"
    if params[:user_type] == "student"
      @batches = Batch.active.all(:include=>:course)
      render :update do |page|
        page.replace_html "intermediate_selector", :partial => "batch_selector"
        page.replace_html "send_portion", ""
      end
    elsif params[:user_type] == "employee"
      @departments = EmployeeDepartment.active.all
      render :update do |page|
        page.replace_html "intermediate_selector", :partial => "department_selector"
        page.replace_html "send_portion", ""
      end
    end
  end
  
  def load_student_sms_send
    @user_type =  "Student"
    @templates = MessageTemplate.custom_templates.all(:joins=>[:message_template_contents], :conditions=>["message_template_contents.user_type='Student'"], :include=>"message_template_contents")
    students = Student.all(:conditions=>["phone2 is not NULL and phone2 !='' "])
    @final_values= SmsMessage.fetch_students(students)
    render :update do |page|
      page.replace_html "send_portion", :partial => "student_sms_send"
      page.replace_html "intermediate_selector", " "
    end
  end
  
  
  def load_employee_sms_send
    @user_type =  "Employee"
    @templates = MessageTemplate.custom_templates.all(:joins=>[:message_template_contents], :conditions=>["message_template_contents.user_type='Employee'"], :include=>"message_template_contents")
    @final_empployee_values = SmsMessage.fetch_employees
    render :update do |page|
      page.replace_html "send_portion", :partial => "employee_sms_send"
      page.replace_html "intermediate_selector", " "
    end
  end
  
  
  def load_guardian_sms_send
    @user_type =  "Guardian"
    @templates = MessageTemplate.custom_templates.all(:joins=>[:message_template_contents], :conditions=>["message_template_contents.user_type='Guardian'"], :include=>"message_template_contents")
    students = Student.all(:joins=> :immediate_contact, :conditions=>["guardians.mobile_phone is not NULL and mobile_phone !='' "], :order=>"first_name, middle_name, last_name")
    @final_values= SmsMessage.fetch_students(students)
    render :update do |page|
      page.replace_html "send_portion", :partial => "guardian_sms_send"
      page.replace_html "intermediate_selector", " "
    end
  end
  
  def load_group_sms_send
    @group = UserGroup.find(params[:group_id])
    @user_list = @group.fetch_users_list.present? ? @group.fetch_users_list : []
    @user_type =  "GroupMembers" 
    @templates = MessageTemplate.custom_templates.all(:include=>"message_template_contents")
    render :update do |page|
      page.replace_html "send_portion", :partial => "group_sms_send"
    end
  end
  
  
  def template_content_for_send
    @message_template =  MessageTemplate.find(params[:template_id])
    @user_type = params[:user_type]
    if @user_type == "GroupMembers"
      # replace div and place text_area based on template
      @student_template_content = @message_template.student_template_content.content if @message_template.student_template_content.present?
      @employee_template_content = @message_template.employee_template_content.content if @message_template.employee_template_content.present?
      @guardian_template_content = @message_template.guardian_template_content.content if @message_template.guardian_template_content.present?
    else
      @message_template_content  = @message_template.template_content_for_user_type(@user_type)
    end
    render :update do |page|
      page.replace_html "template_content", :partial => "template_content_for_send"
    end
  end
  
  
  def send_sms_to_recipients
    all_parents = params[:all_parents].present? ? true : false
    immediate_contact = params[:all_immediate].present? ? true : false
    date = params[:message][:date].present? ?  params[:message][:date].to_date : Date.today
    sms_type = params[:message][:type] 
    send_type = params[:message][:send_type]
    user_type = params[:message][:user_type]
    select_data = JSON.parse(params[:recipients])
    selected_ids = fetch_student_ids(select_data,user_type) if (user_type == 'Student' or  user_type == 'Guardian' ) and !send_type.present?
    selected_ids = fetch_employee_ids(select_data) if user_type == 'Employee' and !send_type.present?
    selected_ids = select_data["0"]["b1"]["list"].select{|e| e["selected"]==1 }.collect{|e| e["id"]} if send_type == 'birthday'  or user_type == 'GroupMembers' 
    user_group = UserGroup.find(params[:group_id]) if params[:group_type] == 'group'
    group = MessageBuilder.build_group(params[:group_id], params[:group_type]) 
    if sms_type == "new_message"
      if user_type ==  "Student"
        recipients = {:student_ids => selected_ids }
      elsif user_type == "Employee"
        recipients = {:employee_ids => selected_ids } 
      elsif user_type == "Guardian"
        recipients = {:guardian_sids => selected_ids }   
      elsif user_type == "GroupMembers"
        recipients = user_group.fetch_recipients_lists(selected_ids) if params[:group_type] == 'group'
        recipients = fetch_user_list(selected_ids) if params[:group_type] == 'undefined'
      end
      message = params[:message][:message]
      SmsManager.send_plain_message(message,recipients,group, date, all_parents, immediate_contact)
      flash[:notice] = "#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}"
      render(:update) do |page|
        page.reload
      end
    elsif sms_type == "template"
      template_message =  params[:message][:template_message]
      if user_type ==  "Student"
        template_contents = {:student => template_message}  
        recipients = {:student_ids => selected_ids } 
      elsif user_type == "Employee"
        template_contents = {:employee => template_message}
        recipients = {:employee_ids => selected_ids } 
      elsif user_type == "Guardian"
        template_contents = {:guardian => template_message}
        recipients = {:guardian_sids => selected_ids }   
      elsif user_type == "GroupMembers" 
        recipients = user_group.fetch_recipients_lists(selected_ids) if params[:group_type] == 'group'
        recipients = fetch_user_list(selected_ids) if params[:group_type] == 'undefined'
        template_contents = {:employee => template_message[:employee], :student => template_message[:student], :guardian => template_message[:guardian]}
      end
      validation_result = MessageTemplate.validate_received_template(template_contents)
      if validation_result == true 
        SmsManager.send_template_based_messages(template_contents,recipients,group,false,date, all_parents, immediate_contact)
        flash[:notice] = "#{t('sms_sending_intiated_view_log', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}"
        render(:update) do |page|
          page.reload
        end
      else 
        @errors = validation_result
        render :update do |page|
          page.replace_html "error_messages", :partial => "error_messages"
        end
      end 
    end
  end

  check_request_fingerprint :send_sms_to_recipients  

  def students
    @batches=Batch.active.all(:include=>:course)
    if request.post?
      error=false
      unless params[:send_sms][:student_ids].nil?
        student_ids = params[:send_sms][:student_ids]
        sms_setting = SmsSetting.new()
        @recipients=[]
        student_ids.each do |s_id|
          student = Student.find(s_id)
          guardian = student.immediate_contact
          if student.is_sms_enabled
            if sms_setting.student_sms_active
              @recipients.push student.phone2 unless (student.phone2.nil? or student.phone2 == "")
            end
            if sms_setting.parent_sms_active
              unless guardian.nil?
                @recipients.push guardian.mobile_phone unless (guardian.mobile_phone.nil? or guardian.mobile_phone == "")
              end
            end
          end
        end        
        @recipients = @recipients.compact.uniq
        unless @recipients.empty?
          message = params[:send_sms][:message]
          unless message.blank?
            @recipients.each_slice(300) do |batch_recipients|
              sms = Delayed::Job.enqueue(SmsManager.new(message,batch_recipients),{:queue => 'sms'})
            end
            # raise @recipients.inspect
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
              page.visual_effect(:highlight, 'status-message')
              page.replace_html 'student-list',:text=>""
            end
          else
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('message_blank')}</p>"
            end
          end
        else
          error=true
        end
      else
        error=true
      end
      if error
        render(:update) do |page|
          page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('select_valid_students')}</p>"
        end
      end
    end
  end

  def list_students
    batch = Batch.find(params[:batch_id])
    @students = batch.students.all(:select => 'students.id,admission_no,students.first_name,middle_name,students.last_name,students.phone2,students.roll_number,guardians.id as guardian_id,guardians.mobile_phone',:joins => 'LEFT OUTER JOIN `guardians` ON `guardians`.id = `students`.immediate_contact_id', :conditions=>'is_sms_enabled=true', :order => 'first_name')
    @sms_setting = SmsSetting.new()
    #    @students = Student.find_all_by_batch_id(batch.id,:conditions=>'is_sms_enabled=true')
  end

  def batches
    @batches = Batch.all(:select => "batches.*,CONCAT(courses.code,'-',batches.name) as course_full_name,count(DISTINCT IF((students.phone2 != '' OR guardians.mobile_phone != '') AND students.is_sms_enabled = true,students.id,NULL)) as students_count",:joins => "INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN students ON students.batch_id = batches.id LEFT OUTER JOIN guardians ON guardians.id = students.immediate_contact_id",:conditions => { :is_deleted => false, :is_active => true },:order => "course_full_name",:group => 'id')
    if request.post?
      unless params[:send_sms][:batch_ids].nil?
        batch_ids = params[:send_sms][:batch_ids]
        sms_setting = SmsSetting.new()
        @recipients = []
        batch_ids.each do |b_id|
          batch = Batch.find(b_id)
          batch_students = batch.students
          batch_students.each do |student|
            if student.is_sms_enabled
              if sms_setting.student_sms_active
                @recipients.push student.phone2 unless (student.phone2.nil? or student.phone2 == "")
              end
              if sms_setting.parent_sms_active
                guardian = student.immediate_contact
                unless guardian.nil?
                  @recipients.push guardian.mobile_phone unless (guardian.mobile_phone.nil? or guardian.mobile_phone == "")
                end
              end
            end
          end
        end
        @recipients = @recipients.compact.uniq
        unless @recipients.empty?
          message = params[:send_sms][:message]
          unless message.blank?
            @recipients.each_slice(300) do |batch_recipients|
              sms = Delayed::Job.enqueue(SmsManager.new(message,batch_recipients),{:queue => 'sms'})
            end
            render(:update) do |page|
              page.replace_html 'batches_list',:text=>""
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
              page.visual_effect(:highlight, 'status-message')
            end
          else
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('message_blank')}</p>"
            end
          end
        else
          error = true
        end
      else
        error = true
      end
      if error
        render(:update) do |page|
          page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('select_valid_batches')}</p>"
        end
      end
    end
  end

  def sms_all
    batches=Batch.active.all({:include=>{:students=>:immediate_contact}})
    sms_setting = SmsSetting.new()
    student_sms=sms_setting.student_sms_active
    parent_sms=sms_setting.parent_sms_active
    employee_sms=sms_setting.employee_sms_active
    @recipients = []
    batches.each do |batch|
      batch_students = batch.students
      batch_students.each do |student|
        if student.is_sms_enabled
          if student_sms
            @recipients.push student.phone2 unless (student.phone2.nil? or student.phone2 == "")
          end
          if parent_sms
            guardian = student.immediate_contact
            unless guardian.nil?
              @recipients.push guardian.mobile_phone unless (guardian.mobile_phone.nil? or guardian.mobile_phone == "")
            end
          end
        end
      end
    end
    emp_departments = EmployeeDepartment.active_and_ordered(:include=>:employees)
    emp_departments.each do |dept|
      dept_employees = dept.employees
      dept_employees.each do |employee|
        if employee_sms
          @recipients.push employee.mobile_phone unless (employee.mobile_phone.nil? or employee.mobile_phone == "")
        end
      end
    end
    @recipients = @recipients.compact.uniq
    unless @recipients.empty?
      message = params[:send_sms][:message]
      @recipients.each_slice(300) do |batch_recipients|
        Delayed::Job.enqueue(SmsManager.new(message,batch_recipients),{:queue => 'sms'})
      end
    end

  end

  def employees
    if request.post?
      unless params[:send_sms][:employee_ids].nil?
        employee_ids = params[:send_sms][:employee_ids]
        sms_setting = SmsSetting.new()
        @recipients=[]
        employee_ids.each do |e_id|
          employee = Employee.find(e_id)
          if sms_setting.employee_sms_active
            @recipients.push employee.mobile_phone unless (employee.mobile_phone.nil? or employee.mobile_phone == "")
          end
        end
        @recipients = @recipients.compact.uniq
        unless @recipients.empty?
          message = params[:send_sms][:message]
          unless message.blank?
            @recipients.each_slice(300) do |batch_recipients|
              Delayed::Job.enqueue(SmsManager.new(message,batch_recipients),{:queue => 'sms'})
            end
            render(:update) do |page|
              page.replace_html 'employee-list',:text=>""
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
              page.visual_effect(:highlight, 'status-message')
            end
          else
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('message_blank')}</p>"
            end
          end
        else
          error = true
        end
      else
        error = true
      end
      if error
        render(:update) do |page|
          page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('select_valid_employees')}</p>"
        end
      end
    end
  end

  def list_employees
    dept = EmployeeDepartment.find(params[:dept_id])
    @employees = dept.employees.all(:order => 'first_name')
  end

  def departments
    @departments = EmployeeDepartment.all(:select =>"employee_departments.*,COUNT(IF(employees.mobile_phone != '', employees.id,NULL)) as employees_count",:joins => "LEFT OUTER JOIN employees ON employees.employee_department_id = employee_departments.id",:group => 'id',:order => 'name')
    if request.post?
      unless params[:send_sms][:dept_ids].nil?
        dept_ids = params[:send_sms][:dept_ids]
        sms_setting = SmsSetting.new()
        @recipients = []
        dept_ids.each do |d_id|
          department = EmployeeDepartment.find(d_id)
          department_employees = department.employees
          department_employees.each do |employee|
            if sms_setting.employee_sms_active
              @recipients.push employee.mobile_phone unless (employee.mobile_phone.nil? or employee.mobile_phone == "")
            end
          end
        end
        @recipients = @recipients.compact.uniq
        unless @recipients.empty?
          message = params[:send_sms][:message]
          unless message.blank?
            @recipients.each_slice(300) do |batch_recipients|
              Delayed::Job.enqueue(SmsManager.new(message,batch_recipients),{:queue => 'sms'})
            end
            render(:update) do |page|
              page.replace_html 'departments_list',:text=>""
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('sms_sending_intiated', :log_url => url_for(:controller => "sms", :action => "show_sms_messages"))}</p>"
              page.visual_effect(:highlight, 'status-message')
            end
          else
            render(:update) do |page|
              page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('message_blank')}</p>"
            end
          end
        else
          error = true
        end
      else
        error = true
      end
      if error
        render(:update) do |page|
          page.replace_html 'status-message',:text=>"<p class=\"flash-msg\">#{t('select_valid_departments')}</p>"
        end
      end
    end
  end

  def show_sms_messages
    @automated =  params[:automated] == "true" ? true : false
    @start_date = params[:start_date].present? ? params[:start_date].to_date : Date.today - 1.months 
    @end_date = params[:end_date].present? ? params[:end_date].to_date : Date.today
    @sms_messages = SmsMessage.paginate_sms_message(params[:page], @automated,@start_date, @end_date )
    @total_sms = Configuration.get_config_value("TotalSmsCount")
    unless  @start_date > @end_date
      if request.xhr? 
        if params[:page]=="1"
          render :update do |page|
            page << 'j("#custom_messages").addClass("toggle_active"); j("#automatic_alerts").removeClass("toggle_active");'
            page.replace_html "message_list", :partial => "sms_messages"
          end
        else 
          render :update do |page|
            page.insert_html :bottom, "message_list", :partial => "sms_messages"
          end
        end
      end
    else
      flash[:notice] = t('date_invalid')
      render :update do |page|
        page.reload
      end
    end
  end

  def show_sms_logs
    @sms_message = SmsMessage.find(params[:id])
    @sms_logs = @sms_message.sms_logs.all(:order=>"id DESC",:include=>[:user])
    render(:update) do |page|
      page.replace_html 'logs', :partial=>"show_sms_logs"
    end
  end
  
  def birthday_sms
    @send_type = "birthday"
    @tempalte_edit_setting = MultiSchool.current_school.edit_sms_template
  end
  
  def student_birthday_sms_send
    @send_type = params[:send_type]
    @date = params[:date].present? ?  params[:date].to_date : Date.today
    @user_type =  "Student"
    @templates = MessageTemplate.birthday_templates.all(:joins=>[:message_template_contents], :conditions=>["message_template_contents.user_type='Student'"], :include=>"message_template_contents")
    #birthday students
    @students = Student.active.all(:conditions=>["MONTH(date_of_birth) = ? and DAY(date_of_birth) = ?", @date.month, @date.day]).sort{|a,b| a.full_name.downcase <=> b.full_name.downcase}
    @student_list = @students.map { |s| {"id"=>s.id ,"value"=>s.full_name_with_admission_no ,"child_count"=>0} }
    render :update do |page|
      page.replace_html "send_portion", :partial => "birthday_student_sms_send"
    end
  end
  
  def employee_birthday_sms_send
    @send_type = params[:send_type]
    @date = params[:date].present? ?  params[:date].to_date : Date.today
    @user_type =  "Employee"
    @templates = MessageTemplate.birthday_templates.all(:joins=>[:message_template_contents], :conditions=>["message_template_contents.user_type='Employee'"], :include=>"message_template_contents")
    #birthday_employees
    @employees = Employee.all(:conditions=>["MONTH(date_of_birth) = ? and DAY(date_of_birth) = ?", @date.month, @date.day]).sort{|a,b| a.full_name.downcase <=> b.full_name.downcase}
    @employee_list = @employees.map { |e| {"id"=>e.id ,"value"=>e.full_name ,"child_count"=>0} }
    render :update do |page|
      page.replace_html "send_portion", :partial => "employee_birthday_sms_send"
    end
  end
  
  private
  
  def fetch_student_ids(select_data,user_type)
    student_ids = []
    select_data["0"]["b1"]["list"].each_with_index do |element,index|
      if element["selected"] == 1
        students = Student.active.all(:conditions=>["batch_id = ? and (phone2 is not NULL and phone2 !='') ", element["id"]]).collect(&:id) unless user_type == 'Guardian'
        students = Student.active.all(:joins=> :immediate_contact, :conditions=>["batch_id = ? and (guardians.mobile_phone is not NULL and mobile_phone !='') ", element["id"]]).collect(&:id) if user_type == 'Guardian'
        student_ids = student_ids + students
      elsif element["selected"]==0
        # do nothing
      else
        select_data["1"]["b1"+"b"+index.to_s]["list"].each do |subelement|
          student_ids =  student_ids << subelement["id"]  if subelement["selected"] == 1
        end
      end
    end
    return student_ids
  end
  
  def fetch_employee_ids(select_data)
    employee_ids = []
    #two level for departments
    select_data["0"]["b1"]["list"].each_with_index do |element,index|
      if element["selected"]==1
        employees = Employee.all(:conditions=>["employee_department_id = ? and (mobile_phone is not NULL and mobile_phone !='') ",element["id"] ], :order=>"first_name, middle_name, last_name").collect(&:id)
        employee_ids = employee_ids + employees
      elsif element["selected"]==0
        # do nothing
      else
        select_data["1"]["b1"+"b"+index.to_s]["list"].each do |subelement|
          if subelement["selected"]==1
            employee_ids = employee_ids << subelement["id"]
          end
        end
      end
    end
    return employee_ids
  end
  
  def fetch_user_list(selected_ids)
    users = User.all(:include=>[:employee_entry, :student_entry], :conditions=>["id in (?)",selected_ids])
    student_users = users.select{|u| u.student == true}
    employee_users =  users.select{|u| u.employee == true}
    student_ids =  student_users.collect{|u| u.student_entry.id }
    employee_ids = employee_users.collect{|u| u.employee_entry.id }
    return {:student_ids => student_ids, :employee_ids => employee_ids , :guardian_sids => student_ids}
  end
  
end
