class DelayedGenerateAssessmentReport < Struct.new(:generated_report_id, :batch_id)
  @@report_logger = Logger.new('log/gradebook_report_errors.log')
  
  def perform
    generated_report = GeneratedReport.find generated_report_id
    report_batches = batch_id.present? ? generated_report.generated_report_batches.pending_batch(batch_id) : generated_report.generated_report_batches.pending_batches
    report_batches.each do |rep_batch|
      batch_report_generation(generated_report, rep_batch)
    end
  end
  
  def batch_report_generation(generated_report, rep_batch)
    @rollback = false
    @errors = []
    ActiveRecord::Base.transaction do
      status = send("#{generated_report.report_type.underscore}_report", generated_report.report_id, rep_batch.batch_id, rep_batch.id)
      log_error! status.errors if status.failed
      unless @rollback
        reset_batch_wise_report(rep_batch)
        rep_batch.update_attributes({:generation_status => 2, :last_error => nil, :report_published => false, :batch_wise_student_report_id => nil})
      end
      raise ActiveRecord::Rollback if @rollback
    end
  rescue Exception => e
    log "---------Debug Log-----------------"
    log e.message
    log e.backtrace
    log "--------------------------"
    
    rep_batch.update_attributes({:generation_status => (rep_batch.generation_status == 4 ? 5 : 3) , :last_error => [e.message], :report_published => false})
  ensure
    rep_batch.update_attributes({:generation_status => (rep_batch.generation_status == 4 ? 5 : 3), :last_error => @errors}) if @rollback
  end
  
  def assessment_plan_report(plan_id, batch_id, report_batch_id)
    plan = AssessmentPlan.find plan_id
    final_assessment = plan.final_assessment
    if !final_assessment.new_record? and !final_assessment.no_exam
      insert_final_marks(final_assessment,batch_id)
    else
      reset_agbs(final_assessment, batch_id)
    end
    Gradebook::Components::ReportFactory.build(:reportable => plan,:batch_id => batch_id, :report_batch_id => report_batch_id)
  end
  
  def assessment_term_report(term_id,batch_id, report_batch_id)
    term = AssessmentTerm.find(term_id)
    final_assessment = term.final_assessment
    if !final_assessment.new_record? and !final_assessment.no_exam
      insert_final_marks(final_assessment,batch_id) 
    else
      reset_agbs(final_assessment, batch_id)
    end
    Gradebook::Components::ReportFactory.build(:reportable => term,:batch_id => batch_id, :report_batch_id => report_batch_id)
  end
  
  def assessment_group_report(group_id, batch_id, report_batch_id)
    group = AssessmentGroup.find(group_id, :include => :assessment_group_batches)
    Gradebook::Components::ReportFactory.build(:reportable => group,:batch_id => batch_id, :report_batch_id => report_batch_id)
  end
  
  def insert_final_marks(final_assessment,batch_id)
    if final_assessment
      agb = final_assessment.assessment_group_batches.find_or_initialize_by_batch_id(:batch_id => batch_id)
      agb.send(:create_without_callbacks) if agb.new_record?
      agb.reload
      DelayedAssessmentMarksSubmission.new(agb.id, 'AssessmentGroupBatch').perform
    end
  end
 
  def log_error!(errors = nil)
    @rollback = true
    @errors << errors if errors
  end
  
  def reset_batch_wise_report(rep_batch)
    batch_wise_id = rep_batch.batch_wise_student_report_id
    if batch_wise_id
      other_report_batches = GeneratedReportBatch.all(:conditions => ['id NOT IN (?) AND batch_wise_student_report_id = ?', rep_batch.id, batch_wise_id])
      BatchWiseStudentReport.find_by_id(batch_wise_id).try(:destroy) unless other_report_batches.present?
    end
  end
  
  def reset_agbs(group, batch_id)
    group.assessment_group_batches.to_a.select{|agb| agb.batch_id == batch_id}.each{|agb| agb.destroy }
  end
  
  def log(text)
    @@report_logger.info text
  end
end
