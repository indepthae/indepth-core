module FedenaEmailAlert
  
  # This class is responsible for logging of mails delivered  
  class MailLogger

    MAX_RECIPIENTS_COUNT_PER_LIST = 100

    attr_accessor :id, :mail_log

    # Gets the logger object for the +MailLog+ entry
    # @param [Integer] id use the id of the +MailLog+ entry 
    def self.get (id)
      mail_log = MailLog.find(id)
      new(mail_log)
    end

    # Creates a new +MailLog+ entry and returns a logger object
    # @param [String] klass_type takes 'alert' or 'composed' as the value
    # @param [Hash] params model specific parameters for +AlertMailLog+ or +ComposedMailLog+
    def self.make (klass_type, params={})
      klass = "#{klass_type}_mail_log".camelize.constantize
      mail_log = klass.create(params)
      new(mail_log)
    end

    # create an instance using a +MailLog+ object
    # @param [MailLog] mail_log 
    def initialize (mail_log)
      @mail_log = mail_log
      @id = mail_log.id                
    end

    # Logs the delivery of an email by saving the details into table
    # @params [Student, Employee] recipient_record user record of the recipient
    # @params [string] recipient_mail_id mail_id  of the recipient
    # @params [string] recipient_name name  of the recipient
    # @params [string] recipient_type type  of the recipient
    def log_delivery! (args)
      add_recipient(args)
    end

    # Gets the last +mail_log_recipient_list+ for the log object
    def last_log_recipient_list
      @last_log_recipient_list ||=
        mail_log.mail_log_recipient_lists.recipients_count_lt(mail_log.class::MAX_RECIPIENTS_COUNT_PER_LIST).last ||
          add_list!      
    end

    # Gets the recipient list being filled
    def recipient_list
      last_log_recipient_list.recipients
    end

    # Add recipient to the log list. Also calls `add_list!` when the recipients_count value
    #  equals the MAX_RECIPIENTS_COUNT_PER_LIST
    # @params [Student, Employee] recipient_record user record of the recipient
    # @params [string] recipient_mail_id mail_id  of the recipient
    # @params [string] recipient_name name  of the recipient
    # @params [string] recipient_type type  of the recipient
    def add_recipient (args)
      last_log_recipient_list.add_recipient(args)
      add_list! if last_log_recipient_list.recipients_count == mail_log.class::MAX_RECIPIENTS_COUNT_PER_LIST
    end

    # Builds a new +mail_log_recipient_list+ for the +mail_log+, to be called when recipients count
    #  in a list hits MAX_RECIPIENTS_COUNT_PER_LIST
    def add_list!
      commit_list!
      @last_log_recipient_list = mail_log.mail_log_recipient_lists.build(:recipients => [])
    end

    # Saves any unsaved +mail_log_recipient_list+, to be called when a section of delivery is done
    def commit_list!
      @last_log_recipient_list.save if @last_log_recipient_list.present? && @last_log_recipient_list.changed?
    end
    
    alias finish! commit_list!
        
  end  
end