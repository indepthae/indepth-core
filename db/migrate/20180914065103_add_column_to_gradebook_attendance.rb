class AddColumnToGradebookAttendance < ActiveRecord::Migration
  def self.up
    add_column :gradebook_attendances, :report_type, :string
  end

  def self.down
    remove_column :gradebook_attendances, :report_type
  end
end
