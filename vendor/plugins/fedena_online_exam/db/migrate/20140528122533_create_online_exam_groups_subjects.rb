class CreateOnlineExamGroupsSubjects < ActiveRecord::Migration
  def self.up
    create_table :online_exam_groups_subjects, :id => false do |t|
      t.references :online_exam_group
      t.references :subject
    end
  end

  def self.down
    drop_table :online_exam_groups_subjects
  end
end
