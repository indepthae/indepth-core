class SupplierType < ActiveRecord::Base
  validates_presence_of:name,:code

  has_many :suppliers
  has_many :purchase_orders

  named_scope :active,{ :conditions => { :is_deleted => false }}

  def validate
    if SupplierType.active.reject{|st| st.id == id}.find_by_code(code).present? and is_deleted == false
      errors.add("code","is already taken")
    end
  end

  def can_be_deleted?
    (suppliers.active.present? or purchase_orders.active.present?) ? false : true
  end

  def full_name
    "#{name}-#{code}"
  end
end
