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

class ReminderController < ApplicationController
  before_filter :login_required
  #  filter_access_to [:sent_reminder,:index]
  filter_access_to :all
  before_filter :protect_view_reminders, :only=>[:view_reminder,:mark_unread,:delete_reminder_by_recipient]
  before_filter :protect_sent_reminders, :only=>[:view_sent_reminder,:delete_reminder_by_sender]
  check_request_fingerprint :create_reminder

  def index
    @user = current_user
    @reminders = Reminder.paginate(:page => params[:page], :conditions=>["recipient = '#{@user.id}' and is_deleted_by_recipient = false"], :order=>"created_at DESC",:include=>:user)
    @read_reminders = Reminder.find_all_by_recipient(@user.id, :conditions=>"is_read = true and is_deleted_by_recipient = false", :order=>"created_at DESC")
    @new_reminder_count = Reminder.find_all_by_recipient(@user.id, :conditions=>"is_read = false and is_deleted_by_recipient = false")
    @all_reminders = Reminder.find_all_by_recipient(@user.id,:conditions => {:is_deleted_by_recipient => false}, :order=>"created_at DESC")
  end
  
  def model_box
    @user = current_user
    @all_reminders = Reminder.find_all_by_recipient(@user.id,:conditions => {:is_deleted_by_recipient => false}, :order=>"created_at DESC")
    render_model_box 
  end

  def create_reminder
    @user = current_user
    @new_reminder_count = Reminder.find_all_by_recipient(@user.id, :conditions=>"is_read = false")
    if request.post?
      @reminder=Reminder.new(params[:reminder])
      # ReminderAttachmentRelation.create(:reminder=>@reminder,:reminder_attachment)
      # temporary reminder object to run model validations , do not save this object
      @reminder.sender=@user.id
      @reminder.recipient=@user.id
      recipients=params[:recipients_employees]+params[:recipients_students]+params[:recipients_parents]
      is_valid=@reminder.valid?
      if recipients.blank?
        @reminder.errors.add_to_base("Recipient list is empty")
      end
      if @reminder.errors.empty?
        recipients_array =[]
        recipients_array += comma_string_to_integer_array(params[:recipients_employees])
        recipients_array += comma_string_to_integer_array(params[:recipients_students])
        student_ids=comma_string_to_integer_array(params[:recipients_parents])
        recipients_array+=get_parent_ids_from_student_ids(student_ids)
        # Reminder.delay.send_message_to_list(@user.id,recipients_array,@reminder.subject,@reminder.body)
        @reminder.reminder_attachments.collect(&:save)
        attachments_list=@reminder.reminder_attachments.collect(&:id)
        Delayed::Job.enqueue(
          DelayedReminderJob.new(
            :sender_id  => @user.id,
            :recipient_ids => recipients_array,
            :subject=>@reminder.subject,
            :body=>@reminder.body,
            :attachments_list=>attachments_list
          )
        )
        # Reminder.delay.send_message_to_list_with_attachments(@user.id,recipients_array,@reminder.subject,@reminder.body,attachments_list)
        # reminder.reminder_attachments.collect(&:attachment)
        flash[:notice]=t('flash1')
        redirect_to :back
      else
        @reminder_attachment_relations =  @reminder.reminder_attachment_relations.build
        @reminder_attachments=@reminder_attachment_relations.build_reminder_attachment.to_a
        @reminder.reminder_attachments=@reminder_attachments.to_a
        get_departments_batches_and_parents()
        retain_selected_recipients()
        render :create_reminder
      end
    else
      @reminder=Reminder.new
      @reminder_attachment_relations =  @reminder.reminder_attachment_relations.build
      @reminder_attachments=@reminder_attachment_relations.build_reminder_attachment.to_a
      @reminder.reminder_attachments=@reminder_attachments.to_a
      get_departments_batches_and_parents()
      # when recipients list is passed as argument
      unless params[:send_to].nil?
        recipients_array = params[:send_to].split(",").collect{ |s| s.to_i }
        @recipients = User.active.find(recipients_array,:order=>"first_name ASC")
      end
    end
  end

  def select_employee_department
    @user = current_user
    if @user.admin? or @user.employee?
      @departments = EmployeeDepartment.active_and_ordered
    elsif @user.parent?
      @departments =[]
    end

    render :partial=>"select_employee_department"
  end

  def select_users
    @user = current_user
    users = User.active.find(:all, :conditions=>"student = false")
    @to_users = users.map { |s| s.id unless s.nil? }
    render :partial=>"to_users", :object => @to_users
  end

  def select_student_course
    @user = current_user
    if @user.admin? or @user.employee?
      @batches = Batch.active
    elsif @user.student?
      @batches = @user.student_record.batch.to_a
    elsif @user.parent?
      @batches =""
    end
    render :partial=> "select_student_course"
  end

  def select_parents
    @user = current_user
    if @user.admin?
      @parents_for_batch = Batch.active
    elsif @user.employee? and @user.has_required_control?
      @parents=[]
      @parents+=@user.employee_record.batches
      @user.employee_record.subjects.each do |subject|
        @parents<<subject.batch
      end
      @parents.uniq!
    elsif @user.student?
      @parents = @user.student_record.immediate_contact.to_a
    elsif @user.parent?
      @parents =""
    end
    render :partial=> "select_student_course"
  end

  def to_employees
    if params[:dept_id] == ""
      render :update do |page|
        page.replace_html "to_employees", :text => ""
      end
      return
    end
    department = EmployeeDepartment.find(params[:dept_id])
    if @current_user.admin? or @current_user.employee?
      employees = department.employees.sort_by{|a| a.full_name.downcase}
    elsif @current_user.student?
      employees=[]
      if @current_user.student_record.batch.present? and @current_user.student_record.batch.employees.present?
        @current_user.student_record.batch.employees.each do |employee|
          employees<<employee if employee.employee_department_id==department.id
        end
      end
      if @current_user.student_record.subjects.present?
        @current_user.student_record.subjects.each do |subject|
          if subject.employees.present?
            subject.employees.each do |employee|
              employees<<employee if employee.employee_department_id==department.id
            end
          end
        end
      end
      if @current_user.student_record.batch.subjects.present?
        @current_user.student_record.batch.subjects.all(:conditions=>["elective_group_id IS NULL"]).each do |subject|
          if subject.employees.present? and subject.batch_id==@current_user.student_record.batch_id
            subject.employees.each do |employee|
              employees<<employee if employee.employee_department_id==department.id
            end
          end
        end
      end
      employees.uniq!

    elsif @current_user.parent?
      @batches=[]
      Student.find_all_by_sibling_id(Guardian.find_by_user_id(@current_user.id).ward_id).each do |student|
        @batches<<student.batch
      end
      @subjects=[]
      Student.find_all_by_sibling_id(Guardian.find_by_user_id(@current_user.id).ward_id).each do |student|
        @subjects+=student.subjects if student.subjects.present?
      end
      @normal_subjects=[]
      Student.find_all_by_sibling_id(Guardian.find_by_user_id(@current_user.id).ward_id).each do |student|
        @normal_subjects+=student.batch.subjects.all(:conditions=>["elective_group_id IS NULL"]) if student.batch.subjects.present?
      end

      employees=[]
      @batches.each do |batch|
        batch.employees.each do |employee|
          employees<<employee if employee.employee_department_id==department.id
        end
      end
      @subjects.each do |subject|
        if subject.employees.present?
          subject.employees.each do |employee|
            employees<<employee
          end
        end
      end
      @normal_subjects.each do |subject|
        if subject.employees.present?
          subject.employees.each do |employee|
            employees<<employee
          end
        end
      end
      employees.uniq!

    else
      employees=[]
    end

    @to_employees = employees.map { |s| s.user.id unless s.user.nil? }

    @to_employees.delete nil
    render :update do |page|
      page.replace_html 'to_employees', :partial => 'to_employees', :object => @to_employees
    end
  end

  def to_students
    if params[:batch_id] == ""
      render :update do |page|
        page.replace_html "to_students", :text => ""
      end
      return
    end

    batch = Batch.find(params[:batch_id])
    if @current_user.admin? or @current_user.employee? or @current_user.student?
      students = batch.students.sort_by{|a| a.full_name.downcase}
    elsif @current_user.parent?
      students =batch.students.find(:all,:conditions=>["sibling_id=?",Guardian.find_by_user_id(@current_user.id).ward_id])
    else
      students=[]
    end

    @to_students = students.map { |s| s.user.id unless s.user.nil? }
    @to_students.delete nil
    render :update do |page|
      page.replace_html 'to_students', :partial => 'to_students', :object => @to_students
    end
  end

  def to_parents
    if params[:batch_id] == ""
      render :update do |page|
        page.replace_html "to_parents", :text => ""
      end
      return
    end

    batch = Batch.find(params[:batch_id])
    if @current_user.admin?
      parents =[]
      batch.students.each do |student|
        parents<<student unless student.immediate_contact.nil?
      end
    elsif @current_user.employee? and @current_user.has_required_control?
      parents =[]
      batch.students.each do |student|
        parents<<student unless student.immediate_contact.nil?
      end
    elsif @current_user.student?
      parents=@current_user.student_record.to_a
    else
      parents=[]
    end
    @to_parents = parents.map { |s| s.user.id unless s.user.nil? or s.user.is_deleted }
    @to_parents.delete nil
    render :update do |page|
      page.replace_html 'to_parents', :partial => 'to_parents', :object => @to_parents
    end
  end

  def update_recipient_list
    if params[:recipients_employees]
      recipients_array = params[:recipients_employees].split(",").collect{ |s| s.to_i }
      @recipients_employees = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list', :partial => 'recipient_list_employees'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end
  def update_recipient_list1
    if params[:recipients_students]
      recipients_array = params[:recipients_students].split(",").collect{ |s| s.to_i }
      @recipients_students = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list1', :partial => 'recipient_list_students'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end
  def update_recipient_list2
    if params[:recipients_parents]
      recipients_array = params[:recipients_parents].split(",").collect{ |s| s.to_i }
      @recipients_parents = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list2', :partial => 'recipient_list_parents'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end
  def sent_reminder
    @user = current_user
    @sent_reminders = Reminder.paginate(:page => params[:page], :conditions=>["sender = '#{@user.id}' and is_deleted_by_sender = false"],  :order=>"created_at DESC")
    @new_reminder_count = Reminder.find_all_by_recipient(@user.id, :conditions=>"is_read = false")
  end

  def view_sent_reminder
    @sent_reminder = Reminder.find(params[:id2])
    @reminder_attachments=@sent_reminder.reminder_attachments
  end

  def delete_reminder_by_sender
    @sent_reminder = Reminder.find(params[:id2])
    Reminder.update(@sent_reminder.id, :is_deleted_by_sender => true)
    flash[:notice] = "#{t('flash2')}"
    redirect_to :action =>"sent_reminder"
  end

  def delete_reminder_by_recipient
    user = current_user
    employee = user.employee_record
    @reminder = Reminder.find(params[:id2])
    Reminder.update(@reminder.id, :is_deleted_by_recipient => true)
    flash[:notice] = "#{t('flash2')}"
    redirect_to :action =>"index"
  end

  def view_reminder
    user = current_user
    @new_reminder = Reminder.find(params[:id2])
    Reminder.update(@new_reminder.id, :is_read => true)
    @sender = @new_reminder.user
    @reminder_attachments=@new_reminder.reminder_attachments
    if request.post?
      reminder_body=ActionController::Base.helpers.sanitize(params[:reminder][:body])
      # if reminder_body.empty?
      #   flash[:notice]="#{t('flash8')}"
      #   redirect_to :controller=>"reminder", :action=>"view_reminder", :id2=>params[:id2]
      #   return
      # end
      reminder=Reminder.new(params[:reminder])
      reminder.sender=current_user.id
      reminder.recipient=@sender.id
      #FIXME workaround to handle dual entry
      reminder_attachments= reminder.reminder_attachments.dup
      reminder.reminder_attachments=[]
      # TODO make this inside a transaction
      if reminder.save && ( reminder_attachments.empty? || reminder_attachments.first.valid?)
        reminder.reminder_attachments=reminder_attachments
        flash[:notice]="#{t('flash3')}"
        redirect_to :controller=>"reminder", :action=>"view_reminder", :id2=>params[:id2]
      else
        # remove reminder object if it is created by mistake
        reminder.destroy
        # flash[:notice]="#{reminder.errors.full_messages}"
        # flash[:notice]+="#{reminder_attachments.first.errors.full_messages}"
        # flash[:notice]+="<b>ERROR:</b>#{t('flash4')}"
        flash[:error]=""
        flash[:error]+="<li> #{t('flash9')}</li>" if  reminder_attachments.present? #&& reminder_attachments.first.try(:valid?)
        flash[:error]+="<li> #{t('flash11')}</li>"  if reminder_body.empty?
        flash[:error]+="<li> #{t('flash10')}</li>"  if params[:reminder][:subject].empty?
        redirect_to :controller=>"reminder", :action=>"view_reminder", :id2=>params[:id2]
      end
    else
      # for reply message
      @reply_reminder=Reminder.new
      @reply_reminder_attachment_relations =  @reply_reminder.reminder_attachment_relations.build
      @reply_reminder_attachments=@reply_reminder_attachment_relations.build_reminder_attachment.to_a
      @reply_reminder.reminder_attachments=@reply_reminder_attachments.to_a
    end
  end

  def mark_unread
    @reminder = Reminder.find(params[:id2])
    Reminder.update(@reminder.id, :is_read => false)
    flash[:notice] = "#{t('flash5')}"
    redirect_to :controller=>"reminder", :action=>"index"
  end

  def pull_reminder_form
    @employee = Employee.find(params[:id])
    render :partial => "send_reminder"
  end

  def send_reminder
    if params[:create_reminder]
      unless params[:create_reminder][:message] == "" or params[:create_reminder][:to] == ""
        Reminder.create(:sender=>params[:create_reminder][:from], :recipient=>params[:create_reminder][:to], :subject=>params[:create_reminder][:subject],
          :body=>params[:create_reminder][:message] , :is_read=>false, :is_deleted_by_sender=>false,:is_deleted_by_recipient=>false)
        render(:update) do |page|
          page.replace_html 'error-msg', :text=> "<p class='flash-msg'>#{t('your_message_sent')}</p>"
        end
      else
        render(:update) do |page|
          page.replace_html 'error-msg', :text=> "<p class='flash-msg'>#{t('enter_subject')}</p>"
        end
      end
    else
      redirect_to :controller=>:reminder
    end
  end

  def reminder_actions
    @user = current_user
    message_ids = params[:message_ids]
    unless message_ids.nil?
      message_ids.each do |msg_id|
        msg = Reminder.find_by_id(msg_id)
        if params[:reminder][:action] == 'delete'
          Reminder.update(msg.id, :is_deleted_by_recipient => true, :is_read => true)
        elsif params[:reminder][:action] == 'read'
          Reminder.update(msg.id, :is_read => true)
        elsif params[:reminder][:action] == 'unread'
          Reminder.update(msg.id, :is_read => false)
        end
      end
    end
    @reminders = Reminder.paginate(:page => params[:page], :conditions=>["recipient = '#{@user.id}' and is_deleted_by_recipient = false"], :order=>"created_at DESC")
    @new_reminder_count = Reminder.find_all_by_recipient(@user.id, :conditions=>"is_read = false and is_deleted_by_recipient = false")

    redirect_to :action=>:index, :page=>params[:page]
  end

  def sent_reminder_delete
    @user = current_user
    message_ids = params[:message_ids]
    unless message_ids.nil?
      message_ids.each do |msg_id|
        msg = Reminder.find_by_id(msg_id)
        Reminder.update(msg.id, :is_deleted_by_sender => true)
      end
    end
    @sent_reminders = Reminder.paginate(:page => params[:page], :conditions=>["sender = '#{@user.id}' and is_deleted_by_sender = false"],  :order=>"created_at DESC")
    @new_reminder_count = Reminder.find_all_by_recipient(@user.id, :conditions=>"is_read = false")

    redirect_to :action=>:sent_reminder, :page=>params[:page]
  end
  private
  
    def render_model_box
      render :update do |page|
        page << "build_modal_box({'title' : '#{t('manage_leave_types_for_leave_group')}'})" 
        page.replace_html 'popup_content', :partial => 'model_box'
      end
    end
    
    def comma_string_to_integer_array(string)
      return [] if string.nil?
      return string.split(',').map { |char| char.to_i}
    end
    def get_parent_ids_from_student_ids(student_ids)
      students=Student.find(:all,:conditions=>["user_id in (?)",student_ids])
      parent_ids=[]
      students.each do |student|
        parent_ids<<student.immediate_contact.user_id unless student.immediate_contact.nil?
      end
      return parent_ids
    end
    def get_departments_batches_and_parents
      @user=current_user
      @departments,@batches,@parents_for_batch=Reminder.get_departments_batches_and_parents(@user)
    end
    # TODO: refractor
    def retain_selected_recipients
      recipients_array=[]
      unless params[:recipients_employees].blank?
        recipients_array += params[:recipients_employees].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
        @recipients_employees = User.active.find(params[:recipients_employees].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC")
      end
      unless params[:recipients_students].blank?
        recipients_array += params[:recipients_students].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
        @recipients_students = User.active.find(params[:recipients_students].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC")
      end
      unless params[:recipients_parents].blank?
        recipients_array += params[:recipients_parents].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
        @recipients_parents = User.active.find(params[:recipients_parents].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC")
      end
    end
end
