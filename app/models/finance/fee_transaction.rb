class FeeTransaction < ActiveRecord::Base
  belongs_to :finance_transaction
  belongs_to :finance_fee

  validates_uniqueness_of :finance_fee_id,:scope=>:finance_transaction_id
end
