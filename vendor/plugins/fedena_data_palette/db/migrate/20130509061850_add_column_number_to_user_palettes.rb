class AddColumnNumberToUserPalettes < ActiveRecord::Migration
  def self.up
    add_column :user_palettes, :column_number, :integer
  end

  def self.down
    remove_column :user_palettes, :column_number
  end
end
