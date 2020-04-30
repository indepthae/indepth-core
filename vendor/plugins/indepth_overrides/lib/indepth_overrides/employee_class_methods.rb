module IndepthOverrides
	module EmployeeClassMethods
		def self.included(base)
		    base.instance_eval do
		   			def fetch_employee_advance_search_data(params)
							params = params[:params] if params.key?(:params)
				      employee_ids = params[:result]
				      searched_for = params[:for]
				      status = params[:status]
				      employees = []
				      if params[:status] == 'true'
				        search = Employee.ascend_by_first_name.search(params[:search])
				        employees += search.all
				      elsif params[:status] == 'false'
				        search = ArchivedEmployee.ascend_by_first_name.search(params[:search])
				        employees += search.all
				      else
				        search1 = Employee.ascend_by_first_name.search(params[:search]).all
				        search2 = ArchivedEmployee.ascend_by_first_name.search(params[:search]).all
				        employees+=search1+search2
				      end
				      if Authorization.current_user.general_admin?
					      employees = employees.reject!{|e| e.user.admin? && !e.user.general_admin?}
				    	end
				      data_hash = {:method => "employee_advance_search", :parameters => params, :searched_for => searched_for, :employees => employees}
				      find_report_type(data_hash)
						end 
		    end
		end
	end
end