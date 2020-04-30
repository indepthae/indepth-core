module InvoicesHelper

  def link_to_add_fields(name, c, association)
    new_object = c.object.class.reflect_on_association(association).klass.new
    fields = c.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :c => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\") "),{:class=>"add_button_img"})
  end

  def link_to_remove_fields(name, c, association)
    c.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this,\"#{association}\")", {:class=>"delete_button_img"})
  end
end
