require 'ostruct'

class MailLogRecipientList < ActiveRecord::Base
  
  belongs_to :mail_log
  
  serialize :recipients, Array

  def increment_recipient_count
    self.recipients_count ||= 0
    self.recipients_count += 1
  end

  def add_recipient (args)
    if args[:recipient_record]
      args[:recipient_record_id] = args[:recipient_record].id
      args[:recipient_record_type] = args[:recipient_record].class.to_s
    end

    recipients <<
      if mail_log.is_a? ComposedMailLog
        add_recipient_for_composed_mail(args)
      else
        add_recipient_for_alert_mail(args)
      end

    increment_recipient_count
  end

  private

  def add_recipient_for_composed_mail (args)
    recipient = OpenStruct.new
    [:recipient_record_id, :recipient_record_type , :mail_id, :recipient_name, :recipient_type, :error].each do |key|
      recipient.send("#{key}=", args[key])
    end
    recipient
  end

  def add_recipient_for_alert_mail (args)
    recipient = OpenStruct.new
    [:recipient_record_id, :recipient_record_type, :mail_id, :recipient_name, :body, :subject, :error].each do |key|
      recipient.send("#{key}=", args[key])
    end
    recipient.recipient_type = args[:recipient_record].try(:user_type)
    recipient
  end

end