class CreateImportLogDetails < ActiveRecord::Migration
  def self.up
    create_table :import_log_details do |t|
      t.references :import
      t.string :model
      t.string :status
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :import_log_details
  end
end
