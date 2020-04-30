# Copyright (c) 2010 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the MIT License (http://www.opensource.org/licenses/mit-license.php)

module Oauth2
  module Provider

    class HttpsRequired < StandardError
    end

    module ApplicationControllerMethods

      def self.included(controller_class)
        controller_class.extend(ClassMethods)
        controller_class.alias_method_chain :login_required, :oauth
        controller_class.oauth_allowed
      end
      

      def current_user_id_for_oauth
        current_user.id.to_s
      end

      def login_required_with_oauth

        if FedenaPlugin.can_access_plugin? "fedena_oauth2_provider"

          #handling cross domain requests
          headers['Access-Control-Allow-Origin'] = '*'
          headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
          headers['Access-Control-Request-Method'] = '*'
          headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'

          #for preflight requests
          if request.method == :options            
            render :text => '', :content_type => 'text/plain' and return
          end
          
          if user_id = self.user_id_for_oauth_access_token
            unless @token_status == "expired"
              session[:user_id] = user_id
            else
              response.header["WWW-Authenticate"]="OAuth realm='Fedena api', error='token-expired'"
              render :status=>:unauthorized, :text=>"token-expired"
            end
          elsif looks_like_oauth_request?
            response.header["WWW-Authenticate"]="OAuth realm='Fedena api', error='invalid-token'"
            render :text => "invalid-token", :status => :unauthorized
          elsif oauth_header_present?
            response.header["WWW-Authenticate"]="OAuth realm='Fedena api', error='invalid-request'"
            render :text => "invalid-request", :status => :bad_request
          else
            login_required_without_oauth
          end
        else
          login_required_without_oauth
        end
      end
      
      module ClassMethods
        def oauth_allowed(options = {}, &block)
          raise 'options cannot contain both :only and :except' if options[:only] && options[:except]

          [:only, :except].each do |k|
            if values = options[k]
              options[k] = Array(values).map(&:to_s).to_set
            end
          end
          write_inheritable_attribute(:oauth_options, options)
          write_inheritable_attribute(:oauth_options_proc, block)
        end
      end
      
      protected

      def user_id_for_oauth_access_token
        return nil unless oauth_allowed?

        if looks_like_oauth_request?
          #          raise HttpsRequired.new("HTTPS is required for OAuth Authorizations") unless request.ssl?
          token = OauthToken.find_one(:access_token, oauth_token_from_request_header)
          @token_status = "expired" if (token && token.expired?)
          token.user_id if (token && !token.expired?)          
        end
      end

      def oauth_header_present?
        request.headers["Authorization"].present?
      end
      
      def oauth_token_from_request_header
        if request.headers["Authorization"] =~ /Token token="(.*)"/
          return $1
        end
      end

      def looks_like_oauth_request?
        !!oauth_token_from_request_header
      end

      def oauth_allowed?
        oauth_options_proc = self.class.read_inheritable_attribute(:oauth_options_proc)
        oauth_options = self.class.read_inheritable_attribute(:oauth_options)
        if oauth_options_proc && !oauth_options_proc.call(self)
          false
        else
          return false if oauth_options.nil?
          oauth_options.empty? ||
            (oauth_options[:only] && oauth_options[:only].include?(action_name)) ||
            (oauth_options[:except] && !oauth_options[:except].include?(action_name))
        end
      end

    end
  end
end
