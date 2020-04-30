class CceReportGenerator
  unloadable

  def initialize(params_hash)
    @errors=[]
    @params_hash=params_hash
    @status=validate_generation(@params_hash)
    @batches=get_batches_list(@params_hash) if @status
  end

  def validate_and_save
    Delayed::Job.enqueue(self,{:queue => 'cce_report'})
  end

  def validate_generation(params_hash)
    if params_hash[:batch].present?
      return true
    else
      return false
    end
  end

  def get_batches_list(params_hash)
    Batch.find_all_by_id(params_hash[:batch].keys)
  end

  def get_operation_level(batches,params_hash)
    batches.each do |batch|
      student_list=params_hash[:batch][batch.id.to_s][:students].split(",").map(&:to_i).sort
      if (batch.is_active ? batch.students.collect(&:id).sort : batch.graduated_students.collect(&:id).sort) == student_list
        if batch.check_credit_points
          batch.generate_cce_reports
          batch.delete_student_cce_report_cache
        end
      else
        student_list.each do |s|
          student=Student.find s
          student.batch_in_context_id=batch.id
          student.generate_cce_student_wise_reports
          student.delete_student_cce_report_cache
        end
      end
    end
  end

  def perform
    get_operation_level(@batches,@params_hash)
    prev_record = Configuration.find_by_config_key("job/CceReportGenerator/1")
    if prev_record.present?
      prev_record.update_attributes(:config_value=>Time.now)
    else
      Configuration.create(:config_key=>"job/CceReportGenerator/1", :config_value=>Time.now)
    end
  end

end