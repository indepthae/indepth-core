module FedenaEmailAlert
  
  # The class is responsible to hold the alert bodies post process
  # This class will have low weight object for each alert body after processing for the model object which triggered
  # the alert. Mostly instance of the class will be queued inside a DJ and upon perform will resolve mail contents like
  # subject, message and footer for individual user and create a list of +MailPayload+ which will then send the mail.
  class AlertMailPayload

    DATA_ATTRS = [:model_name, :model_id, :alert_name, :recipient_ids, :sender_id,
                  :recipient_type, :alert_variables, :mail_logger_id]
    attr_accessor *DATA_ATTRS

    # +model_name+ and +model_id+ of the triggering model object
    # +recipient_ids+ : list of user ids of targeted recipients
    # +alert_name+ : name of alert as from the AlertHead configuration
    # +recipient_type+ : recipient's type from AlertBody
    # +alert_variables+ : model object specific values resolved based on the AlertBody configurations
    def initialize (args)
      DATA_ATTRS.each do |attr|
        instance_variable_set("@#{attr.to_s}", args[attr])
      end
    end

    # make mail payload and send to all recipients and log
    def process
      if recipient_ids == :all_users
        process_for_all_users
      else
        process_by_recipient_ids
      end
    end

    # recipients list based on the recipient_ids
    def recipients
      @recipients ||= User.find_all_by_id(recipient_ids)
    end

    # for DJ
    def perform
      process
    end

    # queue name for DJ
    def job_queue_name
      'email'
    end

    private

    def process_by_recipient_ids
      @sent_recipients = []
      process_for_list(recipients)
    ensure
      mail_logger.finish!
    end

    BATCH_SIZE = 500

    def process_for_all_users
      @sent_recipients = []
      User.active.find_in_batches(:batch_size => BATCH_SIZE, :joins => :student_entry,
                              :select => 'users.id, students.first_name, students.middle_name, students.last_name, students.email, users.student',
                              :conditions => 'users.student = 1 and (students.email is not null or students.email <> "") and students.is_email_enabled = 1') do |batch|
        process_for_list(batch)
      end
      User.active.find_in_batches(:batch_size => BATCH_SIZE, :joins => {:student_entry => :immediate_contact}, :include => {:student_entry => :immediate_contact},
                              :select => 'users.id, guardians.first_name, guardians.last_name, guardians.email, students.immediate_contact_id',
                              :conditions => 'users.student = 1 and students.is_email_enabled = 1 and (guardians.email is not null or guardians.email <> "")') do |batch|
        process_for_list(batch)
      end
      User.active.find_in_batches(:batch_size => BATCH_SIZE, :joins => :employee_entry,
                               :select => 'users.id, employees.first_name, employees.middle_name, employees.last_name, employees.email, users.employee',
                               :conditions => '(employees.email is not null or employees.email <> "")') do |batch|
        process_for_list(batch)
      end
    ensure
      mail_logger.finish!
    end


    def process_for_list (recipient_list)
      recipient_list.each do |recipient|
        next if recipient.email.blank?
        process_and_send_for_one(recipient)
        @sent_recipients << recipient # TODO : push based on mail response
      end
    end

    # process mail payload and send for individual recipient
    def process_and_send_for_one (recipient)
      mail_payload = MailPayload.new(
          :subject => subject(recipient),
          :body => message(recipient),
          :recipient_record => recipient,
          :recipient_type => (recipient_type == 'parent' ? 'guardian' : recipient_type),
          :sender => User.find_by_id(sender_id),
          :hostname => Fedena.hostname,
          :mail_type => :alert,
          :alert_name => alert_name,
          :mail_logger => mail_logger
      )
      mail_payload.send_mail # TODO: handle response
      recipient
    end

    # resolve mail subject text based on the alert configuration and alert_variables
    def subject (recipient)
      subject_variables = alert_variables[:subject].dup
      subject_variables.merge!(recipient_details(recipient))
      subject = "#{I18n.t("#{recipient_type.to_s}_subject_#{alert_name.to_s}", subject_variables)}"
      subject
    end

    # resolve mail message text based on the alert configuration and alert_variables and recipient details
    def message (recipient)
      message_variables = alert_variables[:message].dup
      message_variables.merge!(recipient_details(recipient))
      message = "#{I18n.t("#{recipient_type.to_s}_#{alert_name.to_s}", message_variables)}"
      message = process_message_hyperlinks(message)
      message
    end

    def process_message_hyperlinks (message)
      message_variables = alert_variables[:message].dup
      if message.include?('RECEIPT_LINK')
        link = "#{Fedena.hostname}/finance/generate_fee_receipt_pdf?transaction_id=#{message_variables[:id]}"
        message.gsub!("RECEIPT_LINK","<a href='#{link}'>#{I18n.t('click_here_to_view_receipt')}</a>")
      end

      if message.include?("FEE_LINK")
        message.gsub!("FEE_LINK","<a href='#{Fedena.hostname}/student/fee_details/#{message_variables[:student_id]}/#{message_variables[:finance_fee_collection_id]}'>#{I18n.t('click_here_to_view_fee')}</a>")
      end
      message.gsub!("URL","#{Fedena.hostname}")
      message
    end

    # recipient details based on the configuration +:stud_name+ Proc and user instance
    def recipient_details (user)
      details = {:recipient_name => user.first_name}
      details.merge!(:student_name => alert_variables[:student_name][user.email]) if alert_variables[:student_name]
      details
    end

    def mail_logger
      @mail_logger ||= MailLogger.get(mail_logger_id)
    end
    

  end
  
end