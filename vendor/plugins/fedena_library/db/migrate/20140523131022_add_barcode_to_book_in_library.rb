class AddBarcodeToBookInLibrary < ActiveRecord::Migration
  def self.up
    add_column :books, :barcode, :string
    add_index :books, :barcode
  end

  def self.down
    remove_column :books, :barcode, :string
    remove_index :books, :barcode
  end
end
