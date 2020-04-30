class AddAccountWiseParametersToCustomGateways < ActiveRecord::Migration
  def self.up
    add_column :custom_gateways, :account_wise_parameters, :text
    add_column :custom_gateways, :enable_account_wise_split, :boolean, :default=>false
  end

  def self.down
    remove_column :custom_gateways, :enable_account_wise_split
    remove_column :custom_gateways, :account_wise_parameters
  end
end
