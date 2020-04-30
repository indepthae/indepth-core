class AddIsDeletedToApplicants < ActiveRecord::Migration
  def self.up
    add_column :applicants, :is_deleted, :boolean, :default=>false
  end

  def self.down
    remove_column :applicants, :is_deleted
  end
end
