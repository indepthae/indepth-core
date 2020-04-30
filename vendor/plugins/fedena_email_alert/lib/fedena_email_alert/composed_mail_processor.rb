module FedenaEmailAlert

  class ComposedMailProcessor

    attr_reader :mail_logger
    
    delegate :subject, :body, :has_template, :mail_recipient_list, :sender, :mail_attachments, :additional_info, :to => :mail_message
    delegate :recipients, :recipient_type, :recipient_ids, :to => :mail_recipient_list

    def initialize (mail_message_id)
      @mail_message_id = mail_message_id
    end

    def process
      if recipient_type == 'all_users'
        process_for_all_users
      else
        process_for_selected_users
      end
    end

    def mail_message
      @mail_message ||= MailMessage.find(@mail_message_id)
    end

    def perform
      process
    end

    private

    BATCH_SIZE = 500

    def processed_recipients (mail_recipient_type)
      case mail_recipient_type
      when 'student', 'employee'
        recipient_model.find_in_batches(:batch_size => BATCH_SIZE, :conditions => {:id => recipient_ids}) do |batch|
          yield(batch)
        end
      when 'guardian'
        recipient_model.find_in_batches(:batch_size => BATCH_SIZE, :conditions => {:id => recipient_ids},
          :joins => :immediate_contact, :include => :immediate_contact,
          :select => 'students.id, students.first_name, students.middle_name, students.last_name,
            guardians.email, students.immediate_contact_id, guardians.user_id') do |batch|
            yield(batch)
        end
      when 'all_students'
        Student.find_in_batches(:batch_size => BATCH_SIZE,
          :select => 'students.id, students.first_name, students.middle_name, students.last_name, students.email, students.user_id',
          :conditions => 'email is not null and is_email_enabled = 1') do |batch|
          yield(batch)
        end
      when 'all_guardians'
        Student.find_in_batches(:batch_size => BATCH_SIZE, :joins => :immediate_contact, :include => :immediate_contact,
          :select => 'students.id, students.first_name, students.middle_name, students.last_name, guardians.email, students.immediate_contact_id, guardians.user_id',
          :conditions => 'guardians.email is not null') do |batch|
          yield(batch)
        end
      when 'all_employees'
        Employee.find_in_batches(:batch_size => BATCH_SIZE,
          :select => 'employees.id, employees.first_name, employees.middle_name, employees.last_name, employees.email, employees.user_id',
          :conditions => 'email is not null') do |batch|
          yield(batch)
        end
      end
    end

    def process_for_selected_users
      initialize_mail_log
      target_recipient_type = recipient_type.gsub(/all_(.*)s/,'\1')
      @sent_recipients = []
      processed_recipients(recipient_type) do |recipient_list|
        process_and_send(recipient_list, target_recipient_type)
      end
    ensure
      mail_logger.finish!
    end

    def process_for_all_users
      initialize_mail_log
      @sent_recipients = []
      %w(student guardian employee).each do |target_recipient_type|
        processed_recipients('all_' + target_recipient_type.pluralize) do |recipient_list|
          process_and_send(recipient_list, target_recipient_type)
        end
      end
    ensure
      mail_logger.finish!
    end

    def process_and_send (recipients_list, target_recipient_type)
      recipients_list.each do |recipient|
        next if recipient.email.blank?
        sent = process_and_send_for_one(recipient, target_recipient_type)
        @sent_recipients << recipient if sent
      end
    end

    def process_and_send_for_one (recipient, target_recipient_type)
      mail_recipient = recipient_to_use(recipient, target_recipient_type)
      return false if mail_recipient.nil?
      mail_payload = MailPayload.new(
                    :subject => subject,
                    :body => process_body(mail_recipient),
                    :sender => sender,
                    :recipient_record => recipient,
                    :recipient_mail_id => mail_recipient.email,
                    :recipient_name => mail_recipient.full_name,
                    :recipient_type => target_recipient_type,
                    :hostname => additional_info.try(:hostname),
                    :mail_type => :composed,
                    :mail_message => mail_message,
                    :mail_logger => mail_logger
      )

      mail_payload.send_mail # TODO: handle responses and return appropriately
      recipient
    end

    # TODO: implement the interpolations
    def process_body (recipient)
      if has_template
        # process template for individual user
      else
        body
      end
    end

    def t (*args)
      I18n.t(*args)
    end

    def initialize_mail_log
      @mail_logger = MailLogger.make(
        'composed',
        :subject => subject,
        :body => body,
        :mail_message => mail_message,
        :sender => sender
      )
    end

    def finish_mail_log
      @mail_logger.finish!
    end

    RECIPIENT_MODELS = {'student' => Student, 'guardian' => Student, 'employee' => Employee,
                        'all_students' => Student, 'all_guardians' => Student, 'all_employees' => Employee}.freeze

    def recipient_model
      RECIPIENT_MODELS[recipient_type]
    end

    def recipient_to_use (recipient, target_recipient_type)
      case target_recipient_type
        when 'student', 'employee'
          recipient
        when 'guardian'
          recipient.immediate_contact
      end
    end

  end

end
