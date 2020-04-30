class AddSubjectSkillSetIdToSujects < ActiveRecord::Migration
  def self.up
    add_column :subjects, :subject_skill_set_id, :integer
  end

  def self.down
    remove_column :subjects, :subject_skill_set_id
  end
end
