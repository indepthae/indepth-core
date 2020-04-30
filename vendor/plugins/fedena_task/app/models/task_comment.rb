class TaskComment < ActiveRecord::Base
  belongs_to :task
  belongs_to :user

  has_attached_file :attachment,
    :path => "uploads/:class/:user_id/:id/:basename.:extension",
    :url => "/task_comments/download_attachment/:id",
    :max_file_size => 512000,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]
  
  validates_presence_of :user_id, :description, :task_id
  validates_attachment_size :attachment, :less_than => 500.kilobytes, :message=> :should_be_less_than

  def can_be_deleted_by?(user_in_question)
    (user_in_question==self.user || user_in_question == self.task.user)
  end

  def can_be_downloaded_by?(user_in_question)
    (user_in_question==self.task.user || self.task.assignees.include?(user_in_question))
  end

  

 

end
