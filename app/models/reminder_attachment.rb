class ReminderAttachment < ActiveRecord::Base
  has_many :reminders,:through=>:reminder_attachment_relations
  has_many :reminder_attachment_relations
  has_attached_file :attachment,
  :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
  :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
  :reject_if => proc { |attributes| attributes.present? },
  :max_file_size => 5.megabytes,
  :download => false

  validates_presence_of :attachment_file_name
  
  validates_attachment_size :attachment, :less_than => 5.megabytes,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }
end
