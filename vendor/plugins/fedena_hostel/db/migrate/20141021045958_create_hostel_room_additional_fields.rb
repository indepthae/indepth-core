class CreateHostelRoomAdditionalFields < ActiveRecord::Migration
  def self.up
    create_table :hostel_room_additional_fields do |t|
      t.string :name
      t.boolean :is_mandatory
      t.string :input_type
      t.integer :priority
      t.boolean :is_active
      t.integer :school_id
      t.string :type

      t.timestamps
    end
  end

  def self.down
    drop_table :hostel_room_additional_fields
  end
end
