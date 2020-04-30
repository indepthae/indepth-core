class CreateGroupPostComments < ActiveRecord::Migration
  def self.up
    create_table :group_post_comments do |t|
      t.references :group_post
      t.references :user
      t.text :comment_body

      t.timestamps
    end
  end

  def self.down
    drop_table :group_post_comments
  end
end
