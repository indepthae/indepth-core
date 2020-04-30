class MessageThread < ActiveRecord::Base
  validates_presence_of :subject,:creator_id, :message=>"#{t('subject_cant_blank')}"
  validates_length_of :subject, :maximum => 100, :message=>"#{t('subject_must_be_below_100')}"
  xss_terminate
  belongs_to :creator, :class_name => 'User'
  has_many :messages, :dependent=>:destroy
  accepts_nested_attributes_for :messages
  include MessageMod
  extend MessageMod
  before_create  :update_recipient, :if=>Proc.new{|thread| thread.send_to.present?}
  attr_accessor :recipients_presence, :message_body_presence, :send_to, :attachment_support
  
  def validate
    if messages.all?
      if messages.first.present? and messages.first.message_recipients.empty?
        errors.add(:recipients_presence,"#{t('select_recipient')}") unless is_group_message
      end
    end
  end
  
  def build_messages
    self.messages.build unless messages.present?
  end
  
  def update_recipient
    student_user = self.recipient
    guardian_user_id = student_user.student_entry.immediate_contact.user_id
    message = self.messages.first
    if message.present?
      if send_to == 'guardian'
         message.message_recipients.first.recipient_id = guardian_user_id
      elsif send_to == 'both'
        new_thread = self.clone
        if new_thread.send(:create_without_callbacks)
          new_message = message.clone
          new_message.message_attachments_attributes = message.message_attachments_attributes if message.has_attachment?
          new_message.message_thread_id = new_thread.id
          new_message.save          
          if message.has_attachment?
            message.attachment_list=[]
            new_message.message_attachments_assocs.each do |ma|
              message.attachment_list << ma.message_attachment_id    
            end                      
          end     
          new_recipient = new_message.message_recipients.new(:recipient_id=>guardian_user_id)
          new_recipient.save
        end
      end
    end
  end
  
  def recipient_only_thread?
    !can_reply or !group_responses.present?if is_group_message_for(Authorization.current_user.id)
  end
  
  class << self
    def apply_filter(filter)
      user = Authorization.current_user
      if filter == 'all'
        return for_user user
      else
        return send("for_#{filter}",user)
      end
    end
    
    def for_employees(user)
      filter_query('employee',user,'admin')
    end
    
    def for_parents(user)
      filter_query('parent',user)
    end
    
    def for_students(user)
      filter_query('student',user)
    end
    
    def filter_query(filter,user,filter2 = nil)
      filter_apply1 = "OR creator.#{filter2} = true" if filter2
      filter_apply2 = "OR recipient.#{filter2} = true" if filter2
      all(:select => "distinct message_threads.*",
        :conditions=>["(message_threads.is_group_message = false OR 
        (message_threads.is_group_message = true AND message_threads.creator_id != #{user.id} AND (creator.#{filter} = true #{filter_apply1}) ))
         AND message_threads.is_deleted = false AND ((message_recipients.recipient_id = #{user.id} AND message_recipients.is_deleted = false AND (creator.#{filter} = true #{filter_apply1}))
         OR (msg.sender_id = #{user.id} AND msg.is_deleted = false AND (recipient.#{filter} = true #{filter_apply2})))"],
        :joins=>['INNER JOIN users creator ON message_threads.creator_id = creator.id 
          INNER JOIN messages msg ON msg.message_thread_id = message_threads.id 
          INNER JOIN message_recipients ON message_recipients.message_id = msg.id 
          INNER JOIN users recipient ON message_recipients.recipient_id = recipient.id'],
        :order=>'updated_at DESC')
    end
    
    def for_group(user)
      all(:select => "distinct message_threads.*",
        :conditions=>['message_threads.is_group_message = ?  AND message_threads.is_deleted = ? AND message_threads.creator_id = ?
            AND ((message_recipients.recipient_id = ? AND message_recipients.is_deleted = ?) OR (messages.sender_id = ? 
            AND messages.is_deleted = ?))',true,false,user.id,user.id,false,user.id,false],
        :joins=>{:messages=>{:message_recipients=>:recipient}},
        :order=>'updated_at DESC',:include=>include_for_thread)
    end
    
    def for_user(user)
      all(:select => "distinct message_threads.*",
        :conditions=>["message_threads.is_deleted = false AND ((message_recipients.recipient_id = #{user.id} AND message_recipients.is_deleted = false)
         OR (msg.sender_id = #{user.id} AND msg.is_deleted = false))"],
        :joins=>['INNER JOIN users creator ON message_threads.creator_id = creator.id 
          INNER JOIN messages msg ON msg.message_thread_id = message_threads.id 
          INNER JOIN message_recipients ON message_recipients.message_id = msg.id 
          INNER JOIN users recipient ON message_recipients.recipient_id = recipient.id'],
        :order=>'updated_at DESC')
    end
    
    def get_parents(batch_id,current_user)
      parents = all_parents(current_user,batch_id) #get_all_parents(current_user)
      user_ids = parents.collect(&:user_id)
      user_ids.delete current_user.id
      user_ids.compact.uniq
    end
      
    def get_students(batch_id,current_user)
      students = all_students(current_user,batch_id)
      user_ids = students.collect(&:user_id)
      user_ids.delete current_user.id
      user_ids.compact.uniq
    end
    
    def get_employees(dept_id,current_user)
        employees = all_employees(current_user,dept_id)
        user_ids = employees.collect(&:user_id)
        user_ids.delete current_user.id
        user_ids.compact.uniq
    end
    
    def include_for_thread
      {:messages=>[:message_recipients,:message_attachments]}
    end
    
    def user_include
      {:recipient=>[{:student_entry=>[{:batch=>:course}]},{:employee_entry=>:employee_department},{:archived_student_entry=>[{:batch=>:course}]},:archived_employee_entry,:guardian_entry]}
    end
  end
  
  def active_messages(params={})
    user = Authorization.current_user
    conditions = "((messages.is_deleted = true AND messages.sender_id != #{user.id}) OR messages.is_deleted = false) 
                    AND ((message_recipients.is_deleted = true AND message_recipients.recipient_id != #{user.id}) 
                    OR message_recipients.is_deleted = false)"
    self.messages.all(:select=>'distinct messages.*',:conditions=>["#{conditions}"],
      :joins=>:message_recipients, 
      :order=>params[:order],:include=>:message_attachments)
  end
  
  def delete_for(user)
    message_ids = self.message_ids
    MessageRecipient.update_all("is_deleted = true", ['message_id in (?) and recipient_id = ?',message_ids, user.id])
    self.messages.update_all("is_deleted = true",['sender_id = ?',user.id])
  end
  
  def delete_sub_thread_for(current_user,recipient_id)
    messages = self.load_sub_thread(recipient_id,current_user.id)
    b_ids = self.broadcast_messages.collect(&:id)
    message_ids = messages.collect(&:id)
    MessageRecipient.update_all("is_deleted = true", ['message_id in (?) and recipient_id = ?',message_ids, current_user.id])
    other_message_ids = message_ids - b_ids
    Message.update_all("is_deleted = true",['sender_id = ? and id in (?)',current_user.id,other_message_ids])
  end
  
  def recipient
    if is_group_message
      recipient = creator unless creator == Authorization.current_user
    else
      recipient = messages.first.message_recipients.first.recipient
      if recipient
        if recipient == Authorization.current_user
          return messages.first.sender
        else
          return recipient
        end
      end
    end
  end
  
  def is_group_message_for(user_id)
    creator_id == user_id and is_group_message
  end
  
  def group_recipients(page = nil)
    MessageRecipient.paginate(:conditions=> {:thread_id=>id},
      :include=>self.class.user_include, :page => page, :per_page => 20) if is_group_message
  end
  
  def recipient_tag(recipient,entry)
    if recipient.student?
      "#{t('batch')} : #{entry.batch.full_name}"
    elsif recipient.parent?
      "#{t('parent')} #{t('of')} #{recipient.full_name}"
    else
      "#{t('department')} : #{entry.department}"
    end
  end
  
  def get_entry(recipient)
    return nil if recipient.nil?
    unless recipient.is_deleted
      entry = recipient.student_entry if recipient.student?
      entry = recipient.guardian_entry if recipient.parent?
      entry = recipient.employee_record if recipient.employee? or recipient.admin?
    else
      entry = recipient.archived_student_entry if recipient.student?
      entry = nil if recipient.parent?
      entry = recipient.archived_employee_entry if recipient.employee? or recipient.admin?
    end
    return entry
  end
  
  def group_responses
    current_user_id = Authorization.current_user.id
    conditions = "((messages.is_deleted = true AND messages.sender_id != #{current_user_id}) OR messages.is_deleted = false) 
                  AND ((message_recipients.is_deleted = true AND message_recipients.recipient_id != #{current_user_id}) 
                  OR message_recipients.is_deleted = false)"
    recipients = MessageRecipient.all(:select=>'distinct message_recipients.*',
      :joins=>['INNER JOIN messages on messages.sender_id = message_recipients.recipient_id'], 
      :conditions=>["(messages.message_thread_id = ? AND message_recipients.thread_id = ? AND messages.sender_id != ?) 
        AND #{conditions}",id,id,current_user_id],:include=>self.class.user_include)
    
    recipients.reject do |recipient|
      #      !load_sub_thread(recipient.recipient_id,Authorization.current_user.id).present?
      messages = self.messages.all(:select=>'distinct messages.*', 
        :conditions=>["(messages.sender_id in (?) and message_recipients.recipient_id in (?)) 
        AND #{conditions}",[recipient.recipient_id,current_user_id],[recipient.recipient_id,current_user_id]],
        :joins=>:message_recipients,
        :order=>'created_at desc')
      messages.reject! { |message| message.id == primary_message.id}
      !messages.present?
    end
  end
  
  def recipients_count
    MessageRecipient.count(:conditions=> {:thread_id=>id})
  end
  
  def primary_message
    self.messages.all(:conditions=>{:is_primary=>true}).first
  end
  
  def has_unread_messages?
    self.messages.count(:conditions=>{:message_recipients=>{:is_read => false, :recipient_id=>Authorization.current_user.id}}, 
      :joins=>:message_recipients) > 0
  end
  
  def has_unread_messages_from(sender_id)
    self.messages.count(:conditions=>{:sender_id=>sender_id,
        :message_recipients=>{:is_read => false, :recipient_id=>Authorization.current_user.id}}, :joins=>:message_recipients) > 0
  end
  
  def broadcast_messages
    self.messages.all(:conditions=>{:is_to_all=>true},:include=>:message_attachments)
  end
  
  def load_sub_thread(recipient_id,current_user_id)
    conditions = "((messages.is_deleted = true AND messages.sender_id != #{current_user_id}) OR messages.is_deleted = false) 
                AND ((message_recipients.is_deleted = true AND message_recipients.recipient_id != #{current_user_id}) 
                OR message_recipients.is_deleted = false)"
    msgs = self.messages.all(:select=>'distinct messages.*', 
      :conditions=>["(messages.sender_id in (?) and message_recipients.recipient_id in (?)) 
        AND #{conditions}",[recipient_id,current_user_id],[recipient_id,current_user_id]],
      :joins=>:message_recipients,
      :order=>'created_at desc',:include=>[:message_attachments])
    msgs.reject{|msg| msg.id == primary_message.id } if has_deleted_record(recipient_id)
    return msgs
  end
  
  def has_deleted_record(recipient_id)
    MessageRecipient.count(:conditions=>["message_threads.id = ? AND messages.sender_id = ? AND message_recipients.recipient_id = ?
     AND message_recipients.is_deleted = ?",id,recipient_id,Authorization.current_user.id,true],:joins=>{:message=>:message_thread}) > 0
  end
end
