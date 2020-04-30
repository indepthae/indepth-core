class ComposedMailLog < MailLog

  MAX_RECIPIENTS_COUNT_PER_LIST = 100

  belongs_to :mail_message
  
  def title_text
    subject
  end
  
end