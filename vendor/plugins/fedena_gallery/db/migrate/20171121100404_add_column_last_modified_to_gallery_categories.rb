class AddColumnLastModifiedToGalleryCategories < ActiveRecord::Migration
  def self.up
    add_column :gallery_categories , :last_modified, :datetime
  end

  def self.down
    remove_column :gallery_categories, :last_modified
  end
end
