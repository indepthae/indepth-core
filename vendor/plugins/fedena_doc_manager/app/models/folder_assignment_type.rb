class FolderAssignmentType < ActiveRecord::Base
  has_and_belongs_to_many :assignable_folder
end
