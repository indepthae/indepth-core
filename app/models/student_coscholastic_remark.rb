class StudentCoscholasticRemark < ActiveRecord::Base
  belongs_to  :student
  belongs_to  :batch
  named_scope :filled, :conditions => ["remark <> ''"]
end
