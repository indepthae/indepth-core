class AddColumnsToSubjects < ActiveRecord::Migration
  def self.up
    add_column :subjects, :is_asl,  :boolean,:default=>false
    add_column :subjects, :asl_mark,  :integer
    add_column :subjects, :is_sixth_subject,  :boolean,:default=>false
    add_column :elective_groups, :is_sixth_subject,  :boolean,:default=>false
  end

  def self.down
    remove_column :subjects, :is_asl
    remove_column :subjects, :asl_mark
    remove_column :subjects, :is_sixth_subject
    remove_column :elective_groups, :is_sixth_subject
  end
end
