module FedenaEmailAlert
  module EmailAlertOnUpdate

    def self.included(base)
      base.send :before_update,:email_alerts_prepare_on_update
      base.send :after_update,:email_alerts_send_on_update
    end

    private

    # prepares email alerts on update
    def email_alerts_prepare_on_update
      return true unless FedenaPlugin.can_access_plugin?('fedena_email_alert')
      @alert_processor = AlertMailProcessor.new(self, :on=>:update)
      @alert_processor.process_alerts
    end

    # queue the prepared email alerts to be sent
    def email_alerts_send_on_update
      return true unless FedenaPlugin.can_access_plugin?('fedena_email_alert')
      if @alert_processor
        @alert_processor.send_alerts
      end
    end

  end
end