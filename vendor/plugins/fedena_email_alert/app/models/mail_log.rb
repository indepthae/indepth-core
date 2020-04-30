class MailLog < ActiveRecord::Base

  has_many :mail_log_recipient_lists
  belongs_to :sender, :class_name => "User"

  serialize :recipients
  
  named_scope :logs_between, lambda { |start_date, end_date| {:conditions => ['created_at between ? and ?', start_date.to_date.beginning_of_day, end_date.to_date.end_of_day]} }
  
end
