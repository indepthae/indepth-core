class FormFieldText < FormField
  belongs_to :form_template
  validates_presence_of :label,:message => t('form_templates.field_title_blank')

  def set_initial_field_data
    self.field_type = "text"
    settings = FieldConfig.fields["text"]
    self.label = settings['label']
    self.show_label = settings['show_label']
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
