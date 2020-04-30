module TransportReportsHelper
  
  def error_message_box(error_msg)
    "<div class='wrapper'><div class='error-icon'></div><div class='error-msg'>#{error_msg}</div></div>" if error_msg.present?
  end
end
