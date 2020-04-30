class AddGuardianPhotoToArchivedGuardian < ActiveRecord::Migration
  def self.up
    add_column :archived_guardians, :photo_file_name, :string
    add_column :archived_guardians, :photo_content_type, :string
    add_column :archived_guardians, :photo_file_size, :integer
    add_column :archived_guardians, :photo_updated_at, :datetime
  end

  def self.down
    remove_column :archived_guardians, :photo_file_name
    remove_column :archived_guardians, :photo_content_type
    remove_column :archived_guardians, :photo_file_size
    remove_column :archived_guardians, :photo_updated_at
  end
end
