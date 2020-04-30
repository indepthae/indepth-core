class MailLogsController < ApplicationController

  before_filter :login_required
  filter_access_to :index, :show

  def index    
    get_email_logs
    if request.xhr?
      render :update do |page|
        if params[:page]=="1"
          page.replace_html "message_list", :partial => "email_logs"
        else
          page.insert_html :bottom, "message_list", :partial => "email_logs"
        end        
      end
    end
  end

  def show
    @mail_log = MailLog.find(params[:id])
    @recipient_log =
        @mail_log.mail_log_recipient_lists.paginate(:per_page => 1, :page => (params[:page] || 1)).first
    @recipient_logs = @recipient_log.present? ? @recipient_log.recipients : []
    if params[:paginate]
      unless @recipient_logs.empty?
        render(:update) {|page| page.insert_html :bottom, :recipient_logs, :partial => 'recipient_logs'}
      else
        render :text => 'no_content', :status => 404
      end
    else
      render(:update) {|page| page.replace_html :logs, :partial => 'show'}
    end
  end

  private

  def get_email_logs
    start_date = params[:start_date] || (Date.today - 1.months)
    end_date = params[:end_date] || Date.today 
    
    @mail_logs =
      unless request.xhr?
        ComposedMailLog.logs_between(start_date, end_date).
          paginate(:page => 1, :per_page => 15, :order => 'id desc')
      else
        if params[:type].nil? or params[:type] == 'composed'
          ComposedMailLog.logs_between(start_date, end_date).
            paginate(:page => params[:page], :per_page => 15, :order => 'id desc')
        elsif params[:type] == 'alerts'
          AlertMailLog.logs_between(start_date, end_date).
            paginate(:page => params[:page], :per_page => 15, :order => 'id desc')      
        end
      end  

  end

end