module Notifier

  # Helper method to add a notification to +Notification+ model.
  # @param [Array, String] recipient_ids will take an array of user ids to which notification is to be sent.
  #  'all' will send the notification to all users, which can be controlled with +options+ argument
  # @param [String] content of notification
  # @param [String] initiator is the string value denoting the initiating module or class, Eg: 'Attendance', 'News' etc
  # @param [Hash] links optional parameters to pass object details to be used to render hyper links in notification list
  # @option links [String] :target
  # @option links [String] :target_param
  # @option links [String] :target_value
  # @param [Hash] options will contain additional option to control the 'all' recipient ids
  # @option options [Boolean] :no_guardians excludes guardian users from the result of all users
  # @option options [Boolean] :no_employees excludes employees users from the result of all users
  # @option options [Boolean] :no_students excludes students users from the result of all users
  
  def inform (recipient_ids, content, initiator, links={}, options={})
    notification = Notification.new(:content=>content,:initiator=>initiator,:payload=>links)

    if notification.save
      delayed_notification =
          if recipient_ids == 'all'
            options.merge!(:notification_id => notification.id, :send_to_all => true)
            DelayedNotification.new(options)
          else
            DelayedNotification.new(:recipient_ids => recipient_ids, :notification_id => notification.id)
          end
      delayed_notification.send_notification
    end
  end

end