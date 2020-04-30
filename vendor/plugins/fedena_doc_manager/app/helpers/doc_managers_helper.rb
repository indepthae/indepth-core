module DocManagersHelper

  def link_to_remove_additional_fields(name,id)
    link_to_function(name, "remove_additional_fields(this)", {:class=>"delete_button_img"})
  end

  def get_custom_stylesheets

    @direction = (rtl?) ? 'rtl/' : ''
    stylesheets = [] unless stylesheets
    stylesheets << "#{@direction}doc_managers/add_iframe_files"
    stylesheets << @direction+'application'
    
  end
end
