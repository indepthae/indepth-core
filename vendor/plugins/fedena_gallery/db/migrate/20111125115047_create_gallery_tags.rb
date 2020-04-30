class CreateGalleryTags < ActiveRecord::Migration
  def self.up
    create_table :gallery_tags do |t|
      t.references :gallery_photo
      t.integer :member_id
      t.string :member_type
      t.timestamps
    end
  end

  def self.down
    drop_table :gallery_tags
  end
end
