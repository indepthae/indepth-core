class GalleryCategory < ActiveRecord::Base
  xss_terminate
  has_many :gallery_photos, :dependent => :destroy
  has_many :gallery_category_privileges, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  named_scope :old_data,{ :conditions => { :old_data => true , :is_delete=>false }}
  named_scope :new_data,{ :conditions => { :old_data => false, :is_delete=>false }}

  before_save :notify_users, :if => Proc.new{|album| album.published_changed? && album.published?}


  def delay_destroy
    if self.update_attribute(:is_delete, true)
      self.instance_variable_set(:@destroy_later, true)
      Delayed::Job.enqueue(self, :queue => 'gallery')
    else
      return false
    end
  end

  def perform
    if self.instance_variable_get(:@destroy_later)
      self.destroy
    end
  end

  private

  def notify_users
    body = t(:gallery_notification_text, :name => name)
    links = {:target => 'show_gallery_album', :target_value => self.id}
    arguments =
      if visibility?
        args = ['all', body, 'Gallery', links]
        args << {:no_guardians => true} unless parent_can_access?
        args
      else
        [privileged_user_ids, body, 'Gallery', links]
      end
    inform(*arguments)
  end

  def privileged_user_ids
    user_ids = []
    members = gallery_category_privileges.all(:include => :imageable).collect(&:imageable)
    members.each do |member|
      if member.is_a? Employee
        user_ids << member.user_id
      elsif member.is_a? Student
        user_ids << member.user_id
        user_ids << member.immediate_contact.user_id if parent_can_access? && member.immediate_contact && member.immediate_contact.user_id
      end
    end
    user_ids
  end

  def parent_can_access?
    @parent_can_access ||= FeatureAccessSetting.find_by_feature_name('Gallery').try(:parent_can_access?) || false
  end

end
