class AddGatewayToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :gateway, :string
  end

  def self.down
    remove_column :payments, :gateway
  end
end
