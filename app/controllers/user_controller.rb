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

class UserController < ApplicationController
  layout :choose_layout
  before_filter :login_required, :except => [:forgot_password, :login, :set_new_password, :reset_password, :set_mobile_session]
  filter_access_to [:profile,:user_change_password], :attribute_check=>true, :load_method => lambda { User.active.first(:conditions => ["username LIKE BINARY(?)",params[:user_name].join('/')]) }
  filter_access_to [:edit, :create, :index, :edit_privilege, :user_change_password,:delete,:list_user,:all_users, :search_user_ajax, :user_filters]
  # before_filter :protect_user_data, :only => [:profile, :user_change_password]
  before_filter :check_if_loggedin, :only => [:login]
  before_filter :escape_dirty_params,:only => [:forgot_password]
  #  around_filter :cache_quick_links, :only => [:show_quick_links]
  include AutosuggestMenuHelper
  check_request_fingerprint :create
  
  
  def index
    @user_type = params[:user_type]||'students'
    @filters = User.fetch_filter_criteria(@user_type)
    @forced_type = "all"
  end
  
  def search_user_ajax
    @user_type = params[:user_type]
    @query = params[:query]
    @filter = params[:filter]
    @type = params[:type]
    if params[:forced_type] == nil
      @forced_type = "all"
    else
      @forced_type = params[:forced_type]
    end
    user = User.fetch_users(params[:user_type], params[:query], params[:filter], params[:type],@forced_type)
    if user.nil?
      @users = nil
    else
      @users = user.paginate(:per_page => 30, :page => params[:page])
    end
    render :partial => "user_list"
  end
  
  def user_filters
    @user_type = params[:user_type]
    @filters = User.fetch_filter_criteria(@user_type)
    render :partial => 'user_filters'
  end
  
  def block_user
    user = User.find params[:id]
    user.update_attributes(:is_blocked=>true)
    flash[:notice] = "#{t('block_user_text')}"
    @forced_type = params[:forced_type]
    @user_type = params[:user_type]
    @query = params[:query]
    @filter = params[:filter]
    @type = params[:type]
    user = User.fetch_users(params[:user_type], params[:query], params[:filter], params[:type],params[:forced_type])
    if user.nil?
      @users = nil
    else
      @users = user.paginate(:per_page => 30, :page => params[:page])
    end
    render :partial => "user_list"
    
