class AddCommomFieldToWeekdaySet < ActiveRecord::Migration
  def self.up
    add_column :weekday_sets, :is_common, :boolean,:default=>false
  end

  def self.down
    remove_column :weekday_sets, :is_common
  end
end
