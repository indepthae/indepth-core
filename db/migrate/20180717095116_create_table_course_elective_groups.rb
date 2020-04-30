class CreateTableCourseElectiveGroups < ActiveRecord::Migration
  def self.up
    create_table :course_elective_groups do |t|
      t.string  :name
      t.integer :parent_id
      t.string  :parent_type
      t.boolean :is_deleted, :default => false
      t.date    :end_date
      t.boolean :is_sixth_subject, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :course_elective_groups
  end
end
