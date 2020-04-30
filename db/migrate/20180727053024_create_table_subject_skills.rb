class CreateTableSubjectSkills < ActiveRecord::Migration
  def self.up
    create_table :subject_skills do |t|
      t.string  :name
      t.references :subject_skill_set
      t.boolean :calculate_final
      t.string  :formula
      t.decimal :maximum_marks, :precision => 8, :scale => 2
      t.decimal :manimum_marks, :precision => 8, :scale => 2
      t.string  :grade
      t.integer :higher_skill_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :subject_skills
  end
end
