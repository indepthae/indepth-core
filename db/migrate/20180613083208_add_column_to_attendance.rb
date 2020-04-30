class AddColumnToAttendance < ActiveRecord::Migration
  def self.up
    add_column :attendances, :notification_sent, :boolean
  end

  def self.down
    remove_column :attendances, :notification_sent
  end
end
