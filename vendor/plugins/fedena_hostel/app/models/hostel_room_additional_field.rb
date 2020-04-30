class HostelRoomAdditionalField < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name,:case_sensitive => false
  validates_format_of     :name, :with => /^[^~`@%$*()\-\[\]{}"':;\/.,\\=+|]*$/i,
    :message => :must_contain_only_letters_numbers_space
  named_scope :active,:conditions => {:is_active => true}
  has_many :hostel_room_additional_details
end

