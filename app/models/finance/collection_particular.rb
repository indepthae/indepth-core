class CollectionParticular < ActiveRecord::Base
  # associates finance fee particulars created under the finance fee category before creating a collection
  belongs_to :finance_fee_particular
  belongs_to :finance_fee_collection

  validates_uniqueness_of :finance_fee_collection_id,:scope=>:finance_fee_particular_id
end
