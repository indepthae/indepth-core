
class IndentItem < ActiveRecord::Base
  belongs_to :indent
  belongs_to :store_item

  default_scope :conditions => { :is_deleted => false }

  validates_presence_of   :quantity, :issued, :issued_type, :store_item_id, :required, :price
  validates_numericality_of  :required, :greater_than => 0, :less_than => 100000
  validates_numericality_of  :issued,  :greater_than_or_equal_to => 0, :less_than => 100000
  validates_numericality_of :price, :greater_than_or_equal_to => 0

  named_scope :active,{ :conditions => { :is_deleted => false }}
  before_save :verify_precision

  def verify_precision
    self.price = FedenaPrecision.set_and_modify_precision self.price
  end


  def destroy
    update_attributes(:is_deleted => true)
  end

  def issue_indent_item
    unless pending == 0
      self.quantity = (store_item.quantity - pending)
      previous_store_item_quantity = store_item.quantity
      store_item.update_attributes(:quantity => (quantity > 0 ? quantity : 0) )
      update_attributes(:issued => issued > 0 ? (quantity >= 0 ? (issued + pending) : (issued + previous_store_item_quantity)) : quantity > 0 ? required : previous_store_item_quantity,:pending => quantity > 0 ? 0 : quantity.abs,:quantity => store_item.quantity)
    end
  end
end
