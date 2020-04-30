# Copyright (c) 2010 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the MIT License (http://www.opensource.org/licenses/mit-license.php)

class OauthAuthorizeController < ::ApiController

#  include Oauth2::Provider::SslHelper
  include Oauth2::Provider::TransactionHelper
  
  transaction_actions :authorize
  
  def index
    return unless validate_params
  end

  def authorize
    return unless validate_params

    unless params[:authorize] == 'Yes'
      redirect_to "#{params[:redirect_uri]}?error=access-denied"
      return
    end if request.post?

    authorization = @client.create_authorization_for_user_id(current_user_id_for_oauth)
    state_param = if params[:state].blank?
      ""
    else
      "&state=#{CGI.escape(params[:state])}"
    end

    redirect_to "#{params[:redirect_uri]}?code=#{authorization.code}&expires_in=#{authorization.expires_in}#{state_param}"
  end

  private

  # TODO: support 'code', 'token', 'code-and-token'
  VALID_RESPONSE_TYPES = ['code']
  def check_access_token
    
  end
  
  def validate_params
    if params[:client_id].blank? || params[:response_type].blank?
      redirect_to "#{params[:redirect_uri]}?error=invalid-request"
      return false
    end

    unless VALID_RESPONSE_TYPES.include?(params[:response_type])
      redirect_to "#{params[:redirect_uri]}?error=unsupported-response-type"
      return
    end

    if params[:redirect_uri].blank?
      render :text => "You did not specify the 'redirect_uri' parameter!", :status => :bad_request
      return false
    end

    @client = Oauth2::Provider::OauthClient.find_by_client_id(params[:client_id])
    tokens = Oauth2::Provider::OauthToken.find_all_with(:user_id, current_user_id_for_oauth).select{|token| token.oauth_client_id == @client.id.to_s}

    
    if @client.nil?
      redirect_to "#{params[:redirect_uri]}?error=invalid-client-id"
      return false
    end

    if @client.redirect_uri != params[:redirect_uri]
      redirect_to "#{params[:redirect_uri]}?error=redirect-uri-mismatch"
      return false
    end

    if tokens.blank? and request.get?
      render 'index'
      return
    end
    
    true
  end

  def login_required
    if current_user.nil?
      session[:back_url] = request.url
      redirect_to '/'
    end
  end

end
