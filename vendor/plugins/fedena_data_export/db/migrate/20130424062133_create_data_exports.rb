class CreateDataExports < ActiveRecord::Migration
  def self.up
    create_table :data_exports do |t|
      t.references :export_structure
      t.string   :file_format
      t.string   :status
      t.string   :export_file_file_name
      t.string   :export_file_content_type
      t.integer  :export_file_file_size
      t.datetime :export_file_updated_at
      t.integer  :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :data_exports
  end
end
