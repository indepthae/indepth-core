class PollVote < ActiveRecord::Base
  validates_uniqueness_of :user_id, :scope => :poll_question_id, :message =>:has_already_voted
  belongs_to  :poll_question
  belongs_to :user
  def validate
    if(poll_option_id.blank? && custom_answer.blank? || poll_option_id==0)
      errors.add_to_base :you_havent_selected_an_option_yet
    end
  end

end
