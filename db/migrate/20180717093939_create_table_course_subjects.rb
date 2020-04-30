class CreateTableCourseSubjects < ActiveRecord::Migration
  def self.up
    create_table :course_subjects do |t|
      t.string  :name
      t.integer :parent_id
      t.string :parent_type
      t.string :code
      t.boolean :no_exams, :default => false
      t.integer :max_weekly_classes
      t.boolean :is_deleted, :default => false
      t.decimal :credit_hours ,:precision => 15, :scale => 2
      t.boolean :prefer_consecutive, :default => false
      t.decimal :amount ,:precision => 15, :scale => 2
      t.boolean :is_asl, :default => false
      t.integer :asl_mark
      t.boolean :is_sixth_subject
      
      t.integer :subject_skill_set_id
      t.timestamps
    end
  end

  def self.down
    drop_table :course_subjects
  end
end
