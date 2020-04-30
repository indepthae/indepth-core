class AddColumnIsDeletedToGalleryPhoto < ActiveRecord::Migration
  def self.up
    add_column :gallery_photos , :is_deleted, :boolean, :default => false
  end

  def self.down
    remove_column :gallery_photos, :is_deleted
  end
end
