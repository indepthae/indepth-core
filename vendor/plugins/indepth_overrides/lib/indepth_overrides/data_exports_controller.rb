module IndepthOverrides
	module DataExportsController
		def self.included(base)
			base.instance_eval do 
				alias_method_chain :new, :indepth
			end
		end

		def new_with_indepth
		#@export_structures = ExportStructure.all(:order => "model_name ASC")
		@export_structures = ExportStructure.all(:order => "model_name ASC", :conditions => "model_name <> 'vehicle'")
	    @export_structures.reject!{|de| (FedenaPlugin.accessible_plugins.include? de.plugin_name) == false unless de.plugin_name.nil?}
	    @export_structures.reject!{|de| Date.today - 30.days < de.data_export.created_at.to_date if de.data_export.present?}
	    if current_user.general_admin?
	    	 exclude_models = ["leave_group","payroll_group", "finance_transaction"]
	    	 @export_structures.reject!{|es| exclude_models.include? es.model_name}
	    end
	    @data_export = DataExport.new
	    @models = params[:models]
	    @file_format = params[:file_format]
	    respond_to do |format|
	      format.html #new.html.erb
	    end
		end

	end
end