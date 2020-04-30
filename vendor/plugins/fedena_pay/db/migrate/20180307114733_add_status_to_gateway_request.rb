class AddStatusToGatewayRequest < ActiveRecord::Migration
  def self.up
    add_column :gateway_requests, :status, :boolean, :default=>false
    add_index :gateway_requests, [:transaction_reference, :status], :name => 'index_on_reference'
  end

  def self.down
    remove_column :gateway_requests, :status
    remove_index :gateway_requests, [:transaction_reference, :status], :name => 'index_on_reference'
  end
end
