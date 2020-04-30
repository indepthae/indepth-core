class TallyExportFile < ActiveRecord::Base

  has_attached_file :export_file,
  :url => "/tally_exports/download/:id",
  :path => "uploads/:class/:attachment/:id_partition/:basename.:extension"


#  validates_attachment_content_type :export_file, :content_type =>'text/xml',
#  :message=>'Only XML file permitted'

end
