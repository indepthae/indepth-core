class DisciplineAttachment < ActiveRecord::Base
  belongs_to :discipline_participation
  has_attached_file :attachment,
    :path => "uploads/:class/:discipline_participation_id/:id_partition/:basename.:extension",
    :url => "/discipline_complaints/:attachment_discipline_complaint_id/download_attachment?id1=:id",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_size :attachment, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }

  Paperclip.interpolates :discipline_participation_id do |attachment,style|
    attachment.instance.discipline_participation_id
  end
  Paperclip.interpolates :attachment_discipline_complaint_id do |attachment,style|
    attachment.instance.discipline_participation.discipline_complaint_id
  end
end
