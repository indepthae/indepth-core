class AddIndicesForSchoolStatsHostel < ActiveRecord::Migration
  def self.up
    add_index :room_details, :hostel_id
    add_index :room_allocations, :room_detail_id
  end

  def self.down
    remove_index :room_details, :hostel_id
    remove_index :room_allocations, :room_detail_id
  end
end
