class CreateStudentAttachmentCategories < ActiveRecord::Migration
  def self.up
    create_table :student_attachment_categories do |t|
      t.string :attachment_category_name
      t.boolean :is_deletable, :default => 0
      t.integer :creator_id

      t.timestamps
    end
  end

  def self.down
    drop_table :student_attachment_categories
  end
end
