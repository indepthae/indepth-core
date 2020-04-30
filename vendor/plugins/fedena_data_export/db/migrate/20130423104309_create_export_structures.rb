class CreateExportStructures < ActiveRecord::Migration
  def self.up
    create_table :export_structures do |t|
      t.string  :model_name
      t.text    :query
      t.string  :template
      t.string  :plugin_name
      t.text    :csv_header_order

      t.timestamps
    end
  end

  def self.down
    drop_table :export_structures
  end
end
