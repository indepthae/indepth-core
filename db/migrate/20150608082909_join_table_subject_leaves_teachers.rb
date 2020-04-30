class JoinTableSubjectLeavesTeachers < ActiveRecord::Migration
  def self.up
    create_table :subject_leaves_teachers, :id => false do |t|
      t.references :employee
      t.references :subject_leave
    end
    add_index :subject_leaves_teachers, [:employee_id, :subject_leave_id],:name => :index_by_fields
  end

  def self.down
    drop_table :subject_leaves_teachers
  end
end
