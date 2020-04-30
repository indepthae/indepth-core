class CsvExportController < ApplicationController
  before_filter :login_required
  before_filter :is_permitted?
  filter_access_to :all
  require 'fastercsv'
  check_request_fingerprint :generate_csv

  def generate_csv
    filename    = "#{params[:csv_report_type]}.csv"
    report_type = params[:csv_report_type]
    report_data = fetch_report_data(report_type,filename)
  end

  private

  def fetch_report_data(report_type,filename)
    case report_type
    when "student_advance_search"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('student','fetch_student_advance_search_result', parameters)
      return
    when "consolidated_subjectwise_attendance_report"
      data=Attendance.fetch_consolidated_subjectwise_attendance_data(params)
    when "student_attendance_report"
      data = Attendance.fetch_student_attendance_data(params)
    when "day_wise_report"
      data = Attendance.fetch_day_wise_report_data(params)
    when "attendance_register_csv"
      data = Attendance.fetch_attendance_register_data(params)
    when "student_ranking_per_subject"
      data = Exam.fetch_student_ranking_per_subject_data(params)
    when "student_ranking_per_batch"
      data = Exam.fetch_student_ranking_per_batch_data(params)
    when "student_ranking_per_course"
      data = Exam.fetch_student_ranking_per_course_data(params)
    when "student_ranking_per_school"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('exam', 'fetch_student_ranking_per_school_data', parameters)
      return
    when "student_ranking_per_attendance"
      data = Exam.fetch_student_ranking_per_attendance_data(params)
    when "employee_attendance_report"
      parameters = {:params => params, :locale => I18n.locale}
      if params[:from] == "reportees_leaves"
        csv_export('employee_attendance','fetch_reportees_attendance_data',parameters)
      else
        csv_export('employee_attendance','fetch_employee_attendance_data',parameters)
      end
      return
    when "employee_advance_search"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('employee','fetch_employee_advance_search_data', parameters)
      return
    when "subject_wise_report"
      data = Exam.fetch_subject_wise_data(params)
    when "consolidated_exam_report"
      data = Exam.fetch_consolidated_exam_data(params)
    when "ranking_level"
      data = RankingLevel.fetch_ranking_level_data(params)
    when "fee_structure_overview"
      data = Student.fetch_students_structure_data(params)
    when "student_fees_structure"
      data = Student.fetch_student_fees_structure_data(params)
    when "finance_transaction"
      data = FinanceTransaction.fetch_finance_transaction_data(params)
    when "finance_payslip"
      data = FinanceTransaction.fetch_finance_payslip_data(params)
    when "exam_timings"
      data = AssessmentGroupBatch.fetch_exam_timings_data(params)
    when "finance_fee_collection_report"
      data = FinanceFeeCollection.fetch_finance_fee_collection_data(params)
    when "finance_fee_course_wise_report"
      data=  FinanceFeeCollection.fetch_finance_fee_course_wise_data(params)
    when "finance_fee_batch_fee_report"
      data=FinanceTransaction.fetch_finance_batch_fee_transaction_data(params)
    when "salary_with_department_report"
      data=FinanceTransaction.fetch_salary_with_department_data(params)
    when /^custom_category/
      data=FinanceTransaction.fetch_income_data(params)
    when "compare_finance_transaction"
      data=FinanceTransaction.fetch_compare_finance_transactions_date(params)
    when "employee_payslip"
      data = MonthlyPayslip.fetch_employee_payslip_data(params)
    when "grouped_exam_report"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('grouped_exam_report','fetch_grouped_exam_data',parameters)
      return
    when "student_wise_report"
      data = CceReport.fetch_student_wise_report(params)
    when "tax_report"
      data = FinanceTransaction.fetch_finance_tax_data(params)
    when "timetable_data"
      data = Timetable.fetch_timetable_data(params)
    when "employee_timetable_data"
      data = Timetable.fetch_employee_timetable_data(params)
    when "student_fees_headwise_report"
      data = Student.fetch_student_fees_data(params)
    when "view_all_payslips"
      data = EmployeePayslip.fetch_group_wise_employee_payslips_data(params)
    when "discipline_complaint_report"
      data = DisciplineComplaint.fetch_discipline_complaint_data(params)
    when "messages_export"
      data = Reminder.fetch_reminder_data(params)
    when "employee_leave_balance_report"
      parameters = {:params => params, :locale => I18n.locale}
      csv_export('employee_leave_balance','fetch_leave_balance_data',parameters)
      return
    when "gradebook_subject_report"
      data = ConvertedAssessmentMark.gradebook_subject_report(params)
    when "gradebook_consolidated_reports"
      data = ConvertedAssessmentMark.gradebook_consolidated_reports(params)
    when "advance_fees"
      data = AdvanceFeeWallet.fetch_advance_fees_data(params)
    else
      FedenaPlugin::AVAILABLE_MODULES.each do |mod|
        modu = mod[:name].camelize.constantize
        if modu.respond_to?("csv_export_list")
          data = modu.send("csv_export_data",report_type,params) if modu.send("csv_export_list").include?(report_type)
        end
      end
    end
    data = write_csv_report(data) if data.present?
    send_data(data, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def write_csv_report(data)
  	csv_data = FasterCSV.generate do |csv|
  	  data.each do |data_row|
        csv << data_row
	    end
  	end
  end

  def csv_export(model,method,parameters)
    csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model,method)
    if csv_report.nil?
      csv_report=AdditionalReportCsv.new(:model_name => model, :method_name => method, :parameters => parameters, :status => true)
      if csv_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
      end
    else
      unless csv_report.status
        if csv_report.update_attributes(:parameters => parameters, :csv_report => nil, :status => true)
          Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
        end
      end 
    end
    flash[:notice]="#{t('csv_report_is_in_queue')}"
    redirect_to :controller => :report, :action=>:csv_reports,:model=>model,:method=>method
  end

  def is_permitted?
    type = params[:csv_report_type]
    unless is_allowed? type,params
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def is_allowed?(type,params) #ToDO Check remaining cases
    case type
    when "subject_wise_report"
      @subject = Subject.find params[:subject_id]
      can_access_request? :generated_report2,@subject,:context=>:exam
    when 'consolidated_exam_report'
      exam_group = ExamGroup.find params[:exam_group]
      can_access_request? :consolidated_exam_report,exam_group.batch,:context=>:exam
    when 'student_ranking_per_subject'
      subject = Subject.find params[:subject_id]
      can_access_request? :student_subject_rank,subject,:context=>:exam
    when 'student_ranking_per_batch'
      batch= Batch.find params[:batch_id]
      can_access_request? :student_batch_rank,batch,:context=>:exam
    when 'student_ranking_per_course'
      can_access_request? :student_course_rank,:exam
    when 'student_ranking_per_attendance'
      batch = Batch.find params[:batch_id]
      can_access_request? :student_attendance_rank,batch,:context=>:exam
    when 'ranking_level'
      can_access_request? :student_ranking_level_report,:exam
    when 'grouped_exam_report'
      batch = Batch.find params[:batch]
      can_access_request? :generated_report4,batch,:context=>:exam
    when 'student_ranking_per_school'
      can_access_request? :student_school_rank,:exam
    when "messages_export"
      (params[:user_id].to_i == current_user.id) or (current_user.parent? and current_user.ward_entry.user_id == params[:user_id].to_i)
    else
      true
    end
  end
end
