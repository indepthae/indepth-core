class RecordAddlAttachment < ActiveRecord::Base
  belongs_to :student_record
  has_attached_file :attachment,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/student_record_attachment/:id_partition/:basename.:extension",
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
end
