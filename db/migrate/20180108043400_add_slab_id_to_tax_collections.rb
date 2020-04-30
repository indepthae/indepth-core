class AddSlabIdToTaxCollections < ActiveRecord::Migration
  def self.up
    add_column :tax_collections, :slab_id, :integer, :null => false
  end

  def self.down
    remove_column :tax_collections, :slab_id
  end
end
