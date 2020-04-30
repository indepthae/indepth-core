module IndepthOverrides
	module ExportsController
		def self.included(base)
			base.instance_eval do 
				alias_method_chain :new, :indepth
			end
		end

		def new_with_indepth
		  @models = Export.get_models.select{ |model| defined?model.second.camelize.constantize == "constant" }
	    @models.reject!{|s| s[1] == 'EmployeeSalaryStructureForImport'} if current_user.general_admin?
	    @export = Export.new
	  end

	end
end