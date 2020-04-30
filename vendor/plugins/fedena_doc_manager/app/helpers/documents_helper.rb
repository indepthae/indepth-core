module DocumentsHelper

  def link_to_remove(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", {:class=>"delete_button_img"})
  end

  def link_to_remove_additional_fields(name,id)
    link_to_function(name, "remove_additional_fields(this)", {:class=>"delete_button_img"})
  end

  def build_documents(documents)
    existing = documents
    new = (1 - existing.size).times.map{ current_user.documents.build }
    new + existing
  end

end
