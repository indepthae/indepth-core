class NotificationRecipient < ActiveRecord::Base
  belongs_to  :notification
  belongs_to  :recipient, :class_name => 'User'
end