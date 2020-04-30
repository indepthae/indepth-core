class AddColumnVisibilityToGalleryCategories < ActiveRecord::Migration
  def self.up
    add_column :gallery_categories , :visibility, :boolean
  end

  def self.down
    remove_column :gallery_categories, :visibility
  end
end
