class Message < ActiveRecord::Base
  validates_presence_of :body,:on=>:create, :if =>Proc.new{|message| message.message_attachments_attributes.nil?}, :message=>"#{t('message_blank')}"
  xss_terminate
  belongs_to  :message_thread
  belongs_to  :sender, :class_name => 'User'
  has_many  :message_recipients, :dependent=>:destroy
  has_many :message_attachments_assocs
  has_many :message_attachments, :through => :message_attachments_assocs
  accepts_nested_attributes_for :message_attachments, :allow_destroy => true   #,
  #  :reject_if => proc { |attributes| !attributes['attachment'].present? || attributes['_destroy']== 1}, 
  accepts_nested_attributes_for :message_recipients
  attr_accessor :recipient_list, :message_attachments_attributes, :attachment_list
  after_create :push_notify
  before_create :check_attachment, :if => :message_attachments_attributes

  include MessageMod
  extend MessageMod

  def push_notify
    PushNotification.push_notify(
      {:data => {
          :title => message_thread.subject,
          :body => body,
          :tag => "message-#{message_thread_id}",
          :type => 'message',
          :target => 'message',
          :target_param => 'message_thread_id',
          :target_value => message_thread_id,
          :payload => message_payload
        },
        :user_ids => (recipient_list || message_recipients.collect(&:recipient_id))
      })
  end
  
  def message_payload
    payload = {:id => id, :body => body, :sender_id => sender_id, :created_at => created_at}
    message_attachments.each do |ma|
      payload.merge(:attachment => ma.attachment.url(:original, false)) if has_attachment?
    end
    payload
  end
  
  def check_attachment
    if attachment_list.present?   
      self.attachment_list.each do |a|
        self.message_attachments_assocs.build(:message_attachment_id => a)
      end
    elsif message_attachments_attributes
      message_attachments_attributes.each_pair do |k,v|       
        if v['attachment'].present? or !v['_destroy']== 1
          attach = MessageAttachment.new(v)
          self.message_attachments_assocs.build(:message_attachment_id => attach.id) if attach.save
        end
      end
    end
  end  
  
  def build_child
    message_recipients.build
  end

  def has_attachment?
    if self.new_record?           
      self.message_attachments_attributes.present? and self.message_attachments_attributes['attachment'].present?
    else      
      self.message_attachments.present?
    end
  end
  
  class << self
    
    def get_departments_batches_and_parents(user)
      employee_departments = all_employees(user).collect(&:employee_department_id)
      student_batches      = all_students(user).collect(&:batch_id)
      parent_batches       = all_parents(user).collect(&:batch_id)
      return EmployeeDepartment.find_all_by_id(employee_departments.uniq),
        Batch.find_all_by_id(student_batches.uniq),
        Batch.find_all_by_id(parent_batches.uniq)
    end
    
  end
  
end