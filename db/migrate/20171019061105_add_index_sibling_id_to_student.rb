class AddIndexSiblingIdToStudent < ActiveRecord::Migration
   def self.up
    add_index :students, :sibling_id
  end

  def self.down
    remove_index :students, :sibling_id
  end
end
