
class PurchaseItem < ActiveRecord::Base
  belongs_to :user
  belongs_to :purchase_order
  belongs_to :store_item

  attr_writer :item_name
  delegate :item_name, :to => :store_item, :allow_nil => true

  validates_presence_of :quantity, :discount, :tax,:store_item_id, :price
  validates_numericality_of  :price,:greater_than => 0, :less_than_or_equal_to => 10000000
  validates_numericality_of  :quantity, :greater_than_or_equal_to => 0, :less_than => 100000
  validates_numericality_of :discount,:tax, :greater_than_or_equal_to => 0, :less_than => 100

  default_scope :conditions => { :is_deleted => false }

  named_scope :active,{ :conditions => { :is_deleted => false }}

  before_save :verify_precision

  def verify_precision
    self.price = FedenaPrecision.set_and_modify_precision self.price
    self.tax = FedenaPrecision.set_and_modify_precision self.tax
    self.discount = FedenaPrecision.set_and_modify_precision self.discount
  end

  def destroy
    update_attributes(:is_deleted => true)
  end

#  def total_amount   
#    net_amount + tax_amount
#    #(quantity *  price) + (quantity *  price * tax * 0.01) - ( quantity *  price ) * (discount  * 0.01) unless discount.nil? or  tax.nil? 
#  end

  def total_amount
    if FedenaInventory.old_tax_mode?
      net_amount = gross_amount + tax_amount(gross_amount)
      net_amount - discount_amount(net_amount) 
    else
      net_amount = gross_amount - discount_amount(gross_amount)
      net_amount + tax_amount(net_amount)
    end  
  end
  
  def gross_amount
    quantity * price
  end

  def discount_amount(amount)
    amount * (discount * 0.01)
  end
  
  def tax_amount(amount)
    return amount * ( tax * 0.01)
  end

end
