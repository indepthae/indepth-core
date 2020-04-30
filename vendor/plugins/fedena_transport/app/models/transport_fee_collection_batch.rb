class TransportFeeCollectionBatch < ActiveRecord::Base
  belongs_to  :batches
  belongs_to  :transport_fee_collection
end
