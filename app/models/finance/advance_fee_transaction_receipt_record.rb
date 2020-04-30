class AdvanceFeeTransactionReceiptRecord < ActiveRecord::Base
  belongs_to :advance_fee_collection
  belongs_to :transaction_receipt
  belongs_to :fee_account
  belongs_to :fee_receipt_template

end
