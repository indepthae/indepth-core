module FoldersHelper
  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", {:class=>"delete_button_img"})
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :s => builder)
    end
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"})
  end

  def build_documents(folder)
    existing = folder.documents
    new = (1 - existing.size).times.map{ folder.documents.new(:user_id => @current_user.id) }
    new + existing
  end

end
