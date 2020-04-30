class HostelFeeCollection < ActiveRecord::Base
  belongs_to :batch
  belongs_to :master_fee_particular
  has_many :finance_transaction,:through=>:hostel_fees
  has_many :hostel_fees, :dependent => :destroy
  has_one :event, :as=>:origin,:dependent=>:destroy
#  has_many :taxable_slabs, :as => :taxable
#  has_many :tax_slabs, :through => :taxable_slabs
  
  #tax associations  
  has_many :collectible_tax_slabs, :as => :collection, :dependent => :destroy
  has_many :collection_tax_slabs, :through => :collectible_tax_slabs, :class_name => "TaxSlab"
  
  has_many :tax_collections, :as => :taxable_entity, :dependent => :destroy
  has_many :tax_fees, :through => :tax_collections, :source => :taxable_fee, :source_type => "HostelFee"  

  belongs_to :financial_year

  cattr_accessor :tax_slab_id
  #validates_uniqueness_of :name, :scope=>:batch_id
  validates_presence_of :name, :start_date, :due_date
  #  before_save :validate_dates
  named_scope :deleted, :conditions => { :is_deleted => true }
  named_scope :active, :conditions => { :is_deleted => false }
  named_scope :current_active_financial_year, lambda { |x|
                {:conditions => ["hostel_fee_collections.financial_year_id #{FinancialYear.current_financial_year_id.present? ? '=' : 'IS'} ?",
                                  FinancialYear.current_financial_year_id]} }
  named_scope :for_financial_year, lambda { |x| {:conditions => ["hostel_fee_collections.financial_year_id #{x.present? ? '=' : 'IS'} ?", x] }}
  accepts_nested_attributes_for :collectible_tax_slabs, :allow_destroy => true
  accepts_nested_attributes_for :hostel_fees

  def validate
    if self.start_date.present? && self.due_date.present?
      errors.add_to_base :start_date_cant_be_after_due_date if self.start_date > self.due_date
      #      errors.add_to_base :start_date_cant_be_after_due_date if self.start_date > self.due_date
      #      errors.add_to_base :end_date_cant_be_after_due_date if self.end_date > self.due_date
      if self.financial_year_id.to_i.zero?
        if (FinancialYear.last(:conditions => ["start_date BETWEEN ? AND ? OR end_date BETWEEN ? AND ?",
                                               self.start_date, self.due_date, self.start_date, self.due_date])).present?

        end
        self.financial_year_id = nil
      elsif self.financial_year_id.present?
        fy = FinancialYear.find_by_id(self.financial_year_id)
        errors.add_to_base :financial_year_must_be_set unless fy.present?
        errors.add_to_base :date_range_must_be_within_financial_year if fy.present? and !(self.start_date >= fy.try(:start_date) && self.due_date <= fy.try(:end_date))
      else
        errors.add_to_base :financial_year_must_be_set
      end
    else

    end
  end
  # def check_fee_category
  #   finance_fees = HostelFee.find_all_by_hostel_fee_collection_id(self.id)
  #   flag = 1
  #   finance_fees.each do |f|
  #     flag = 0 unless f.finance_transaction_id.nil?
  #   end
  #   flag == 1 ? true : false
  # end
  def check_fee_category
    self.has_paid_fees?
  end

  def soft_delete
    update_attributes(:is_deleted=>true)
  end

  def has_paid_fees?
    self.hostel_fees.all(:conditions => 'finance_transaction_id IS NOT NULL' ).present?
  end
  
  def has_paid_fees_in_this_batch?(batch_id)
    self.hostel_fees.all(:conditions => "finance_transaction_id IS NOT NULL and batch_id=#{batch_id}" ).present?
  end
  
  def transaction_amount(start_date,end_date)
    trans =[]
    self.finance_transaction.each{|f| trans<<f if (f.transaction_date.to_s >= start_date and f.transaction_date.to_s <= end_date)}
    trans.map{|t|t.amount}.sum
  end

  def fee_table
    self.hostel_fees.all(:conditions=>"finance_transaction_id IS NULL")
  end

  class << self
    def has_unlinked_collections?
      HostelFeeCollection.count(:conditions => "master_fee_particular_id IS NULL") > 0
    end
  end
  
end
