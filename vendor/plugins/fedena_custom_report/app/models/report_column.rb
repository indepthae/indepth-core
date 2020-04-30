class ReportColumn < ActiveRecord::Base
  belongs_to :report
  before_save :set_default_title
  default_scope  :order=>"position"
  LABEL_NAMES = YAML::load(File.open(File.dirname(__FILE__)+'/../../config/label_names.yml'))
  EMPLOYEE_ORDER = [:main]
  STUDENT_ORDER = [:main,:father,:mother,:parents,:immediate_contact, :student_previous_data]
  
  def set_default_title
    self.title = self.method.titleize if self.title.blank?
  end

  def association_method_object
    model = self.association_method.camelize.singularize
    Kernel.const_get(model)
  end

  def label_name
    if self.method.to_s.include?("_additional_fields_")
     label_name =  self.method.to_s.to_sym
    elsif self.method.to_s.include?("_bank_fields_")
      label_name =  self.method.to_s.to_sym
    else
      if self.association_method.nil?
        label_name = self.method.to_sym
      else
        label_name = (self.association_method.to_s + "_" + self.method.to_s).to_sym
      end
    end
    LABEL_NAMES[label_name]||label_name
  end
end
