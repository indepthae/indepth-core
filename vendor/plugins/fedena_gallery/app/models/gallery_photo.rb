class GalleryPhoto < ActiveRecord::Base
  xss_terminate
  belongs_to :gallery_category
  has_many :gallery_tags, :dependent => :destroy

  named_scope :old_data,{ :conditions => { :old_data => true , :is_deleted=>false}}
  named_scope :new_data,{ :conditions => { :old_data => false, :is_deleted=>false }}
  named_scope :alive, {:conditions => { :is_deleted=>false}}
  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  has_attached_file :photo,
    :styles => {
    :thumb=> "300x300#",
    :small  => "150x150#"},
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :url => "/galleries/download_image/:id?style=:style",
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 5242880,
    :permitted_file_types =>VALID_IMAGE_TYPES,
    :whiny=>false,
    :download=>false

  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,:message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  validates_attachment_size :photo, :less_than => 5242880,\
    :message=>:must_be_less_than_5_mb,:if=> Proc.new { |p| p.photo_file_name_changed? }

  validates_presence_of :gallery_category_id
  validates_length_of :description, :maximum => 220
  validates_presence_of :photo_file_name
  #there is no problem with original pic..

  def delay_destroy
    if self.update_attribute(:is_deleted, true)
      self.instance_variable_set :@_paperclip_attachments, nil
      self.instance_variable_set(:@destroy_later, true)
      Delayed::Job.enqueue(self, :queue => 'gallery')
    else
      return false
    end
  end

  def self.delay_destroy(ids)
      self.transaction do
        records = GalleryPhoto.find_all_by_id(ids)
        records.each do |record|
          status = record.delay_destroy
          raise ActiveRecord::Rollback unless status
        end
      end
  end

  def perform
    if self.instance_variable_get(:@destroy_later)
      self.destroy
    end
  end

end
