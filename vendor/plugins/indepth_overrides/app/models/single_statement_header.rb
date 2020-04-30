class SingleStatementHeader < ActiveRecord::Base
	VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']
  
  has_attached_file :logo,
    # :styles => { :original=> "150x110#"},
    :url => "uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :default_url  => '/images/application/dummy_logo.png',
    :default_path  => ':rails_root/public/images/application/dummy_logo.png',
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 512000,
    :permitted_file_types =>VALID_IMAGE_TYPES


  validates_attachment_content_type :logo, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.logo_file_name.blank? }
  validates_attachment_size :logo, :less_than => 5120000,
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.logo_file_name_changed? }

  # def header_enabled?
  #   if self.header_space
  #     return false
  #   elsif self.nil?
  #   	return true	
  #   else
  #     return true
  #   end
  # end
end
