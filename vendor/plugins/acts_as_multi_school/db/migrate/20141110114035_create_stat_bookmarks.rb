class CreateStatBookmarks < ActiveRecord::Migration
  def self.up
    create_table :stat_bookmarks do |t|
      t.string :name
      t.text :url
      t.references :admin_user
      t.timestamps
    end
  end

  def self.down
    drop_table :stat_bookmarks
  end
end
