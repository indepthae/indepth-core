class CreateSubjectSkillSets < ActiveRecord::Migration
  def self.up
    create_table :subject_skill_sets do |t|
      t.string  :name
      t.boolean :calculate_final
      t.string  :formula
      
      t.timestamps
    end
  end

  def self.down
    drop_table :subject_skill_sets
  end
end