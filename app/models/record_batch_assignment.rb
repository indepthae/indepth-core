class RecordBatchAssignment < ActiveRecord::Base
  belongs_to :batch
  belongs_to :record_group
  belongs_to :record_assignment
  has_many :student_records,:primary_key=>'batch_id',:foreign_key=>"batch_id"
end
