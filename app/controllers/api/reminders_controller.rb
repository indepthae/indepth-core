class Api::RemindersController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @reminders = Reminder.search(:to_user_username_equals=>@current_user.username).scoped(:conditions => ["DATE(reminders.created_at)='#{params[:created_at]}'"]).all
    respond_to do |format|
      unless  @current_user.present? and params[:created_at].present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :reminders }
      end
    end
  end

  def create
    @xml = Builder::XmlMarkup.new
    @reminder = Reminder.new
    @reminder.user = @current_user
    @reminder.to_user = User.first(:conditions => ["username LIKE BINARY(?)",params[:receiver]])
    @reminder.subject = params[:subject]
    @reminder.body = params[:body]
    respond_to do |format|
      if @reminder.save
        format.xml  { render :reminder, :status => :created }
      else
        format.xml  { render :xml => @reminder.errors, :status => :unprocessable_entity }
      end
    end
  end
end
