class OnlineExamGroupsQuestion < ActiveRecord::Base
  belongs_to :online_exam_group
  belongs_to :online_exam_question
  
  serialize :answer_ids

  validates_presence_of :online_exam_group_id, :online_exam_question_id, :mark
  validates_numericality_of :mark,:greater_than=> 0,:allow_nil=>true
  validates_uniqueness_of :online_exam_question_id, :scope=>:online_exam_group_id
  #validates_uniqueness_of :position, :scope=>:online_exam_group_id

  def self.last_position(exam_id)
    last_pos = 0
    last_question = OnlineExamGroupsQuestion.find(:last,:conditions=>{:online_exam_group_id=>exam_id}, :order=>"position ASC")
    unless last_question.nil?
      last_pos = last_question.position
    end
    return last_pos
  end
end
