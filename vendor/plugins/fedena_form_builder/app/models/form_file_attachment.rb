class FormFileAttachment < ActiveRecord::Base
  belongs_to :form_field_file
  has_attached_file	:attachment, 
    :path => "uploads/:class/:id_partition/:basename.:extension",
    :url => "/form_submissions/download/:id",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types => []
  
end