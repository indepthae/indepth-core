class TaxAssignment < ActiveRecord::Base
  # associates tax slab with finance fee particulars
  belongs_to :taxable, :polymorphic => true, :dependent => :destroy
  belongs_to :tax_slab
  
end