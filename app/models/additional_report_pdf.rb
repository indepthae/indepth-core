class AdditionalReportPdf < ActiveRecord::Base
  
  require 'securerandom'
  serialize :parameters, Hash  
  serialize :opts, Hash  
  has_attached_file :pdf_report,
    :url => "/report/pdf_report_download/:id",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :max_file_size => 10.megabytes,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]
  
  validates_attachment_size :pdf_report, :less_than => 10.megabytes,\
    :message=>'must be less than 10 MB.',:if=> Proc.new { |p| p.pdf_report_file_name_changed? }
  
  def pdf_generation
    
    self.model_name.camelize.constantize.send(method_name, self.parameters, self.opts)
    
    parameters[:filename].present? ? file_path= "tmp/#{parameters[:controller_name]}-#{parameters[:action_name]}/#{parameters[:filename]}.pdf" : file_path="tmp/#{SecureRandom.random_number(Time.now.strftime("%H%M%S%d%m%Y").to_i)}_#{method_name_translation}.pdf"
    
    self.pdf_report = open(file_path)
    self.status = false
    if self.save
      File.delete(file_path)
    else
     self.update_attribute(:status, false) 
    end
    
  end
  
  def method_name_translation
    t("reports_name.#{method_name}")
  end
  
end