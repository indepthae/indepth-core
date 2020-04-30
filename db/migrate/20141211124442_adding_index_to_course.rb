class AddingIndexToCourse < ActiveRecord::Migration
  def self.up
    add_index :courses, :is_deleted
  end

  def self.down
    remove_index :courses, :is_deleted
  end
end
