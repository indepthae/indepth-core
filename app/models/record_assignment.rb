class RecordAssignment < ActiveRecord::Base
  belongs_to :course
  belongs_to :record_group
  has_many :record_batch_assignments,:dependent=>:destroy
  validates_presence_of :record_group_id
  accepts_nested_attributes_for :record_batch_assignments, :allow_destroy => true

  def validate
    if self.add_for_future==false and !self.record_batch_assignments.reject{|p| (p._destroy == true if p._destroy)}.present?
      errors.add_to_base(:nor_batches_nor_add_for_future)
    end
  end
end
