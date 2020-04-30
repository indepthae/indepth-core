module PinGroupsHelper
  def course_names(course_ids)
    RegistrationCourse.find(:all,:conditions => {:id => course_ids}).compact.map{|rc| rc.course.full_name}.join(', ')
  end

  def course_pin_system_registered_for_course(course_id)
    course_pin = CoursePin.find_by_course_id(course_id)
    if course_pin.nil?
      return true
    else
      return false if course_pin.is_pin_enabled?
    end
    return true
  end
end
