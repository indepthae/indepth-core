class VehicleCertificate < ActiveRecord::Base
  
  attr_accessor :delete_certificate
  
  belongs_to :vehicle
  belongs_to :certificate_type
  
  validates_presence_of :certificate_type_id, :vehicle_id, :certificate_no, :date_of_issue, :date_of_expiry
  before_save :check_if_certificate_deleted
  
  VALID_IMAGE_TYPES = [ 'image/png','image/jpg','image/jpeg','image/gif','image/bmp','application/pdf',
    'application/powerpoint','application/mspowerpoint','application/vnd.ms-powerpoint',
    'application/x-mspowerpoint','application/msword','application/mspowerpoint',
    'application/vnd.ms-powerpoint','application/excel','application/vnd.ms-excel',
    'application/x-excel','application/x-msexcel','application/rtf','application/x-rtf',
    'text/richtext','text/plain','application/wordperfect','application/x-wpwin',
    'text/tab-separated-values','text/csv','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.slideshow','application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet','image/svg+xml','application/vnd.ms-works','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/wpd','application/wordperf'
  ]
  
  has_attached_file :certificate,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id/:style/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types => VALID_IMAGE_TYPES,
    :download => true

  validates_attachment_content_type :certificate,
    :content_type => VALID_IMAGE_TYPES,:message=>'is invalid'

  validates_attachment_size :certificate, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.certificate_file_name_changed? }
  
  #validate dates
  def validate
    if date_of_expiry.present? && date_of_issue.present?
      errors.add(:date_of_expiry, :less_than_date_of_issue) if date_of_expiry < date_of_issue
    end
  end
  
  #delete certificate file if attachment is removed by user
  def check_if_certificate_deleted
    if self.delete_certificate.present? and self.delete_certificate.to_s == "true"
      unless self.changed.include?("certificate_updated_at")
        self.certificate.clear
      end
    end
  end
end
