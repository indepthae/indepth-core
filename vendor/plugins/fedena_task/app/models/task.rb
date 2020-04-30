class Task < ActiveRecord::Base
 
  after_create :notify_assignees
  before_update :notify_assignees_about_update
  belongs_to :user
  has_many :task_comments,:dependent => :destroy
  has_many :task_assignees,:dependent => :destroy
  has_many :assignees, :through=>:task_assignees, :class_name=>'User'

  has_attached_file :attachment,
    :path => "uploads/:class/:user_id/:id_partition/:basename.:extension",
    :url => "/tasks/download_attachment/:id",
    :max_file_size => 512000,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_presence_of :user_id, :title, :description, :status, :due_date, :start_date

  validates_inclusion_of :status, :in => %w(Assigned Completed), :message => :invalid_status
  validates_attachment_size :attachment, :less_than => 500.kilobytes,  :message=> :should_be_less_than

  delegate :first_name,:to => :user,:allow_nil=>true,:prefix=>:user

  def can_be_viewed_by?(user_in_question)
    (user_in_question==self.user || self.assignees.include?(user_in_question))
  end

  def can_be_downloaded_by?(user_in_question)
    (user_in_question==self.user || self.assignees.include?(user_in_question))
  end

  def task_can_be_deleted_by?(user_in_question)
    (user_in_question==self.user and (user_in_question.admin? or user_in_question.privileges.collect(&:name).include?("TaskManagement")))
  end

  def task_can_be_edited_by?(user_in_question)
    (user_in_question==self.user and (user_in_question.admin? or user_in_question.privileges.collect(&:name).include?("TaskManagement")))
  end
  def validate
    if start_date.to_date > due_date.to_date
      self.errors.add(:due_date, :cannot_be_before_start_date)
    end
    if self.new_record?
      unless self.due_date.nil?
        self.errors.add(:due_date, :should_be_in_the_future) if self.due_date < Date.today
      end
    end
  end
  
  def due?
    due_date >= Date.today
  end

  def notify_assignees
    recipient_ids = self.assignees.collect(&:id)
    body = "<b>#{self.title}</b> #{t('by')} <b>#{self.user.present? ? self.user.full_name : t('deleted_user')}</b> : #{t('end_date')} : " + format_date(self.due_date,:format => :short_date)
    links = {:target=>'view_task',:target_param=>'task_id',:target_value=>self.id}
    inform(recipient_ids,body,'Task',links)
  end
  
  def notify_assignees_about_update
    recipient_ids = self.assignees.collect(&:id)
    body = self.changed.include?("status") ? "#{t('task_status_changed')} #{t('for_text')} <b>#{self.title}</b> #{t('to_text')} <b>#{self.status}</b>" :  "#{t('task_updated')} : <b> #{self.title} </b>"
    links = {:target=>'view_task',:target_param=>'task_id',:target_value=>self.id}
    inform(recipient_ids,body,'Task',links)
  end

  def self.latest_comments_for_user(user,limit)
    all_tasks = user.tasks.collect(&:id) + user.assigned_tasks.collect(&:id)
    TaskComment.find(:all,:conditions=>{:task_id=>all_tasks.uniq},:include=>:task,:limit=>limit,:order=>"updated_at DESC")
  end

  
  Paperclip.interpolates :user_id  do |attachment, style|
    attachment.instance.user_id
  end
end
