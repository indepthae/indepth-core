class Invoice < ActiveRecord::Base
  has_many :sold_items
  has_many :additional_charges
  has_many :discounts
  has_many :sales_user_details,:dependent => :destroy
  has_one :finance_transaction, :as => :finance
  validates_uniqueness_of :invoice_no, :scope => :store_id
  belongs_to :store
  belongs_to :financial_year
  attr_accessor :subtotal, :grandtotal
  accepts_nested_attributes_for :sold_items, :allow_destroy => true
  accepts_nested_attributes_for :additional_charges, :allow_destroy => true, :reject_if => lambda { |a| a.values.all?(&:blank?) }
  accepts_nested_attributes_for :discounts, :allow_destroy => true, :reject_if => lambda { |a| a.values.all?(&:blank?) }
  accepts_nested_attributes_for :sales_user_details, :allow_destroy => true
  #belongs_to :finance_transaction
  validates_numericality_of :tax, :greater_than_or_equal_to => 0, :allow_nil => true
  after_create :update_item_quantity_on_create
  before_create :set_tax_mode
  after_validation_on_update :update_item_quantity_on_update
  before_create :set_financial_year
  before_destroy :restore_quantities

  def set_financial_year
    self.financial_year_id = FinancialYear.current_financial_year_id
  end

  validate_on_create :check_store
  validate_on_update :check_store

  named_scope :paid, {:conditions=> {:is_paid => true}}

  def gross_amount
    sold_items.to_a.sum(&:total_amount)
  end

  def total_discounts
    discounts.to_a.sum(&:amount).to_f
  end

  def total_additional_charges
    additional_charges.to_a.sum(&:amount).to_f
  end

  def net_amount
    gross_amount  - total_discounts + total_additional_charges
  end

  def tax_amount
    #(net_amount * tax.to_f) / 100
    return net_amount * ( tax * 0.01) if saved_in_new_tax_mode?
    return gross_amount * (tax * 0.01) if saved_in_old_tax_mode?

  end

  def payable_amount
    net_amount + tax_amount
  end
  def tax_mode_sym
    (tax_mode == 1) ? :new : :old
  end

  def saved_in_old_tax_mode?
    tax_mode_sym == :old
  end

  def saved_in_new_tax_mode?
    tax_mode_sym == :new
  end

  def tax
    read_attribute(:tax) || 0
  end

  def set_tax_mode
    self.tax_mode = FedenaInventory.tax_mode_key
  end

  def update_item_quantity_on_create
    self.sold_items.each do |item|
      new_qty = item.store_item.quantity - item.quantity
      if new_qty >= 0
        item.store_item.update_attribute(:quantity,new_qty)
      else
        item.store_item.update_attribute(:quantity,0)
      end
    end
  end

  def update_item_quantity_on_update
    self.sold_items.each do |item|
      unless item.changes.empty?
        unless item.changes["quantity"].nil?
          qty = item.store_item.quantity.to_i + item.changes["quantity"].first.to_i
          item.store_item.update_attribute(:quantity,qty)

          new_qty = item.store_item.quantity.to_i - item.quantity.to_i
          if new_qty >= 0
            item.store_item.update_attribute(:quantity,new_qty)
          else
            item.store_item.update_attribute(:quantity,0)
          end
        end
      end
    end
  end

  def is_paid?
    return false if self.is_paid == true
    return true
  end

  def restore_quantities
    store_items = self.sold_items
    store_items.each do |item|
      item.store_item.update_attribute(:quantity, item.store_item.quantity + item.quantity)
    end
  end

  def validate
    self.sold_items.group_by(&:store_item_id).each do |k,v|
      errors.add("sold_items","added multiple times") if v.count > 1
      return
    end

  end

  def check_store
    store_id = self.store_id
    self.sold_items.each do |item|
      unless item.store_item.nil?
        if item.store_item.store_id != store_id
          errors.add("item","does not belong to store")
          return
        end
      end
    end
  end

end
