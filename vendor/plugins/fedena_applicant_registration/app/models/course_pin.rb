class CoursePin < ActiveRecord::Base
  belongs_to :course
  validates_uniqueness_of :course_id
end
