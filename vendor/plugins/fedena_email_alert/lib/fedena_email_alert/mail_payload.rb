module FedenaEmailAlert
  
  class MailPayload

    MANDATORY_FIELDS = [:subject, :body, :recipient_record, :recipient_type,
                        :hostname, :mail_type]

    attr_reader *MANDATORY_FIELDS
    attr_reader :recipient_name, :recipient_mail_id, :sender, :footer,
                :mail_message, :direction, :alert_name, :mail_logger

    # @option [Symbol] mail_type
    # @option [String] recipient_name
    # @option [String] recipient_mail_id
    # @option [String] subject
    # @option [String] body
    # @option [String] footer
    # @option [Student, Employee] recipient_record
    # @option [String] recipient_type
    # @option [MailMessage] mail_message
    # @option [String] alert_name
    # @option [User] sender
    # @option [MailLogger] mail_logger
    # @option [String] direction
    def initialize (args)
      args = args.with_indifferent_access
      MANDATORY_FIELDS.each do |field|
        args[field].present? ? instance_variable_set("@#{field}", args[field]) : raise(ArgumentError, "value needed for #{field}")
      end

      @recipient_name = args[:recipient_name] || @recipient_record.full_name
      @recipient_mail_id = args[:recipient_mail_id] || @recipient_record.email
      @sender = args[:sender] || ""
      @mail_type = args[:mail_type] || :composed
      @mail_message = args[:mail_message] || raise(ArgumentError, "value needed for mail_message") if @mail_type == :composed
      @mail_name = args[:alert_name] || raise(ArgumentError, "value needed for alert_name") if @mail_type == :alert
      @mail_logger = args[:mail_logger]
      @direction = args[:direction] || 'ltr'
    end


    def send_mail
      if mail_type == :composed
        deliver_composed_mail
      elsif mail_type == :alert
        deliver_alert_mail
      end
    end

    def recipient_mail_string
      "#{recipient_name} <#{recipient_mail_id}>"
    end

    private

    def deliver_composed_mail
      if email_subscribed
        FedenaEmailer.deliver_composed_mail(self)
      end
    rescue => exception
      @error = exception.message
    ensure
      log_delivery(
          :recipient_record => recipient_record,
          :mail_id => recipient_mail_id,
          :recipient_name => recipient_name,
          :recipient_type => recipient_type,
          :error => @error
      )
    end

    def deliver_alert_mail
      if email_subscribed
        FedenaEmailer.deliver_alert_mail(self)
      end
    rescue => exception
      @error = exception.message
    ensure
      log_delivery(
          :recipient_record => recipient_record,
          :mail_id => recipient_mail_id,
          :recipient_name => recipient_name,
          :body => body,
          :subject => subject,
          :error => @error
      )
    end

    def email_subscribed
      user_id = recipient_record.is_a?(User) ? recipient_record.id : recipient_record.user_id
      subscribed = !EmailSubscription.exists?(:email => recipient_mail_id, :user_id => user_id)
      @error = 'unsubscribed' unless subscribed
      subscribed
    end

    def log_delivery(args)
      mail_logger.log_delivery!(args) if mail_logger
    end

    def logger
      @logger ||= Logger.new('log/mails.log')
    end

    def write_error (e)
      e.backtrace.each {|x| logger.info(x)}
    end

  end
  
end
