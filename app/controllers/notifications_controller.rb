class NotificationsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    mark_read
    unless params[:filter].blank?
      @filter = params[:filter]
      @notifications = Notification.apply_filter(params[:filter]).paginate(:page => params[:page], :per_page => 10)
    else
      @notifications = @current_user.notifications.paginate(:page => params[:page], :per_page => 10)
    end
    @filters = Notification.get_filters
    respond_to do |format|
      format.html {}
      format.js { render :action => 'scroll_update' }
    end
  end
  
  def show_notification_box
    render :update do |page|
      page.replace_html 'notification_cont', :partial => 'layouts/notifications', :locals => {:notification_count => @current_user.unread_notifications_count}
    end
  end
  
  def apply_filter
    @filter = params[:filter]
    @filters = Notification.get_filters
    @notifications = Notification.apply_filter(params[:filter]).paginate(:page => params[:page], :per_page => 10)
    render :action => 'notification_update'
  end
  
  def mark_notification_read
    mark_read
    render :text=>'success'
  end
  
  private
  
  def mark_read
    NotificationRecipient.update_all("is_read = true",['recipient_id = ?  and is_read = ?', @current_user.id,false])
  end
end