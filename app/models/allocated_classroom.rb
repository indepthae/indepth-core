class AllocatedClassroom < ActiveRecord::Base
  belongs_to :classroom_allocation
  belongs_to :timetable_entry
  belongs_to :classroom
  
  validates_uniqueness_of :classroom_id , :scope => [:classroom_allocation_id , :timetable_entry_id , :subject_id ], :message => "Already allocated same room just now"
  

end
