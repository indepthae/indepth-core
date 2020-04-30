class PaytmPaymentRecord < ActiveRecord::Base
  
  belongs_to :transaction_ledger, :class_name => "FinanceTransactionLedger"
  
  validates_presence_of :transaction_ledger_id ,:order_id, :amount
end
