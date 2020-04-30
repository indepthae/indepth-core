class CreateCourseTranscriptSettings < ActiveRecord::Migration
  def self.up
    create_table :course_transcript_settings do |t|
      t.references :course
      t.boolean  :show_grade
      t.boolean  :show_percentage
      t.timestamps
    end
  end

  def self.down
    drop_table :course_transcript_settings
  end
end