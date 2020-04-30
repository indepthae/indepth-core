class CreateGalleryCategories < ActiveRecord::Migration
  def self.up
    create_table :gallery_categories do |t|
      t.string :name
      t.string :description
      t.boolean :is_delete ,:default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :gallery_categories
  end
end
