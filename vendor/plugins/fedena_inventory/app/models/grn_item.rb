
class GrnItem < ActiveRecord::Base
  belongs_to :grn
  belongs_to :store_item

  validates_presence_of :quantity, :unit_price, :store_item_id
  validates_numericality_of  :quantity, :greater_than => 0, :less_than => 100000
  validates_numericality_of :unit_price

  named_scope :active,{ :conditions => { :is_deleted => false }}

  default_scope :conditions => { :is_deleted => false }
  before_save :verify_precision

#  def total_amount
 #   self.quantity *  self.unit_price + ( self.quantity *  self.unit_price *  self.tax * 0.01) - ( self.quantity *  self.unit_price )* ( self.discount * 0.01)
  #end

  def total_amount
    if grn.saved_in_old_tax_mode?
      net_amount = gross_amount + tax_amount(gross_amount)
      net_amount - discount_amount(net_amount) 
    else
      net_amount = gross_amount - discount_amount(gross_amount)
      net_amount + tax_amount(net_amount)
    end  
  end
  
  def gross_amount
    quantity * unit_price
  end

  def discount_amount(amount)
    amount * (discount * 0.01)
  end
  
  def tax_amount(amount)
    return amount * ( tax * 0.01)
  end
  
  def verify_precision
    self.unit_price = FedenaPrecision.set_and_modify_precision self.unit_price
    self.tax = FedenaPrecision.set_and_modify_precision self.tax
    self.discount = FedenaPrecision.set_and_modify_precision self.discount
  end

  def validate
    errors.add("expiry_date","can not be less than today") if expiry_date.to_date < Date.today
  end

  def destroy
    update_attributes(:is_deleted => true)
  end

end
