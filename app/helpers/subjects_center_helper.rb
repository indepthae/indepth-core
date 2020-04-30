module SubjectsCenterHelper
  def component_edit_link(link_text, type, course_id, id)
    link_to_remote link_text, {:url => { :action => 'edit_component', :id => id, :type => type, :course_id => course_id }, :method => :get}, :class => ""
  end
  
  def component_add_link(link_text, type, course_id, parent_type, parent_id)
    link_to_remote "+ #{link_text}", {:url => { :action => 'new_component', :parent_id => parent_id, :parent_type => parent_type , :type => type, :course_id => course_id }, :method => :get}, :class => ""
  end
  
  def component_delete_link(link_text, type, course_id, object)
    if object.dependency_present?
      "<strike>#{t('delete_text')}</strike>"
    else
      link_to link_text, '#', :class => "",
        :onclick => "make_popup_box(this, 'confirm', '#{t('delete_confirmation_'+type, {:name => object.name})}',{'ok' : '#{t('delete')}', 'cancel' : '#{t('cancel')}', 'title' : '#{t('delete_text_'+type)}', 'popup_class' : 'remove_component'}); return load_component_delete_method('#{type}',#{course_id},#{object.id});"
    end
  end
end