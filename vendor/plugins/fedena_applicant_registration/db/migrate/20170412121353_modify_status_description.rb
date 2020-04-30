class ModifyStatusDescription < ActiveRecord::Migration
  def self.up
    change_column :application_statuses, :description, :text
  end

  def self.down
    change_column :application_statuses, :description, :string
  end
end