#    redirect_to :controller => 'user'
  end
  
  def unblock_user
    user = User.find params[:id]
    user.update_attributes(:is_blocked=>false)
    flash[:notice] = "#{t('unblock_user_text')}"
    @user_type = params[:user_type]
    @query = params[:query]
    @filter = params[:filter]
    @type = params[:type]
    @forced_type = params[:forced_type]
    user = User.fetch_users(params[:user_type], params[:query], params[:filter], params[:type],params[:forced_type])
    if user.nil?
      @users = nil
    else
      @users = user.paginate(:per_page => 30, :page => params[:page])
    end
    render :partial => "user_list"
  end
  def choose_layout
    return 'login' if action_name == 'login' or action_name == 'set_new_password'
    return 'forgotpw' if action_name == 'forgot_password'
    return 'dashboard' if action_name == 'dashboard'
    'application'
  end
  
  def set_mobile_session
    cookies.delete("_fedena_session_".to_sym)
    reset_session
    cookies["_fedena_session_"] = {
      :value => params[:session_id],
      :http_only => true
    }
    @target_url = params[:target_url]
    if @target_url.present?
      render :layout=>false
    else
      redirect_to :action=>"dashboard"
    end
  end
  
  def all_users
    @users = User.active.all
  end

  def get_autosuggest_menuitems
    respond_to do |format|
      #format.json {render :json=>{ :available_options=>autosuggest_menuitems }}
      format.js { render 'get_autosuggest_menuitems'  }
    end
  end
  
  def list_user
    if params[:user_type].nil?
      page_not_found
    end
    if params[:user_type] == 'Admin'
      @users = User.active.find(:all, :conditions => {:admin => true}, :order => 'first_name ASC')
      render(:update) do |page|
        page.replace_html 'users', :partial=> 'users'
        page.replace_html 'employee_user', :text => ''
        page.replace_html 'student_user', :text => ''
      end
    elsif params[:user_type] == 'Employee'
      render(:update) do |page|
        hr = Configuration.find_by_config_value("HR")
        unless hr.nil?
          page.replace_html 'employee_user', :partial=> 'employee_user'
          page.replace_html 'users', :text => ''
          page.replace_html 'student_user', :text => ''
        else
          @users = User.active.find_all_by_employee(1)
          page.replace_html 'users', :partial=> 'users'
          page.replace_html 'employee_user', :text => ''
          page.replace_html 'student_user', :text => ''
        end
      end
    elsif params[:user_type] == 'Student'
      render(:update) do |page|
        page.replace_html 'student_user', :partial=> 'student_user'
        page.replace_html 'users', :text => ''
        page.replace_html 'employee_user', :text => ''
      end
    elsif params[:user_type] == "Parent"
      render(:update) do |page|
        page.replace_html 'student_user', :partial=> 'parent_user'
        page.replace_html 'users', :text => ''
        page.replace_html 'employee_user', :text => ''
      end
    elsif params[:user_type] == ''
      @users = ""
      render(:update) do |page|
        page.replace_html 'users', :partial=> 'users'
        page.replace_html 'employee_user', :text => ''
        page.replace_html 'student_user', :text => ''
      end
    end
  end

  def list_employee_user
    #change this
    emp_dept = params[:dept_id]
    @employee = Employee.find_all_by_employee_department_id(emp_dept, :order =>'first_name ASC')
    @users = @employee.collect { |employee| employee.user}
    @users.delete(nil)
    render(:update) {|page| page.replace_html 'users', :partial=> 'users'}
  end

  def list_student_user
    #change this
    batch = params[:batch_id]
    @student = Student.find_all_by_batch_id(batch, :conditions => { :is_active => true },:order =>'first_name ASC')
    @users = @student.collect { |student| student.user}
    @users.delete(nil)
    render(:update) {|page| page.replace_html 'users', :partial=> 'users'}
  end

  def list_parent_user
    #change this
    unless params[:batch_id].blank?
      batch = params[:batch_id]
      user_ids = Guardian.find(:all, :select=>'guardians.user_id',:joins=>'INNER JOIN students ON students.immediate_contact_id = guardians.id', :conditions => ['students.batch_id = ? AND is_active=1', batch]).collect(&:user_id).compact
      @users = User.find_all_by_id(user_ids,:conditions=>"is_deleted is false",:order =>'first_name ASC')
    else
      @users=[]
    end
    render(:update) {|page| page.replace_html 'users', :partial=> 'users'}
  end

  def change_password
    
    @user = current_user
    if request.post?
      if User.authenticate?(@user.username, params[:user][:old_password])
        if params[:user][:new_password] == params[:user][:confirm_password]
          @user.password = params[:user][:new_password]
          if @user.update_attributes(:password => @user.password, :role => @user.role_name)
            flash[:notice] = "#{t('flash9')}"
            redirect_to :action => 'dashboard'
          else
            flash[:warn_notice] = "<p>#{@user.errors.full_messages}</p>"
          end
        else
          flash[:warn_notice] = "<p>#{t('flash10')}</p>"
        end
      else
        flash[:warn_notice] = "<p>#{t('flash11')}</p>"
      end
    end
  end

  def user_change_password
    user_name = params[:user_name].join('/')
    #    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",params[:id]])
    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",user_name])
    if @user.present?
      if request.post?
        if params[:user][:new_password]=='' and params[:user][:confirm_password]==''
          flash[:warn_notice]= "<p>#{t('flash6')}</p>"
        else
          if params[:user][:new_password] == params[:user][:confirm_password]
            @user.password = params[:user][:new_password]
            if @user.update_attributes(:password => @user.password,:role => @user.role_name)
              flash[:notice]= "#{t('flash7')}"
              redirect_to :action=>"profile", :id=>@user.username
            else
              render :user_change_password
            end
          else
            flash[:warn_notice] =  "<p>#{t('flash10')}</p>"
          end
        end
      end
    else
      flash[:notice] = t('no_users')
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def create
    @config = Configuration.available_modules

    @user = User.new(params[:user])
    if request.post?
          
      if @user.save
        flash[:notice] = "#{t('flash17')}"
        redirect_to :controller => 'user', :action => 'profile', :id => @user.username
      end
           
    end
  end

  def delete
    @user = User.active.first(:conditions => ["username LIKE BINARY(?) AND admin = 1",params[:id]])
    unless @user.nil?
      if current_user == @user
        flash[:notice] = "You cannot delete your own profile"
        redirect_to :controller => "user", :action => "dashboard" and return
      else
        if @user.employee_record.nil?
          flash[:notice] = "#{t('flash12')}" if @user.destroy
        end
      end
    end
    redirect_to :controller => 'user'
  end
  
  def dashboard
    @user = current_user
    @config = Configuration.available_modules
    @employee = @user.employee_record if ["#{t('admin')}","#{t('employee_text')}"].include?(@user.role_name)
    if @user.student?
      @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)", @user.username])
    end
    if @user.parent?
      session[:student_id]=params[:id].present?? params[:id] : @user.guardian_entry.current_ward_id
      Fedena.present_student_id=session[:student_id]
      @student=@user.guardian_entry.current_ward
      @students=@student.siblings.select{|g| g.immediate_contact_id=@user.guardian_entry.id}
    end
    @first_time_login = Configuration.get_config_value('FirstTimeLoginEnable')
    if  session[:user_id].present? and @first_time_login == "1" and @user.is_first_login != false
      flash[:notice] = "#{t('first_login_attempt')}"
      redirect_to :controller => "user",:action => "first_login_change_password"
    end
  end
 
  def edit
    #@user = User.active.find_by_username(params[:id])
    #@current_user = current_user
    #if request.post? and @user.update_attributes(params[:user])
    #flash[:notice] = "#{t('flash13')}"
    #redirect_to :controller => 'user', :action => 'profile', :id => @user.username
    #end
    redirect_to :action=> "dashboard"
  end

  def forgot_password
    #    flash[:notice]="You do not have permission to access forgot password!"
    #    redirect_to :action=>"login"
    if request.post? and params[:reset_password]
      if user = User.active.first(:conditions => ["username LIKE BINARY(?)",params[:reset_password][:username]])
        unless user.email.blank?
          user.reset_password_code = Digest::SHA1.hexdigest( "#{user.email}#{Time.now.to_s.split(//).sort_by {rand}.join}" )
          user.reset_password_code_until = 1.day.from_now
          user.role = user.role_name
          user.save(false)
          url = "#{request.protocol}#{request.host_with_port}"
          begin
            UserNotifier.deliver_forgot_password(user,url)
          rescue Exception => e
            puts "Error------#{e.message}------#{e.backtrace.inspect}"
            flash[:notice] = "#{t('flash21')}"
            return
          end
          flash[:notice] = "#{t('flash18')}"
          redirect_to :action => "index"
        else
          flash[:notice] = "#{t('flash20')}"
          return
        end
      else
        flash[:notice] = "#{t('flash19')}"
      end
    end
  end


  def login
    @institute = Configuration.find_by_config_key("LogoName")
    available_login_authes = FedenaPlugin::AVAILABLE_MODULES.select{|m| m[:name].camelize.constantize.respond_to?("login_hook")}
    selected_login_hook = available_login_authes.first if available_login_authes.count>=1
    if selected_login_hook
      authenticated_user = selected_login_hook[:name].camelize.constantize.send("login_hook",self)
    else
      if request.post? and params[:user]
        @user = User.new(params[:user])
        user = User.active.first(:conditions => ["username LIKE BINARY(?)",@user.username])
        if user.present? and User.authenticate?(@user.username, @user.password)
          authenticated_user = user
        end
      end
    end
    if authenticated_user.present?
      flash.clear
      if authenticated_user.is_blocked == false
        successful_user_login(authenticated_user) and return
      else
        flash[:notice] = "#{t('blocked_login_error_message')}"
      end
    elsif authenticated_user.blank? and request.post?
      flash[:notice] = "#{t('login_error_message')}"
    end
  end

  def first_login_change_password
    @user = current_user
    @setting = Configuration.get_config_value('FirstTimeLoginEnable')
    if @setting == "1" and @user.is_first_login != false
      if request.post?
        if params[:user][:new_password] == params[:user][:confirm_password]
          if @user.update_attributes(:password => params[:user][:confirm_password],:is_first_login => false)
            flash[:notice] = "#{t('password_update')}"
            redirect_to :controller => "user",:action => "dashboard"
          else
            render :first_login_change_password
          end
        else
          @user.errors.add('password','and confirm password doesnot match')
          render :first_login_change_password
        end
      end
    else
      flash[:notice] = "#{t('not_applicable')}"
      redirect_to :controller => "user",:action => "dashboard"
    end
  end

  def logout
    available_login_authes = FedenaPlugin::AVAILABLE_MODULES.select{|m| m[:name].camelize.constantize.respond_to?("logout_hook")}
    selected_logout_hook = available_login_authes.first if available_login_authes.count>=1
    if selected_logout_hook
      clear_session
      selected_logout_hook[:name].camelize.constantize.send("logout_hook",self,"/")
    else
      respond_to do |format|
        format.js {
          if Configuration.find_by_config_key('EnableSessionTimeout').try(:config_value) == "1"
            if session[:user_id].present? and Configuration.find_by_config_key('EnableSessionTimeout').try(:config_value) == "1" and Configuration.find_by_config_key("Enable#{@current_user.role_name}SessionTimeout").try(:config_value) == "1"
              clean_session
              flash[:notice] = "#{t('logged_out_due_to_inactivity')}"
              render :js => "window.location = '/'"
            end
          else
            render :nothing => true
          end
        }
        format.html {
          clean_session
          flash[:notice] = "#{t('logged_out')}"
          redirect_to :controller => '/' and return
        }
      end 
    end
  end

  def profile
    user_name = params[:user_name].join('/')
    @config = Configuration.available_modules
    @current_user = current_user
    @username = @current_user.username if session[:user_id]
    #    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",params[:id]])
    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",user_name])

    @financial_years = FinancialYear.all

    unless @user.nil?
      @employee = Employee.first(:conditions => ["employee_number LIKE BINARY(?)",@user.username])
      @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",@user.username])
      @ward  = @user.parent_record if @user.parent
         
    else
      flash[:notice] = "#{t('flash14')}"
      redirect_to :action => 'dashboard'
    end
  end

  def reset_password
    user = User.active.find_by_reset_password_code(params[:id],:conditions=>"reset_password_code IS NOT NULL")
    if user
      if user.reset_password_code_until > Time.now
        redirect_to :action => 'set_new_password', :id => user.reset_password_code
      else
        flash[:notice] = "#{t('flash1')}"
        redirect_to :action => 'index'
      end
    else
      flash[:notice]= "#{t('flash2')}"
      redirect_to :action => 'index'
    end
  end

