class CreateAttendanceLabels < ActiveRecord::Migration
  def self.up
    create_table :attendance_labels do |t|
      t.string :name
      t.string :code
      t.string :type
      t.float :weightage
      t.boolean :is_active
      t.boolean :has_notification

      t.timestamps
    end
  end

  def self.down
    drop_table :attendance_labels
  end
end
