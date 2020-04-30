class SchoolsController <  MultiSchoolController
  helper_method :admin_user_session
  helper_method :school_group_session
  before_filter :find_school, :only=>[:show,:edit,:update,:destroy,:add_domain,:delete_domain,:sms_settings,:smtp_settings,:check_smtp_settings, :admin_login,
    :generate_settings,:remove_settings,:remove_smtp_settings,:whitelabel_settings,:remove_whitelabel_settings,:show_sms_logs,:show_sms_messages,:profile,:domain,:make_domain_primary]

  filter_access_to [:index, :new, :create]
  filter_access_to [:show,:edit,:update,:destroy,:add_domain,:delete_domain,:make_domain_primary,:sms_settings,:smtp_settings,:check_smtp_settings, :admin_login,
    :generate_settings,:remove_settings,:remove_smtp_settings,:whitelabel_settings,:remove_whitelabel_settings,:show_sms_logs,:show_sms_messages,:profile,:domain], :attribute_check=>true
  filter_access_to :list_schools, :attribute_check => true, :load_method => lambda{SchoolGroup.find(params[:multi_school_group_id])}

  # GET /schools
  def index
    @schools = admin_user_session.school_group.schools.active.paginate(:page => params[:page], :per_page=>10, :include => :school_domains)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @schools }
    end
  end

  def search
    schools =  School.find(:all,:conditions=>["((schools.name LIKE ? OR schools.code LIKE ?) AND schools.school_group_id = ? AND schools.is_deleted = ?)",
                                              "#{params[:query]}%","#{params[:query]}%",admin_user_session.school_group.id,false])

    render :json=>{:query=>params[:query],:suggestions=>schools.collect(&:name), :data=>schools.collect(&:id)}
  end

  # GET /schools/1
  def show
    @sms_settings = School.load_sms_settings
    @current_school_settings = @sms_settings[@school.code]

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @school }
    end
  end

  def domain
    render :partial=>"domain"
  end

  def profile
    render :partial=>"profile"
  end

  # GET /schools/new
  def new
    if(params[:client_school_group].present? and admin_user_session.class.name == "MasterSupportUser")
      @school_group = ClientSchoolGroup.find(params[:client_school_group])
    else
      @school_group = admin_user_session.school_group
    end
    @school = @school_group.schools.build
    @school.school_domains.build
    @school.build_available_plugin(:plugins=>[])
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @school }
    end
  end

  # GET /schools/1/edit
  def edit
    @school.build_available_plugin(:plugins=>[]) unless @school.available_plugin
  end

  # POST /schools
  def create
    if(params[:client_school_group].present? and admin_user_session.class.name == "MasterSupportUser")
      @school_group = ClientSchoolGroup.find(params[:client_school_group])
    else
      @school_group = admin_user_session.school_group
    end
    @school = @school_group.schools.build(params[:school])
    @school.creator_id = admin_user_session.id
    respond_to do |format|
      @school.build_available_plugin(:plugins=>[]) unless @school.available_plugin
      if @school.save
        flash[:notice] = "<span style='color: black;'>School was successfully created.<span><br /> <span style='color:#666666 !important;'>You can access this school at <a href='http://#{@school.school_domains.first.try(:domain)}' style='color:#990000 !important;font-weight: normal;' target='_blank'>#{@school.school_domains.first.try(:domain)}</a>&nbsp; &nbsp; Username: <b style='font-weight: normal;color: black;'>admin</b>&nbsp;&nbsp Password: <b style='font-weight: normal;color: black;'>admin123</b></span>"
        if (@school.available_plugin.plugins.include?("fedena_pay") and admin_user_session.available_gateways.present?)
          format.html { redirect_to assign_gateways_school_payment_gateways_path(@school) }
          format.xml  { render :xml => @school, :status => :created, :location => @school }
        else
          format.html { redirect_to(@school) }
          format.xml  { render :xml => @school, :status => :created, :location => @school }
        end
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @school.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /schools/1
  def update
    MultiSchool.current_school = @school
    respond_to do |format|
      params[:school][:available_plugin_attributes]={:plugins=>[]} unless params[:school][:available_plugin_attributes][:plugins]
      if @school.update_attributes(params[:school])
        flash[:notice] = 'School was successfully updated.'
        format.html { redirect_to(@school) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @school.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /schools/1
  def destroy
    MultiSchool.current_school = @school
    error=false
    ActiveRecord::Base.transaction do
      if @school.soft_delete
        unless @school.school_deletion
          error=true
          raise ActiveRecord::Rollback
        end if(CdsAdapter rescue false)
      else
        error=true
      end
    end
    unless error
      flash[:notice]="School deleted successfully"
      respond_to do |format|
        format.html { redirect_to(schools_url) }
        format.xml  { head :ok }
      end
    else
      respond_to do |format|
        format.html {render :action => "show",:id=>@school.id  }
        format.xml  { render :xml => @school.errors, :status => :unprocessable_entity }
      end
    end
  end

  def add_domain
    @domain = @school.school_domains.new(params[:add_domain])
    render :update do |page|
      SchoolDomain.transaction do
        if @domain.save
          message="Domain added."
          page.replace_html 'detail_list', :partial=>"domain"
        else
          message = "Unable to add domain - #{@domain.errors.full_messages.join(',')}"
        end

        page.replace_html 'message_div', message
      end
    end
  end

  def make_domain_primary
    @domain = @school.school_domains.find(params[:domain_id])
    SchoolDomain.transaction do
      if @domain.update_attribute(:is_primary, true)
        @message = "Domain set primary."
      else
        @message = "Unable to edit domain - #{@domain.errors.full_messages.join(',')}"
      end
      render :partial => 'domain'
    end
  end

  def delete_domain
    domain = @school.school_domains.find_by_id(params[:domain_id])
    SchoolDomain.transaction do
      destroyed = domain.destroy if domain
      if destroyed
        @message="Domain deleted"
      else
        @message="Could not delete domain - #{domain.errors.full_messages.join(',')}"
      end
    end
    #@message = (destroyed ?  "Domain deleted" : "Could not delete domain - #{@domain.errors.full_messages.join(',')}")
    render :partial=>'domain'
  end

  def sms_settings
    @current_school_settings = @school.sms_credential
    if request.post?
      unless @current_school_settings.nil?
        @current_school_settings.update_attributes(:settings=>params[:sms_config])
        flash[:notice]="SMS settings for #{@school.name} have been updated successfully"
      else
        @school.create_sms_credential(:settings=>params[:sms_config])
        flash[:notice]="SMS settings for #{@school.name} have been created successfully"
      end
      redirect_to :action=>"sms_settings", :id=>@school.id
    end

  end

  def smtp_settings
    @current_school_settings = @school.smtp_setting
    if request.post?
      unless @current_school_settings.nil?
        @current_school_settings.update_attributes(:settings=>params[:smtp_config])
        flash[:notice]="SMTP settings for #{@school.name} have been updated successfully"
      else
        @school.create_smtp_setting(:settings=>params[:smtp_config])
        flash[:notice]="SMTP settings for #{@school.name} have been created successfully"
      end
      redirect_to :action=>"smtp_settings", :id=>@school.id
    end
  end

  def whitelabel_settings
    @current_school_settings = @school.whitelabel_setting
    if request.post?
      unless @current_school_settings.nil?
        @current_school_settings.update_attributes(:settings=>params[:whitelabel_config])
        flash[:notice]="Whitelabel settings for #{@school.name} have been updated successfully"
      else
        @school.create_whitelabel_setting(:settings=>params[:whitelabel_config])
        flash[:notice]="Whitelabel settings for #{@school.name} have been created successfully"
      end
      redirect_to :action=>"whitelabel_settings", :id=>@school.id
    end
  end

  def remove_whitelabel_settings
    whitelabel_settings = @school.whitelabel_setting
    unless whitelabel_settings.nil?
      whitelabel_settings.destroy
    end
    redirect_to :action=>:whitelabel_settings, :id=>@school.id
  end

  def generate_settings
    @sms_settings = School.load_sms_settings
    @current_school_settings = @sms_settings[@school.code]
    @school.create_sms_settings if @current_school_settings.nil?
    redirect_to :action=>:sms_settings, :id=>@school.id
  end

  def remove_settings
    sms_settings = @school.sms_credential
    unless sms_settings.nil?
      sms_settings.destroy
    end
    redirect_to :action=>:sms_settings, :id=>@school.id
  end

  def remove_smtp_settings
    smtp_settings = @school.smtp_setting
    unless smtp_settings.nil?
      smtp_settings.destroy
    end
    redirect_to :action=>:smtp_settings, :id=>@school.id
  end

  def show_sms_messages
    MultiSchool.current_school = @school
    @sms_messages = SmsMessage.paginate(:conditions=>{:school_id=>@school.id}, :order=>"id DESC", :page => params[:page], :per_page => 30)
    @total_sms = Configuration.get_config_value("TotalSmsCount")
  end

  def show_sms_logs
    MultiSchool.current_school = @school
    @sms_message = SmsMessage.find(params[:id2])
    @sms_logs = @sms_message.sms_logs.paginate( :order=>"id DESC", :page => params[:page], :per_page => 30)
  end

  def list_schools
    if params[:multi_school_group_id]
      @multi_school_group = SchoolGroup.find(params[:multi_school_group_id])
      @schools = School.paginate(:all,:conditions=>{:school_group_id=>@multi_school_group.id,:is_deleted=>false},:page => params[:page], :per_page=>10)
    end
    render "admin_users/schools_list"
  end

  def admin_login
    school_domain  = params[:domain_id].present? ? SchoolDomain.find(params[:domain_id]) : @school.domains.first
    if school_domain && @school.school_domains.include?(school_domain)
      session.each{|k,v| session.delete(k) unless [:_csrf_token, :admin_user].include? k}
      session[:user_id] = (admin_user_session.type == "MasterSupportUser") ? 0 : -1
      redirect_to "http://#{school_domain.domain}/?#{SessionInjector.generate_handshake_parameter(request,school_domain.domain)}"
    else
      flash[:notice] = "Access denied."
      redirect_to school_path(@school)
    end
  end

  private
  
  def domain_url
    domain = ""
    @school.school_domains.each do |dom|
      if(ping dom.domain)
        domain = dom.domain
        #domain = "#{request.protocol}#{@school.school_domains.first.domain}"
        domain = "#{request.protocol}#{dom.domain}"
        if(request.port.present?)
          domain += ":#{request.port}"
        end
        return domain
      end
    end
  end

  def ping(url)
    regex = /^.*(http|https):\/\/(.*).*$/
    m = url.match(regex)
    url = $2 || url
    domain = url.split('/').first
    url_resource = url.split(domain).last
    begin
      if(url_resource.present?)
        return Net::HTTP.new("#{domain}").head(url_resource).kind_of? Net::HTTPOK
      else
        return Net::HTTP.new("#{domain}").head('/').kind_of? Net::HTTPOK
      end
    rescue
      return false
    end
  end

  def find_school
    @school = School.find(params[:id], :conditions=>{:is_deleted=>false})
    @school_group = @school.school_group
  end

  def get_url(school_id)
    MultiSchool.current_school = School.find school_id
    config = SmsSetting.get_sms_config
    unless config.blank?
      sendername = config['sms_settings']['sendername']
      sms_url = config['sms_settings']['host_url']
      username = config['sms_settings']['username']
      password = config['sms_settings']['password']
      success_code = config['sms_settings']['success_code']
      username_mapping = config['parameter_mappings']['username']
      username_mapping ||= 'username'
      password_mapping = config['parameter_mappings']['password']
      password_mapping ||= 'password'
      phone_mapping = config['parameter_mappings']['phone']
      phone_mapping ||= 'phone'
      sender_mapping = config['parameter_mappings']['sendername']
      sender_mapping ||= 'sendername'
      message_mapping = config['parameter_mappings']['message']
      message_mapping ||= 'message'
      encoded_message = URI.encode("your message")
      unless config['additional_parameters'].blank?
        additional_param = ""
        config['additional_parameters'].split(',').each do |param|
          additional_param += "&#{param}"
        end
      end
    end
    "#{sms_url}?#{username_mapping}=#{username}&#{password_mapping}=#{password}&#{sender_mapping}=#{sendername}&#{message_mapping}=#{encoded_message}#{additional_param}&#{phone_mapping}="
  end
end
