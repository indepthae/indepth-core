class Notification < ActiveRecord::Base
  xss_terminate :except => [:content]
  has_many :notification_recipients, :dependent=>:destroy
  accepts_nested_attributes_for :notification_recipients
  serialize :payload, Hash

  attr_accessor :recipient_ids

  MOBILE_PUSH_LIST = ['Leave', 'Finance', 'Event', 'Event-Examination', 'News', 'Gradebook', 'Attendance',
                      'Gallery', 'CollectFee'].freeze
  NOTIFICATION_REFERENCE_LIST = {:parent => ["view_form", "show_news"]}

  # after_create :push_notify

  class << self
    def get_filters
      current_user = Authorization.current_user
      Notification.all(:joins=>:notification_recipients, :conditions=>{:notification_recipients=>{:recipient_id=>current_user.id}},
      :order=>'created_at DESC').collect(&:initiator).uniq
    end
    
    def apply_filter(filter)
      user = Authorization.current_user
      if filter == 'all'
        user.notifications
      else
        Notification.all(:joins=>:notification_recipients, :conditions=>{:initiator=> filter,
            :notification_recipients=>{:recipient_id=>user.id}},:order=>'created_at DESC')
      end
    end
  end

  def push_notify (recipient_ids, options={})
    return unless MOBILE_PUSH_LIST.include? initiator
    data = {
        :title => initiator,
        :body => content,
        :tag => 'notifications',
        :type => 'notification',
        :target => nil,
        :target_param => nil,
        :target_value => nil
    }
    data.merge! payload if payload
    PushNotification.push_notify(
        {:data => data,
         :user_ids => Array(recipient_ids),
         :options => options
        })
  end

end