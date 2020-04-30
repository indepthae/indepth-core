class CreateRoomDetails < ActiveRecord::Migration
  def self.up
    create_table :room_details do |t|
      t.references  :hostel
      t.string      :room_number
      t.integer     :students_per_room
      t.decimal     :rent, :precision => 8, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :room_details
  end
end
