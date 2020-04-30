require 'net/http'
class FedenaEmailAlertEmailMaker
  attr_accessor :recipients, :message,:subject,:sender,:hostname,:footer,:rtl,:school_id,:other_details
  def initialize(sender,subject,message, recipients,hostname,footer,rtl,others={})
    @recipients = recipients
    @message = message
    @subject=subject
    @sender=sender
    @hostname=hostname
    @footer=footer
    @rtl=rtl
    @other_details=others
    unless @sender.present?
      @sender=Fedena.present_user.email if Fedena.present_user.present?
    end

  end
  def perform
    FedenaEmailer::deliver_emails(@sender,@recipients, @subject, @message,@hostname,@footer,@rtl,@other_details)
  end
end
