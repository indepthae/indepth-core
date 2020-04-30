class GeneratedReport < ActiveRecord::Base
  
  #  serialize :batch_ids, Array
  
  belongs_to :report, :polymorphic => true
  belongs_to :course
  has_many :generated_report_batches, :dependent => :destroy
  has_many :batches, :through => :generated_report_batches
  
  after_save :generate_report
  
  def get_batches(group, course)
    current_user=Authorization.current_user
    if current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or current_user.admin?
      is_privilaged = true
    end
    employee = current_user.employee_record
    batches = group.assessment_group_batches.select{|a| a.course_id == course.id}.compact
    if is_privilaged
      all_batches = course.batches_in_academic_year(group.academic_year_id)
    elsif current_user.employee? and current_user.is_a_batch_tutor? 
      batch_ids = employee.batches.collect(&:id)
      all_batches = course.batches_in_academic_year(group.academic_year_id).all(:conditions=>["batches.id in (?)",batch_ids])
    else  
      all_batches = course.batches_in_academic_year(group.academic_year_id)
    end
    
    batches_list = {}
    report_batches = generated_report_batches.all(:include => [:batch_wise_student_report, {:individual_reports => [:student, :individual_report_pdf]}])
    all_batches.each do |b|
      status = []
      group_batch = batches.detect{|agb| agb.batch_id == b.id}
      if group_batch.present? and  group_batch.childrens_present?
        status << "#{t('no_marks_entered')}" unless group_batch.marks_added
      else
        status << "#{t('not_scheduled')}"
      end
      students = b.effective_students
      status << "#{t('no_students_for_this_batch')}" unless students.present?
      generated_batch = report_batches.detect{|agb| agb.batch_id == b.id}
      if generated_batch.present?
        pdf_report_ids = []
        generated_batch.individual_reports.each do |r|
          student = students.to_a.find{|s| s.s_id == r.student_id}
          next unless student
          pdf_report_ids.push [r.individual_report_pdf.attachment.url(:original, false), "#{student.full_name.gsub(/ /, '_')}_#{student.admission_no.gsub(/ |\//, '_')}.pdf"] if r.individual_report_pdf.present?
        end
      end
      batches_list[b.id] = {:selected => generated_batch.present?, :name => b.name, 
        :can_generate => status.empty?, :students => students.length,  :status_no => generated_batch.try(:generation_status),
        :status => generated_batch.try(:status_text), :publish_status => generated_batch.try(:publish_status), 
        :generate_status => status, :report_published => generated_batch.try(:report_published), :last_error => generated_batch.try(:last_error),
        :batch_report_ids => pdf_report_ids,
        :batch_report_file_name => "exam_reports_#{b.name}.zip"
      }
    end
    batches_list
  end
  
  def get_term_batches(course,is_privileged)
    current_user=Authorization.current_user
    if is_privileged
      all_batches = course.batches_in_academic_year(report.assessment_plan.academic_year_id)
    elsif current_user.employee and current_user.is_a_batch_tutor?
      employee = current_user.employee_record
      batch_ids = employee.batches.collect(&:id)
      all_batches = course.batches_in_academic_year(report.assessment_plan.academic_year_id).all(:conditions=>["batches.id in (?)",batch_ids])
    end
    batches_list = {}
    report_batches = generated_report_batches.all(:include => [:batch_wise_student_report, {:individual_reports => [:student, :individual_report_pdf]}])
    final_assessment = report.final_assessment
    if final_assessment.present?
      term_groups = final_assessment.all_assessment_groups
      derived_groups = final_assessment.assessment_groups.derived_groups
    end
    #    derived_groups << final_assessment if final_assessment.present?
    all_batches.each do |b|
      status = []
      if final_assessment.present?
        term_groups.each do |group|
          group_batch = group.assessment_group_batches.detect{|agb| (agb.assessment_group_id == group.id and agb.batch_id == b.id)}
          if group_batch.present? and  group_batch.childrens_present?
            status << "#{group.name} - #{t('no_marks_entered')}" unless group_batch.marks_added
          else
            status << "#{group.name} - #{t('not_scheduled')}"
          end
        end
        derived_groups.each do |d_group|
          group_batch = d_group.assessment_group_batches.detect{|agb| (agb.assessment_group_id == d_group.id and agb.batch_id == b.id)}
          unless group_batch.present? and group_batch.try(:marks_added)
            status << ("#{d_group.name} - #{t('marks_not_calculated')}")
          end
        end
      else
        status << "#{t('final_term_not_configured')}"
      end
      #      status << "#{t('no_examgroups_present')}" if term_groups.length == 0
      students = b.effective_students
      status << "#{t('no_students_for_this_batch')}" unless students.present?
      generated_batch = report_batches.detect{|agb| agb.batch_id == b.id}
      if generated_batch.present?
        pdf_report_ids = []
        generated_batch.individual_reports.each do |r|
          student = students.to_a.find{|s| s.s_id == r.student_id}
          next unless student
          pdf_report_ids.push [r.individual_report_pdf.attachment.url(:original, false), "#{student.full_name.gsub(/ /, '_')}_#{student.admission_no.gsub(/ |\//, '_')}.pdf"] if r.individual_report_pdf.present?
        end
      end
      batches_list[b.id] = {:selected => generated_batch.present?, :name => b.name, 
        :students => students.length, :status => generated_batch.try(:status_text), :status_no => generated_batch.try(:generation_status),
        :publish_status => generated_batch.try(:publish_status), :can_generate => status.empty?, :generate_status => status,
        :report_published => generated_batch.try(:report_published), :last_error => generated_batch.try(:last_error),
        :batch_report_ids => pdf_report_ids,
        :batch_report_file_name => "term_reports_#{b.name}.zip"
      }
    end
    batches_list
  end
  
  def get_plan_batches(all_batches, report)
    batches_list = {}
    report_batches = generated_report_batches.all(:include => [:batch_wise_student_report, {:individual_reports => [:student, :individual_report_pdf]}])
    final_assessment = report.final_assessment
    
    unless final_assessment.new_record?
      term_groups = final_assessment.all_assessment_groups
      derived_groups = final_assessment.assessment_groups.derived_groups
    end
    
    all_batches.each do |b|
      status = []
      unless final_assessment.new_record?
        term_groups.each do |group|
          group_batch = group.assessment_group_batches.detect{|agb| (agb.assessment_group_id == group.id and agb.batch_id == b.id)}
          if group_batch.present? and  group_batch.childrens_present?
            status << "#{group.name} - #{t('no_marks_entered')}" unless group_batch.marks_added
          else
            status << "#{group.name} - #{t('not_scheduled')}"
          end
        end
        derived_groups.each do |d_group|
          group_batch = d_group.assessment_group_batches.detect{|agb| (agb.assessment_group_id == d_group.id and agb.batch_id == b.id)}
          unless group_batch.present? and group_batch.try(:marks_added)
            status << ("#{d_group.name} - #{t('marks_not_calculated')}")
          end
        end
        #        status << "#{t('no_examgroups_present')}" if term_groups.length == 0
      else
        status << "#{t('final_plan_not_configured')}"
      end
      students = b.effective_students
      status << "#{t('no_students_for_this_batch')}" unless students.present?
      
      generated_batch = report_batches.detect{|agb| agb.batch_id == b.id}
      batch_wise_report = generated_batch.try(:batch_wise_student_report)
      if generated_batch.present?
        pdf_report_ids = []
        generated_batch.individual_reports.each do |r|
          student = students.to_a.find{|s| s.s_id == r.student_id}
          next unless student
          pdf_report_ids.push [r.individual_report_pdf.attachment.url(:original, false), "#{student.full_name.gsub(/ /, '_')}_#{student.admission_no.gsub(/ |\//, '_')}.pdf"] if r.individual_report_pdf.present?
        end
      end
      
      batches_list[b.id] = {:selected => generated_batch.present?, :name => b.name, 
        :students => students.length, :status => generated_batch.try(:status_text), :status_no => generated_batch.try(:generation_status),
        :publish_status => generated_batch.try(:publish_status), :can_generate => status.empty?, :generate_status => status,
        :report_published => generated_batch.try(:report_published), :last_error => generated_batch.try(:last_error),
        :batch_report_present => batch_wise_report.present?,
        :batch_report_status => BatchWiseStudentReport::STATUS[batch_wise_report.try(:status)],
        :batch_report_link => ((batch_wise_report.present? and batch_wise_report.try(:status) == 'success') ?  batch_wise_report.report.url(:original,false) : nil),
        :batch_report_ids => pdf_report_ids,
        :batch_report_file_name => "planner_reports_#{b.name}.zip"
      }
    end
    batches_list
  end
  
  def generate_report(batch_id = nil)
    Delayed::Job.enqueue(DelayedGenerateAssessmentReport.new(id, batch_id),{:queue => "gradebook"})
  end
  
  def publish_reports(course_id, batch_id = nil)
    conditions = (batch_id.present? ? {:batch_id => batch_id} : {})
    report_batches = generated_report_batches.all(:conditions => conditions)
    report_batches.each{|rb| rb.update_attributes(:report_published => true,:published_date=>Date.today)}
    if report_type == 'AssessmentGroup'
      conditions[:course_id] = course_id
      conditions[:batch_id] = report_batches.collect(&:batch_id) unless batch_id.present?
      group_batches = report.assessment_group_batches.all(:conditions => conditions)
      group_batches.each do |rb|
        rb.result_published = true
        rb.send(:update_without_callbacks)
      end
    end
  end
  
  def fetch_students(batch_id)
    report_batch = generated_report_batches.first(:conditions => {:batch_id => batch_id}, :include => :individual_reports)
    student_ids = report_batch.individual_reports.collect(&:student_id)
    batch = Batch.find batch_id
    if batch.is_active?
      Student.all(:conditions => {:batch_id => batch_id, :id => student_ids}, :order => Student.sort_order)
    else
      Student.all(:joins => :batch_students, :conditions=>{:id => student_ids,:batch_students =>{:batch_id => batch.id} }, :order => Student.sort_order) + 
        ArchivedStudent.all(:conditions => {:former_id => student_ids})
    end
  end
  
  def fetch_status(batch_id)
    generated_report_batches.first(:conditions => {:batch_id => batch_id}).report_published
  end
  
end
