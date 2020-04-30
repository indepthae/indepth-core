class FineCancelTracker < ActiveRecord::Base
  belongs_to :fine_tracker, :polymorphic => true
end
