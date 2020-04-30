class DelayedNotification

  DEFAULT_OPTIONS = {:send_to_all => false, :no_guardians => false, :no_students => false, :no_employees => false}

  def initialize(*args)
    @options = DEFAULT_OPTIONS.dup
    @options.merge! args.extract_options!

    @send_to_all = @options[:send_to_all] || false
    unless @send_to_all
      @recipient_ids  = Array(@options[:recipient_ids]).flatten.uniq
    end
    @notification_id = @options[:notification_id]
  end
  
  def perform
    if @send_to_all
      send_to_all_users
    else
      send_to_multiple_users
    end
  end

  def notification
    @notification ||= Notification.find(@notification_id)
  end

  def send_notification
    @recipient_ids.compact! if @recipient_ids.present?
    if @send_to_all || @recipient_ids.length > 1
      Delayed::Job.enqueue(self, {:queue => "notification"})
    else
      send_to_single_user
    end
    notification.push_notify(@recipient_ids, @options)
  end

  private

  def send_to_single_user
    notification.notification_recipients.create(:recipient_id => @recipient_ids.first)
  end

  INSERT_BATCH_SIZE = 1000.freeze

  def send_to_multiple_users
    @recipient_ids.each_slice(INSERT_BATCH_SIZE) do |ids|
      bulk_insert(ids)
    end
  end

  def send_to_all_users
    User.active.find_in_batches(:batch_size => INSERT_BATCH_SIZE, :conditions => all_user_conditions, :select => 'id') do |users|
      bulk_insert(users.collect(&:id))
    end
  end

  def bulk_insert (recipient_ids)
    row_values = ""
    recipient_ids.compact.each do |user_id|
      row_values += "(#{notification.id},#{user_id},#{MultiSchool.current_school.id}),"
    end
    row_values = row_values.chop
    sql_query = "INSERT INTO `notification_recipients` (notification_id,recipient_id,school_id) VALUES #{row_values};"
    ActiveRecord::Base.connection.execute(sql_query)
  end

  def all_user_conditions
    conditions = []
    conditions << '(parent = 0 or parent is null)' if @options[:no_guardians]
    conditions << '(student = 0 or student is null)' if @options[:no_students]
    conditions << '(employee = 0 or employee is null)' if @options[:no_employees]
    conditions.blank? ? {} : conditions.join(' and ')
  end
  
end