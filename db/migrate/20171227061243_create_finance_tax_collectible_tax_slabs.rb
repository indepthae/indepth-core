class CreateFinanceTaxCollectibleTaxSlabs < ActiveRecord::Migration
  def self.up
    create_table :collectible_tax_slabs do |t|
      t.references :collectible_entity, :polymorphic => true, :null => false
      t.references :collection, :polymorphic => true, :null => false
      t.references :tax_slab, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :collectible_tax_slabs
  end
end
