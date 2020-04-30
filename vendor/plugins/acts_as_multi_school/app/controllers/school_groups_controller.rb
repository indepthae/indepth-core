class SchoolGroupsController < MultiSchoolController
  helper_method :admin_user_session
  helper_method :school_group_session
  before_filter :find_school_group, :only=>[:show,:edit,:update,:destroy,:sms_settings,:smtp_settings,:check_smtp_settings,
    :remove_settings,:remove_smtp_settings,:whitelabel_settings,:remove_whitelabel_settings,:add_group_domain,:delete_group_domain]
  before_filter :get_school_count, :only=>[:index, :show, :edit, :new, :sms_settings, :smtp_settings,:check_smtp_settings,:whitelabel_settings,:remove_whitelabel_settings,:add_group_domain,:delete_group_domain]

  def show

  end

  def add_group_domain
    #    @school = School.find(params[:id])
    domain = @school_group.school_domains.new(params[:add_domain])
    if domain.save
      flash[:notice] = "Added domain successfully."
    else
      flash[:notice] = "Unable to add domain - #{domain.errors.full_messages.join(',')}"
    end
    redirect_to :action=>"show",:id=>@school_group.id
  end

  def delete_group_domain
    #    @school = School.find(params[:id])
    domain = @school_group.school_domains.find_by_id(params[:domain_id])
    domains = @school_group.school_domains
    if domains.count>1
      domain.destroy if domain
      flash[:notice]="Domain deleted successfully."
    else
      flash[:notice]="Domain could not be deleted since it is the only domain available for the group."
    end
    redirect_to :action=>"show",:id=>@school_group.id
  end

  def sms_settings
    @current_group_settings = @school_group.sms_credential
    if request.post?
      unless @current_group_settings.nil?
        @current_group_settings.update_attributes(:settings=>params[:sms_config])
        flash[:notice]="SMS settings for #{@school_group.name} have been updated successfully"
      else
        @school_group.create_sms_credential(:settings=>params[:sms_config])
        flash[:notice]="SMS settings for #{@school_group.name} have been created successfully"
      end
      redirect_to :action=>"sms_settings", :id=>@school_group.id
    end
  end

  

  def remove_settings
    sms_settings = @school_group.sms_credential
    unless sms_settings.nil?
      sms_settings.destroy
    end
    redirect_to :action=>:sms_settings, :id=>@school_group.id
  end

  def smtp_settings
    @current_group_settings = @school_group.smtp_setting
    if request.post?
      unless @current_group_settings.nil?
        @current_group_settings.update_attributes(:settings=>params[:smtp_config])
        flash[:notice]="SMTP settings for #{@school_group.name} have been updated successfully"
      else
        @school_group.create_smtp_setting(:settings=>params[:smtp_config])
        flash[:notice]="SMTP settings for #{@school_group.name} have been created successfully"
      end
      redirect_to :action=>"smtp_settings", :id=>@school_group.id
    end
  end

  def check_smtp_settings
    begin
      @school_group.send_test_mail(admin_user_session)
      flash[:notice]="SMTP settings for #{@school_group.name} works perfectly."
    rescue Timeout::Error => e
      flash[:notice]="Address or Port is invalid."
    rescue Net::SMTPAuthenticationError => e
      flash[:notice]="Enable starttls auto or Username/Password combination is invalid."
    rescue ArgumentError => e
      flash[:notice]="Invalid Authentication."
    rescue SocketError => e
      flash[:notice]="Address is invalid."
    end
    redirect_to :action=>"smtp_settings", :id=>@school_group.id
  end

  def remove_smtp_settings
    smtp_settings = @school_group.smtp_setting
    unless smtp_settings.nil?
      smtp_settings.destroy
    end
    redirect_to :action=>:smtp_settings, :id=>@school_group.id
  end

  def whitelabel_settings
    @current_group_settings = @school_group.whitelabel_setting
    if request.post?
      unless @current_group_settings.nil?
        @current_group_settings.update_attributes(:settings=>params[:whitelabel_config])
        flash[:notice]="Whitelabel settings for #{@school_group.name} have been updated successfully"
      else
        @school_group.create_whitelabel_setting(:settings=>params[:whitelabel_config])
        flash[:notice]="Whitelabel settings for #{@school_group.name} have been created successfully"
      end
      redirect_to :action=>"whitelabel_settings", :id=>@school_group.id
    end
  end

  def remove_whitelabel_settings
    whitelabel_settings = @school_group.whitelabel_setting
    unless whitelabel_settings.nil?
      whitelabel_settings.destroy
    end
    redirect_to :action=>:whitelabel_settings, :id=>@school_group.id
  end

  private

  def get_school_count
    @schools_count = School.count(:conditions=>{:is_deleted=>false})
  end

  def find_school_group
    @school_group = SchoolGroup.find(params[:id])
  end
end
