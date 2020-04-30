class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.references :user
      t.string :title
      t.text :description
      t.string :status
      t.date :start_date
      t.date :due_date
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime  :attachment_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :tasks
  end
end
