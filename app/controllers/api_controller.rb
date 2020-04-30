class ApiController < ActionController::Base
  require 'rexml/parseexception'
  include FeatureLock
  before_filter :login_required
  include ApplicationDefaultVariables

  def login_required
    if current_user.nil?
      response.header["WWW-Authenticate"]="OAuth realm='Fedena api'"
      render :status => :unauthorized, :text=>'invalid-request'
    else
      FedenaPrecision.set_precision_count
    end
  end

  def current_user
    @current_user ||= User.find_by_id session[:user_id]
  end
  
  def academic_year
    @academic_year = if params[:academic_year]
      AcademicYear.find_by_name(params[:academic_year]).try(:id)
    else
      AcademicYear.active.first.try(:id)
    end
  end

  if Rails.env.production?
    rescue_from ActiveRecord::RecordNotFound do |exception|
      @xml = Builder::XmlMarkup.new
      logger.info "[FedenaRescue] AR-Record_Not_Found #{exception.to_s}"
      log_error exception
      render "single_access_tokens/500.xml", :status => 500  and return
    end

    rescue_from REXML::ParseException do |exception|
      @xml = Builder::XmlMarkup.new
      logger.info "[FedenaRescue] Malformed XML Error #{exception.to_s}"
      log_error exception
      render "single_access_tokens/500.xml", :status => 500  and return
    end
    
    rescue_from NoMethodError do |exception|
      @xml = Builder::XmlMarkup.new
      logger.info "[FedenaRescue] No method error #{exception.to_s}"
      log_error exception
      render "single_access_tokens/500.xml"  and return
    end

    rescue_from ActionController::InvalidAuthenticityToken do|exception|
      @xml = Builder::XmlMarkup.new
      logger.info "[FedenaRescue] Invalid Authenticity Token #{exception.to_s}"
      log_error exception
      render "single_access_tokens/500.xml"  and return
    end

    rescue_from Searchlogic::Search::UnknownConditionError do|exception|
      @xml = Builder::XmlMarkup.new
      logger.info "[FedenaRescue] Unknow Condition Error #{exception.to_s}"
      log_error exception
      render "single_access_tokens/500.xml"  and return
    end
  end

end
