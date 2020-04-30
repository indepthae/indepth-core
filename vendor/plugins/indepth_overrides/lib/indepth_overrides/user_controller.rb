module IndepthOverrides
	module UserController
		def self.included(base)
			base.instance_eval do 
				alias_method_chain :login, :indepth
				alias_method_chain :forgot_password, :indepth
				alias_method_chain :choose_layout, :indepth
				alias_method_chain :create, :indepth
				alias_method_chain :search_user_ajax, :indepth
				alias_method_chain :edit_privilege,:indepth
				alias_method_chain :profile, :indepth
				alias_method_chain :block_user, :indepth
				alias_method_chain :unblock_user, :indepth
				before_filter :check_master_admin?, :only=> [:user_change_password, :profile]
			end
		end

		def check_master_admin?
			if current_user.general_admin? 
				user = User.find_by_username params[:user_name]
			    if user.admin? && !user.general_admin?
					flash[:notice] = "#{t('flash_msg4')}"
		            redirect_to :controller => 'user', :action => 'dashboard'
		        end
		    end
		end
    
		def login_with_indepth
			@institute = Configuration.find_by_config_key("LogoName")
	    available_login_authes = FedenaPlugin::AVAILABLE_MODULES.select{|m| m[:name].camelize.constantize.respond_to?("login_hook")}
	    selected_login_hook = available_login_authes.first if available_login_authes.count>=1
	    if selected_login_hook
	      authenticated_user = selected_login_hook[:name].camelize.constantize.send("login_hook",self)
	    else
	      if request.post? and params[:user]
	        @user = User.new(params[:user])
	        user = User.active.first(:conditions => ["username LIKE BINARY(?)",@user.username])
          guardian = Guardian.first(:include => :user, 
            :conditions => ["u.is_deleted = false AND guardians.familyid LIKE ?",@user.username], 
            :joins => "INNER JOIN users u ON u.id = guardians.user_id") unless user.present?
          
	        if user.present? and User.authenticate?(@user.username, @user.password)
	          authenticated_user = user
	        elsif guardian.present?
	        	user = guardian.user
	        	if user.present? and User.authenticate?(user.username, @user.password)
              authenticated_user = user
            end
	        end
	      end
	    end
	    if authenticated_user.present?
	      flash.clear
	      if authenticated_user.is_blocked == false
	        successful_user_login(authenticated_user) and return
	      else
	        flash[:notice] = "#{t('blocked_login_error_message')}"
	        render 'indepth_user/login'
	      end
	    elsif authenticated_user.blank? and request.post?
	      flash[:notice] = "#{t('login_error_message')}"
	      render 'indepth_user/login'
	    elsif request.get?
	    	render 'indepth_user/login'
	    end
		end

		def forgot_password_with_indepth
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
	            render 'indepth_user/forgot_password' && return
	          end
	          flash[:notice] = "#{t('flash18')}"
	          redirect_to :action => "index"
	        else
	          flash[:notice] = "#{t('flash20')}"
	          render 'indepth_user/forgot_password' && return
	        end
	      else
	        flash[:notice] = "#{t('flash19')}"
	        render 'indepth_user/forgot_password'
	      end
	    else
	    	render 'indepth_user/forgot_password'
	    end
		end

		def choose_layout_with_indepth
	      return 'login' if action_name == 'login' or action_name == 'set_new_password'
	      return 'forgotpw' if action_name == 'forgot_password'
	      return 'indepth_dashboard' if action_name == 'dashboard'
	      'indepth_application'
		end

		def create_with_indepth
			@config = Configuration.available_modules
			    @user = ::User.new(params[:user])
			    if request.post?
			      if @user.save
			        flash[:notice] = "#{t('flash17')}"
			        redirect_to :controller => 'user', :action => 'profile', :id => @user.username
			      else
			      	render 'indepth_user/create'
			      end
			    else
			    	render 'indepth_user/create'
			    end
		end

		def search_user_ajax_with_indepth
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
	      if current_user.general_admin? 
	      	user = user.reject{|u| u.admin? && !u.general_admin?}
	      end
	      @users = user.paginate(:per_page => 30, :page => params[:page])
	    end
	    render :partial => "user_list"
	  end

	  def edit_privilege_with_indepth
	    user_name = params[:user_name].join('/')
	    #    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",params[:id]])
	    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",user_name])
	    if @user.admin? or @user.student? or @user.parent? or current_user == @user or @user.general_admin?
	      flash[:notice] = "#{t('flash_msg4')}"
	      redirect_to :controller => "user",:action => "dashboard"
	    else
	    	@finance = Configuration.find_by_config_value("Finance")
	      @sms_setting = SmsSetting.application_sms_status
	      @hr = Configuration.find_by_config_value("HR")
	      @privilege_tags = {}
	      privilege_tags=PrivilegeTag.find(:all, :joins => :privileges, :include => :privileges, :order=>"priority ASC", :group => "privilege_tags.id")
	      if current_user.general_admin?
	      	privilege_tags.reject!{|s| s.name_tag == 'finance_control'}
	      end
	      privilege_tags.each do |pt|
		      prvgs = pt.privileges.all(:conditions=>"name<>'FinanceControl'",:order=>"priority ASC").select{|p| p.applicable?}
		      if current_user.general_admin?
			      if pt.name_tag == 'hr_management'
			      	prvgs.reject!{|s| ["PayrollAndPayslip", "EmployeeReports"].include? s.name}
			      end
			      if pt.name_tag == 'administration_operations'
			      	prvgs.reject!{|s| ["ManageUsers"].include? s.name}
			      end
		  	  end
		      @privilege_tags[pt] = prvgs
		  end
	      @privilege_tags = @privilege_tags.sort_by{|k,v| k.priority}
	      @user_privileges=@user.privileges
	      if request.post?
	        new_privileges = params[:user][:privilege_ids] if params[:user]
	        new_privileges ||= []
	        @user.privileges = Privilege.find_all_by_id(new_privileges)
	        @user.clear_menu_cache
	        #@user.delete_user_menu_caches
	        flash[:notice] = "#{t('flash15')}"
	        redirect_to :action => 'profile',:id => @user.username
	      end
	    end
	  end
#		def can_see_single_statement?
#            return true if @current_user.admin?
#			return true if (self.privileges.map(&:name).include? "ManageFee" or 
#          self.privileges.map(&:name).include? "FeeSubmission" or 
#          self.privileges.map(&:name).include? "ManageRefunds" or 
#          self.privileges.map(&:name).include? "FinanceReports")
#		end

		def profile_with_indepth
	  	profile_without_indepth
	  	render 'indepth_user/profile'
	  end

	  def block_user_with_indepth
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
	    	if current_user.general_admin? 
	      	user = user.reject{|u| u.admin? && !u.general_admin?}
	      end
	      @users = user.paginate(:per_page => 30, :page => params[:page])
	    end
	    render :partial => "user_list"
	    
	#    redirect_to :controller => 'user'
	  end
	  
	  def unblock_user_with_indepth
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
	    	if current_user.general_admin? 
	      	user = user.reject{|u| u.admin? && !u.general_admin?}
	      end
	      @users = user.paginate(:per_page => 30, :page => params[:page])
	    end
	    render :partial => "user_list"
	  end

  end
end