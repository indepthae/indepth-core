class InstantFeeDetail < ActiveRecord::Base
  belongs_to :instant_fee
  belongs_to :instant_fee_particular

  before_save :verify_precision
  after_save :build_tax_associations
  
  def build_tax_associations
    if instant_fee.tax_enabled?
      cts = self.instant_fee.collectible_tax_slabs.new
      tp = self.instant_fee.tax_payments.new
      if self.instant_fee_particular_id == nil
        cts.tax_slab_id = self.slab_id
        cts.collectible_entity = tp.taxed_entity = self
      else
        cts.tax_slab_id = self.instant_fee_particular.tax_slabs.try(:last).try(:id)
        cts.collectible_entity = tp.taxed_entity = self.instant_fee_particular
      end
      if cts.tax_slab_id.present?
        tp.tax_amount = self.tax_amount
        cts.save        
        tp.save        
      end
    end
  end
  
  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
    self.discount = FedenaPrecision.set_and_modify_precision self.discount
    self.net_amount = FedenaPrecision.set_and_modify_precision self.net_amount
  end

  def particular_name
    self.instant_fee_particular.nil? ? self.custom_particular : self.instant_fee_particular.name
  end

  def particular_description
    self.instant_fee_particular.nil? ? "Custom Particular" : self.instant_fee_particular.description
  end
end
