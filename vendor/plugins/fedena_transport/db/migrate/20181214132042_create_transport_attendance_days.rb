class CreateTransportAttendanceDays < ActiveRecord::Migration
  def self.up
    create_table :transport_attendance_days do |t|
      t.date :attendance_date
      t.integer :route_type
      t.references :route
      t.string :receiver_type
      t.boolean :all_present, :default => true
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_attendance_days
  end
end
