class GradebookRecord < ActiveRecord::Base
  attr_accessor :item_name
  belongs_to :gradebook_record_group
  belongs_to :record_group
  belongs_to :linkable, :polymorphic => true
end
