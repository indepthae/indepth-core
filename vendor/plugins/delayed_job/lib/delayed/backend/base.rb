module Delayed
  module Backend
    module Base
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Add a job to the queue
        def enqueue(*args)
          object = args.shift
          options = args.extract_options!

          unless object.respond_to?(:perform)
            raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
          end

          object.instance_variable_set(:@_hostname,Fedena.hostname)
          object.instance_variable_set(:@_locale,options[:locale]) if options[:locale]
          object.instance_variable_set(:@_hostname,options[:hostname]) if options[:hostname]
          object.instance_variable_set(:@_current_user_id,options[:current_user_id]) if options[:current_user_id]

          priority = args.first || Delayed::Worker.default_priority
          run_at   = args[1] || (object.respond_to?(:job_run_at) ? object.job_run_at : nil)
          queue   = options[:queue] || (object.respond_to?(:job_queue_name) ? object.job_queue_name : nil)
          self.create(:payload_object => object, :priority => priority.to_i, :run_at => run_at, :queue => queue)
        end

        def reserve(worker, max_run_time = Worker.max_run_time)
          # We get up to 5 jobs from the db. In case we cannot get exclusive access to a job we try the next.
          # this leads to a more even distribution of jobs across the worker processes
          find_available(worker.name, 5, max_run_time).detect do |job|
            job.lock_exclusively!(max_run_time, worker.name)
          end
        end

        # Hook method that is called before a new worker is forked
        def before_fork
        end

        # Hook method that is called after a new worker is forked
        def after_fork
        end

        def work_off(num = 100)
          warn "[DEPRECATION] `Delayed::Job.work_off` is deprecated. Use `Delayed::Worker.new.work_off instead."
          Delayed::Worker.new.work_off(num)
        end

        def get_all
          all
        end

      end

      ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

      def failed?
        failed_at
      end
      alias_method :failed, :failed?

      def name
        @name ||= begin
          payload = payload_object
          if payload.respond_to?(:display_name)
            payload.display_name
          else
            payload.class.name
          end
        end
      end

      def payload_object=(object)
        self['handler'] = object.to_yaml
      end

      def payload_object
        @payload_object ||= deserialize(self['handler'])
      end

      # Moved into its own method so that new_relic can trace it.
      def invoke_job
        with_locale do
          payload_object.perform
        end
      end

      # Unlock this job (note: not saved to DB)
      def unlock
        self.locked_at    = nil
        self.locked_by    = nil
      end

      def reschedule_at
        payload_object.respond_to?(:reschedule_at) ?
          payload_object.reschedule_at(self.class.db_time_now, attempts) :
          self.class.db_time_now + (attempts ** 4) + 5
      end

      def max_attempts
        payload_object.max_attempts if payload_object.respond_to?(:max_attempts)
      end

      private

      def with_locale &block
        if(::MultiSchool rescue false)
          school_id = payload_object.instance_variable_get(:@school_id) || (payload_object.respond_to?(:school_id) && payload_object.school_id)
          if(school_id)
            ::MultiSchool.current_school = School.find school_id
            set_locale
            set_translate_options
          end
        else
          set_locale
          set_translate_options
        end
        if current_user_id = payload_object.instance_variable_get(:@_current_user_id)
          Authorization.current_user = User.find_by_id current_user_id
        end
        yield block
      ensure
        ::ActiveRecord::Base.clean_date_format
        Authorization.current_user = nil
        ::MultiSchool.current_school = nil if(::MultiSchool rescue false)
        reset_locale
        unassign_translate_options
      end

      def set_locale
        reset_locale
        if locale = payload_object.instance_variable_get(:@_locale)
          I18n.locale = locale
          locale_key = locale.to_sym
        else
          lan = Configuration.find_by_config_key("Locale")
          FedenaPrecision.set_precision_count
          institution_type = "ch"
          if lan
            I18n.locale = "#{lan.config_value}-#{institution_type}" 
            locale_key = lan.config_value.to_sym
          end
        end
        Fedena.hostname = payload_object.instance_variable_get(:@_hostname) || ''
        Fedena.rtl = RTL_LANGUAGES.include? locale_key
      end

      def reset_locale
        I18n.default_locale = :en
        I18n.locale = :en
        Fedena.hostname = ''
        Fedena.rtl = false
      end
      
      def set_translate_options
        unassign_translate_options
        CustomTranslation.translate_options ||= CustomTranslation.store_cache
      end
  
      def unassign_translate_options
        CustomTranslation.translate_options = nil
      end
  

      def deserialize(source)
        handler = YAML.load(source) rescue nil

        unless handler.respond_to?(:perform)
          if handler.nil? && source =~ ParseObjectFromYaml
            handler_class = $1
          end
          attempt_to_load(handler_class || handler.class)
          handler = YAML.load(source)
        end

        return handler if handler.respond_to?(:perform)

        raise DeserializationError,
          'Job failed to load: Unknown handler. Try to manually require the appropriate file.'
      rescue TypeError, LoadError, NameError, ArgumentError => e
        raise DeserializationError,
          "Job failed to load: #{e.message}. Try to manually require the required file."
      end

      # Constantize the object so that ActiveSupport can attempt
      # its auto loading magic. Will raise LoadError if not successful.
      def attempt_to_load(klass)
        klass.constantize
      end

      protected

      def set_default_run_at
        self.run_at ||= self.class.db_time_now
      end

    end
  end
end
