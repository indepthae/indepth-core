class CreateTransportAttendances < ActiveRecord::Migration
  def self.up
    create_table :transport_attendances do |t|
      t.date :attendance_date
      t.integer :receiver_id
      t.string :receiver_type
      t.integer :route_type
      t.references :route
      t.datetime  :entering
      t.datetime  :leaving
      t.references :school
      
      t.timestamps
    end
  end

  def self.down
    drop_table :transport_attendances
  end
end
