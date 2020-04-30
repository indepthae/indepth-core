class MailMessage < ActiveRecord::Base

  Info = Struct.new(:hostname, :rtl)

  attr_accessor :recipient_type, :recipient_ids, :attachment_error
  serialize :additional_info

  belongs_to :sender, :class_name => 'User'
  has_many :mail_attachments, :dependent => :destroy
  has_one :mail_recipient_list, :dependent => :destroy
  accepts_nested_attributes_for :mail_attachments

  validates_presence_of :subject, :body
  validates_presence_of :recipient_ids, :if => lambda {|rec| ['student', 'guardian', 'employee'].include?(rec.recipient_type) && !rec.send_to_all}

  after_validation :set_recipient_list
  after_save :queue_mail

  has_redactor_field :body
  xss_terminate :except => [:body]

  def validate
    attachment_errors = mail_attachments.collect{|attachment| attachment.errors.full_messages unless attachment.valid? }.flatten.uniq.compact
    attachment_errors << t(:mail_attachment_count_error) if mail_attachments.length > 5
    attachment_errors << t(:mail_attachment_size_error) if mail_attachments.collect(&:attachment_file_size).sum(&:to_i) > 1e+7
    errors.add(:attachment_error, attachment_errors.join(', ')) if attachment_errors.present?
  end

  def recipients
    @recipients ||=(
      ids = recipient_ids.is_a?(Array) ? recipient_ids : recipient_ids.to_s.split(",")
      if recipient_type == "employee"
        Employee.find_all_by_id(ids)
      elsif recipient_type == "student" || recipient_type == "guardian"
        Student.find_all_by_id(ids)
      else
        []
      end
    )
  end

  def recipient_ids
    @recipient_ids ||= mail_recipient_list.try(:recipient_ids)
  end

  def recipient_type
    @recipient_type ||= mail_recipient_list.try(:recipient_type)
  end

  def effective_recipient_type
    if send_to_all
      'all_' + recipient_type.pluralize
    else
      recipient_type
    end
  end

  def send_to_all= (value)
    @send_to_all = (value == 'true') ? true : false
  end
  
  attr_reader :send_to_all

  private

  def set_recipient_list
    build_mail_recipient_list(:recipient_ids => recipients.collect(&:id),
      :recipient_type => effective_recipient_type)
  end

  def queue_mail
    Delayed::Job.enqueue(FedenaEmailAlert::ComposedMailProcessor.new(id))
  end

end
