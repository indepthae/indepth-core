class MultiTransactionFine < ActiveRecord::Base
  has_many :finance_transaction_fines
  has_many :finance_transactions, :through => :finance_transaction_fines
  belongs_to :receiver, :polymorphic => true
  attr_accessor :fee_id, :fee_type
  validates_presence_of :amount
  validates_presence_of :fee_id
  validates_numericality_of :amount, :greater_than => 0
end
