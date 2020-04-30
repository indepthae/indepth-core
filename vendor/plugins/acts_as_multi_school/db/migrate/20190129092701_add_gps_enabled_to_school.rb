class AddGpsEnabledToSchool < ActiveRecord::Migration
  def self.up
    add_column :schools, :gps_enabled, :boolean, :default=>false
  end

  def self.down
     remove_column :schools, :gps_enabled
  end
end
