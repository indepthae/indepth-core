require 'override_errors'
class EmailAlertsController < ApplicationController
  helper OverrideErrors

  before_filter :login_required, :except=>[:unsubscribe]
  filter_access_to :index,:email_alert_settings,:compose_mail, :batch_or_department_list,
                   :user_list, :email_unsubscription_list, :remove_unsubscription

  layout :get_layout


  def get_layout
    return 'email_subscription' if action_name == 'unsubscribe'
    'application'
  end

  def index
    
  end

  def email_alert_settings
    if request.post?
    
      if params[:select_options].present? 
        params[:select_options].each do|em,val|
          if EmailAlert.find_by_model_name(em).nil?
            EmailAlert.create(:model_name=>em,:value=>true,:mail_to=>params[:select_options][em].present?? params[:select_options][em][:mail_to]:[])
          else
            EmailAlert.find_by_model_name(em).update_attributes(:value=>true,:mail_to=>params[:select_options][em].present?? params[:select_options][em][:mail_to]:[])
          end
        end
        (EmailAlert.active.collect(&:model_name)-params[:select_options].keys).each do |eml|
          EmailAlert.find_by_model_name(eml).update_attributes(:value=>false,:mail_to=>[])
        end
      else
        EmailAlert.active.collect(&:model_name).each do |eml|
          EmailAlert.find_by_model_name(eml).update_attributes(:value=>false,:mail_to=>[])
        end
      end
      flash.now[:notice] = t('email_settings_saved')
    end
  end

  def email_unsubscription_list
    @date = params[:search] && params[:search][:updated_at_on] || Date.today
    @unsubscribtion_list = EmailSubscription.search(params[:search]).paginate(:include=> :user, :per_page=>30, :page=>params[:page])
    if request.xhr?
      render(:update) do |page|
        page.replace_html "u-list", :partial=>"email_alerts/unsubscription_list"
      end
    end
  end

  def unsubscribe
    verifier = ActiveSupport::MessageVerifier.new(ActionController::Base.session_options[:secret])
    id, email = verifier.verify(params[:key])
    @key = params[:key]
    @user = User.active.find_by_id_and_email(id, email)
    @confirmed = false
    if @user
      if request.post?
        @confirmed = true
        if @user.student
          student = @user.student_record
          student.update_attributes(:is_email_enabled=>false)
        end
        d = EmailSubscription.find_or_create_by_user_id(:user_id => @user.id,:name => @user.full_name, :email => @user.email)
        d.touch
        flash[:notice]= "#{t('unsubscribed')}"
      end
    else
      flash[:notice]= "#{t('invalid_unsubscription_link')}"
    end
    render :email_subscription
  end

  def remove_unsubscription
    unsubscribed_entry = EmailSubscription.find(params[:entry_id])
    if unsubscribed_entry && unsubscribed_entry.destroy
      render(:update) do |page|
        page.remove "entry-#{params[:entry_id]}"
      end
    end
  end

  def compose_mail
    get_collection
    unless request.post?
      @mail_message = MailMessage.new
    else
      @mail_message = MailMessage.new(mail_message_params)

      if @mail_message.save
        flash[:notice] = "#{t('mail_sent_successfully')}"
        redirect_to :controller=>"email_alerts",:action=>"index"
      else
        puts @mail_message.errors.inspect
        flash.now[:error] = "#{t('errors_present')}"
      end
    end

  end

  check_request_fingerprint :compose_mail

  def batch_or_department_list
    @mail_message = MailMessage.new
    get_collection
    render(:update) do |page|
      page.replace_html "select-student-course", :partial => "select_batch_or_department"
    end
  end

  def user_list
    get_users
    render :update do |page|
      page.replace_html 'source', :partial => 'user_list'
    end
  end
  

  private

  def get_collection
    case recipient_type
      when 'student', 'guardian'
        @batches = Batch.active(:include=>:students, :joins => :students)
      when 'employee'
        @employee_departments = EmployeeDepartment.active(:include=>:employees, :joins => :employees)
    end
  end

  def get_users
    case recipient_type
      when 'student'
        @students = Student.scoped(:conditions => {:batch_id => params[:batch_id]})\
                        .all(:conditions => "email is not null and email <> '' and is_email_enabled = 1",
                             :order =>"#{Student.sort_order}")
      when 'guardian'
        @students = Student.scoped(:conditions => {:batch_id => params[:batch_id]})\
                        .all(:conditions => "guardians.email is not null and guardians.email <> ''",
                             :joins => :immediate_contact, :include => :immediate_contact, :order =>"#{Student.sort_order}")
      when 'employee'
        @employees = Employee.scoped(:conditions => {:employee_department_id => params[:department_id]})\
                         .all(:conditions => "email is not null and email <> ''", :order => :first_name)
    end
  end

  def recipient_type
    @recipient_type ||= params[:mail_message].present? ? (params[:mail_message][:recipient_type] || 'student') : 'student'
  end

  def mail_message_params
    params[:mail_message] \
        .merge(:sender_id => @current_user.id) \
        .merge(:additional_info => mail_additional_info)
  end

  def mail_additional_info
    MailMessage::Info.new("#{request.protocol}#{request.host_with_port}", Fedena.rtl ? 'rtl' : 'ltr')
  end

end