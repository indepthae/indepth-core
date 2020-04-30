class TransportFee < ActiveRecord::Base
  belongs_to :transport_fee_collection
  belongs_to :groupable, :polymorphic => true
  delegate :name, :to=> :transport_fee_collection, :allow_nil => true
  belongs_to :receiver, :polymorphic => true
  has_one :finance_transaction, :as => :finance
  has_many :transport_fee_finance_transactions
  has_many :finance_transactions ,:through=>:transport_fee_finance_transactions, :dependent => :destroy, :order => "finance_transactions.id DESC"
  has_many :finance_transactions_with_fine,:through=>:transport_fee_finance_transactions,:source=>:finance_transaction,:conditions=>"finance_transactions.fine_included =1"
  #tax associations
  has_many :tax_collections, :as => :taxable_fee, :dependent => :destroy
  has_many :tax_particulars, :through => :tax_collections, :source => :taxable_entity, :source_type => "TransportFeeCollection"

  has_many :tax_payments, :as => :taxed_fee
  has_many :taxed_particulars, :through => :tax_payments, :source => :taxed_entity, :source_type => "TransportFee"
  #invoice associations
  has_many :fee_invoices, :as => :fee
  has_many :transport_fee_discounts
  has_one :fine_cancel_tracker, :as => :fine_tracker
  attr_accessor :invoice_number_enabled
  after_create :add_invoice_number, :if => Proc.new { |fee| fee.invoice_number_enabled.present? }
  before_destroy :mark_invoice_number_deleted
  validates_numericality_of :balance,:greater_than_or_equal_to=>0
  validates_uniqueness_of :receiver_id,:scope=>[:transport_fee_collection_id,:receiver_type]

  accepts_nested_attributes_for :tax_collections, :allow_destroy => true

  before_save :verify_precision
  validates_uniqueness_of :receiver_id,:scope=>[:transport_fee_collection_id,:receiver_type]

  before_validation :set_balance,:if=> Proc.new{|hf| hf.balance.nil?}
  after_create :trigger_update_collection_master_particular_reports
  after_destroy :trigger_update_collection_master_particular_reports


  named_scope :active , :joins=>[:transport_fee_collection], :conditions=>"transport_fee_collections.is_deleted=false and transport_fees.is_active=true",
  :readonly => false
  named_scope :inactive , :joins=>[:transport_fee_collection], :conditions => "transport_fee_collections.is_deleted=false and transport_fees.is_active=false",
  :readonly => false
  named_scope :unpaid ,:conditions=>" balance > 0.0"
  named_scope :for_financial_year, lambda { |x| {:joins => :transport_fee_collection,
                                 :conditions => ["transport_fee_collections.financial_year_id #{x.present? ? '=' : 'IS'} ?", x] }}

  def trigger_update_collection_master_particular_reports
    if self.destroyed? or !self.is_active
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('remove', self, {:collection => self.transport_fee_collection}))
    else
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('insert', self))
    end
  end

  def invoice_no
    fee_invoices.present? ? fee_invoices.try(:first).try(:invoice_number) : ""
  end

  def add_invoice_number
    FeeInvoice.create_with_failsafe(self)
  end

  def mark_invoice_number_deleted
    fee_invoice = fee_invoices.try(:last)
    fee_invoice.mark_deleted if fee_invoice.present?
  end

  def verify_precision
    self.bus_fare = FedenaPrecision.set_and_modify_precision self.bus_fare
  end

  def next_user
    next_st =  self.transport_fee_collection.transport_fees.first(:conditions => "id > #{self.id}", :order => "id ASC")
    next_st ||= self.transport_fee_collection.transport_fees.first(:order => "id ASC")
  end

  def previous_user
    prev_st = self.transport_fee_collection.transport_fees.first(:conditions => "id < #{self.id}", :order => "id DESC")
    prev_st ||= self.transport_fee_collection.transport_fees.first(:order => "id DESC")
    prev_st ||= self.first(:order => "id DESC")
  end
  def next_default_user
    next_st =  self.transport_fee_collection.transport_fees.first(:conditions => "id > #{self.id} and transaction_id is null", :order => "id ASC")
    next_st ||= self.transport_fee_collection.transport_fees.first( :conditions=>["transaction_id is null"] , :order => "id ASC")
  end

  def previous_default_user
    prev_st = self.transport_fee_collection.transport_fees.first(:conditions => "id < #{self.id} and transaction_id is null", :order => "id DESC")
    prev_st ||= self.transport_fee_collection.transport_fees.first( :conditions=>["transaction_id is null"],:order => "id DESC")
    prev_st ||= self.transport_fee_collection.transport_fees.first( :conditions=>["transaction_id is null"], :order => "id DESC")
  end

  def get_transport_fee_collection(start_date, end_date ,trans_id)
    transport_id = FinanceTransactionCategory.find_by_name('Transport').id
    FinanceTransaction.find(:all,:conditions=>"FIND_IN_SET(id,\"#{trans_id}\") and transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}' and category_id ='#{transport_id}' ")
  end

  def finance_transaction_id
    return self.transaction_id
  end

  def former_student
    return ArchivedStudent.find_by_former_id(self.receiver_id)
  end

  def former_employee
    return ArchivedEmployee.find_by_former_id(self.receiver_id)
  end

  def student_id
    return self.receiver_id if self.receiver_type == 'Student'
  end
  def payee_name
    if receiver.nil?
      if receiver_type=="Student"
        if former_student
          "#{former_student.full_name}(#{former_student.admission_no})"
        else
          "#{t('user_deleted')}"
        end
      else
        if former_employee
          "#{former_employee.full_name}(#{former_employee.employee_number})"
        else
          "#{t('user_deleted')}"
        end
      end
    else
      receiver.full_name
    end
  end

  def  is_paid?
    balance==0
  end

  def fine_amount
    finance_transactions_with_fine.sum(:fine_amount)
  end

  def has_fine
    fine_amount > 0
  end

  def tax_enabled_on_creation(tfc)
    self.tax_enabled = tfc.tax_enabled
    if tfc.tax_enabled
      tax_slab = tfc.collection_tax_slabs.try(:last)
      if tax_slab.present?
        taxable_amount = self.bus_fare.to_f
        tax_amount = taxable_amount > 0 ? (taxable_amount *  tax_slab.rate).to_f / 100.0  : 0.0
        tax_amount = get_precision_count(tax_amount).to_f
        tax_collection = self.tax_collections.build({:tax_amount => tax_amount,
            :slab_id => tax_slab.id })
        tax_collection.taxable_entity = tfc
        self.tax_amount = tax_amount
      end
    end
  end

  def total_discount_amount
    total_fees = self.bus_fare
    total = 0.0
    transport_fee_discounts = self.transport_fee_discounts
    transport_fee_discounts.each{ |tfd| total = total + (tfd.is_amount ? tfd.discount : (total_fees*(tfd.discount/100)))} if transport_fee_discounts.present?
    total.to_f
  end

  def update_tax_on_discount(tfc=nil)
    tfc ||= self.transport_fee_collection
    if self.tax_enabled
      tax_slab = tfc.collection_tax_slabs.try(:last)
      if tax_slab.present?
        self.balance -= self.tax_amount if self.tax_amount.present?
        taxable_amount = self.bus_fare.to_f - self.total_discount_amount
        tax_amount = taxable_amount > 0 ? (taxable_amount *  tax_slab.rate).to_f / 100.0  : 0.0
        tax_collection = self.tax_collections.present? ? self.tax_collections.last :
          self.tax_collections.build({:slab_id => tax_slab.id })
        tax_collection.tax_amount = tax_amount
        if tax_collection.new_record?
          tax_collection.taxable_entity = tfc
        else
          tax_collection.save
        end
        tax_amount = get_precision_count(tax_amount).to_f
        self.tax_amount = tax_amount
        self.balance += tax_amount
        self.save
      end
    end
  end

  def update_balance_fine_amount(tfc=nil)
    tfc ||= self.transport_fee_collection
    tft = self.finance_transactions
    if tft.count == 1 && tft.first.transaction_ledger.is_waiver
      self.balance_fine = nil
      self.save
    end
  end

  def auto_fine_amount(date,discount, transport_fee)
    days=(Date.today_with_timezone-date.due_date.to_date).to_i
    auto_fine=date.fine
    fine_amount=0
    #    paid_fine=0
    bal= (self.bus_fare-discount).to_f
    if days > 0 and auto_fine and !transport_fee.is_fine_waiver
      fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"], :order => 'fine_days ASC')
      if Configuration.is_fine_settings_enabled? && transport_fee.balance_fine.present? && transport_fee.balance <= 0
        fine_amount = get_precision_count(transport_fee.balance_fine).to_f
      else
        fine_amount=fine_rule.is_amount ? fine_rule.fine_amount : (bal*fine_rule.fine_amount)/100 if fine_rule
        #      paid_fine=fine_amount
        if fine_rule.present? and self.balance==0
          fine_amount=get_precision_count(fine_amount).to_f-get_precision_count(self.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)).to_f
        end
      end
      
    end
    fine_amount
  end

  def _paid_amount
    finance_transactions.sum(:amount).to_f
  end
  
  def track_fine_calculation(finance_type, amount, finance_id, transaction_id = nil)
    user_id = Fedena.present_user.id
    date = format_date(Date.today_with_timezone.to_date, :format => :long)
    FineCancelTracker.create(:user_id=> user_id, :amount => amount, :date=>date, :finance_id => finance_id, :finance_type => finance_type, :transaction_id=> transaction_id)
  end

  private

    def set_balance
      self.balance=self.bus_fare.to_f
      self.balance +=self.tax_amount.to_f if self.tax_enabled?
    end

    def get_precision_count(val)
        precision_count ||= FedenaPrecision.get_precision_count
        return sprintf("%0.#{precision_count}f",val)
    end
  class << self
    def update_collection_report data
      TransportFee.find(data[:fees_to_insert] + data[:fees_to_remove]).each do |tf|
        tf.trigger_update_collection_master_particular_reports
      end
    end
  end
end
