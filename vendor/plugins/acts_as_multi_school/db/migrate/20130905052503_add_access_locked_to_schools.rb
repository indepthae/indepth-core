class AddAccessLockedToSchools < ActiveRecord::Migration
  def self.up
    add_column :schools, :access_locked, :boolean, :default=>false
  end

  def self.down
    remove_column :schools, :access_locked
  end
end
