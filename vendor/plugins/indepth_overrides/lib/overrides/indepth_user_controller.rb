#module IndepthOverrides
#  module IndepthUserController
#  	def self.included (base)
#  		base.instance_eval do
#	  		alias_method_chain :login, :tmpl
#	  	end
#  	end
#
#  	def login_with_tmpl
#	    @institute = Configuration.find_by_config_key("LogoName")
#	    available_login_authes = FedenaPlugin::AVAILABLE_MODULES.select{|m| m[:name].camelize.constantize.respond_to?("login_hook")}
#	    selected_login_hook = available_login_authes.first if available_login_authes.count>=1
#	    if selected_login_hook
#	      authenticated_user = selected_login_hook[:name].camelize.constantize.send("login_hook",self)
#	    else
#	      if request.post? and params[:user]
#	        @user = User.new(params[:user])
#	        user = User.active.first(:conditions => ["username LIKE BINARY(?)",@user.username])
#	        guardian = Guardian.first(:conditions => ["familyid LIKE ?",@user.username])         
#	        if user.present? and User.authenticate?(@user.username, @user.password)
#	          authenticated_user = user
#	        elsif guardian.present?
#	        	user = guardian.user
#	        	if user.present? and User.authenticate?(user.username, @user.password)
#              authenticated_user = user
#            end
#	        end
#	      end
#	    end
#	    if authenticated_user.present?
#	      flash.clear
#	      if authenticated_user.is_blocked == false
#	        successful_user_login(authenticated_user) and return
#	      else
#	        flash[:notice] = "#{t('blocked_login_error_message')}"
#	      end
#	    elsif authenticated_user.blank? and request.post?
#	      flash[:notice] = "#{t('login_error_message')}"
#	    end
#    end
#
#    #    def can_see_single_statement?
#    #      return true if @current_user.admin?
#    #      return true if  self.privileges.map(&:name).include? "ManageFee" or 
#    #        self.privileges.map(&:name).include? "FeeSubmission" or 
#    #        self.privileges.map(&:name).include? "ManageRefunds" or 
#    #        self.privileges.map(&:name).include? "FinanceReports"
#    #    end
#  end
#end