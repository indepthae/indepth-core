class GroupFile < ActiveRecord::Base
  belongs_to :group
  belongs_to :user
  belongs_to :group_post
  has_attached_file :doc,
    :styles => {:small  => "250x200>"},
    :url => "/groups/:group_id/group_posts/:id/download_attachment?style=:style",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[],
    :whiny=>false

  validates_attachment_size :doc, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.doc_file_name_changed? }

  validates_presence_of :doc_file_name

  Paperclip.interpolates :group_id do |attachment,style|
    attachment.instance.group_post.group_id
  end
end