class JoinTableIaGroupSubject < ActiveRecord::Migration
  def self.up
    create_table :ia_groups_subjects, :id => false do |t|
      t.references :ia_group
      t.references :subject
    end
    add_index :ia_groups_subjects, [:ia_group_id, :subject_id],:name => :index_by_fields
  end

  def self.down
    drop_table :ia_groups_subjects
  end
end
