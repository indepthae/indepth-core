class DisciplineAction < ActiveRecord::Base
  belongs_to :discipline_complaint
  belongs_to :user
  has_many :discipline_student_actions,:dependent=>:destroy
  validates_presence_of :remarks, :body
end
