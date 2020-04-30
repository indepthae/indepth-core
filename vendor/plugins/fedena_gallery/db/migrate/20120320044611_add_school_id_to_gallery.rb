class AddSchoolIdToGallery < ActiveRecord::Migration
  def self.up
    [:gallery_categories,:gallery_photos,:gallery_tags].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:gallery_categories,:gallery_photos,:gallery_tags].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id
    end
  end
end
