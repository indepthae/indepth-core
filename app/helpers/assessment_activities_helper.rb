module AssessmentActivitiesHelper
  
  def fetch_activities_path(profile)
    profile.new_record? ? assessment_activities_path : assessment_activity_path
  end
  
  def link_to_add_activity_fields(name,form,association,partial)
    new_object = form.object.class.reflect_on_association(association).klass.new
    fields = form.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(partial, :f => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"})
  end
  
end
