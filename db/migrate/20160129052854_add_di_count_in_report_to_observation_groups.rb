class AddDiCountInReportToObservationGroups < ActiveRecord::Migration
  def self.up
    add_column :observation_groups, :di_count_in_report, :integer
  end

  def self.down
    remove_column :observation_groups, :di_count_in_report
  end
end
