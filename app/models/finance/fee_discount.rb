#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class FeeDiscount < ActiveRecord::Base

  belongs_to :master_fee_discount, :conditions => {:discount_type => 'FinanceFee'}
  belongs_to :finance_fee_category
  validates_presence_of :name, :finance_fee_category_id, :discount
  validates_numericality_of :discount, :allow_blank => true
  validates_inclusion_of :discount, :in => 0..100, :unless => :is_amount, :message => :amount_in_percentage_cant_exceed_100, :allow_blank => true
  belongs_to :receiver, :polymorphic => true
  belongs_to :master_receiver, :polymorphic => true
  # Ensure this callback "fetch_and_set_collection" is first inline destroy callback chains,
  # in order to ensure collection information is captured, for reporting related job to function well.
  before_destroy :fetch_and_set_collection
  has_many :finance_fee_collections, :through => :collection_discounts
  has_many :collection_discounts, :dependent => :destroy
  has_many :finance_fee_discounts, :dependent => :destroy
  has_many :finance_fees, :finder_sql => 'SELECT `finance_fees`.* FROM `finance_fees`
                                                             INNER JOIN students ON students.id = #{self.receiver_id}                                                                                                  
                                                             INNER JOIN collection_discounts cd 
                                                                          ON cd.fee_discount_id=#{self.id}                                                             
                                                                   WHERE finance_fees.fee_collection_id = cd.finance_fee_collection_id AND 
                                                                               finance_fees.batch_id=#{self.batch_id} AND 
                                                                               finance_fees.student_id = students.id'
  #((fee_discounts.receiver_type="Batch" and fee_discounts.receiver_id=#{self.batch_id || 0}) or (fee_discounts.receiver_type="StudentCategory" and fee_discounts.receiver_id=#{self.student_category_id || 0}) or (fee_discounts.receiver_type="Student" and fee_discounts.receiver_id=#{self.student_id || 0}))"
  named_scope :for_category, lambda { |cat_id| {:conditions => {:finance_fee_category_id => cat_id}} }
  named_scope :without_masters, :conditions => {:master_fee_discount_id => nil}

  belongs_to :batch
  belongs_to :finance_fee_particular
  belongs_to :multi_fee_discount
  attr_accessor :collection_for_batch

  before_update :collection_exist

  before_validation :set_master_receiver
  attr_accessor :waiver_check
  #  after_destroy :delete_multi_fee_discount
  before_validation :set_discount_name, :if => Proc.new { |x| x.new_record? }
  before_update :set_discount_name, :if => Proc.new {|x| !x.new_record? and x.master_fee_discount_id_was.present? and x.master_fee_discount_id_changed? }
