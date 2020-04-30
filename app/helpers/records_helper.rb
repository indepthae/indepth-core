module RecordsHelper
  
  include RecordAdditionalFieldsHelper
  
  def link_to_add_addl_attachment(name, f, association,addl_options={})
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, h("add_addl_attachment(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"}.merge(addl_options))
  end
  
end
