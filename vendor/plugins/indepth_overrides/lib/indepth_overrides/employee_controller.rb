module IndepthOverrides
	module EmployeeController

		def self.included(base)
			base.instance_eval do 
				alias_method_chain :edit_privilege, :indepth
				alias_method_chain :advanced_search, :indepth
				alias_method_chain :employees_list, :indepth
				alias_method_chain :admission4, :indepth
				layout :choose_layout
				before_filter :check_master_admin?, :only=> [:remove, :profile]
			end
		end


		def admission4_with_indepth
	    @departments = EmployeeDepartment.ordered
	    @categories  = EmployeeCategory.find(:all)
	    @positions   = EmployeePosition.find(:all)
	    @grades      = EmployeeGrade.find(:all)
	    if request.post?
	      @employee = Employee.find(params[:id])
	      manager=Employee.find_by_id(params[:employee][:reporting_manager_id])
	      if manager.present?
	        Employee.update(@employee, :reporting_manager_id => manager.user_id)
	      end
	      flash[:notice]=t('flash25')
	      if current_user.general_admin?
	      	redirect_to :controller => "leave_groups", :action => "manage_leave_group", :id=> @employee.id, :from => 'employee_admission'
		    else
		      redirect_to :controller => "payroll", :action => "manage_payroll", :id=>@employee.id, :from => 'employee_admission'
		    end
	    end

	  end
		def employees_list_with_indepth
	    department_id = params[:department_id]
	    @employees = Employee.find_all_by_employee_department_id(department_id,:order=>'first_name ASC')
	    if current_user.general_admin?
		    @employees.reject!{|e| e.user.admin? && !e.user.general_admin?}
	  	end
	    render :update do |page|
	      page.replace_html 'employee_list', :partial => 'employee_view_all_list', :object => @employees
	    end
	  end

		def edit_privilege_with_indepth
		    user_name = params[:user_name].join('/')
		    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",user_name])
		    @employee = @user.employee_record
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
		      redirect_to :action => 'admission4',:id => @employee.id
		    end
		end

		def advanced_search_with_indepth
		    @search = Employee.search(params[:search])
		    @sort_order=""
		    @sort_order=params[:sort_order] if  params[:sort_order]
		    if params[:search]
		      if params[:search][:status_equals]=="true"
		        @employees = Employee.ascend_by_first_name.search(params[:search]).paginate(:page => params[:page], :per_page => 30)
		        #        @employees1 = @search.all
		        #        @employees2 = []
		      elsif params[:search][:status_equals]=="false"
		        @employees = ArchivedEmployee.ascend_by_first_name.search(params[:search]).paginate(:page => params[:page], :per_page => 30)
		        #        @employees1 = @search.all
		        #        @employees2 = []
		      else
		        @employees = [{:employee => {:search_options => params[:search], :order => :first_name}}, {:archived_employee => {:search_options => params[:search], :order => :first_name}}].model_paginate(:page => params[:page],:per_page => 30)
		        #        @search1 = Employee.search(params[:search]).all
		        #        @search2 = ArchivedEmployee.search(params[:search]).all
		        #        @employees1 = @search1
		        #        @employees2 = @search2
		      end
		      if Authorization.current_user.general_admin?
			      @employees.reject!{|emp| (emp.user.admin? && !emp.user.general_admin?) }
			      @employees
		  	  end
		    end
		end

		# def advance_search_pdf_with_indepth
		# 	@data_hash = Employee.fetch_employee_advance_search_data(params)
		#     render :pdf => 'employee_advanced_search_pdf'
		# end

		def check_master_admin?
			if current_user.general_admin? 
				employee = Employee.find params[:id]
			    if employee.user.admin? && !employee.user.general_admin?
					flash[:notice] = "#{t('flash_msg4')}"
		            redirect_to :controller => 'user', :action => 'dashboard'
		        end
		    end
		end

		def choose_layout		  	       
	      'indepth_application'
		end
	end
end