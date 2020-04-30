class SupportTaskStat < ActiveRecord::Base
  
  serialize :params
  
  after_create :push_to_delayed_job
  before_create :create_log_file
  
  def task_status
    if status.present?
      status == 1 ? "Completed" : "Failed"
    else
      return "Pending"
    end
  end
  
  def script_name
    script_name = SupportTaskEngine.scripts[script_id]
    script_name.present? ? script_name.name.titleize : "Deleted Script" 
  end
  
  def start_time
    to_ist(created_at).strftime("%d-%m-%Y %-l:%M:%S %p")
  end
  
  def end_time
    to_ist(updated_at).strftime("%d-%m-%Y %-l:%M:%S %p") unless task_status == "Pending"
  end
  
  def to_ist(time)
    time.in_time_zone(TZInfo::Timezone.get('Asia/Kolkata'))
  end
  
  def create_log_file
    log_name = "log/support_task/#{self.owner_id}_#{self.script_id}_#{Time.now.to_i}.log"
    logit = Logger.new(log_name)
    logit.info("Task initiated at #{Time.now.utc}")
    self.log = log_name  
  end
  
  def push_to_delayed_job
    Delayed::Job.enqueue(self)  
  end
  
  def perform
    set_school(self.owner_id)
    current_script = script_select(self.script_id)
    result = run_task(current_script, self.params, self.task_type)
    status = result == true ? 1 : 0
    logit = Logger.new(self.log)
    logit.info("Completed at #{Time.now.utc}")
    self.update_attributes(:status=>status)
    system("rm #{self.csv_file}") if self.csv_file.present?
  end
   
  def run_task(current_script, params, type)
    if type=="Check"
      current_script.check(params, self)
    else
      current_script.run(params, self)
    end 
  end
   
  def script_select(sid)
    SupportTaskEngine.scripts[sid]
  end
   
  def set_school(school_id)
    MultiSchool.current_school=School.find_by_id(school_id)
  end

end
