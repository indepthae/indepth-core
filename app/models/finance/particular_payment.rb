class ParticularPayment < ActiveRecord::Base
  belongs_to :finance_fee
  belongs_to :finance_fee_particular
  belongs_to :finance_transaction
  has_many :particular_discounts, :dependent=>:destroy
  after_create :update_transaction_date


  accepts_nested_attributes_for :particular_discounts, :allow_destroy=>true
  #  validates_uniqueness_of :finance_fee_particular_id,:scope=>:finance_transaction_id
  validate :payment_uniqueness
  
  def payment_uniqueness 
    conditions = [] 
    conditions << "finance_fee_particular_id = #{self.finance_fee_particular_id}"
    conditions << "finance_transaction_id = #{self.finance_transaction_id}"
    conditions << "id <> #{self.id}" unless new_record?
    payment = ParticularPayment.last(:conditions => conditions.compact.join(" AND "), 
      :from => "particular_payments use index (particular_payment_uniqueness)")    
    errors.add(:finance_fee_particular_id, :taken) if payment.present?
  end
  
  private

  def update_transaction_date
    update_attribute(:transaction_date,finance_transaction.transaction_date)
  end
end
