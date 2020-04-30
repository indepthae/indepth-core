class BatchWiseStudentReport < ActiveRecord::Base
  belongs_to :course
  serialize :parameters, Hash
  has_attached_file :report,
    :url => "/cce_reports/batch_wise_student_report_download/:id",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :max_file_size => 5242880,
    :permitted_file_types =>[]

  after_save :remove_excess_entry, :unless => :is_gradebook?
  after_save :reset_old_reports, :if => :is_gradebook?
  
  named_scope :cce       ,:conditions => {:is_gradebook => false}
  named_scope :gradebook ,:conditions => {:is_gradebook => true }
  
  STATUS = {'running' => 'generating_batchwise_report', 'in queue' => 'batch_wise_report_in_queue', 'failed' => 'batchwise_report_generation_failed'}
  
  
  def remove_excess_entry
    if BatchWiseStudentReport.cce.count > 10
      BatchWiseStudentReport.cce.first.destroy
    end
  end
  
  def reset_old_reports
    if self.parameters[:report_type] == 'plan_report'
      status , ids = AssessmentPlan.reset_batch_wise_reports( self )
      if status
        self.class.find_all_by_id(ids).each {|obj| obj.destroy}
      end
    end
  end

  def perform
    @report=BatchWiseStudentReport.find(self.id)
    @report.update_attributes(:status => 'running')
    pdf_generation
    @report.report = zip_file
    @report.save
    @report.update_attribute('status','success')
  rescue Exception => e
    puts e.message
    @report.update_attribute('status','failed')
  ensure
    puts "removing directory "+@path
    system('rm -rf '+@path)
  end
  
  def zip_file
    File.open(@path+"/#{file_name}",'r')
  end
 
  def pdf_generation
    Authorization.current_user = User.first(:conditions=>{:admin=>true})
    @path="tmp/"+Time.now.to_i.to_s
    Batch.find_all_by_id(self.parameters[:batch_ids],:include=>:course).each do |batch|
      @course_code=batch.course.code
      system("mkdir "+@path)
      opts = build_options
      pdf = report_pdf(batch)
      get_students(batch).each do |student|
        begin
          send("generate_#{report_name.underscore}", student, pdf, opts, self.parameters, batch.id)
        rescue Exception=> e
          puts e.message
          next
        end
      end
    end
    system("cd "+@path+";zip -r "+"#{file_name} .")
  end
  
  def get_students(batch)
    batch.effective_students
  end
  
  #Deprecated after component release
  #ToDo: Safe remove the code after release becomes stable
  def generate_gradebook_report(student, pdf, opts,parameters, batch_id)
    pdf.generate_pdf("#{student.first_name}-#{student.admission_no}-#{report_name}",opts) do
      @student = student
      @student.batch_in_context_id = batch_id
      @batch = Batch.find batch_id
      @assessment_plan = AssessmentPlan.find parameters[:reportable_id]
      @generated_report = @assessment_plan.course_report(@batch.course_id)
      @general_records = AssessmentReportSettingCopy.result_as_hash(@generated_report.id,@assessment_plan.id)
      @schol_report = @student.individual_reports.first(:conditions => {:reportable_id => @assessment_plan.id, :reportable_type => 'AssessmentPlan'})
      raise "No Reports Present for #{@student}" unless @schol_report
      @grade_sets = GradeSet.find_all_by_id [@general_records['ScholasticGradeScale'], @general_records['CoScholasticGradeScale']]
      @grade_set = @assessment_plan.final_assessment.grade_set
    end
  end
  
  def generate_cce_report(student, pdf, opts, parameters, batch_id)
    pdf.generate_pdf("#{student.first_name}-#{student.admission_no}-#{report_name}",opts) do
      params = {:report_format_type=>'pdf',:type=>'regular'}
      params.merge!({:id=>student.id,:batch_id=>student.batch_id})
      @student=student
      @batch=@student.batch
      @exam_groups=@batch.exam_groups.all(:joins=>[:cce_exam_category,:exams],:group=>"id")
      @records=CceReportSettingCopy.result_as_hash(@batch,@student)
      @general_records=CceReportSettingCopy.general_records_as_hash(@batch)
      @config = Configuration.get_multiple_configs_as_hash ['InstitutionName', 'InstitutionAddress', 'InstitutionPhoneNo','InstitutionEmail','InstitutionWebsite']
      @settings = CceReportSetting.get_multiple_settings_as_hash ["TwoSubUpscaleStart", "TwoSubUpscaleEnd", "OneSubUpscaleStart", "OneSubUpscaleEnd"]
      @data_hash = CceReport.fetch_student_wise_report(params)
      @eiop_eligibily_grade=CceReportSettingCopy.setting_result_as_hash(@batch,'grade')
      @pass_text=CceReportSettingCopy.setting_result_as_hash(@batch,'pass_text')
      @eiop_text=CceReportSettingCopy.setting_result_as_hash(@batch,'eiop_text')
      @check_term="all"
      @grading_levels = @batch.grading_level_list
      gsids=@batch.course.observation_groups.collect(&:cce_grade_set_id).uniq
      @grade_sets=CceGradeSet.find_all_by_id(gsids)
      fetch_attendance_data
      fetch_report
    end
  end
  
  def report_pdf(batch)
    PdfMaker.new(self.is_gradebook? ? 'assessment_reports': 'cce_reports',report_type,@path+"/"+batch.full_name)
  end
  
  def build_options
    if report_type == 'cce_full_exam_report'
      {:header =>{:content=>nil},:margin=>{:left=>10,:right=>10,:top=>10,:bottom=>5}}
    else
      {:margin=>{:left=>10,:right=>10,:top=>8,:bottom=>8},:header => {:html => nil},:footer => {:html => nil}}
    end
  end
  
  def report_type
    case self.parameters[:report_type]
    when 'cce_report'
      'cce_full_exam_report'
    when 'plan_report'
      'student_plan_report_pdf'
    else
      'student_report_pdf'
    end
  end
  
  def report_name
    is_gradebook? ? 'Gradebook-Report' : 'CCE-Report'
  end
  
  def file_name
    is_gradebook? ? "#{@course_code.gsub(/ /, '_')}_Gradebook_Reports.zip" : "#{@course_code.gsub(/ /, '_')}_CCE_Reports.zip"
  end
  
end