class FormFieldOption < ActiveRecord::Base
  belongs_to :form_field
  belongs_to :form_field_select
  belongs_to :form_field_checkbox
  belongs_to :form_field_radio
  
  validates_presence_of :label, :message=> t('form_templates.option_value_blank')
  default_scope :order => "placement_order ASC"

  def validate

    unless self.new_record?
      if self.form_field.form_template.forms.present?
        if errors.empty? and !self.changed.empty?
          errors.add(:base,t('template_modified'))
        end
      end
    else
    end
  end
  
end
