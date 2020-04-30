class AddSchoolIdToOnlineExam < ActiveRecord::Migration
  def self.up
    [:online_exam_attendances,:online_exam_groups,:online_exam_options,:online_exam_questions,:online_exam_score_details].each do |c|
      add_column c,:school_id,:integer
      add_index c,:school_id
    end
  end

  def self.down
    [:online_exam_attendances,:online_exam_groups,:online_exam_options,:online_exam_questions,:online_exam_score_details].each do |c|
      remove_index c,:school_id
      remove_column c,:school_id,:integer      
    end
   end
end
