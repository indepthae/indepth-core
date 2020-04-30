module FedenaEmailAlert

  # This class processes the alert mails for an event
  # Will use the event source object and the Alert bodies to prepare the alert mails
  # generates AlertMailPayload object and queues to DJ
  class AlertMailProcessor

    attr_reader :event_object, :model_event, :mail_logger, :email_alert

    # +even_object+ is the model object which is source of the alert event
    def initialize (event_object, options = {})
      @model_event = options[:on] || :create
      @event_object = event_object
    end

    # prepare alerts based on the +event_object+ state (new or update) and alert configurations
    # makes a list of MailAlertPayload and queues in DJ
    def process_alerts
      @email_alert = get_email_alert
      return unless email_alert

      initialize_mail_log

      @payload_collection = AlertMailPayloadCollection.new
      email_alert.mail_to.each do |alert_body|
        next unless alert_mail_recipient_types.include? alert_body.recipient
        alert_payload = prepare_alert_payload(alert_body)
        @payload_collection << alert_payload if alert_payload
      end
    end

    # queues the prepared mail payloads to be sent later
    def send_alerts
      return unless email_alert
      # @payload_collection.each do |alert_payload|
      #   Delayed::Job.enqueue(alert_payload)
      # end
      Delayed::Job.enqueue(@payload_collection)
    end

    private

    # fetches the applicable alerts from configuration
    def get_email_alert
      ((model_event == :create) ? email_alert_for_model_on_create : email_alert_for_model_on_update)
    end

    # prepare a mail alert data
    # returns a +MailAlertPayload+ object
    def prepare_alert_payload (alert_body)
      alert_recipients = get_alert_recipients_list(alert_body)

      return nil if alert_recipients.blank?

      mail_alert_payload = AlertMailPayload.new(
          :alert_name => email_alert.name,
          :model_name => email_alert.model,
          :model_id => event_object.id,
          :recipient_type => alert_body.recipient,
          :mail_logger_id => mail_logger.id,
          :sender_id => Fedena.present_user.try(:id)
      )

      mail_alert_payload.recipient_ids = alert_recipients
      mail_alert_payload.alert_variables = prepare_alert_variables(alert_body)
      mail_alert_payload
    end

    # prepare the variables needed for each alert mail from the event_object
    def prepare_alert_variables (alert_body)
      alert_variables = {}
      alert_variables[:message] = resolve_for_model_object(alert_body.message)
      alert_variables[:subject] = resolve_for_model_object(alert_body.subject)

      # the alert data settings ':footer' does not have any significance any more
      alert_variables[:footer] = {}
      alert_variables[:student_name] = alert_body.stud_name ? event_object_eval(alert_body.stud_name) : nil
      alert_variables
    end

    # fetches the recipient user list for alert_body
    def get_alert_recipients_list (alert_body)
      if alert_body.to == :all_users
        :all_users
      elsif alert_body.to.is_a? Proc
        Array(event_object_eval(alert_body.to)).uniq.compact.select{|user| user.email.present?}.collect(&:id)
      end
    end

    # fetches the applicable alerts based on the configuration for update
    def email_alert_for_model_on_update
      return nil unless plugin_accessible?

      alerts_for_model = email_alerts_for_model
      # TODO: refactor below find
      # The update body is not well designed currently, the keys ':fields' seems like bad design.
      #   Moreover the hook ':after_update' is unused
      alert = alerts_for_model.find do |alert_body|
        (alert_body.fields.nil? or event_object_eval(alert_body.fields) == 'mail_value' or event_object_eval(alert_body.fields)) and
            (alert_body.modifications.present? ? event_object_eval(alert_body.modifications) : false) and
            EmailAlert.active.model_has_alert(alert_body.name.to_s)
      end

      alert
    end

    # fetches the applicable alerts based on the configuration for create
    def email_alert_for_model_on_create
      return nil unless plugin_accessible?

      alerts_for_model = email_alerts_for_model
      alert = alerts_for_model.find do |alert_body|
        (alert_body.conditions.nil? or event_object_eval(alert_body.conditions) and alert_body.hook == :after_create) and
            EmailAlert.active.model_has_alert(alert_body.name.to_s)
      end

      alert
    end

    # fetch allowed recipient types based on email settings
    def alert_mail_recipient_types
      @alert_mail_recipient_types ||= EmailAlert.active.model_name_eq(@email_alert.name.to_s).first.mail_to
    end

    # resolves the properties for the current model object and returns the values as a hash
    def resolve_for_model_object (properties)
      properties_hash = {}
      properties.each do |property|
        val = event_object_eval(property)
        val = (val.is_a?(Date) || val.is_a?(DateTime)) ? format_date(val,:long) : val
        properties_hash.merge!( property.gsub(".","_").to_sym=>"#{val}")
      end
      return properties_hash
    end

    # helper to evaluate inside the model object instance
    def event_object_eval (arg)
      arg.is_a?(Proc) ? event_object.instance_eval(&arg) : event_object.instance_eval(arg)
    end

    # fetches all applicable email alert bodies for this model
    def email_alerts_for_model
      FedenaEmailAlert.alert_bodies.find_all_by_model(event_object.class.name.underscore.to_sym)
    end

    # helper to check if the plugin is accessible
    def plugin_accessible?
      FedenaPlugin.can_access_plugin?('fedena_email_alert')
    end

    def initialize_mail_log
      @mail_logger = MailLogger.make(
        'alert',
        :alert_event => email_alert.name.to_s,
        :alert_record => event_object   
      )
    end

  end

end