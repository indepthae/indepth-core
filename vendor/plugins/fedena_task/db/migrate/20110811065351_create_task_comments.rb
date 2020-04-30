class CreateTaskComments < ActiveRecord::Migration
  def self.up
    create_table :task_comments do |t|
      t.references :user
      t.references :task
      t.text :description
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime  :attachment_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :task_comments
  end
end
