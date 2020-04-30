
class Grn < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :financial_year
  has_one :finance_transaction, :as => :finance
  has_many :grn_items, :dependent => :destroy
  
  validates_presence_of :grn_no,:invoice_no,:purchase_order_id,  :in=>1..6
  validates_format_of :invoice_no, :with => /^[A-Z0-9_-]*$/i
  validates_numericality_of :other_charges, :unless => "other_charges.nil?"

  after_create :update_store

  named_scope :active,{ :conditions => { :is_deleted => false }}
  named_scope :paid , {:conditions => "finance_transaction_id IS NOT NULL"}

  accepts_nested_attributes_for :grn_items, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true
  before_save :verify_precision
  before_create :set_tax_mode 
  before_create :set_financial_year

  def set_financial_year
    self.financial_year_id = FinancialYear.current_financial_year_id
  end

  def verify_precision
    self.other_charges = FedenaPrecision.set_and_modify_precision self.other_charges
  end

  def set_tax_mode
    self.tax_mode = FedenaInventory.tax_mode_key
  end

#  def can_be_deleted?
#    finance_transaction.present? ? false : true
#  end
  def total_amount
    grn_items.collect(&:total_amount).inject(:+) + other_charges.to_f
  end

  def paid_amount
    finance_transaction.amount.to_f
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
    
  def validate
    if purchase_order.present?
      if grn_date.to_date < purchase_order.po_date.to_date
        errors.add("grn_date","cannot be less than purchase order date")
      end

      if invoice_date.to_date < purchase_order.po_date.to_date
        errors.add("invoice_date","cannot be less than purchase order date")
      end
    end
    
    if Grn.active.reject{|g| g.id == id}.find_by_grn_no(grn_no).present? and is_deleted == false
      errors.add("grn_no","is already taken")
    end
    
    if Grn.active.reject{|g| g.id == id}.find_by_invoice_no(invoice_no).present? and is_deleted == false
      errors.add("invoice_no","is already taken")
    end
    
    to_check = grn_items.reject{|ii| ii._destroy == true}
    unless to_check.present?
      errors.add('grn_items',"can't be blank")
    end
  end

  def update_store
    inventory = FinanceTransactionCategory.find_by_name('Inventory')
    amount= 0
    grn_items.each do |i|
      i.store_item.update_attributes!(:quantity => (i.store_item.quantity + i.quantity), :unit_price =>i.unit_price)
      #amount += ( i.quantity *  i.unit_price ) + ( i.quantity *  i.unit_price )* ( i.tax * 0.01) - ( i.quantity *  i.unit_price )* ( i.discount * 0.01)
    end
    #amount += other_charges unless self.other_charges.nil?
    finance = create_finance_transaction(:title =>"#{purchase_order.store.name}",:description => "#{inventory.description}", :amount=> total_amount, :transaction_date=> Date.today,:category => inventory)
    self.update_attributes(:finance_transaction_id=> finance.id )
    serve_indent
  end

  def serve_indent
    if purchase_order.indent.present? and purchase_order.indent.try(:status) == "Pending"
      grn_items.each do |grn_item|
        indent_items = purchase_order.indent.indent_items.select{|indent_item| grn_item.store_item == indent_item.store_item}
        indent_items.each do |indent_item|
          if indent_item.pending > 0
            indent_item.issue_indent_item
          end
        end
      end
      purchase_order.indent.accept
    end
  end

  def self.grn_details(parameters)
    sort_order=parameters[:sort_order]
    status=parameters[:status]
    if sort_order.nil?
      grn=Grn.all(:select=>"grns.*,po_no,suppliers.name as supplier,stores.name as store",:joins=>"INNER JOIN `purchase_orders` ON `purchase_orders`.id = `grns`.purchase_order_id LEFT OUTER JOIN `suppliers` ON `suppliers`.id = `purchase_orders`.supplier_id INNER JOIN `stores` ON `stores`.id = `purchase_orders`.store_id",:conditions=>["grns.created_at >= ? and grns.created_at <= ? and grns.is_deleted='0'" ,status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>'grn_no ASC')
    else
      grn=Grn.all(:select=>"grns.*,po_no,suppliers.name as supplier,stores.name as store",:joins=>"INNER JOIN `purchase_orders` ON `purchase_orders`.id = `grns`.purchase_order_id LEFT OUTER JOIN `suppliers` ON `suppliers`.id = `purchase_orders`.supplier_id INNER JOIN `stores` ON `stores`.id = `purchase_orders`.store_id",:conditions=>["grns.created_at >= ? and grns.created_at <= ? and grns.is_deleted='0'" ,status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>sort_order)
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('grns.grn_no')}","#{t('supplier') }","#{t('purchase_order_no') }","#{t('store')}","#{t('grns.invoice_no')}","#{t('grns.grn_date')}","#{t('grns.invoice_date')}","#{t('grns.other_charges')}"]
    data << col_heads
    grn.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.grn_no}"
      col<< "#{s.supplier}"
      col<< "#{s.po_no}"
      col<< "#{s.store}"
      col<< "#{s.invoice_no}"
      col<< "#{s.grn_date.to_date}"
      col<< "#{s.invoice_date.to_date}"
      col<< "#{s.other_charges}"
      col=col.flatten
      data<< col
    end
    return data
  end

end
