class AddSchoolIdToPlacement < ActiveRecord::Migration
  def self.up
    [:placementevents,:placement_registrations].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
     [:placementevents,:placement_registrations].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
