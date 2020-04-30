class AddIndicesToDiscipline < ActiveRecord::Migration
  def self.up
    add_index :discipline_complaints, [:user_id]
    add_index :discipline_complaints, [:school_id]
    add_index :discipline_participations, [:user_id,:discipline_complaint_id,:type],:name => 'by_user_and_complaint'
    add_index :discipline_participations,[:school_id]
    add_index :discipline_comments, [:user_id]
    add_index :discipline_comments, [:school_id]
    add_index :discipline_actions, [:user_id]
    add_index :discipline_actions, [:school_id]
    add_index :discipline_student_actions, [:discipline_participation_id,:discipline_action_id],:name => 'by_action_and_participation'
  end

  def self.down
    remove_index :discipline_complaints, [:user_id]
    remove_index :discipline_complaints, [:school_id]
    remove_index :discipline_participations,:name => 'by_user_and_complaint'
    remove_index :discipline_participations,[:school_id]
    remove_index :discipline_comments, [:user_id]
    remove_index :discipline_comments, [:school_id]
    remove_index :discipline_actions, [:user_id]
    remove_index :discipline_actions,[:school_id]
    remove_index :discipline_student_actions,:name => 'by_action_and_participation'
  end
end
