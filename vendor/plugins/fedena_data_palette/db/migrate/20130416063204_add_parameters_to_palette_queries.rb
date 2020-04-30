class AddParametersToPaletteQueries < ActiveRecord::Migration
  def self.up
    add_column :palette_queries, :parameters, :text
  end

  def self.down
    remove_column :palette_queries, :parameters
  end
end
