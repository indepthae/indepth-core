class CreateTransportImports < ActiveRecord::Migration
  def self.up
    create_table :transport_imports do |t|
      t.references :import_from
      t.references :import_to
      t.text :imports
      t.text :completed_imports
      t.integer :status
      t.text :last_error
      t.references :school

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_imports
  end
end
