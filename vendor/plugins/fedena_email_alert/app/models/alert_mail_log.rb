class AlertMailLog < MailLog

  MAX_RECIPIENTS_COUNT_PER_LIST = 50

  belongs_to :alert_record, :polymorphic => true
  
  def title_text
    key = 'mail_logs.' + alert_event.to_s
    "#{I18n.t(key)}"
  end
  
end