#  after_save :update_fee_balances
  
  after_create :trigger_update_collection_master_particular_reports, :if => Proc.new {|x| x.is_instant }
  after_destroy :trigger_update_collection_master_particular_reports, :if => Proc.new {|x| x.is_instant }

  def fetch_and_set_collection
    self.collection_for_batch = self.finance_fee_collections.all(:joins => :batches,
                                                                 :conditions => ["batches.id = ?", self.batch_id]).try(:last)
  end

  def trigger_update_collection_master_particular_reports
    if self.destroyed?
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('remove', self, {:collection => self.collection_for_batch}))
    else
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('insert', self))
    end
  end

  def set_discount_name
    master_fee_discount = MasterFeeDiscount.find_by_id(self.master_fee_discount_id)
    self.name = master_fee_discount.name if master_fee_discount.present?
  end

  def delete_multi_fee_discount
    multi_fee_discount.destroy # add additional checks latter
  end

  def validate
    if master_receiver_type=='FinanceFeeParticular'
      particular=master_receiver
      if is_amount and discount.to_f > particular.amount.to_f
        errors.add_to_base(t('discount_cannot_be_greater_than_total_amount'))
      end
      # ========== Issue Fix for 8844 ========
    elsif master_receiver_type=='Batch'
      feecategory=FinanceFeeCategory.all(:joins => {:fee_particulars => :batch}, :select => "finance_fee_categories.*, batches.name as batch_name, finance_fee_particulars.id as particular_id, finance_fee_particulars.amount as amount", :conditions => ["batches.id=? && finance_fee_categories.id=? && finance_fee_particulars.is_deleted=? && finance_fee_particulars.receiver_type=?", batch_id, finance_fee_category_id, false, "Batch"])
      sum_amount=feecategory.map { |i| i.amount.to_d }.sum.to_f if feecategory.present?
      if is_amount and discount.to_f > sum_amount.to_f
        errors.add_to_base(t('discount_cannot_be_greater_than_total_amount'))
      end
    elsif master_receiver_type=='StudentCategory'
      feecategory=FinanceFeeCategory.all(:joins => {:fee_particulars => :batch}, 
        :select => "distinct finance_fee_particulars.id as particular_id, finance_fee_categories.*, batches.id as batches_id, batches.name as batch_name, finance_fee_particulars.amount as amount", 
        :conditions => ["batches.id=? && finance_fee_categories.id=? && finance_fee_particulars.is_deleted=? && (finance_fee_particulars.receiver_type=? ||(finance_fee_particulars.receiver_type=? && finance_fee_particulars.receiver_id=?))", batch_id, finance_fee_category_id, false, "Batch", "StudentCategory", master_receiver.id])
      # feecategory=FinanceFeeCategory.all(:joins => {:fee_particulars => {:batch => {:students => :student_category}}}, :select => "distinct finance_fee_particulars.id as particular_id, finance_fee_categories.*,student_categories.name as stud_cat_name, batches.id as batches_id, batches.name as batch_name, finance_fee_particulars.amount as amount", :conditions => ["batches.id=? && finance_fee_categories.id=? && student_categories.id=? && finance_fee_particulars.is_deleted=? && (finance_fee_particulars.receiver_type=? ||(finance_fee_particulars.receiver_type=? && finance_fee_particulars.receiver_id=?))", batch_id, finance_fee_category_id, master_receiver.id, false, "Batch", "StudentCategory", master_receiver.id])
      sum_amount=feecategory.map { |i| i.amount.to_d }.sum.to_f if feecategory.present?
      if sum_amount.nil?
        errors.add_to_base(t('student_or_particular_not_found'))
      elsif is_amount and discount.to_f > sum_amount.to_f and !sum_amount.nil?
        errors.add_to_base(t('discount_cannot_be_greater_than_total_amount'))
      end
    elsif  master_receiver_type=='Student'
      if is_instant
        feecategory=FinanceFeeCategory.all(:joins=>:fee_particulars, :select=>"distinct finance_fee_particulars.id as particular_id, finance_fee_categories.*, finance_fee_particulars.batch_id as batches_id, finance_fee_particulars.amount as amount", :conditions=>["finance_fee_particulars.batch_id=? && finance_fee_categories.id=? && ((finance_fee_particulars.is_deleted=? && finance_fee_particulars.is_instant = ?) || (finance_fee_particulars.is_deleted=? && finance_fee_particulars.is_instant = ?)) && (finance_fee_particulars.receiver_type=? || finance_fee_particulars.receiver_type=? || (finance_fee_particulars.receiver_type=? && finance_fee_particulars.receiver_id=?))",batch_id,finance_fee_category_id,true,true,false,false,"StudentCategory","Batch","Student",master_receiver.id])
      else
        feecategory=FinanceFeeCategory.all(:joins=>{:fee_particulars=>{:batch=>:students}}, :select=>"distinct finance_fee_particulars.id as particular_id, finance_fee_categories.*, batches.id as batches_id, batches.name as batch_name, finance_fee_particulars.amount as amount", :conditions=>["batches.id=? && finance_fee_categories.id=? && students.id=? && finance_fee_particulars.is_deleted=? && (finance_fee_particulars.receiver_type=? || (finance_fee_particulars.receiver_type=? && finance_fee_particulars.receiver_id=?) )",batch_id,finance_fee_category_id,master_receiver.id,false,"Batch","Student",master_receiver.id])
      end
      sum_amount=feecategory.map{|i| i.amount.to_d}.sum.to_f if feecategory.present?
      if is_amount and discount.to_f > sum_amount.to_f
        errors.add_to_base(t('discount_cannot_be_greater_than_total_amount'))
        return false
      end
    end
    if batch_id.blank?
      if master_receiver_type=='FinanceFeeParticular'
        errors.add_to_base("#{t('particular')} #{t('cant_be_blank')}")
      else
        errors.add_to_base(t('batch_cant_be_blank'))
      end
    end
  end

  def total_payable
    payable = finance_fee_category.fee_particulars.active.map(&:amount).compact.flatten.sum
    payable
  end

  def set_master_receiver
    unless master_receiver_type=='FinanceFeeParticular'
      self.master_receiver=self.receiver
    end
  end


  def category_name
    c =StudentCategory.find(self.receiver_id)
    c.name unless c.nil?
  end

  def student_name
    s = Student.find_by_id(self.receiver_id)
    s ||= ArchivedStudent.find_by_former_id(self.receiver_id)
    s.present? ? "#{s.first_name} (#{s.admission_no})" : "N.A. (N.A.)"
  end

  def collection_exist
    unless is_deleted_changed?
      collection_ids=finance_fee_category.fee_collections.collect(&:id)
      if CollectionDiscount.find_by_fee_discount_id_and_finance_fee_collection_id(id, collection_ids)
        errors.add_to_base(t('collection_exists_for_this_category_cant_edit_this_discount'))
        return false
      else
        return true
      end
    end
  end

  
  def self.fetch_waiver_balance(collection)
    financefee=FinanceFee.find(collection.to_i)
    waiver_amount = ((financefee.balance.to_f) - (financefee.tax_amount.to_f)).to_f
  end
  
  def self.create_transaction_for_waiver_discount(fee_details,particular_payment)
    @particular_payment = particular_payment
    transaction = FinanceTransaction.new
    amount = 0
    transportfee = fee_details
    ActiveRecord::Base.transaction do 
      transaction.title = "Waiver Transaction"
      transaction.category = FinanceTransactionCategory.find_by_name("Fee")
      transaction.payee = transportfee.student
      transaction.finance = transportfee
      transaction.amount = amount.to_f
      transaction.transaction_type = 'SINGLE'
      transaction.trans_type = 'particular_wise' if @particular_payment == "true"
      transaction.transaction_date = Date.today_with_timezone.to_date
      transaction.payment_mode = "Cash"
      transaction.payment_note = "waiver discount"
      transaction.is_waiver = true
      transaction.safely_create
      
      
      if transaction.errors.present?
        transaction.errors.full_messages.each do |err_msg|
          @finance_fee.errors.add_to_base(err_msg)
        end
        raise ActiveRecord::Rollback 
      else
        transaction                 
      end
    end
  end
  
  def update_fee_balances
    fee = self.finance_fees.first
      if fee.present?
        FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(fee)
      end
  end

  class << self
    def has_unlinked_discounts? category_id = nil
      conditions = ["master_fee_discount_id IS NULL"]
      if category_id.present?
        conditions[0] += " AND finance_fee_category_id = ?"
        conditions << category_id
      end
      FeeDiscount.count(:conditions => conditions) > 0
    end
  end


end
