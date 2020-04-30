class InstantFee < ActiveRecord::Base
  belongs_to :instant_fee_category
  has_many :instant_fee_details #, :dependent => :destroy
  has_one :finance_transaction,:as => :finance
  belongs_to :payee, :polymorphic => true
 # belongs_to :archived_student ,:primary_key => 'payee_id' , :foreign_key=>'former_id'
  belongs_to :groupable, :polymorphic => true
  #tax associations
  has_many :collectible_tax_slabs, :as => :collection, :dependent => :destroy
  has_many :collection_tax_slabs, :through => :collectible_tax_slabs, :class_name => "TaxSlab"
  
  has_many :tax_collections, :as => :taxable_fee, :dependent => :destroy  
  has_many :tax_particulars, :through => :tax_collections, :source => :taxable_entity, :source_type => "InstantFeeParticular"
  
  has_many :tax_payments, :as => :taxed_fee, :dependent => :destroy  
  has_many :taxed_particulars, :through => :tax_payments, :source => :taxed_entity, :source_type => "InstantFee"

  belongs_to :financial_year
  validates_presence_of :amount,:pay_date
  #  validates_numericality_of :amount
  before_save :verify_precision
  after_destroy :delete_instant_fee_details, :if => Proc.new {|x| x.payee_type != 'Student'}
  #TODO move to student model?
  # def self.get_instant_fees_by_batch_and_student(student_id,batch_id)
  #   student=Student.find(student_id)
  #   batch=Batch.find(batch_id) if batch_id.present?
  #   if batch.present?
  #     list = student.instant_fees.find(:all,
  #                 :joins=>:finance_transaction,
  #                 :select=>"instant_fees.*,batch_id,transaction_date",
  #                 :conditions=>{:finance_transactions=>{:batch_id=>batch.id}})
  #   else
  #     list = student.instant_fees.find(:all,
  #       :joins=>:finance_transaction,
  #       :select=>"instant_fees.*,batch_id,transaction_date",
  #       :conditions=>{:finance_transactions=>{:batch_id=>nil}})
  #   end
  #   return list
  # end

  def delete_instant_fee_details
    InstantFeeDetail.delete_all({:instant_fee_id => self.id }) if self.destroyed?
  end

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end
  def name
    category_name
  end

  def category_name
    self.instant_fee_category.nil? ? self.custom_category : self.instant_fee_category.name
  end
  def category_description
    self.instant_fee_category.nil? ? self.custom_description : self.instant_fee_category.description
  end
  def payee_name
    payee = self.payee.nil? ? self.guest_payee : self.payee.full_name
    payee.nil? ? archived_payee_name : payee
  end

  def archived_payee_name
    if self.payee_type=="Student"
      payee = ArchivedStudent.find_by_former_id(self.payee_id)
    elsif self.payee_type=="Employee"
      payee=ArchivedEmployee.find_by_former_id(self.payee_id)
    end
    payee.present?? payee.full_name : "#{t('user_deleted')}"
  end

  def particular_total_amount
    total_amount = 0
    self.instant_fee_details.each do |detail|
      total_amount += detail.amount
    end
    total_amount
  end

  def particular_total_net_amount
    total_net_amount = 0
    self.instant_fee_details.each do |detail|
      total_net_amount += detail.net_amount
    end
    total_net_amount
  end

  def particular_total_discount
    total_amount = self.particular_total_amount
    total_net_amount = self.particular_total_net_amount
    total_discount = total_amount - total_net_amount
    total_discount
  end
  def validate
    if (self.guest_payee.blank? or self.guest_payee.blank?) and self.payee_id.nil?
      return false
    else
      return true
    end
  end
end
