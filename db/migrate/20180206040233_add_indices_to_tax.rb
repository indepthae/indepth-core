class AddIndicesToTax < ActiveRecord::Migration
  def self.up
    add_index :collectible_tax_slabs, [:collectible_entity_type, :collectible_entity_id], :name => "index_by_collectible_entity"
    add_index :collectible_tax_slabs, [:collection_type, :collection_id], :name => "index_by_collection"
    add_index :collectible_tax_slabs, [:tax_slab_id], :name => "index_by_tax_slab_id"
    add_index :tax_assignments, [:taxable_type, :taxable_id], :name => "index_by_taxable"
    add_index :tax_assignments, [:tax_slab_id], :name => "index_by_tax_slab_id"    
    add_index :tax_collections, [:taxable_entity_type,:taxable_entity_id], :name => "index_by_taxable_entity"
    add_index :tax_collections, [:taxable_fee_type,:taxable_fee_id], :name => "index_by_taxable_fee"
    add_index :tax_collections, [:slab_id], :name => "index_by_slab_id"
    add_index :tax_payments, [:taxed_entity_type,:taxed_entity_id], :name => "index_by_taxed_entity"
    add_index :tax_payments, [:taxed_fee_type,:taxed_fee_id], :name => "index_by_taxed_fee"    
  end

  def self.down    
    remove_index :tax_payments, [:taxed_fee_type,:taxed_fee_id], :name => "index_by_taxed_fee"
    remove_index :tax_payments, [:taxed_entity_type,:taxed_entity_id], :name => "index_by_taxed_entity"
    remove_index :tax_collections, [:slab_id], :name => "index_by_slab_id"
    remove_index :tax_collections, [:taxable_fee_type,:taxable_fee_id], :name => "index_by_taxable_fee"
    remove_index :tax_collections, [:taxable_entity_type,:taxable_entity_id], :name => "index_by_taxable_entity"
    remove_index :tax_assignments, [:tax_slab_id], :name => "index_by_tax_slab_id"    
    remove_index :tax_assignments, [:taxable_type, :taxable_id], :name => "index_by_taxable"
    remove_index :collectible_tax_slabs, [:tax_slab_id], :name => "index_by_tax_slab_id"
    remove_index :collectible_tax_slabs, [:collection_type, :collection_id], :name => "index_by_collection"
    remove_index :collectible_tax_slabs, [:collectible_entity_type, :collectible_entity_id], :name => "index_by_collectible_entity"
  end
end
