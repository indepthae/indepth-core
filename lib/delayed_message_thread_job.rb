class DelayedMessageThreadJob

  def initialize(*args)
    opts = args.extract_options!
    @recipient_ids = Array(opts[:recipient_ids]).flatten.uniq
    @thread_id = opts[:thread_id]
    @attachments = opts[:attachment]
  end

  def perform
    @message_thread = MessageThread.find @thread_id
    @recipient_ids.each do |r_id|
      @message_thread.primary_message.message_recipients.create(:recipient_id=>r_id,:thread_id=>@thread_id)
    end
  end
  
  def initialize_with_school_id(*args)
    @school_id = MultiSchool.current_school.id
    initialize_without_school_id(*args)
  end
  
  alias_method_chain :initialize,:school_id
  
  
  def perform_with_school_id
    MultiSchool.current_school = School.find(@school_id)
    perform_without_school_id
  end
  
  alias_method_chain :perform,:school_id
end
