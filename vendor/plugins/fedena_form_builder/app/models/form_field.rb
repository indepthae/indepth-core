class FormField < ActiveRecord::Base
  belongs_to :form_templates
  default_scope :order => "placement_order ASC"
  named_scope :no_hr, :conditions => "field_type != 'hr'", :order => 'placement_order asc'

  attr_accessor :show_label
  has_many :form_field_options
end
