class CreateRoomAllocations < ActiveRecord::Migration
  def self.up
    create_table :room_allocations do |t|
      t.references  :room_detail
      t.references  :student
      t.boolean :is_vacated, :default=>false
      t.timestamps
    end
  end

  def self.down
    drop_table :room_allocations
  end
end