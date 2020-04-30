class MultiSchoolController < ActionController::Base
  helper :all
  helper_method :admin_user_session
  helper_method :saas?
  protect_from_forgery # :secret => '434571160a81b5595319c859d32060c1'
  filter_parameter_logging :password
  before_filter :require_admin_session
  before_filter :set_current_admin_user
  before_filter :set_locales

  def self.inherited(base)
    super
    base.send :layout, :select_layout
  end

  def user_dashboard
    if admin_user_session.class.to_s == "MultiSchoolAdmin"
     if admin_user_session.school_stats_accessable?
       return school_statistics_live_path
     else
       return schools_path
     end
    end
  end

  def select_layout
    return "schools" if (action_name == "login" or action_name == "forgot_password" or action_name == "set_new_password")
    return "multi_school" if admin_user_session.class.to_s == "MultiSchoolAdmin"
  end

  def admin_user_session

    @admin_user_session ||= case MultiSchool.current_school_group.class.to_s
    when "MultiSchoolGroup"
      AdminUser.find_by_id_and_is_deleted(session[:admin_user],false, :conditions=>{:school_group_users=>{:school_group_id=>MultiSchool.current_school_group.id}},:joins=>:school_group_user)
    else
      AdminUser.find_by_id_and_is_deleted(session[:admin_user],false)
    end
  end

  def school_group_session
    unless session[:current_school_group].blank?
      current_group = SchoolGroup.find_by_id(session[:current_school_group])
      return nil if current_group.blank?
      current_group
    else
      nil
    end
  end

  def require_admin_session
    redirect_to login_admin_users_url and return if admin_user_session.nil?
  end

  def permission_denied
    if request.xhr?
      render :text=>"<label> You are not allowed to view the requested page. <label>"
    else
      flash[:notice] = "You are not allowed to view the requested page."
      redirect_to user_dashboard
    end
  end

  def current_user
    admin_user_session
  end

  def set_current_admin_user
    Authorization.current_user= admin_user_session
  end

  def set_locales
    I18n.locale = :en
  end

  if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound do |exception|
      flash[:notice] = "The record is not found."
      logger.info "[FedenaRescue] AR-Record_Not_Found #{exception.to_s}"
      log_error exception
      redirect_to :controller=>:admin_users ,:action=>:dashboard
    end

    rescue_from ActionController::UnknownAction do |exception|
      flash[:notice] = "Unknown Action."
      logger.info "[FedenaRescue] Unknown Action #{exception.to_s}"
      log_error exception
      redirect_to :controller=>:admin_users ,:action=>:dashboard
    end

    rescue_from NoMethodError do |exception|
      flash[:notice] = "Some error occured, please contact the support."
      logger.info "[FedenaRescue] No method error #{exception.to_s}"
      log_error exception
      redirect_to :controller=>:admin_users ,:action=>:dashboard
    end

    rescue_from ActionController::InvalidAuthenticityToken do|exception|
      flash[:notice] = "Authentication not valid"
      logger.info "[FedenaRescue] Invalid Authenticity Token #{exception.to_s}"
      log_error exception
      if request.xhr?
        render(:update) do|page|
          page.redirect_to :controller => 'admin_users', :action => 'dashboard'
        end
      else
        redirect_to :controller => 'admin_users', :action => 'dashboard'
      end
    end
  end

  def saas?
    (ActsAsSaas rescue false) ? true : false
  end

end
