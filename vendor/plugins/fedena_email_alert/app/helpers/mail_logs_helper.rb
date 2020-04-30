module MailLogsHelper

  def mail_log_recipient_details (recipient)
    if @mail_log.is_a? ComposedMailLog
      composed_log_recipient_details(recipient)
    elsif @mail_log.is_a? AlertMailLog
      alert_log_recipient_details(recipient)
    end
  end

  def alert_log_recipient_details (recipient)
    content_tag(:tbody, :class => 'group') do
      row =
        content_tag(:tr) do
          html = content_tag(:td, "#{recipient.recipient_name} (#{t(recipient.recipient_type.downcase)})")
          html << content_tag(:td, "#{recipient.mail_id}")
          html << content_tag(:td, "#{log_delivery_status(recipient)}")
          html << (
            content_tag(:td, :class => 'right_text') do
              content_tag(:span, t('show_message'), :class => 'action_link')
            end
          )
        end
      row << (
          content_tag(:tr, :class => 'recipient_message') do
            content_tag(:td, recipient.body, :colspan => '4')
          end
      )
    end
  end

  def composed_log_recipient_details (recipient)
    content_tag(:tbody, :class => 'group') do
      content_tag(:tr) do
        html = content_tag(:td, "#{recipient.recipient_name} (#{t(recipient.recipient_type)})")
        html << content_tag(:td, "#{recipient.mail_id}")
        html << content_tag(:td, "#{log_delivery_status(recipient)}")
      end
    end
  end

  def log_delivery_status (recipient)
    recipient.error.nil? ? t('sent') : content_tag(:span, t('failed'), :tooltip => recipient.error)
  end

  def mail_content
    if @mail_log.is_a? ComposedMailLog
      composed_mail_content
    elsif @mail_log.is_a? AlertMailLog
      alert_mail_content
    end
  end

  def composed_mail_content
    return '' if @mail_log.mail_message.nil?
    html = content_tag(:h2, @mail_log.mail_message.subject, :class => 'message_subject_head')
    html << content_tag(:div, :class=> 'sent_on_tag') do
      content = content_tag(:span, "#{t('sent_on')} : ", :class => 'key_text')
      content << format_date(change_time_to_local_time(@mail_log.created_at), :format=>:long)
    end
    html << content_tag(:div,:class => 'message_content') do
      @mail_log.mail_message.body
    end
    html << content_tag(:div, "#{t('show_message')}", :class => 'message_content_toggle')
    html <<
        content_tag(:div, :class => 'message_attachments') do
          links = ''
          links << content_tag(:div, "#{t('attachments')} : ", :class => 'key_text')

          @mail_log.mail_message.mail_attachments.each do |mail_attachment|
            links << link_to(mail_attachment.attachment_file_name,
                             mail_attachment.attachment.url(:original, false),
                             :class => 'attachment_link', :target => '_blank')
          end
          links
        end if @mail_log.mail_message.mail_attachments.present?
    html
  end

  def alert_mail_content
    html = content_tag(:h2, @mail_log.title_text, :class => 'message_subject_head')
    html << content_tag(:div, :class=> 'sent_on_tag') do
      content = content_tag(:span, "#{t('sent_on')} : ", :class => 'key_text')
      content << format_date(change_time_to_local_time(@mail_log.created_at), :format=>:long)
    end
    html
  end


end