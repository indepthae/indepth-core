class ShareableFolder < Folder
  has_many :users, :through => :shareable_folder_users
  has_many :shareable_folder_users, :dependent => :destroy
  belongs_to :user
end
