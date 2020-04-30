class AdditionalSettingsController < MultiSchoolController
  helper_method :admin_user_session
  helper_method :school_group_session
  helper_method :child_class
  
  before_filter :find_owner
  before_filter :load_additional_setting

  filter_access_to :all,:except=>[:settings_list], :attribute_check=>true
  filter_access_to :settings_list
  
  def new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @additional_setting }
    end
  end

  def edit
    
  end

  def create

    respond_to do |format|
      if @additional_setting.save
        flash[:notice] = "#{child_class.titleize} was successfully created."
        format.html { redirect_to(@owner) }
        format.xml  { render :xml => @additional_setting, :status => :created, :location => @additional_setting }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @additional_setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @additional_setting.update_attributes(params[child_class.to_sym])
        flash[:notice] = "#{child_class.titleize} was successfully updated."
        format.html { redirect_to(@owner) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @additional_setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  def check_smtp_settings
    begin
      SmtpSetting.send_test_mail(admin_user_session,@owner)
      flash[:notice]="SMTP settings for #{@owner.name} works perfectly."
    rescue Timeout::Error => e
      flash[:notice]="Address Port combination is invalid."
    rescue Errno::ETIMEDOUT => e
      flash[:notice]="Address Port combination is invalid."
    rescue Net::SMTPAuthenticationError => e
      flash[:notice]="Enable starttls auto or Username/Password combination is invalid."
    rescue ArgumentError => e
      flash[:notice]="Invalid Authentication."
    rescue SocketError => e
      flash[:notice]="Address is invalid."
    rescue Errno::ECONNREFUSED => e
      flash[:notice]="Address cannot be blank."
    rescue Exception => e
      flash[:notice]="An error occurred. Please try again."
    end
    redirect_to @owner
  end

  def destroy
    @additional_setting.destroy

    respond_to do |format|
      format.html { redirect_to(additional_settings_url) }
      format.xml  { head :ok }
    end
  end

  def settings_list
    render :partial=>'profile'
  end

  def child_class
    return params[:type].to_s
  end
  
  private

  def inheriting_model
    return params[:type].classify.constantize
  end
 

  def find_owner
    @owner_type = params[:owner_type]
    @owner_id = params[:owner_id]
    @owner = @owner_type.classify.constantize.find(@owner_id)
  end

  def load_additional_setting
    case action_name
    when "settings_list","destroy","update","check_smtp_settings"
      @additional_setting =  ((@owner.send child_class) ?  (@owner.send child_class) : (@owner.send "build_#{child_class}")  )
    when "new"
      if @owner.send child_class
        redirect_to edit_additional_setting_path(@owner_type,@owner_id,child_class) and return
      else
        child_string = "build_#{child_class}"
        @additional_setting =  @owner.send child_string
      end
    when "edit"
      unless @owner.send child_class
        redirect_to new_additional_setting_path(@owner_type,@owner_id,child_class)
      else
        @additional_setting =  @owner.send child_class
      end
    when "create"
      child_string = "build_#{child_class}"
      @additional_setting =  @owner.send child_string,params[child_class.to_sym]
    end
  end

end
