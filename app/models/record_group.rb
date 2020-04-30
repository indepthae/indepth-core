class RecordGroup < ActiveRecord::Base
  has_many :records, :dependent=>:destroy
  has_many :student_records,:through=>:records, :dependent=>:destroy
  has_many :record_assignments, :dependent=>:destroy
  has_many :courses ,:through=>:record_assignments
  has_many :record_batch_assignments, :dependent=>:destroy
  has_many :batches ,:through=>:record_batch_assignments
  has_many :gradebook_records
  accepts_nested_attributes_for :records
  before_validation :strip_whitespace
  validates_presence_of :name,:message=>:is_required
  validates_uniqueness_of :name
  named_scope :active,:conditions => {:is_active => true}
  named_scope :inactive,:conditions => {:is_active => false}

  def strip_whitespace
    self.name = self.name.strip
  end
  
end
