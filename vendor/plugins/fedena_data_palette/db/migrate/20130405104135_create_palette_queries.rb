class CreatePaletteQueries < ActiveRecord::Migration
  def self.up
    create_table :palette_queries do |t|
      t.references :palette
      t.text :user_roles
      t.text :query

      t.timestamps
    end
  end

  def self.down
    drop_table :palette_queries
  end
end
