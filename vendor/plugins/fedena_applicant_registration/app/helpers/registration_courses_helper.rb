module RegistrationCoursesHelper
  def course_pin_system_registered_for_course(course_id)
    course_pin = CoursePin.find_by_course_id(course_id)
    if course_pin.nil?
      return true
    else
      return false if course_pin.is_pin_enabled?
    end
    return true
  end

  def selected_additional_field_ids
    #registration_course = RegistrationCourse.find_by_id(params[:registration_course_id])
    @registration_course.nil? ? Array.new : @registration_course.additional_field_ids.nil? ? Array.new : @registration_course.additional_field_ids
  end
  
  def link_to_remove_options(name, c)
    c.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", {:class=>"delete_button_img"})
  end

  def link_to_add_options(name, c, association)
    new_object = c.object.class.reflect_on_association(association).klass.new
    fields = c.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :c => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"})
  end
end
