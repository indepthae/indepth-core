class GalleryTag < ActiveRecord::Base
  xss_terminate
  belongs_to :gallery_photo
  belongs_to :member, :polymorphic=> true

  validates_presence_of :gallery_photo_id

end
