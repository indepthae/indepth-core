class CreateBarcodeProperties < ActiveRecord::Migration
  def self.up
    create_table :barcode_properties do |t|
      t.string :linked_to
      t.integer :rotate
      t.references :base_template
        t.integer :school_id
      t.timestamps
    end
    add_index :barcode_properties,[:school_id]
  end

  def self.down
    drop_table :barcode_properties
  end
end
