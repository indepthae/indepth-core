class TransportFeeCollection < ActiveRecord::Base
#  belongs_to :batch
  belongs_to :master_fee_particular
  has_many :transport_fees, :dependent => :destroy
#  has_many :transport_fee_collection_batches
  has_many :transport_fee_collection_assignments
  has_many :employee_departments, :through => :transport_fee_collection_assignments, :source => :assignee, 
    :source_type => "EmployeeDepartment"
  has_many :batches, :through => :transport_fee_collection_assignments, :source => :assignee, 
    :source_type => "Batch"      
  has_many :transport_fee_collection_assignments
  has_many :employee_departments, :through => :transport_fee_collection_assignments, :source => :assignee, 
    :source_type => "EmployeeDepartment"
  has_many :batches, :through => :transport_fee_collection_assignments, :source => :assignee, 
    :source_type => "Batch"
  has_many :finance_transaction,:through=>:transport_fees
  belongs_to :financial_year
  validates_presence_of :name,:start_date,:due_date
  named_scope :employee, :select => "distinct transport_fee_collections.*",
              :joins => "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id = transport_fee_collection_id
                          LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id",
              :conditions => "transport_fee_collections.is_deleted=false and transport_fees.receiver_type='Employee' and
                              transport_fee_collections.due_date < '#{Date.today}' AND
                              (fa.id IS NULL OR fa.is_deleted = false)"
  named_scope :current_active_financial_year, lambda { |x| {:conditions => ["transport_fee_collections.financial_year_id
                                                    #{FinancialYear.current_financial_year_id.present? ? '=' : 'IS'} ?",
                                                               FinancialYear.current_financial_year_id]} }
  named_scope :for_financial_year, lambda { |x| {:conditions => ["transport_fee_collections.financial_year_id #{x.present? ? '=' : 'IS'} ?", x] }}    
  has_one :event, :as=>:origin,:dependent=>:destroy
#  has_many :taxable_slabs, :as => :taxable
#  has_many :tax_slabs, :through => :taxable_slabs
  
  #tax associations  
  has_many :collectible_tax_slabs, :as => :collection, :dependent => :destroy
  has_many :collection_tax_slabs, :through => :collectible_tax_slabs, :class_name => "TaxSlab"
  
  has_many :tax_collections, :as => :taxable_entity, :dependent => :destroy
  has_many :tax_fees, :through => :tax_collections, :source => :taxable_fee, :source_type => "TransportFee"
  belongs_to :fine, :conditions => "fines.is_deleted is false"  
  
  cattr_accessor :tax_slab_id
  accepts_nested_attributes_for :transport_fees, :allow_destroy => true

  def validate
    if self.start_date.present? && self.due_date.present?
      errors.add_to_base :start_date_cant_be_after_due_date if self.start_date > self.due_date
      #      errors.add_to_base :start_date_cant_be_after_due_date if self.start_date > self.due_date
      #      errors.add_to_base :end_date_cant_be_after_due_date if self.end_date > self.due_date
      if self.financial_year_id.nil? or self.financial_year_id.zero?
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

  def self.shorten_string(string, count)
    if string.length >= count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = splitted.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      string
    end
  end
  def check_status
    self.has_paid_fees?
  end
  
  def check_status_with_user_type(user_type,batch_id=nil)
    
    if user_type=='student'
      self.has_paid_fees_in_batch?(batch_id)
    else
      self.has_paid_fees_by_employee?
    end
    
  end
  
  def has_paid_fees_by_employee?
     self.transport_fees.all(:conditions => "transaction_id IS NOT NULL and groupable_type='EmployeeDepartment'").present?
  end
  
  def has_paid_fees?
    self.transport_fees.all(:conditions => 'transaction_id IS NOT NULL' ).present?
  end
  
  def has_paid_fees_in_batch?(batch_id)
     self.transport_fees.all(:conditions => "transaction_id IS NOT NULL and groupable_type='Batch' and groupable_id='#{batch_id}'").present?
  end
  
  def transaction_amount(start_date,end_date)
    trans =[]
      self.finance_transaction.each{|f| trans<<f if (f.transaction_date.to_s >= start_date and f.transaction_date.to_s <= end_date)}
    trans.map{|t|t.amount}.sum
  end

  def fee_table
    self.transport_fees.all(:conditions=>"transaction_id IS NULL")
  end
  
  def total_amount_and_discount(start_date=nil, end_date=nil)
    tf_hash = Hash.new
    total_discount = 0.to_f
    transport_fees = self.transport_fees.all(:conditions => "transaction_id is NOT NULL and is_active is true", 
                          :include => [:transport_fee_discounts, :finance_transactions])
    transport_fees.each do |tf|
      first_transaction = tf.finance_transactions.first
      next if (start_date.present? and first_transaction.present? and first_transaction.transaction_date < start_date.to_date)
      tf.transport_fee_discounts.each{ |tfd| total_discount += (tfd.is_amount ? tfd.discount : 
            (tf.bus_fare*tfd.discount/100))} if tf.transport_fee_discounts.present?
    end
    tf_hash["discount"] = total_discount
    tf_hash
  end

  class << self
    def has_unlinked_collections?
      TransportFeeCollection.count(:conditions => "master_fee_particular_id IS NULL") > 0
    end
  end
end
