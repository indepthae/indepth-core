class ApplicantAddlAttachment < ActiveRecord::Base
  
  belongs_to :applicant_addl_attachment_field
  belongs_to :applicant

  
  attr_accessor :delete_attachment
  
  has_attached_file :attachment,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_content_type :attachment,
    :content_type => [ 'image/png','image/jpg','image/jpeg','image/gif','image/bmp','application/pdf',
    'application/powerpoint','application/mspowerpoint','application/vnd.ms-powerpoint',
    'application/x-mspowerpoint','application/msword','application/mspowerpoint',
    'application/vnd.ms-powerpoint','application/excel','application/vnd.ms-excel',
    'application/x-excel','application/x-msexcel','application/rtf','application/x-rtf',
    'text/richtext','text/plain','application/wordperfect','application/x-wpwin',
    'text/tab-separated-values','text/csv','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.slideshow','application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet','image/svg+xml','application/vnd.ms-works','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/wpd','application/wordperf'
  ],:message=>'is invalid'

  validates_attachment_size :attachment, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }
  
  before_save :check_if_attachment_deleted
    
    
  def check_if_attachment_deleted
    if self.delete_attachment.present? and self.delete_attachment.to_s == "true"
      unless self.changed.include?("attachment_updated_at")
        self.attachment.clear
        self.delete_attachment = false
      end
    end
  end
  
  def validate
    addl_field = self.applicant_addl_attachment_field
    unless self.attachment.present?
      self.applicant.errors.add_to_base("#{addl_field.name} can't be blank") if (self.applicant.m_att_attr.present? and self.applicant.m_att_attr.split(", ").include?(addl_field.id.to_s))
    else
      if self.errors.present?
        self.errors.clear
        self.applicant.errors.add_to_base("Attachment for #{addl_field.name} is invalid.")
      end
    end
  end
  
end
