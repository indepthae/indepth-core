class DisciplineStudentAction < ActiveRecord::Base
  belongs_to :discipline_action
  belongs_to :discipline_participation
end
