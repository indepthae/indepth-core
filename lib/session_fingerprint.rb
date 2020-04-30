# prevents forms and pages from being processed more than once.
# needs memcache for working.
# check_request_fingerprint *actions - will keep a finger print check for the action, looks for a fingerprint in params,
# if fingerprint already seen it will raise SessionFingerprint::DuplicateRequestFingerprint exception
# a helper session_fingerprint will give you new fingerprint generated for the request.
# a helper session_fingerprint_field will render a hidden input field with current fingerprint value.
# The validate_fingerprint function always ensures that incoming fingerprint should be 16 digit integer.

module SessionFingerprint

  mattr_accessor :fingerprint

  def self.timestamp
    pid=Process.pid
    t = Time.now
    'f' + '%010d' % t.to_i + '%06d' % t.usec + '%07d' % pid
  end

  def self.generate_session_fingerprint!
    @@fingerprint = timestamp
  end

  def self.memcache_on?
    Rails.cache.is_a? ActiveSupport::Cache::MemCacheStore
  end

  class DuplicateRequestFingerprint < StandardError
  end

  class RequestFingerprint

    cattr_accessor :cache

    @@cache = Rails.cache

    def self.create_fingerprint (fingerprint)
      fingerprint_exist! (fingerprint)
      @@cache.write(cache_key(fingerprint), 1, :expires_in => 5.minutes)
    end

    def self.fingerprint_exist! (fingerprint)
      if @@cache.exist?(cache_key(fingerprint)) or invalid_fingerprint?(fingerprint)
        raise DuplicateRequestFingerprint
      else
        false
      end
    end

    def self.invalid_fingerprint? (fingerprint)
      (fingerprint =~ /^f\d{23}$/).nil?
    end

    def self.cache_key (fingerprint)
      'session_fingerprint/'+fingerprint.to_s
    end

  end

  module ControllerExtensions

    def self.included (base)
      base.instance_eval do
        extend ClassMethods
        include InstanceMethods

        helper_method :session_fingerprint
        before_filter :make_new_fingerprint
      end
    end

    module ClassMethods
      def check_request_fingerprint (*actions)     
        if SessionFingerprint.memcache_on?
          found_filter = filter_chain.find(:save_session_fingerprint)
          if found_filter
            found_filter.options[:only].merge(actions.map { |x| x.to_s })
          else
            before_filter :save_session_fingerprint, :only => actions
          end
          filter_chain
        end
      end
    end

    module InstanceMethods
      def save_session_fingerprint
        if params && params[:session_fingerprint]
          RequestFingerprint.create_fingerprint(params[:session_fingerprint])
        end
      end
      private :save_session_fingerprint

      def make_new_fingerprint
        SessionFingerprint.generate_session_fingerprint!
      end
      private :make_new_fingerprint

      def session_fingerprint (reset=false)
        make_new_fingerprint if reset
        SessionFingerprint.fingerprint
      end

      def session_fingerprint_field (reset = false)
        hidden_field_tag :session_fingerprint, session_fingerprint(reset)
      end

    end

  end

end

ActionController::Base.send :include, SessionFingerprint::ControllerExtensions