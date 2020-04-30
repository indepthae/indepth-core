class CreateAssessmentSchedules < ActiveRecord::Migration
  def self.up
    create_table :assessment_schedules do |t|
      t.references :assessment_group
      t.references :course
      t.date :start_date
      t.date :end_date
      t.integer :no_of_exams_per_day, :default => 1
      t.text :exam_timings
      t.boolean :schedule_created, :default => false
      t.boolean :schedule_published, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :assessment_schedules
  end
end
