class AddingIndexToHostelFee < ActiveRecord::Migration
 def self.up
    add_index :hostel_fees,:rent
  end

  def self.down
    remove_index :hostel_fees,:rent
  end
end
