class AddIsDeletedToCustomGateways < ActiveRecord::Migration
  def self.up
    add_column :custom_gateways, :is_deleted, :boolean, :default=>false
  end

  def self.down
    remove_column :custom_gateways, :is_deleted
  end
end
