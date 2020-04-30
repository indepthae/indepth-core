class StudentAttachment < ActiveRecord::Base
  belongs_to :batch
  belongs_to :student
  has_many :student_attachment_records, :dependent => :destroy
  has_many :student_attachment_categories, :through => :student_attachment_records
  belongs_to :uploader, :class_name => 'User'  
  attr_accessor :category
  
  before_create :update_uploader
  
  validates_presence_of :attachment_name, :batch_id, :student_id
  @@scale = 1024
  @@file_sizes = { "KB" => @@scale, "MB" => @@scale ** 2, "GB" => @@scale ** 3, "TB" => @@scale ** 4  }
    
  def self.attachment_file_size_limit
    attachment_max_size = 10 * @@file_sizes["MB"] # 10 MB default 
    student_attachment_settings_path = "#{RAILS_ROOT}/config/student_attachment_settings.yml"
    student_attachment_settings = YAML.load_file(student_attachment_settings_path) if File.exists?(student_attachment_settings_path)
    attachment_max_size = student_attachment_settings["max_file_size"] if student_attachment_settings.present? and student_attachment_settings["max_file_size"].present?    
    attachment_max_size
  end
  
  def self.file_size_message
    file_size = attachment_file_size_limit
    size_in_words = "#{(file_size / @@file_sizes["TB"].to_f).round(2)} TB" if attachment_file_size_limit >= @@file_sizes["TB"]
    size_in_words = "#{(file_size / @@file_sizes["GB"].to_f).round(2)} GB" if attachment_file_size_limit >= @@file_sizes["GB"] and attachment_file_size_limit < @@file_sizes["TB"]
    size_in_words = "#{(file_size / @@file_sizes["MB"].to_f).round(2)} MB" if attachment_file_size_limit >= @@file_sizes["MB"] and attachment_file_size_limit < @@file_sizes["GB"]
    size_in_words = "#{(file_size / @@file_sizes["KB"].to_f).round(2)} KB" if attachment_file_size_limit >= 1024 and attachment_file_size_limit < @@file_sizes["MB"]
    size_in_words = "#{file_size} Bytes" if attachment_file_size_limit < 1024
    size_in_words
  end
  
  has_attached_file :attachment,
#    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :url => "/student_documents/:id/download",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :max_file_size => attachment_file_size_limit, # || 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[],
    :download => true

  validates_attachment_presence :attachment
  validates_attachment_content_type :attachment,
    :content_type => ['image/png','image/jpg','image/jpeg','image/gif','image/bmp','application/pdf',
    'application/powerpoint','application/mspowerpoint','application/vnd.ms-powerpoint',
    'application/x-mspowerpoint','application/msword','application/mspowerpoint',
    'application/vnd.ms-powerpoint','application/excel','application/vnd.ms-excel',
    'application/x-excel','application/x-msexcel','application/rtf','application/x-rtf',
    'text/richtext','text/plain','application/wordperfect','application/x-wpwin',
    'text/tab-separated-values','text/csv','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.slideshow','application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet','image/svg+xml','application/vnd.ms-works','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/wpd','application/wordperf'], :message => t('student_documents.invalid_file_type')
  validates_attachment_size :attachment, :less_than => attachment_file_size_limit,\
    :message=> t('student_documents.document_file_size_validation', :size => file_size_message),:if=> Proc.new { |p| p.attachment_file_name_changed? }
#    :message=> t('document_file_size_validation', :size => size_in_words) "must be less than #{attachment_file_size_limit / (1024 * 1024).to_f} MB.",:if=> Proc.new { |p| p.attachment_file_name_changed? }
  
  def set_and_save student
    self.batch_id = student.batch_id
    self.uploader_id = Authorization.current_user.id
    self.is_registered = (self.category.present? and self.category == 'registered')
    self.student_attachment_category_ids = self.category if self.category.present? and self.category != 'nil' and self.category != 'registered'
    self.save
  end  
  
  def update_document data
    self.attachment_name = data['attachment_name'] if data.keys.include?('attachment_name') and attachment_name != data['attachment_name'] # and data['attachment_name'].present?
    self.is_registered = (data['category'] == 'registered' and data['category'] != 'nil') if data['category'].present?
    self.save
    category = StudentAttachmentCategory.fetch(data['category']) if data.keys.include?('category')
    self.student_attachment_category_ids = ((category.new_record? or category.registered) ? [] : category.category_id.to_a) if category.present?
  end
  
#  def update_document data
#    self.attachment_name = data['attachment_name'] if data.keys.include?('attachment_name') # and data['attachment_name'].present?
#    self.is_registered = (data['category'].present? and data['category'] == 'registered')
#    self.save
#    category = StudentAttachmentCategory.fetch(data['category']) if data.keys.include?('category')
#    self.student_attachment_category_ids = ((category.new_record? or category.registered) ? [] : category.category_id.to_a) if category.present?
#  end
  
  def update_uploader
    self.uploader_id = Authorization.current_user.id unless self.uploader_id.present?
  end
  
  def self.documents_group(docs)
    doc_groups = docs.group_by {|document| document.student_attachment_categories.first }
    doc_groups['registered_docs'] = doc_groups[nil].select {|doc| doc.is_registered } if doc_groups[nil].present?
    doc_groups["nil"] = doc_groups[nil].reject {|doc| doc.is_registered } if doc_groups[nil].present?
    doc_groups
  end
  
  def self.category_documents(document_groups, category)
    category_id = category.category_id
    category.new_record? ? (category.registered ? document_groups['registered_docs'] : document_groups[category_id]) : document_groups[category]
  end  
  
end


