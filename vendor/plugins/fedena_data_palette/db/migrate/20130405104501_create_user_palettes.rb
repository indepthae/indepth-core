class CreateUserPalettes < ActiveRecord::Migration
  def self.up
    create_table :user_palettes do |t|
      t.references :user
      t.references :palette
      t.integer :position
      t.boolean :is_minimized, :default=>false
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :user_palettes
  end
end
