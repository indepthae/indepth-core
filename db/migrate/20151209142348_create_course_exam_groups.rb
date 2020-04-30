class CreateCourseExamGroups < ActiveRecord::Migration
  def self.up
    create_table :course_exam_groups do |t|
      t.string :name
      t.integer :course_id
      t.string :exam_type
      t.integer :cce_exam_category_id
      t.integer :icse_exam_category_id
      t.integer :school_id

      t.timestamps
    end
  end

  def self.down
    drop_table :course_exam_groups
  end
end
