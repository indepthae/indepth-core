class ChangeColumnGradebookAttendances < ActiveRecord::Migration
  def self.up
    change_column :gradebook_attendances, :total_working_days, :decimal,:precision => 5, :scale => 1
    change_column :gradebook_attendances, :total_days_present, :decimal,:precision => 5, :scale => 1
  end

  def self.down
    change_column :gradebook_attendances, :total_working_days, :integer
    change_column :gradebook_attendances, :total_days_present, :integer
  end
end
