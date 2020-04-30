class GalleryCategoryPrivilege < ActiveRecord::Base
  xss_terminate
  belongs_to :GalleryCategory
  belongs_to :imageable, :polymorphic=>true
end
