class Classroom < ActiveRecord::Base
  belongs_to :building
  validates_presence_of :name, :capacity
  validates_numericality_of :capacity, :only_integer => true, :greater_than => 0
  validates_uniqueness_of :name, :scope=> :building_id
  has_many :allocated_classrooms
end
