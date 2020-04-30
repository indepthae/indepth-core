class AddColumnOldDataToGallery < ActiveRecord::Migration
  def self.up
    [:gallery_categories,:gallery_photos].each do |c|
      add_column c,:old_data,:boolean , :default => false
    end
    ActiveRecord::Base.connection.execute("UPDATE gallery_categories SET old_data = true;")
    ActiveRecord::Base.connection.execute("UPDATE gallery_photos SET old_data = true;")
  end

  def self.down
    [:gallery_categories,:gallery_photos].each do |c|
      remove_column c,:old_data
    end
  end
end
