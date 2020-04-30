require 'email_alert/mail_payload'

class MailProcessor

  def initialize (mail_message_id)
    @mail_message_id = mail_message_id
  end

  delegate :subject, :body, :has_template, :mail_recipient_list, :sender, :mail_attachments, :additional_info, :to => :mail_message
  delegate :recipients, :recipient_type, :recipient_ids, :to => :mail_recipient_list

  def process
    # TODO: do in batches for huge recipient lists to reduce memory bloats
    prepare_and_send
  end

  def mail_message
    @mail_message ||= MailMessage.find(@mail_message_id)
  end

  def perform
    process
  end

  private

  def process_and_send
    @processed_recipients = []
    recipients.each do |recipient|
      process_and_send_for_one(recipient)
      @processed_recipients << recipient # TODO : push based on mail response
    end

    log_mail
  end

  def process_and_send_for_one (recipient)

    mail_payload = MailPayload.new(
                   :subject => subject,
                   :body => process_body(recipient),
                   :sender => sender,
                   :recipient => recipient,
                   :footer => footer,
                   :hostname => additional_info.try(:hostname),
                   :mail_type => :composed,
                   :mail_message => mail_message
    )

    mail_payload.send_mail # TODO: handle responses and return appropriately
    recipient
  end

  def process_body (recipient)
    if has_template
      # process template for individual user
    else
      body
    end
  end

  def log_mail
    # make log object if not already present
    # mail logs for all
  end

  def footer
    @footer ||= "#{t('footer', :school_details => sender.school_details)}"
  end


  def t (*args)
    I18n.t(*args)
  end

end