#  def search_user_ajax
#    unless params[:query].nil? or params[:query].empty? or params[:query] == ' '
#      #      if params[:query].length>= 3
#      #        @user = User.first_name_or_last_name_or_username_begins_with params[:query].split
#      @user = User.active.find(:all,
#        :conditions => ["ltrim(first_name) LIKE ? OR ltrim(last_name) LIKE OR username = ? OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? ) ",
#          "#{params[:query]}%","#{params[:query]}%","#{params[:query]}",
#          "#{params[:query]}%"],
#        :order => "first_name asc") unless params[:query] == ''
#      #      else
#      #        @user = User.first_name_or_last_name_or_username_equals params[:query].split
#      #      end
#      #      @user = @user.sort_by { |u1| [u1.role_name,u1.full_name] } unless @user.nil?
#    else
#      @user = ''
#    end
#    render :layout => false
#  end

  def set_new_password
    if request.post?
      user = User.active.find_by_reset_password_code(params[:id],:conditions=>"reset_password_code IS NOT NULL")
      if user
        if params[:set_new_password][:new_password]=='' and params[:set_new_password][:confirm_password]==''
          flash[:notice]= "#{t('flash6')}"
          redirect_to :action => 'set_new_password', :id => user.reset_password_code
        else
          if params[:set_new_password][:new_password] === params[:set_new_password][:confirm_password]
            user.password = params[:set_new_password][:new_password]
            if user.update_attributes(:password => user.password, :reset_password_code => nil, :reset_password_code_until => nil, :role => user.role_name)
              user.clear_menu_cache
              #User.update(user.id, :password => params[:set_new_password][:new_password],
              # :reset_password_code => nil, :reset_password_code_until => nil)
              flash[:notice] = "#{t('flash3')}"
              redirect_to :action => 'index'
            else
              user.reload
              flash[:notice] = "#{t('user.flash22')}"
              redirect_to :action => 'set_new_password', :id => user.reset_password_code
            end
          else
            flash[:notice] = "#{t('user.flash4')}"
            redirect_to :action => 'set_new_password', :id => user.reset_password_code
          end
        end
      else
        flash[:notice] = "#{t('flash5')}"
        redirect_to :action => 'index'
      end
    end
  end

  def edit_privilege
    user_name = params[:user_name].join('/')
    #    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",params[:id]])
    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",user_name])
    if @user.admin? or @user.student? or @user.parent? or current_user == @user
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller => "user",:action => "dashboard"
    else
      @finance = Configuration.find_by_config_value("Finance")
      @sms_setting = SmsSetting.application_sms_status
      @hr = Configuration.find_by_config_value("HR")
      @privilege_tags = {}
      privilege_tags=PrivilegeTag.find(:all, :joins => :privileges, :include => :privileges, :order=>"priority ASC", :group => "privilege_tags.id")
      privilege_tags.each do |pt|
        @privilege_tags[pt] = pt.privileges.all(:conditions=>"name<>'FinanceControl'",:order=>"priority ASC").select{|p| p.applicable?}
      end
      @privilege_tags = @privilege_tags.sort_by{|k,v| k.priority}
      @user_privileges=@user.privileges
      if request.post?
        new_privileges = params[:user][:privilege_ids] if params[:user]
        new_privileges ||= []
        @user.privileges = Privilege.find_all_by_id(new_privileges)
        @user.clear_menu_cache
        flash[:notice] = "#{t('flash15')}"
        redirect_to :action => 'profile',:id => @user.username
      end
    end
  end

  def header_link
    @user = current_user
    @config = Configuration.available_modules
    @employee = Employee.first(:conditions => ["employee_number LIKE BINARY(?)",@user.username])
    @employee ||= Employee.first if current_user.admin?
    @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",@user.username])
    render :partial=>'header_link'
  end

  def show_quick_links
    quick_links = Rails.cache.fetch(current_user.menu_link_cache_key){
      links = current_user.menu_links
      if current_user.parent?
        allowed_links = links.select{|l| can_access_request?(l.target_action.to_s.to_sym,@current_user.parent_record.user,:context=>l.target_controller.to_s.to_sym)}
      else
        allowed_links = links.select{|l| can_access_request?(l.target_action.to_s.to_sym,@current_user,:context=>l.target_controller.to_s.to_sym)}
      end
      current_user.menu_links = allowed_links
      allowed_links
    }
    render :partial=>"layouts/quick_links", :locals=>{:menu_links=>quick_links}
  end

  def show_all_features
    cat_links = Rails.cache.fetch(current_user.menu_link_cache_key(params[:cat_id])){
      link_cat = MenuLinkCategory.find_by_id(params[:cat_id])
      all_links = link_cat.menu_links
      general_links = all_links.select{|l| l.link_type=="general"}
      if current_user.admin?
        selective_links = general_links
        if current_user.employee_record.present?
          own_links = all_links.select{|l| l.link_type=="own" and l.user_type=="employee"}
          selective_links = general_links + own_links
        end
      elsif current_user.employee?
        own_links = all_links.select{|l| l.link_type=="own" and l.user_type=="employee"}
        selective_links = general_links + own_links
      else
        own_links = all_links.select{|l| l.link_type=="own" and l.user_type=="student"}
        selective_links = general_links + own_links
      end
      if current_user.parent?
        allowed_links = selective_links.select{|l| can_access_request?(l.target_action.to_s.to_sym,@current_user.parent_record.user,:context=>l.target_controller.to_s.to_sym)}
      else
        allowed_links = selective_links.select{|l| can_access_request?(l.target_action.to_s.to_sym,@current_user,:context=>l.target_controller.to_s.to_sym)}
      end
      allowed_links
    }
    render :partial=>"layouts/quick_links", :locals=>{:menu_links=>cat_links}
  end

  #  def show_edit_links
  #    general_links = MenuLink.all.select{|l| l.link_type=="general"}
  #    if current_user.admin?
  #      selective_links = general_links
  #    elsif current_user.employee?
  #      own_links = MenuLink.find_all_by_link_type_and_user_type("own","employee")
  #      selective_links = general_links + own_links
  #    else
  #      own_links = MenuLink.find_all_by_link_type_and_user_type("own","student")
  #      selective_links = general_links + own_links
  #    end
  #    allowed_links = selective_links.select{|l| can_access_request?(l.target_action.to_s.to_sym,l.target_controller.to_s.to_sym)}
  #    own_links = current_user.menu_links.select{|l| can_access_request?(l.target_action.to_s.to_sym,l.target_controller.to_s.to_sym)}
  #    render :partial=>"layouts/select_links", :locals=>{:all_links=>allowed_links,:own_links=>own_links}
  #  end

  def update_quick_links
    allowed_links = MenuLink.find_all_by_id(params[:selected_links])
    current_user.menu_links = allowed_links
    current_user.clear_user_menu_quick_link_cache
    flash[:notice]="Quick Links modified successfully."
    render :text=>""
  end

  def manage_quick_links
    u_roles = current_user.role_symbols
    @available_categories = MenuLinkCategory.find_all_by_name(["academics","collaboration","administration","data_and_reports"]).select{|m| !(m.allowed_roles & u_roles == [])}
    general_links = MenuLink.all.select{|l| l.link_type=="general"}
    if current_user.admin?
      selective_links = general_links
      if current_user.employee_record.present?
        own_links = MenuLink.find_all_by_link_type_and_user_type("own","employee")
        selective_links = general_links + own_links
      end
    elsif current_user.employee?
      own_links = MenuLink.find_all_by_link_type_and_user_type("own","employee")
      selective_links = general_links + own_links
    else
      own_links = MenuLink.find_all_by_link_type_and_user_type("own","student")
      selective_links = general_links + own_links
    end
    if current_user.parent?
      auth_obj = @current_user.parent_record.user
    else
      auth_obj = @current_user
    end
    @own_links = current_user.menu_links.select{|l| can_access_request?(l.target_action.to_s.to_sym,auth_obj,:context=>l.target_controller.to_s.to_sym)}
    @allowed_links = selective_links.select{|l| can_access_request?(l.target_action.to_s.to_sym,auth_obj,:context=>l.target_controller.to_s.to_sym)}
  end

  private
  
  def clean_session
    session[:user_id] = nil if session[:user_id]
    session[:language] = nil
    session[:financial_year] = nil
  end
  
  def successful_user_login(user)
    cookies.delete("_fedena_session")
    session[:user_id] = user.id
    reset_financial_year
    #    flash[:notice] = "#{t('welcome')}, #{user.first_name} #{user.last_name}!"
    redirect_to ((session[:back_url] unless ((session[:back_url]) =~ /user\/logout$/) or ((session[:back_url]) =~ /user\/show_all_features$/)) or ((session[:back_url]) =~ /user\/show_quick_links$/) || {:controller => 'user', :action => 'dashboard'})
  end

end

