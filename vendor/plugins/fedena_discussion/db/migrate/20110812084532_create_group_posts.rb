class CreateGroupPosts < ActiveRecord::Migration
  def self.up
    create_table :group_posts do |t|
      t.references :group
      t.references :user
      t.string :post_title
      t.text :post_body

      t.timestamps
    end
  end

  def self.down
    drop_table :group_posts
  end
end
