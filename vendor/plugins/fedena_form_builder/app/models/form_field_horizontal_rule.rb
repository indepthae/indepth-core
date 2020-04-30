class FormFieldHorizontalRule < FormField
  belongs_to :form_template
  def set_initial_field_data
    self.field_type = "hr"
  end

  def validate
    unless self.new_record?
      if self.form_template.forms.present?
        if errors.empty? and !self.changed.empty?
          errors.add(:base,t('template_modified'))
        end
      end
    end
  end
  
end
