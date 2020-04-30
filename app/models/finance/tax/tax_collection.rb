class TaxCollection < ActiveRecord::Base
  # tracks tax to be collected against each taxable entity
  belongs_to :taxable_entity, :polymorphic => true
  belongs_to :taxable_fee, :polymorphic => true
  belongs_to :tax_slab, :foreign_key => "slab_id"
end
