class MessageTemplatesController < ApplicationController
  before_filter :validate_edit_sms_template , :only=>[:new_message_template, :save_message_template, :edit_message_template, :update_message_template, :delete_message_template]
  filter_access_to :all 
  
  
  def message_templates
    @tempalte_edit_setting = MultiSchool.current_school.edit_sms_template
    @custom_message_templates = MessageTemplate.custom_templates    
    @automated_message_templates = MessageTemplate.automated_templates 
    @birthday_message_templates = MessageTemplate.birthday_templates
    if FedenaPlugin.can_access_plugin?("fedena_reminder")
      @reminder_message_templates = MessageTemplate.all(:conditions=>["template_type = 'REMINDER'"])
    end
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      @transport_message_templates = MessageTemplate.all(:conditions=>["template_type = 'TRANSPORT'"])
    end
  end
  
  def new_message_template
    @message_template = MessageTemplate.new
    if params[:template_type].present?
      @message_template.template_type =  params[:template_type]
    end
    @intended_users = MessageTemplate.get_intended_users(params[:template_type])
    if @intended_users[:student] == true
      student_content = @message_template.build_student_template_content(:user_type => "Student")
    end
    if @intended_users[:employee] == true
      employee_content = @message_template.build_employee_template_content(:user_type => "Employee")
    end
    if @intended_users[:guardian] == true
      guardian_content = @message_template.build_guardian_template_content(:user_type => "Guardian")
    end
    @common_keys = MessageTemplate.common_keys
  end
  
  
  def save_message_template
    @message_template = MessageTemplate.new(params[:message_template])
    if @message_template.save
      flash[:notice] = t("message_template_saved")
      render :update do |page|
        page.redirect_to  message_templates_message_templates_path
      end
    else
      @errors = @message_template.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end
  
  
  def edit_message_template
    @message_template = MessageTemplate.find(params[:id], :include=> [:student_template_content, :employee_template_content, :guardian_template_content] )
    @message_template.set_user_enabled_flags()
    @intended_users = MessageTemplate.get_intended_users(@message_template.template_type)
    if @message_template.template_type != "AUTOMATED"
      if @intended_users[:student] == true
        @message_template.build_student_template_content(:user_type => "Student") if !@message_template.student_template_content.present?
      end
      if @intended_users[:employee] == true
        @message_template.build_employee_template_content(:user_type => "Employee") if !@message_template.employee_template_content.present?
      end
      if @intended_users[:guardian] == true
        @message_template.build_guardian_template_content(:user_type => "Guardian") if !@message_template.guardian_template_content.present?
      end
    else 
      @automated_keys =  MessageTemplate.list_automated_keys(@message_template.automated_template_name)
    end
    @common_keys = MessageTemplate.common_keys
  end 
  
  
  def update_message_template
    @message_template = MessageTemplate.find(params[:id])
    @message_template.attributes = params[:message_template]
    if @message_template.save
      flash[:notice] = t("message_template_updated")
      render :update do |page|
        page.redirect_to message_templates_message_templates_path
      end
    else
      @errors = @message_template.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end
  
  
  def delete_message_template
    @message_template = MessageTemplate.find(params[:id])
    if @message_template.destroy
      flash[:notice] = t("message_template_deleted")
    end
    redirect_to  message_templates_message_templates_path
  end
  
  
  def list_keys_for_template
    @keys = MessageTemplate.fetch_required_keys_based_on_user_type(params[:user_types])
    render :update do |page|
      page.replace_html "template_keys", :partial => "template_keys"
    end
  end
  
end
