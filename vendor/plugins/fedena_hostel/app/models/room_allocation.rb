class RoomAllocation < ActiveRecord::Base
  belongs_to :student
  belongs_to :room_detail
  validates_uniqueness_of :student_id, :scope => [:is_vacated],:if=> 'is_vacated == false'
  before_save :check_gender


  def check_gender
    if self.student.gender.downcase=="f" and self.room_detail.hostel.hostel_type=="Gents"
      self.errors.add_to_base :cant_alloacte
      return false
    end
    if self.room_detail.hostel.hostel_type=="Ladies" and self.student.gender.downcase=="m"
      self.errors.add_to_base :cant_alloacte
      return false
    end
  end


  def check student
    no = RoomAllocation.find_all_by_student_id(student, :conditions=>["is_vacated is false"])
    return false if no.empty?
    return true
  end


end