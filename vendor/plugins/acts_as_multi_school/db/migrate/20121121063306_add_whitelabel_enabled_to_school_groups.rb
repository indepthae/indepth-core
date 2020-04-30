class AddWhitelabelEnabledToSchoolGroups < ActiveRecord::Migration
  def self.up
    add_column :school_groups, :whitelabel_enabled, :boolean, :default=>false
    add_column :school_groups, :license_count, :integer
  end

  def self.down
    remove_column :school_groups, :whitelabel_enabled
    remove_column :school_groups, :license_count
  end
end
