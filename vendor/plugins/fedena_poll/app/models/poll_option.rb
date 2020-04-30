class PollOption < ActiveRecord::Base
  belongs_to:poll_question
  validates_presence_of :option
end
