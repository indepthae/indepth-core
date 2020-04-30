class CancelledAdvanceFeeTransaction < ActiveRecord::Base
  belongs_to :student ,:primary_key => 'payee_id'
  belongs_to :user
  belongs_to :transaction_receipt
  belongs_to :advance_fee_collection
end
