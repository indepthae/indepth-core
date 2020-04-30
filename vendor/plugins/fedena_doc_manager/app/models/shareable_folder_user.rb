class ShareableFolderUser < ActiveRecord::Base
  belongs_to :shareable_folder
  belongs_to :user

  def toggle_favorite
    self.is_favorite = self.is_favorite? ? false : true
    self.save
  end
  
end
