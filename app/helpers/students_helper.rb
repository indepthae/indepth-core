# To change this template, choose Tools | Templates
# and open the template in the editor.

module StudentsHelper
  def link_to_remove_fields(name, c)
    c.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", {:class=>"delete_button_img"})
  end

  def link_to_add_fields(name, c, association)
    new_object = c.object.class.reflect_on_association(association).klass.new
    fields = c.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :c => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"})
  end

  def is_assigned(stud,elective)
    stud_assigned = StudentsSubject.new()
    assigned = stud_assigned.student_assigned(stud,elective)
  end

  def attr_pair(label,value)
    content_tag(:div,:class => :attr_pair) do
      content_tag(:div,label,:class => :attr_label) + content_tag(:div,value,:class => :attr_value)
    end
  end
  
end
