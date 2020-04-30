class AddSchoolStatsEnabledToSchoolGroup < ActiveRecord::Migration
  def self.up
    add_column :school_groups, :school_stats_enabled, :boolean, :default=>false
  end

  def self.down
    remove_column :school_groups, :school_stats_enabled
  end
end
