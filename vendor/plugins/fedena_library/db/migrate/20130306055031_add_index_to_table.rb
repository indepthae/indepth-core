class AddIndexToTable < ActiveRecord::Migration
  def self.up
    add_index :book_additional_fields,:school_id
  end

  def self.down
    remove_index :book_additional_fields,:school_id
  end
end
