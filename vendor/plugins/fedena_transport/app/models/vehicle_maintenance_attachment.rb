class VehicleMaintenanceAttachment < ActiveRecord::Base
  
  attr_accessor :delete_attachment, :attachment_present
  
  belongs_to :vehicle_maintenance
  
  validates_presence_of :name
  before_save :check_if_attachment_deleted
  
  VALID_IMAGE_TYPES = [ 'image/png','image/jpg','image/jpeg','image/gif','image/bmp','application/pdf',
    'application/powerpoint','application/mspowerpoint','application/vnd.ms-powerpoint', "application/octet-stream",
    'application/x-mspowerpoint','application/msword','application/mspowerpoint',
    'application/vnd.ms-powerpoint','application/excel','application/vnd.ms-excel',
    'application/x-excel','application/x-msexcel','application/rtf','application/x-rtf',
    'text/richtext','text/plain','application/wordperfect','application/x-wpwin',
    'text/tab-separated-values','text/csv','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.slideshow','application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet','image/svg+xml','application/vnd.ms-works','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/wpd','application/wordperf'
  ]
  
  has_attached_file :attachment,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id/:style/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_content_type :attachment,
    :content_type => VALID_IMAGE_TYPES,:message=>'is invalid'

  validates_attachment_size :attachment, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }
  
  #validates attachments
  def validate
    if name.present? and !attachment.present?
      errors.add(:attachment_present, :blank)
    else
      errors.add(:attachment_present, :blank) if delete_attachment.to_s == "true"
    end
  end
  
  #delete certificate file if attachment is removed by user
  def check_if_attachment_deleted
    if self.delete_attachment.present? and self.delete_attachment.to_s == "true"
      unless self.changed.include?("attachment_updated_at")
        self.attachment.clear
      end
    end
  end
end
