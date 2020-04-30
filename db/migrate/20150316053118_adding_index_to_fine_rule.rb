class AddingIndexToFineRule < ActiveRecord::Migration
  def self.up
    add_index :fine_rules, :fine_id
  end

  def self.down
    remove_index :fine_rules, :fine_id
  end
end
