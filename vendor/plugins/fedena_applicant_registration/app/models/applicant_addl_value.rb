class ApplicantAddlValue < ActiveRecord::Base



  belongs_to :registration_course
  belongs_to :applicant_addl_field
  belongs_to :applicant
  belongs_to :applicant_guardian
  
  
  attr_accessor :delete_attachment

  
  has_attached_file :attachment,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/applicant_addl_attachment/:id_partition/:basename.:extension",
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
  
  before_validation :modify_field_option
  
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
    addl_field = self.applicant_addl_field
    if addl_field.field_type == "attachment"
      unless self.attachment.present?
        self.applicant.errors.add_to_base("#{addl_field.field_name} can't be blank") if (self.applicant.m_add_attr.present? and self.applicant.m_add_attr.split(", ").include?(addl_field.id.to_s))
      else
        if self.errors.present?  
          self.errors.clear
          self.applicant.errors.add_to_base("Attachment for #{addl_field.field_name} is invalid.")
        end
      end
    else
      self.applicant.errors.add_to_base("#{addl_field.field_name} can't be blank") if (self.applicant.m_add_attr.present? and self.applicant.m_add_attr.split(", ").include?(addl_field.id.to_s) and !self.option.present?)
      if (self.option.present? and (addl_field.field_type=="singleline" and addl_field.record_type=="numeric"))
        self.applicant.errors.add_to_base("#{addl_field.field_name} is not a number.") unless (self.option=~/\A\d+(?:\.\d*)?\z/)==0
      end
    end

  end
  
  def modify_field_option
    if self.option.present?
      if self.option.class.name == "Array"
        self.option.delete("")
        self.option = self.option.join(", ")
      end
    end
  end

  def value
    if self.applicant_addl_field
      if self.applicant_addl_field.field_type == "single_select" or  self.applicant_addl_field.field_type == "multi_select"
        ApplicantAddlFieldValue.find(:all,:conditions=>{:id=>option.split(",")}).map{|o| o.option}.join(", ")
      else
        option
      end
    else
      ""
    end
  end

  def reverse_value
    if self.applicant_addl_field
      if self.applicant_addl_field.field_type == "has_many" or  self.applicant_addl_field.field_type == "belongs_to"
        s= option.split(",")
        if s.count>1
          s
        else
          option
        end
      else
        option
      end
    end
  end
 
end
