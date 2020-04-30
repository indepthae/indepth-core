class CreateTallyExportFiles < ActiveRecord::Migration
  def self.up
    create_table :tally_export_files do |t|
      t.integer :download_no, :default => 0

      t.timestamps
      t.references :school
    end
  end

  def self.down
    drop_table :tally_export_files
  end
end
