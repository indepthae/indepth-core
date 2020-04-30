class FedenaEmailer < ActionMailer::Base

  def emails(sender,recipients, subject, message,hostname,footer,rtl,other_details)
    begin
      recipient_emails = (recipients.class == String) ? recipients.gsub(' ','').split(',').compact : recipients.compact
      setup_emails(sender, recipient_emails, subject, message,hostname,footer,rtl,other_details)
    rescue Exception => e
      puts e.inspect
    end
  end

  def composed_mail(payload)
    @from = payload.sender.email
    @recipients = payload.recipient_mail_string
    @subject = payload.subject
    @sent_on = Time.now
    @unsubscribe_link = unsubscribe_link(payload)
    setup_composed_mail_content(payload)
  end

  def alert_mail(payload)
    @from = payload.sender || ""
    @recipients = payload.recipient_mail_string
    @subject = payload.subject
    @sent_on = Time.now
    setup_alert_mail_content(payload)
  end

  protected

  def setup_composed_mail_content(payload)
    @body['title'] = payload.subject
    @body['message'] = payload.body
    @body['hostname'] = payload.hostname
    @body['footer'] = payload.footer || footer || ''
    @body['direction'] = payload.direction
    @body['unsubscribe_link'] = unsubscribe_link(payload)
    @body['recipient_user'] = payload.recipient_record
    @content_type = 'multipart/mixed'

    part 'multipart/alternative' do |alternative|

      alternative.part 'text/html' do |html|
        html.body = render_message('composed_mail.html', body)
      end

    end

    if payload.mail_message.mail_attachments
      payload.mail_message.mail_attachments.each do |mail_attachment|
        attachment mail_attachment.attachment.content_type do |a|
          a.body = mail_attachment.attachment.to_file.read
          a.filename = mail_attachment.attachment_file_name
        end
      end
    end

  end

  def setup_alert_mail_content(payload)
    @body['title'] = payload.subject
    @body['message'] = payload.body
    @body['hostname'] = payload.hostname
    @body['footer'] = payload.footer || footer || ''
    @body['direction'] = payload.direction
    @body['unsubscribe_link'] = unsubscribe_link(payload)
    @body['recipient_user'] = payload.recipient_record
    @content_type = 'text/html'
  end

  def setup_emails(sender, emails, subject, message,hostname,footer,rtl,other_details)
    @from = sender
    @bcc = emails
    @subject = subject
    @sent_on = Time.now
    @body['message'] = message
    @body['hostname'] = hostname
    @body['footer']=footer || ""
    @body['rtl']=rtl
    @body['email']=emails
    @body['other_details']=other_details
    @content_type="text/html; charset=utf-8"
  end

  def unsubscribe_link (payload)
    user_record = fetch_user_record(payload)
    return nil if user_record.nil?

    verifier = ActiveSupport::MessageVerifier.new(ActionController::Base.session_options[:secret])
    unsubscribe_key = verifier.generate([user_record.id, user_record.email])
    uri = URI.parse(payload.hostname)
    url_for(:controller => :email_alerts, :action => :unsubscribe, :key => unsubscribe_key, :host => uri.host, :protocol => uri.scheme, :port => uri.port)
  end

  def fetch_user_record (payload)
    return payload.recipient_record if payload.recipient_record.is_a?(User)

    if payload.recipient_type == 'student' || payload.recipient_type == 'employee'
      payload.recipient_record.user
    elsif payload.recipient_type == 'guardian'
      payload.recipient_record.immediate_contact.try(:user)
    end
  end

  
  def footer
    @footer ||= make_footer
  end
  
  def make_footer
    details_hash = Configuration.school_details_hash
    
    line_1 = []
    line_1 << "<b>#{details_hash[:institution_name]}</b>" if details_hash[:institution_name].present?
    line_1 << details_hash[:institution_address] if details_hash[:institution_address].present?
    line_1_content = line_1.present? ? "#{line_1.join(', ')}" : ''
    
    line_2 = []
    line_2 << details_hash[:institution_website] if details_hash[:institution_website].present?
    line_2 << "Ph: #{details_hash[:institution_phone]}" if details_hash[:institution_phone].present?
    line_2_content = line_2.present? ? "#{line_2.join(', ')}" : ''
    
    line_seperator = (line_1_content.present? && line_2_content.present?) ? "<br/>" : ""
    
    [line_1_content, line_2_content].join(line_seperator)
  end

end