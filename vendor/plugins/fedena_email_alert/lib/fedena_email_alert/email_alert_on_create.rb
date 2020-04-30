module FedenaEmailAlert
  module EmailAlertOnCreate

    def self.included(base)
      base.send :after_create, :email_alerts_prepare_on_create
    end

    private

    # prepares and queues email alerts on create
    def email_alerts_prepare_on_create
      return true unless FedenaPlugin.can_access_plugin?('fedena_email_alert')
      @email_alert_processor = AlertMailProcessor.new(self)
      @email_alert_processor.process_alerts
      @email_alert_processor.send_alerts
    end

  end
end
