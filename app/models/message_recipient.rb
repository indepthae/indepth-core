class MessageRecipient < ActiveRecord::Base
  validates_presence_of :recipient_id
  xss_terminate
  belongs_to  :message
  belongs_to  :recipient, :class_name => 'User'
  
  def thread
    MessageThread.find thread_id unless thread_id.nil?
  end
end
