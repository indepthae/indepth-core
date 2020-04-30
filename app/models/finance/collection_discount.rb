class CollectionDiscount < ActiveRecord::Base
  # associates fee discounts created under the finance fee category before creating a collection
  belongs_to :fee_discount
  belongs_to :finance_fee_collection

  validates_uniqueness_of :finance_fee_collection_id,:scope=>:fee_discount_id
end
