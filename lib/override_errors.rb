module OverrideErrors
 

  mattr_accessor :field_error_proc
  @@field_error_proc = Proc.new do |html_tag, instance|
    "<span class=\"fieldWithErrors\">#{html_tag} <div class=\"wrapper\"><div class=\"error-icon\"></div><div class=\"error-msg\"> #{Array[instance.error_message].join(",")}</div></div></span>".html_safe
  end

  def text_field(object_name, method, options = {})
    instance_tag = ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object))
    html = instance_tag.to_input_field_tag("text", options)
    if instance_tag.object.respond_to?(:errors) &&  instance_tag.object.errors[method].present?
      self.field_error_proc.call(html,instance_tag)
    else
      html
    end
  end

  def select(object_name, method, choices, options = {}, html_options = {})
    instance_tag = ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object))
    html = instance_tag.to_select_tag(choices, options, html_options)
    if instance_tag.object.respond_to?(:errors) && instance_tag.object.errors[method].present?
      self.field_error_proc.call(html,instance_tag)
    else
      html
    end
  end

  def calendar_date_select_tag(name, value, options = {})
    errors = options[:errors]
    image, options, javascript_options = calendar_date_select_process_options(options)
    value = CalendarDateSelect.format_time(value, javascript_options)
    formatted_date = value.present? ? format_date(value.length > 10 ? value.to_datetime : value.to_date,:format=>:long) : ''
    javascript_options.delete(:format)
    options[:id] ||= name
    options[:class] = (options[:class].present? ? options[:class] : '')+' calendar_field'
    tag = javascript_options[:hidden] || javascript_options[:embedded] ?
      hidden_field_tag(name, value, options) :
      text_field_tag(name, value, options)
    #      "<div class='calendar_field_tag'>"+text_field_tag(name, value, options)+"<div class='calendar_label'></div></div>"
    calendar_date_select_output(tag, image, options, javascript_options, formatted_date)
    unless errors.nil? 
      "<span class=\"fieldWithErrors\">#{tag} <div class=\"wrapper\"><div class=\"error-icon\"></div><div class=\"error-msg\"> #{errors}</div></div></span>".html_safe
    else
      tag
    end
  end
  
  def calendar_date_select(object_name,method, options = {})
    obj = options[:object]
    image, options, javascript_options = calendar_date_select_process_options(options)
    
    value ||=
    if(obj.respond_to?(method) && obj.send(method).respond_to?(:strftime))
      obj.send(method).strftime(CalendarDateSelect.date_format_string())
    elsif obj.respond_to?("#{method}_before_type_cast")
      obj.send("#{method}_before_type_cast")
    elsif obj.respond_to?(method)
      obj.send(method).to_s
    else
      begin
        obj.send(method).strftime(CalendarDateSelect.date_format_string())
      rescue
        nil
      end
    end
    object_name = object_name + "[#{method}]" #HotFix Todo: Fix it later
    instance_tag = ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object))
    value = CalendarDateSelect.format_time(value, javascript_options)
    formatted_date = value.present? ? format_date(value.length > 10 ? value.to_datetime : value.to_date,:format=>:long) : ''
    javascript_options.delete(:format)
    options[:id] ||= object_name
    options[:class] = (options[:class].present? ? options[:class] : '')+' calendar_field'
    html = javascript_options[:hidden] || javascript_options[:embedded] ?
      hidden_field_tag(object_name, value, options) :
      text_field_tag(object_name, value, options)
    calendar_date_select_output(html, image, options, javascript_options, formatted_date)
    if instance_tag.object.respond_to?(:errors) && instance_tag.object.errors[method].present?
      self.field_error_proc.call(html,instance_tag)
    else
      html
    end
  end

  def text_area(object_name, method, options = {})
   instance_tag = ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object))
   html = instance_tag.to_text_area_tag(options)
   if instance_tag.object.respond_to?(:errors) && instance_tag.object.errors[method].present?
     self.field_error_proc.call(html,instance_tag)
   else
     html
   end
 end

  def hidden_field(object_name, method, options = {})
    instance_tag = ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object))
    html = instance_tag.to_input_field_tag("hidden", options)
    if instance_tag.object.respond_to?(:errors) && instance_tag.object.errors[method].present?
      self.field_error_proc.call(html,instance_tag)
    else
      html
    end
  end

  
end