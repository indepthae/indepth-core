
class HostelFee < ActiveRecord::Base

  attr_accessor_with_default :has_fine,false

  belongs_to :student
  #belongs_to :archived_student, :foreign_key => 'former_id', :primary_key => 'student_id'
  belongs_to :hostel_fee_collection
  belongs_to :batch
  has_one :finance_transaction, :as => :finance
  has_many :hostel_fee_finance_transactions
  has_many :finance_transactions ,:through=>:hostel_fee_finance_transactions, :dependent => :destroy, :order => "finance_transactions.id DESC"
  has_many :finance_transactions_with_fine,:through=>:hostel_fee_finance_transactions,:source=>:finance_transaction,:conditions=>"finance_transactions.fine_included =1"
  named_scope :unpaid ,:conditions=>"balance > 0.0"
  #tax associations
  has_many :tax_collections, :as => :taxable_fee, :dependent => :destroy
  has_many :tax_particulars, :through => :tax_collections, :source => :taxable_entity, :source_type => "HostelFeeCollection"
  has_many :tax_payments, :as => :taxed_fee
  has_many :taxed_particulars, :through => :tax_payments, :source => :taxed_entity, :source_type => "HostelFee"
  #invoice associations
  has_many :fee_invoices, :as => :fee
  attr_accessor :invoice_number_enabled  
  after_create :add_invoice_number, :if => Proc.new { |fee| fee.invoice_number_enabled.present? }
  before_destroy :mark_invoice_number_deleted
  accepts_nested_attributes_for :tax_collections, :allow_destroy => true
  
  validates_numericality_of :balance,:greater_than_or_equal_to=>0

  delegate :name,:to=>:hostel_fee_collection,:allow_nil=>true

  before_save :verify_precision
  before_validation :set_balance,:if=> Proc.new{|hf| hf.balance.nil?}
  after_create :trigger_update_collection_master_particular_reports
  after_save :checked_what_is_changed?
  after_save :trigger_update_collection_master_particular_reports, :if => Proc.new {|fee| fee.is_active_changed? }
  after_destroy :trigger_update_collection_master_particular_reports

  def checked_what_is_changed?
    puts changed.inspect
  end

  def trigger_update_collection_master_particular_reports
    if self.destroyed? or !self.is_active
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('remove', self, {:collection => self.hostel_fee_collection}))
    else
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('insert', self))
    end
  end


  def verify_precision
    self.rent = FedenaPrecision.set_and_modify_precision self.rent
  end

  named_scope :active , :joins=>[:hostel_fee_collection] ,:conditions=>{:hostel_fee_collections=>{:is_deleted=>false}}

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
  
  def  is_paid?
    balance==0
  end

  def fine_amount
    finance_transactions_with_fine.sum(:fine_amount)
  end

  def former_student
    return ArchivedStudent.find_by_former_id(self.student_id)
  end

  def payee_name
    if student.nil?
      archived_student= ArchivedStudent.find_by_former_id(student_id)
      if archived_student
        "#{archived_student.full_name}(#{archived_student.admission_no})"
      else
        "#{t('user_deleted')}"
      end
    else
      student.full_name
    end
  end

  def _paid_amount
    finance_transactions.sum(:amount).to_f
  end

  private

  def set_balance
    self.balance=self.rent
    self.balance+= self.tax_amount.to_f if self.tax_enabled?
  end
  class << self
    def update_collection_report data
      HostelFee.find_all_by_hostel_fee_collection_id_and_student_id(data[:fees_to_insert] + data[:fees_to_remove], data[:student_id]).each do |hf|
        hf.trigger_update_collection_master_particular_reports
      end
    end
  end
end


