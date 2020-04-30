class AddGpsEnabledToSchoolGroups < ActiveRecord::Migration
  def self.up
     add_column :school_groups, :gps_enabled, :boolean, :default=>false
  end

  def self.down
    remove_column :school_groups, :gps_enabled
  end
end
