module Gradebook
  module Components
    class ReportFactory < ComponentFactory
      def process_and_build_components
        prepare_data
        @reports = []
        @errors = []
        pre_generation_check
        return status_report if errors.present?
        
        school_details = build_school_details
        students.each do |student|
          sub_components = process_subjects(student)
          reports << Models::Report.new(
            :name => reportable.name,
            :display_name => reportable.display_name,
            :type => reportable.class.table_name.classify,
            :academic_year => reportable.academic_year.try(:name) || "",
            :subjects => sub_components,
            :exam_sets => process_exam_scores(student,sub_components),
            :activity_sets => process_activities(student),
            :student => build_student_details(student),
            :remarks => process_remarks(student),
            :attendance_reports => process_attendance(student),
            :school_details => school_details,
            :grade_scales => build_grade_scales,
            :report_template => template,
            :subject_remarks => process_subject_remarks(subjects, student),
            :header_name => header_name,
            :subjectwise_attendance => process_subjectwise_attendance(student,sub_components),
            :cumulative_subjectwise_attendance => process_cumulative_subjectwise_attendance(student,sub_components)
          )
        end
        process_and_insert_reports
        
        return status_report
      end
      
      def process_subjects(student)
        SubjectFactory.build(:reportable => reportable, :student => student)
      end
      
      def process_subjectwise_attendance(student,sub_components)
       SubjectwiseAttendanceFactory.build(:reportable => reportable ,:student => student, :sub=> sub_components ,:reportable_child => reportable,:cumulative=>false)
      end
      
      def process_cumulative_subjectwise_attendance(student,sub_components)
       SubjectwiseAttendanceFactory.build(:reportable => reportable ,:student => student, :sub=> sub_components ,:reportable_child => reportable,:cumulative=>true)
      end
        
      def process_activities(student)
        ActivityScoreFactory.build(:reportable => reportable, :student => student)
      end
      
      def process_attendance(student)
        if is_assessment_plan? and is_all_terms?
          reports = new_collection
          reportable.assessment_terms.each do |term|
            reports.push AttendanceFactory.build(:reportable => reportable, :student => student, :reportable_child => term)
          end
          
          return reports
        elsif is_consolidated_attendance?
          AttendanceFactory.build(:reportable => reportable, :student => student, :reportable_child => reportable)
        end
      end
        
      def process_exam_scores(student, sub_components)
        ExamScoreFactory.build(:reportable => reportable, :student => student, :sub_components => sub_components )
      end
      
      # => To build general remark
      # => params:
      #     student: student for whom remarks to be build
      # => returns: Collection of Remarks
      def process_remarks(student)
        RemarkFactory.build(:reportable => reportable, :student => student, :subject => nil)
      end
      
      def process_subject_remarks(subjects, student)
        RemarkFactory.build(:reportable => reportable, :student => student, :subjects => subjects)
      end
     
      def process_records(student)
        RecordFactory.build(:reportable => reportable, :student => student)
      end
      
      def build_grade_scales
        GradeScaleFactory.build(:reportable => reportable)
      end
      
      def build_school_details
        name = Configuration.get_config_value('InstitutionName')
        address = Configuration.get_config_value('InstitutionAddress')
        email_with_website = build_email_with_website_details
        current_school_detail = SchoolDetail.first||SchoolDetail.new
        logo = current_school_detail.logo.present? ? true : false
        Models::SchoolDetail.new(
          :name => name,
          :address => address,
          :logo => logo,
          :email_with_website => email_with_website
        )
      end
      
      def build_student_details(student)
        Models::StudentDetail.new(
          :obj_id => student.s_id,
          :name => student.full_name,
          :records => process_records(student),
          :details => process_details(student)
        )
      end
      
      private
        
      attr_accessor :reportable, :assessment_groups, :reportable_child, :report_batch_id, :reports, :errors
      
      ##
      # Preparing Data for the report building for avoiding query firing on loops
      # Setting to Components Module mattr_accessors for accessing across modules
      def prepare_data
        Components.batch = Batch.find(@batch_id, :include => [:course, :subjects, :assessment_group_batches,:attendance_weekday_sets])
        Components.subjects = batch.subjects.ordered.all(
          :conditions=>{:no_exams => false,:is_deleted => false},
          :include => [:batch_subject_group, { :subject_skill_set => {:subject_skills => :sub_skills} }]
        )
        Components.students = batch.effective_students_for_reports
        Components.assessment_groups = reportable.report_groups
        Components.holiday_event_dates = batch.holiday_event_dates
        Components.all_assessment_groups = reportable.get_assessment_groups
        Components.activity_groups = reportable.activity_groups
        Components.settings = AssessmentReportSetting.get_multiple_settings_as_hash(
          AssessmentReportSetting::SETTINGS + AssessmentReportSetting::SCORE_SETTINGS+
            AssessmentReportSetting::ATTENDANCE_SETTINGS + AssessmentReportSetting::MAIN_REMARK_SETTINGS+
            AssessmentReportSetting::SUB_REMARK_SETTINGS + AssessmentReportSetting::REMARK_INHERIT_SETTINGS+
            AssessmentReportSetting::STUDENT_RECORD_SETTINGS + AssessmentReportSetting::SCORE_ROUNDING_SETTINGS, assessment_plan.id
        )
        Components.attendance_entries = GradebookAttendance.all(:conditions=>["batch_id= ? and report_type = ?",batch.id,reportable.reportable_type_for_attendance])
        Components.assessment_date = AssessmentDate.all(:conditions=>{:batch_id=>batch.id})
        Components.gradebook_remarks = GradebookRemark.find_all_by_batch_id(batch.id,:include => [:reportable,:remarkable]) if remarks_enabled?
        Components.overall_grade_set =GradeSet.find_by_id(settings[:grade_set_id], :include => :grades)
        Components.grade_sets = GradeSet.find_all_by_id [settings[:scholastic_grade_scale], settings[:co_scholastic_grade_scale]]
        Components.gradebook_record_groups = assessment_plan.gradebook_record_groups.all(
          :include=>{:gradebook_records=>{:record_group=>{:records=>:student_records}}},
          :joins=>:gradebook_records,:group=>'id', :order=>:priority
        )
        Components.attendances = Attendance.all(:conditions=>{:batch_id=>batch.id})
        Components.scores_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
        Components.exam_totals_hash = Hash.new{ |h,k| h[k] = Hash.new }
      end
      
      def is_consolidated_attendance?
        ((is_assessment_term? and settings[:term_attendance] == "1" and settings[:term_report] == "1") ||
            ( is_assessment_plan? and settings[:planner_attendance] == "1" and settings[:planner_report] == "2"))
      end
      
      def is_all_terms?
        (settings[:planner_attendance] == "1" and settings[:planner_report] == "1")
      end
      
      def build_email_with_website_details
        institution_contacts = []
        institution_contacts.push(Configuration.get_config_value('InstitutionPhoneNo')) if Configuration.get_config_value('InstitutionPhoneNo').present?
        institution_contacts.push(Configuration.get_config_value('InstitutionEmail')) if Configuration.get_config_value('InstitutionEmail').present?
        institution_contacts.push(Configuration.get_config_value('InstitutionWebsite')) if Configuration.get_config_value('InstitutionWebsite').present?
        institution_contacts = institution_contacts.join(" | ")
        return "<br/>#{institution_contacts}"
      end
      
      ##
      # Fetch student details as per settings
      # params:
      # => student
      # returns array having duplet of display label and display value
      def process_details(student)
        student.batch_in_context_id = batch.id
        details = new_collection
        (1..10).each do |i|
          display_text = AssessmentReportSetting.get_display_text(settings["StudentDetail#{i}".underscore.to_sym])
          unless display_text == ""
            details.push [display_text, AssessmentReportSetting.get_display_value(settings["StudentDetail#{i}".underscore.to_sym],student)]
          end
        end
        
        details
      end
      
      # => params: nil
      # => returns: true if general or subject-wise remarks enabled else false
      def remarks_enabled?
        general_remark_enabled? or subject_wise_remark_enabled?
      end
           
      def template
        settings[:custom_template]
      end
      
      def header_name
        if is_assessment_group?
          "#{I18n.t('student_exam_report').upcase} - #{reportable.display_name} - #{reportable.parent.name}"
        elsif is_assessment_term?
          I18n.t('student_term_report')
        else
          I18n.t('student_report').titleize
        end
      end
      
      ##
      # process and calculating aggregate scores. Sets the aggregate score to 
      # each report object and creating student individual reports
      def process_and_insert_reports
        reduced_subject_ranks = process_subject_level_rankings
        reduced_exam_set_ranks = process_exam_set_level_rankings
        
        reports.each do  |report|
          report.exam_sets.each do |set|
            set.set_subject_rank_details(reduced_subject_ranks[report.student.obj_id][set.obj_id])
            set.set_exam_set_rank_details(reduced_exam_set_ranks[report.student.obj_id][set.obj_id])
          end
          ind_report = IndividualReport.new(
            :reportable => reportable,
            :student_id => report.student.obj_id,
            :report_component => report,
            :generated_report_batch_id => report_batch_id
          )
          log_error!(ind_report.errors.full_messages) unless ind_report.save
        end
      end

      # process subject level ranking details
      def process_subject_level_rankings
        reduced_subject_ranks = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
        scores_hash.each_pair do |ass_id, score|
          score.each_pair do |sub_id, subject_score|
            subjects_total = subject_score.sort_by{|k,v| v}.reverse
            total = subjects_total.map{|x| x.last}
            sorted = total.sort.uniq.reverse
            rank = total.map{|e| sorted.index(e) + 1}
            rank_arr = []
            rank.each_with_index do |r,i|
              rank_arr<<[subjects_total[i].first,r]
            end
            rank_hash = Hash[rank_arr]
            students.each do |student|
              reduced_subject_ranks[student.id][ass_id][sub_id] = {
                  :rank => rank_hash[student.id],
                  :highest_score => sorted.first,
                  :lowest_score => sorted.last,
                  :average_score => (sorted.sum/ sorted.length)
              }
            end
          end
        end
        reduced_subject_ranks
      end

      # process exam_set level ranking details
      def process_exam_set_level_rankings
        reduced_exam_set_ranks = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
        exam_totals_hash.each_pair do |assessment_group_id, totals|
          sorted_totals = totals.values.uniq.sort.reverse
          totals.each_pair do |student_id, total|
            reduced_exam_set_ranks[student_id][assessment_group_id] = {
                :rank => sorted_totals.index(total) + 1,
                :highest_score => sorted_totals.first,
                :lowest_score => sorted_totals.last,
                :average_score => (sorted_totals.sum/ sorted_totals.length)
            }
          end
        end
        reduced_exam_set_ranks
      end

      def pre_generation_check
        check_final_assessment
        return if @errors.present?
        check_attendance_warning unless is_assessment_group?
        check_submission_status!

        #resetting individual reports unless errors present from above ops
        reset_individual_reports! unless errors.present?
      end
      
      def check_attendance_warning
        unless term_dates_present?
          log_error! "#{I18n.t('term_dates_not_set')}" if is_automatic_attendance?
        end
      end
      
      def check_submission_status!
        unless students.present?
          log_error! "#{I18n.t('no_students_for_this_batch')}" 
          return
        end
        Components.assessment_groups.each do |group|
          next if is_final_exam_with_no_exam?(group)
          b_group = group.assessment_group_batches.detect{|g| g.batch_id == batch.id}
          if group.derived_assessment?
            log_error! "#{group.name} - #{I18n.t('marks_not_calculated')}" unless b_group.present? and b_group.try(:marks_added)
          else
            if b_group.present? and  b_group.childrens_present?
              log_error! "#{group.name} - #{I18n.t('no_marks_entered')}" unless b_group.try(:marks_added) 
            else
              log_error! "#{group.name} - #{I18n.t('not_scheduled')}"
            end
          end
        end
      end
      
      def check_final_assessment
        log_error! I18n.t('final_exam_not_configured') if reportable.final_assessment.nil? or reportable.final_assessment.new_record?
      end
      
      def term_dates_present?
        term_dates_present = if reportable.is_a? AssessmentTerm
          reportable.end_date.present? and reportable.start_date.present?
        else
          dates_present = []
          reportable.assessment_terms.each{|t| dates_present << (t.end_date.present? and t.start_date.present?)}
          !dates_present.include?(false)
        end
    
        term_dates_present
      end
      
      def is_automatic_attendance?
        (settings[:calculation_mode] == "0") and (settings[:enable_attendance] == "1")
      end
      
      def reset_individual_reports!
        IndividualReport.all(:conditions =>
            {:reportable_id => reportable.id,
            :reportable_type => reportable.class.table_name.classify,
            :student_id => students.collect(&:s_id),
            :generated_report_batch_id => report_batch_id
          }).each{|entry| entry.destroy }
      end
      
      def log_error!(messages)
        @errors += Array(messages)
      end
      
      ##
      # returns object with report build status (failed or success)
      # Access Through : status.success, status.failed, status.errors
      def status_report
        Status.new(!errors.present?,errors.present?, errors)
      end
        
    end
  end
end
