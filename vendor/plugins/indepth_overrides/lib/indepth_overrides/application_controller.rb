module IndepthOverrides
	module ApplicationController
		def self.included(base)
			base.instance_eval do 
				layout 'indepth_application'
			end
		end

		def can_see_single_statement
      puts "checked"
			return true if  (@current_user.admin? || @current_user.student? || @current_user.parent?)
			return true if  (@current_user.employee? && 
          (@current_user.privileges.map(&:name) & ["ManageFee", "FeeSubmission", "ManageRefunds", "FinanceReports"]).present?)          
      # otherwise redirect to dashboard
      flash[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller=>"user", :action=>"dashboard"
      
		end
	end
end