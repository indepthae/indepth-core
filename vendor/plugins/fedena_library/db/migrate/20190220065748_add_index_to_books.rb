class AddIndexToBooks < ActiveRecord::Migration
  def self.up
    add_index :books, :book_number
  end

  def self.down
    remove_index :books, :book_number
  end
end
