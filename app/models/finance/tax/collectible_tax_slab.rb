class CollectibleTaxSlab < ActiveRecord::Base
  # associates tax slabs with collections, to prevent any change of tax slab
  belongs_to :collectible_entity, :polymorphic => true
  belongs_to :collection, :polymorphic => true
  belongs_to :collection_tax_slab, :class_name => "TaxSlab", :foreign_key => "tax_slab_id"
end
