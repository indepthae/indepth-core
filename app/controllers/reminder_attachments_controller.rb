class ReminderAttachmentsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  def download
    reminder_attachment=ReminderAttachment.find(params[:id])
    send_file reminder_attachment.attachment.path, :type => reminder_attachment.attachment_content_type, :disposition => 'inline'
  end
end
