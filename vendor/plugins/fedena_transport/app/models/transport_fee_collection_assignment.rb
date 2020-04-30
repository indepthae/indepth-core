class TransportFeeCollectionAssignment < ActiveRecord::Base
  belongs_to :transport_fee_collection
  belongs_to :assignee, :polymorphic => true
end
