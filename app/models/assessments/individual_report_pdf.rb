class IndividualReportPdf < ActiveRecord::Base
  belongs_to :individual_report
  
  has_attached_file :attachment,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id/:style/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]
  
  validates_attachment_content_type :attachment,
    :content_type => [ 'application/pdf'],:message=>'is invalid'
  
  validates_attachment_size :attachment, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }
end