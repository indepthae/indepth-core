class AddColumnPublishedToGalleryCategories < ActiveRecord::Migration
  def self.up
    add_column :gallery_categories , :published, :boolean, :default => false
  end

  def self.down
    remove_column :gallery_categories, :published
  end
end
