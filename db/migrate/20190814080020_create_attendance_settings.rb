class CreateAttendanceSettings < ActiveRecord::Migration
  def self.up
    create_table :attendance_settings do |t|
      t.string :setting_key
      t.boolean :is_enable
      t.string :user_type

      t.timestamps
    end
  end

  def self.down
    drop_table :attendance_settings
  end
end
