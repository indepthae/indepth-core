module MultiSchoolHelper
  mattr_accessor :ms_field_error_proc
  @@ms_field_error_proc = Proc.new do |html_tag, instance|
    errors = Array(instance.error_message).join(',')
    unless html_tag["label"]
      %(#{html_tag}<span class="validation-error">&nbsp;#{errors}</span>).html_safe
    else
      %(<div class="fieldWithErrors">&nbsp;#{html_tag}</div>).html_safe
    end
  end

  def text_field(object_name, method, options = {})
    instance_tag = ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object))
    html = instance_tag.to_input_field_tag("text", options)
    if instance_tag.object.respond_to?(:errors) && instance_tag.object.errors.respond_to?(:on)
      self.ms_field_error_proc.call(html,instance_tag)
    else
      html
    end
  end

   def password_field(object_name, method, options = {})
    instance_tag = ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object))
    html = instance_tag.to_input_field_tag("password", options)
    if instance_tag.object.respond_to?(:errors) && instance_tag.object.errors.respond_to?(:on)
      self.ms_field_error_proc.call(html,instance_tag)
    else
      html
    end

  end

  def error_string_for(form)
    "<div class=\"formError\">There were problems saving the form.</div>" unless form.object.errors.blank?
  end

end
