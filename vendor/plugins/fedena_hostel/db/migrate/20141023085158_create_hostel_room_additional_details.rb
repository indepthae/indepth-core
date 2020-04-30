class CreateHostelRoomAdditionalDetails < ActiveRecord::Migration
  def self.up
    create_table :hostel_room_additional_details do |t|
      t.references :linkable,:polymorphic=>true
      t.references :hostel_room_additional_field
      t.string :additional_info
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :hostel_room_additional_details
  end
end
