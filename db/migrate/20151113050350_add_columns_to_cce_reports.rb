class AddColumnsToCceReports < ActiveRecord::Migration
  def self.up
    add_column :cce_reports, :max_mark, :float
    add_column :cce_reports, :obtained_mark, :float
    add_column :cce_reports, :converted_mark, :float
  end

  def self.down
    remove_column :cce_reports, :converted_mark
    remove_column :cce_reports, :obtained_mark
    remove_column :cce_reports, :max_mark
  end
end
