module MessagesHelper
  
  def link_to_remove_attachments(name, c)
    c.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", {:class=>"delete_button_img"})
  end

  def link_to_add_attachments(name, c, association,view)
    new_object = c.object.class.reflect_on_association(association).klass.new
    fields = c.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :c => builder)
    end  
    
    link_to_function(name, h("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\",\"#{view}\")"),{:class=>"add_button_img"})
  end
  
  def can_reply?(recipient_id,thread_id)
    if user_exists recipient_id
      MessageSetting.can_reply? recipient_id,thread_id,@current_user
    else
      return false
    end
  end
  
  def get_entry(recipient)
    return nil if recipient.nil?
    unless recipient.is_deleted
      entry = recipient.student_entry if recipient.student?
      entry = recipient.guardian_entry if recipient.parent?
      entry = recipient.employee_record if recipient.employee? or recipient.admin?
    else
      entry = recipient.archived_student_entry if recipient.student?
      entry = nil if recipient.parent?
      entry = recipient.archived_employee_entry if recipient.employee? or recipient.admin?
    end
    return entry
  end
  
  def user_exists(user_id)
    begin
      user = User.find user_id
      user.present? and !user.is_deleted
    rescue ActiveRecord::ActiveRecordError
      return nil
    end
  end
  
  def get_recipient(thread)
    if thread.is_group_message?
      return thread.creator
    else
      return thread.recipient
    end
  end
  
  def simple_format_without_p(text, html_options={})
    start_tag = tag('pre', html_options, true)
    text = text.to_s.dup
    plain_text=sanitize(text, :tags=>[:a])
    if plain_text == text
      text.gsub!(/\r\n?/, "\n")
      text.gsub!(/(\n)/, '<br/>')
      #  text.gsub!(" ","&nbsp;")
      text.insert 0, start_tag
      text << "</pre>"
      auto_link( text, :html => { :target => '_blank' })
    else
      text.insert 0, start_tag
      text << "</pre>"
    end
  end
  
  def conditional_div(options={}, &block)
    if options.delete(:show_div)
      concat content_tag(:div, capture(&block), options)
    else
      concat capture(&block)
    end
  end
end
