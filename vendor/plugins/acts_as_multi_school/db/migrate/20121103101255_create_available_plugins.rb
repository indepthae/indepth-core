class CreateAvailablePlugins < ActiveRecord::Migration
  def self.up
    create_table :available_plugins do |t|
      t.integer :associated_id
      t.string :associated_type
      t.text :plugins

      t.timestamps
    end
  end

  def self.down
    drop_table :available_plugins
  end
end
