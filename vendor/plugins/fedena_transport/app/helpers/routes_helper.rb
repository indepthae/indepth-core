module RoutesHelper
  def link_to_add_stops(name, c, association, index, stops)
    new_object = c.object.class.reflect_on_association(association).klass.new
    fields = c.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :c => builder, :index => index, :stops => stops)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"})
  end
end
