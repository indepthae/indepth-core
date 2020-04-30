class PollQuestion < ActiveRecord::Base
  has_many  :poll_options, :dependent => :destroy
  has_many  :poll_votes, :dependent => :destroy
  has_many :poll_members,:dependent => :destroy
  belongs_to :poll_creator, :class_name => "User"
  accepts_nested_attributes_for :poll_options, :allow_destroy => true
  validates_presence_of :title
#  validates_associated :poll_options

  def validate
    undestroyed_poll_options = 0
    poll_options.each { |t| undestroyed_poll_options += 1 unless t.marked_for_destruction? }
    errors.add_to_base :options_cant_blank if undestroyed_poll_options < 1
  end


  def send_mail
    PollNotifier.deliver_poll_notify(self)
  end

  def poll_question_can_be_edited_by?(user_in_question)
    ((user_in_question.id == self.poll_creator_id) or user_in_question.privileges.map{|p| p.name}.include?('PollControl') or user_in_question.admin?)
  end

  def poll_question_can_be_deleted_by?(user_in_question)
    ((user_in_question.id == self.poll_creator_id) or user_in_question.privileges.map{|p| p.name}.include?('PollControl') or user_in_question.admin?)
  end
  
  def poll_question_can_be_viewed_by?(user_in_question)
    member_user = user_in_question.student_record
    member_user ||= user_in_question.employee_record
    if ((user_in_question.id == self.poll_creator_id) or (user_in_question.privileges.map{|p| p.name}.include?('PollControl')) or (user_in_question.admin?))
      return true
    elsif member_user.poll_question.find_by_id(self.id).present?
      return true
    end
  end


  def self.list_active_poll_questions_for_member(user_in_question)
    member_questions = []
    poll_questions = PollQuestion.all(:conditions => {:is_active => true})
    poll_questions.each do |question|
      if question.poll_question_can_be_viewed_by?(user_in_question)
        member_questions << question
      end
    end
    member_questions
  end

  def self.list_closed_poll_questions_for_member(user_in_question)
    member_questions = []
    poll_questions = PollQuestion.all(:conditions => {:is_active => false})
    poll_questions.each do |question|
      if question.poll_question_can_be_viewed_by?(user_in_question)
        member_questions << question
      end
    end
    member_questions
  end

  def total_poll_votes
    self.poll_votes.count
  end
  def voted_users_list
    users_list=[]
    self.poll_votes.each do |user|
       users_list<<user.user
     end
     return users_list
  end
  def is_voted?
    return true
  end

end