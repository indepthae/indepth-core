class AddPluginToPalettes < ActiveRecord::Migration
  def self.up
    add_column :palettes, :plugin, :string
  end

  def self.down
    remove_column :palettes, :plugin
  end
end
