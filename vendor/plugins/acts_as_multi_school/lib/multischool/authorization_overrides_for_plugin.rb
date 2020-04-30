module MultiSchool
  module AuthorizationOverrides

    def self.attach_overrides
      ApplicationController.send :include, MultiSchool::AuthorizationOverrides::InController
    end
    
    module InController

      def self.included(base)
        base.alias_method_chain :can_access_request?, :multi_school
        base.hide_action :can_access_request!, :can_access_request?
        base.alias_method_chain :can_access_feature?, :multi_school
        base.before_filter :plugin_access_control
      end


      def can_access_request_with_multi_school? (privilege, object_or_sym = nil, options = {}, &block)
        controller = object_or_sym.nil? ? options[:context] : (object_or_sym.is_a?(Symbol) ? object_or_sym : options[:context])
        can_access_request!(privilege,controller,true) and permitted_to?(privilege, object_or_sym, options, &block)
      end

      def can_access_request! (action,controller,silent=false)
        allowed_plugins = MultiSchool.current_school ? MultiSchool.current_school.available_plugins : []
        if silent
          authorization_engine.school_can_access?(controller,action,allowed_plugins)
        else
          authorization_engine.school_can_access!(controller,action,allowed_plugins)
        end
      end
      def can_access_feature_with_multi_school? (feature)
        if Feature.find_by_feature_key(feature).try(:is_enabled)==false
          return false
        else
          file=File.join(RAILS_ROOT,"vendor","plugins","acts_as_multi_school","config","multischool_feature_enabled.yml")
          if File.exists?(file)
            schools=YAML::load(File.open(file))
            feature_present=schools["features"][feature].split(",") & MultiSchool.current_school.school_domains.collect(&:domain)
            if feature_present.blank?
              return false
            else
              return true
            end
          else
            return true
          end
        end
      end
      
      private
      
      def plugin_access_control
        begin
          allowed = can_access_request! action_name, controller_name
        rescue Authorization::NotAuthorized => e
          exception_msg = e
        end
        unless allowed
          logger.info "Permission Denied: #{exception_msg}"
          if respond_to?(:permission_denied)
            send(:permission_denied)
          else
            send(:render, :text => "You are not allowed to access this action.",
              :status => :forbidden)
          end
        end
      end

    end

  end
end
