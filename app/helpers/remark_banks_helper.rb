module RemarkBanksHelper
  
  def link_to_add_remark_template(name,form,association,partial)
    new_object = form.object.class.reflect_on_association(association).klass.new
    fields = form.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(partial, :c => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add-icon-link-width"})
  end
  
end
