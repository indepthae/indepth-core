class GeneratedReportBatch < ActiveRecord::Base
  
  serialize :last_error, Array
  
  belongs_to :generated_report
  belongs_to :batch
  belongs_to :batch_wise_student_report
  
  has_many :individual_reports
  
  named_scope :completed_batches, :conditions => {:generation_status => [2, 5]}
  named_scope :pending_batches, :conditions => {:generation_status => [1, 4]}
  
  named_scope :pending_batch, lambda{|batch_id|
    {
      :conditions => {:generation_status => [1, 4], :batch_id => batch_id},
      :limit => 1
    }
  }
   
  named_scope :batch_for_generation, lambda{|batch_id|
    {
      :conditions => ["batch_id = ? and generation_status not in (?)", batch_id,[1, 4]],
      :limit => 1
    }
  }
  
  after_update :notify_users, :if => Proc.new{|grb| grb.report_published_changed? and grb.report_published}
  
  GENERATION_STATUS = {1 => t('generating_report'), 2 => t('completed'), 3 => t('report_generation_failed'), 4 => t('regenerating_report'), 5 => t('report_regeneration_failed') }
  
  def status_text
    GENERATION_STATUS[generation_status]
  end
  
  def publish_status
    report_published ? t('published') : t('not_published')
  end
  
  def notify_users
    students = Student.find_all_by_batch_id(batch_id)
    guardians = students.map {|x| x.immediate_contact.user_id if x.immediate_contact.present?}.compact
    available_user_ids = students.collect(&:user_id).compact
    available_user_ids << guardians
    content = "#{generated_report.report.name} #{t('report_has_been_published')}"
    links = {:target=>'view_reports',:target_param=>'student_id'}
    inform(available_user_ids,content,'Gradebook',links)
  end
  
end
