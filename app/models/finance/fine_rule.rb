class FineRule < ActiveRecord::Base
  validates_uniqueness_of :fine_days, :scope=>[:fine_id]
  validates_inclusion_of :fine_amount, :in => 0..100,:unless=>:is_amount,:message=>:in_percentage_cant_exceed_100
  belongs_to :fine
  belongs_to :user

  before_save :verify_precision



  named_scope :order_in_fine_days,:order=>'fine_days ASC'

  validates_presence_of :fine_amount,:fine_days
  validates_numericality_of :fine_amount,:fine_days,:allow_blank=>true

  def validate
    if (fine_days and fine_days <= 0)
      errors.add("fine_days",:should_be_greater_than_zero)
    end
    if (fine_amount and fine_amount <= 0)
      errors.add("fine_value",:should_be_greater_than_zero)
    end

    if !self.new_record? and self.changed? 
      if Fine.finance_fee_collection_dependancy_exists(self) or Fine.transport_fee_collection_dependancy_exists(self)
         errors.add("fine_slab",:assigned_to_fee_collection_cant_be_edited)
      end  
    end
  end

  private

  def verify_precision
    self.fine_amount=FedenaPrecision.set_and_modify_precision self.fine_amount
  end
end
