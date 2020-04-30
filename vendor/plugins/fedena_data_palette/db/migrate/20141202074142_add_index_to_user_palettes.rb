class AddIndexToUserPalettes < ActiveRecord::Migration
  def self.up
    add_index :user_palettes, :school_id
#    add_index :user_palettes, [:user_id,:palette_id]
#    add_index :palettes, :name
  end

  def self.down
    remove_index :user_palettes, :school_id
#    remove_index :user_palettes, [:user_id,:palette_id]
#    remove_index :palettes, :name
  end
end
