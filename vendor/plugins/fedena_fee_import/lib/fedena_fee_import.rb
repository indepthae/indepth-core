require 'dispatcher'
# FedenaFeeImport
module FedenaFeeImport
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_fee_import do
      ::StudentController.instance_eval { include FeeImportRedirection }
    end
  end



  module FeeImportRedirection
    def self.included(base)
      base.instance_eval do
        before_filter :redirect_to_import_fee, :only =>[:admission4]
      end
    end

    def redirect_to_import_fee
      if FedenaPlugin.can_access_plugin?("fedena_fee_import")
        unless params[:imported].present? or request.referrer.index("previous_data").nil?
          flash[:notice] = t('select_fee_collections')
          redirect_to :controller => "fee_imports", :action => "import_fees", :id => params[:id]
          return
        end
      end
    end
  end
end

#
