class AddSchoolIdToHostel < ActiveRecord::Migration
  def self.up
    [:hostels,:hostel_fees,:hostel_fee_collections,:room_allocations,:room_details,:wardens].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
     [:hostels,:hostel_fees,:hostel_fee_collections,:room_allocations,:room_details,:wardens].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
