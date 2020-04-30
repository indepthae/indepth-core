class CreateDisciplineStudentActions < ActiveRecord::Migration
  def self.up
    create_table :discipline_student_actions do |t|
      t.references :discipline_action
      t.references :discipline_participation 

      t.timestamps
    end
  end

  def self.down
    drop_table :discipline_student_actions
  end
end
