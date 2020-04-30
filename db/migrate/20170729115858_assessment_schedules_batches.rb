class AssessmentSchedulesBatches < ActiveRecord::Migration
  def self.up
    create_table :assessment_schedules_batches, :id => false do |t|
      t.references :assessment_schedule
      t.references :batch
    end
  end

  def self.down
    drop_table :batch_tutors
  end
end
