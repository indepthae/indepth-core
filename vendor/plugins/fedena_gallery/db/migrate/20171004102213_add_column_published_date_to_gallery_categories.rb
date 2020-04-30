class AddColumnPublishedDateToGalleryCategories < ActiveRecord::Migration
  def self.up
    add_column :gallery_categories , :published_date, :date
  end

  def self.down
    remove_column :gallery_categories, :published_date
  end
end
