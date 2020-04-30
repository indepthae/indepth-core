# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
    
  #ToDo : Deperecated after custom report release, remove file after stable
  class AssessmentGroupReport
    
    attr_accessor :build_coscholastic_report, :student, :students, :headers, :main_header, :build_aggregate_scores, :overall_marks, :overall_grades, :overall_percentage
    
    def initialize(group,batch_group, batch_id)
      @group = group
      @batch_group = batch_group
      @batch =  Batch.find(batch_id, :include => [:subjects,:course, {:students => :converted_assessment_marks}])
      @headers = []
    end
    
    def prepare_data
      @students = batch.effective_students_for_reports
      #      @subjects = batch.subjects.ordered.all(:conditions=>{:no_exams => false,:is_deleted => false})
      @subjects = batch.grouped_subjects
      @grade_set = group.grade_set
      @exam_type = group.exam_type
      if exam_type.activity
        @activities = batch_group.activity_assessments.collect(&:assessment_activity)
      elsif exam_type.subject_attribute||exam_type.subject_wise_attribute
        @attribute_assessments = batch_group.subject_attribute_assessments.all(:joins => :attribute_assessments,
          :include => {:attribute_assessments => :assessment_attribute}, :group => 'subject_attribute_assessments.id')
      end
      @score_settings = AssessmentReportSetting.get_multiple_settings_as_hash AssessmentReportSetting::ATTENDANCE_SETTINGS+AssessmentReportSetting::STUDENT_RECORD_SETTINGS+AssessmentReportSetting::MAIN_REMARK_SETTINGS+AssessmentReportSetting::SUB_REMARK_SETTINGS+AssessmentReportSetting::REMARK_INHERIT_SETTINGS, @group.assessment_plan.id
      self
    end
    
    def build_header
      if exam_type.subject
        @headers = [I18n.t('subject')]
      elsif exam_type.activity
        @headers = [I18n.t('activity'), I18n.t('gb_grade')]
        @headers << I18n.t('credit_points') if @grade_set.enable_credit_points
      elsif exam_type.subject_attribute||exam_type.subject_wise_attribute
        @headers = [I18n.t('subject'), I18n.t('attributes')]
        @headers << I18n.t('marks') unless group.hide_marks
      end
      unless exam_type.activity
        case group.scoring_type
        when 1
          @headers << group.marks_text_with_max_marks if exam_type.subject
          @headers << group.total_marks_with_max_marks if exam_type.subject_attribute||exam_type.subject_wise_attribute
        when 2
          @headers << I18n.t('gb_grade')
        when 3
          @headers << group.marks_text_with_max_marks if exam_type.subject and !group.hide_marks
          @headers << group.total_marks_with_max_marks if (exam_type.subject_attribute||exam_type.subject_wise_attribute) and !group.hide_marks
          @headers << I18n.t('gb_grade')
          @headers << I18n.t('credit_points') if @grade_set.enable_credit_points
        end
      end
      @headers << I18n.t('remarks') if subject_wise_remark_enabled?
    end
    
    def build_scholastic_report
      if exam_type.subject
        subject_assessment_report
      elsif exam_type.activity
        activity_assessment_report
      elsif exam_type.subject_attribute||exam_type.subject_wise_attribute
        attribute_assessment_report
      end
    end
    
    
    def build_attendance(group)
      if exam_type.subject
        subject_attendance_report(group)
      end
    end
    
    def build_student_records
      record_data_table = []
      return unless (is_records_enabled? and is_exam_frequent?)
      gradebook_record_groups = group.assessment_plan.gradebook_record_groups.all(:include=>{:gradebook_records=>{:record_group=>{:records=>:student_records}}},:joins=>:gradebook_records,:group=>'id')
      gradebook_record_groups.to_a.each do |grg|
        record_data = []
        record_data << [[1,'<span class="grg_name">'+grg.name+'</span>']]
        data = group.fetch_record_data(student.s_id,grg,false)#third argument determines whether to add additional blank rows in-order to equalize no.of rows
        data.to_a.each do |row|
          record_data<<[row]
        end
        record_data_table<<record_data
      end
      
      record_data_table
    end
    
    def build_student_remarks
      if general_remark_enabled?
        remarks_data = group.fetch_remark_data(student.s_id)
        remarks_data
      end
    end
    
    private
    
    attr_accessor :batch, :group, :exam_type, :batch_group, :grade_set
    
    def is_records_enabled?
      @score_settings[:enable_student_records] == "1"
    end
    
    def is_manual_attendance?
      @score_settings[:calculation_mode] == "1"
    end
    
    def exam_attendance_enabled?
      @score_settings[:exam_attendance] == "1"
    end
    
    def is_exam_frequent?
      @score_settings[:frequency] == "0"
    end
    
    def general_remark_enabled?
      @score_settings[:general_remarks] == "1"
    end
    
    def subject_wise_remark_enabled?
      @score_settings[:subject_wise_remarks] == "1" and !exam_type.activity
    end
    
    def subject_attendance_report(group)
      attendance_data = []
      if exam_attendance_enabled? and group.consider_attendance
        if is_manual_attendance?
          attendance_entry = GradebookAttendance.all(:conditions=>["student_id = ? and batch_id= ? and linkable_id = ?  and linkable_type = ? and report_type = ?",student.s_id,batch.id,group.id,"exam","exam"])
          if attendance_entry.present?
            percentage = attendance_entry.first.total_days_present*100.0/attendance_entry.first.total_working_days if attendance_entry.first.total_days_present.present? and attendance_entry.first.total_working_days.to_f > 0
            percentage = 0.0 if attendance_entry.first.total_working_days.to_f == 0
            attendance_data<<[I18n.t('percentage_of_days'),percentage.present? ? "#{percentage.round(2)}%": "-"] if @score_settings[:percentage] == "1" # "1" =>show that particular attribute
            attendance_data<<["#{I18n.t('days_present')}/#{I18n.t('no_of_working_days')}",attendance_entry.first.total_days_present.present? ? attendance_entry.first.total_days_present.to_s+"/"+attendance_entry.first.total_working_days.to_s : "-"+"/"+attendance_entry.first.total_working_days.to_s] if @score_settings[:days_present_by_working_days] == "1" 
            attendance_data<<[I18n.t('num_of_working_days'),attendance_entry.first.total_working_days] if @score_settings[:working_days] == "1"
            attendance_data<<[I18n.t('num_of_days_present'),attendance_entry.first.total_days_present.present? ? attendance_entry.first.total_days_present :  "-"] if @score_settings[:days_present] == "1"
            attendance_data<<[I18n.t('num_of_days_absent'),attendance_entry.first.total_days_present.present? ? attendance_entry.first.total_working_days-attendance_entry.first.total_days_present : "-"] if @score_settings[:days_absent] == "1"
          else
            attendance_data<<[I18n.t('percentage_of_days'),"-"] if @score_settings[:percentage] == "1"
            attendance_data<<["#{I18n.t('days_present')}/#{I18n.t('no_of_working_days')}","-"] if @score_settings[:days_present_by_working_days] == "1"
            attendance_data<<[I18n.t('num_of_working_days'),"-"] if @score_settings[:working_days] == "1"
            attendance_data<<[I18n.t('num_of_days_present'),"-"] if @score_settings[:days_present] == "1"
            attendance_data<<[I18n.t('num_of_days_absent'),"-"] if @score_settings[:days_absent] == "1"
          end
        else #auto
          assessment_date = group.assessment_dates.all(:conditions=>{:batch_id=>batch.id}).first
          if assessment_date.present?
            start_date = assessment_date.start_date
            end_date = assessment_date.end_date
            working_days = batch.date_range_working_days(start_date,end_date)
            working_days_count = working_days.count
            student_admission_date = student.admission_date
            student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,working_days,working_days_count)
#            student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? working_days.select {|x| x >= student_admission_date }.length : (start_date >= student_admission_date ? working_days.count : 0)
            leaves_forenoon = Attendance.find(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date,:student_id=>student.id}).count
            leaves_afternoon = Attendance.find(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date,:student_id=>student.id}).count
            leaves_full = Attendance.find(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date,:student_id=>student.id})
            leaves_full =  leaves_full.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
            leaves_full=  leaves_full.count
            leaves_total = leaves_full + 0.5*(leaves_afternoon+leaves_forenoon)
            percentage = student_academic_days == 0 ? "0" : (((student_academic_days-leaves_total)*100.0/student_academic_days).round(2)).to_s+"%"
            attendance_data<<[I18n.t('percentage_of_days'),percentage] if @score_settings[:percentage] == "1"
            attendance_data<<["#{I18n.t('days_present')}/#{I18n.t('no_of_working_days')}",(student_academic_days-leaves_total).to_s+"/"+student_academic_days.to_f.to_s] if @score_settings[:days_present_by_working_days] == "1"
            attendance_data<<[I18n.t('num_of_working_days'),student_academic_days.to_f] if @score_settings[:working_days] == "1"
            attendance_data<<[I18n.t('num_of_days_present'),student_academic_days-leaves_total] if @score_settings[:days_present] == "1"
            attendance_data<<[I18n.t('num_of_days_absent'),leaves_total] if @score_settings[:days_absent] == "1"
          else
            attendance_data<<[I18n.t('percentage_of_days'),"-"] if @score_settings[:percentage] == "1"
            attendance_data<<["#{I18n.t('days_present')}/#{I18n.t('no_of_working_days')}","-"] if @score_settings[:days_present_by_working_days] == "1"
            attendance_data<<[I18n.t('num_of_working_days'),"-"] if @score_settings[:working_days] == "1"
            attendance_data<<[I18n.t('num_of_days_present'),"-"] if @score_settings[:days_present] == "1"
            attendance_data<<[I18n.t('num_of_days_absent'),"-"] if @score_settings[:days_absent] == "1"
          end
        end
      end
      attendance_data
    end
   
    
    def subject_assessment_report
      marks = []
      student_subjects = student.subjects.collect(&:id)
      @subjects.each do |subject|
        if subject.is_a?(Array)
          filtered_subjects = subject.reject{|s| s.elective_group_id? and !(student_subjects.include? s.id) }
          next if filtered_subjects.empty?
          batch_subject_group = filtered_subjects.first.batch_subject_group
          next if batch_subject_group.nil?
          #-------------------------Group Marks in Report------------------------------------#
          converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == batch_subject_group.id and 
                cam.markable_type == 'BatchSubjectGroup' and cam.assessment_group_batch_id == batch_group.id}
          ind_marks = [batch_subject_group.name]
          mark_present = (converted_mark.present? and !converted_mark.is_absent)
          ind_marks = normal_marks(ind_marks, mark_present, converted_mark, batch_subject_group, false)
          marks << ind_marks
          #--------------------------------end-----------------------------------------------#
          filtered_subjects.each do |sub|
            ind_marks = ["<span class='level1'>#{sub.name}</span>"]
            converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == sub.id and 
                cam.markable_type == 'Subject' and cam.assessment_group_batch_id == batch_group.id}
            mark_present = (converted_mark.present? and !converted_mark.is_absent)
            skilled =  (group.skill_assessment? and sub.subject_skill_set_id.present?)
            if skilled
	      col_count = get_col_count(sub)
              marks << normal_marks(ind_marks, mark_present, converted_mark, sub, col_count)
              sub.subject_skill_set.subject_skills.each do |skill|
                ind_marks = ["<span class='level2'>#{skill.name}</span>"]
                marks << skill_marks(ind_marks, mark_present, converted_mark, skill.id, sub, col_count)
                if skill.sub_skills.present?
                  skill.sub_skills.each do |sub_skill|
                    ind_marks = ["<span class='level3'>#{sub_skill.name}</span>"]
                    marks << skill_marks(ind_marks, mark_present, converted_mark, sub_skill.id, sub, col_count)
                  end
                end
              end
            else
              marks << normal_marks(ind_marks, mark_present, converted_mark, sub)
            end
          end
        else
          next if subject.elective_group_id? and !(student_subjects.include? subject.id)
          ind_marks = [subject.name]
          converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == subject.id and 
              cam.markable_type == 'Subject' and cam.assessment_group_batch_id == batch_group.id}
          mark_present = (converted_mark.present? and !converted_mark.is_absent)
          skilled =  (group.skill_assessment? and subject.subject_skill_set_id.present?)
          if skilled
            col_count = get_col_count(subject)
            marks << normal_marks(ind_marks, mark_present, converted_mark, subject, col_count)
            subject.subject_skill_set.subject_skills.each do |skill|
              ind_marks = ["<span class='level1'>#{skill.name}</span>"]
              marks << skill_marks(ind_marks, mark_present, converted_mark, skill.id, subject, col_count)
              if skill.sub_skills.present?
                skill.sub_skills.each do |sub_skill|
                  ind_marks = ["<span class='level2'>#{sub_skill.name}</span>"]
                  marks << skill_marks(ind_marks, mark_present, converted_mark, sub_skill.id, subject, col_count)
                end
              end
            end
          else
            marks << normal_marks(ind_marks, mark_present, converted_mark, subject)
          end
        end
        
      end
      
      marks
    end
    
    def skill_marks(empty_array, mark_present, converted_mark, skill_id, subject, search_marks = true, col_count = 1)
      scoring_type = subject.is_activity? ? 2 : group.scoring_type
      case scoring_type
      when 1
        empty_array << ((search_marks and mark_present) ? converted_mark.skill_mark(skill_id) : '-')
      when 2
        empty_array << ((search_marks and mark_present) ? converted_mark.skill_grade(skill_id) : '-')
      when 3
        empty_array << ((search_marks and mark_present) ? converted_mark.skill_mark(skill_id) : '-') unless group.hide_marks
        empty_array << ((search_marks and mark_present) ? converted_mark.skill_grade(skill_id) : '-')
        empty_array << ((search_marks and mark_present) ? converted_mark.skill_credit_points(skill_id) : '-') if grade_set.enable_credit_points
      end
      if subject_wise_remark_enabled?
        empty_array << {:row_span => col_count, :remark => fetch_subject_wise_remark(subject,student.s_id,group.id)}
      end
      empty_array
    end
    
    def normal_marks(empty_array, mark_present, converted_mark, subject, search_marks = true, col_count = 1)
      scoring_type = subject.is_activity? ? 2 : group.scoring_type
      case scoring_type
      when 1
        empty_array << (mark_present ? converted_mark.mark_with_omm : '-')
      when 2
        if subject.is_activity? and group.mark_and_grade_type?
          count = 2
          count += 1 if grade_set.enable_credit_points
          empty_array << { count => (mark_present ? converted_mark.grade : '-')}
        else
          empty_array << ( mark_present ? converted_mark.grade : '-')
        end
      when 3
        empty_array << ( mark_present ? converted_mark.mark_with_omm : '-') unless group.hide_marks
        empty_array << ( mark_present ? converted_mark.grade : '-')
        empty_array << ( mark_present ? converted_mark.credit_points.to_f : '-') if grade_set.enable_credit_points
      end
      if subject_wise_remark_enabled?
        empty_array << {:row_span => col_count, :remark => fetch_subject_wise_remark(subject,student.s_id,group.id)}
      end
      empty_array
    end
    
    def activity_assessment_report
      marks = []
      @activities.each do |activity|
        ind_marks = [activity.name]
        converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == activity.id and 
            cam.markable_type == 'AssessmentActivity' and cam.assessment_group_batch_id == batch_group.id}
        mark_present = (converted_mark.present? and !converted_mark.is_absent)
        ind_marks << (mark_present ? converted_mark.grade : '-')
        ind_marks << (mark_present ? converted_mark.credit_points.to_f : '-') if grade_set.enable_credit_points
        marks << ind_marks
      end
      
      marks
    end
    
    def attribute_assessment_report
      marks = []
      student_subjects = student.subjects.collect(&:id)
      @subjects.each do |subject|
        if subject.is_a?(Array)
          filtered_subjects = subject.reject{|s| s.elective_group_id? and !(student_subjects.include? s.id) and !s.is_activity }
          next if filtered_subjects.empty?
          batch_subject_group = filtered_subjects.first.batch_subject_group
          next if batch_subject_group.nil?
          #-------------------------Group Marks in Report------------------------------------#
          converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == batch_subject_group.id and 
              cam.markable_type == 'BatchSubjectGroup' and cam.assessment_group_batch_id == batch_group.id}
          ind_marks = [batch_subject_group.name,'','']
          mark_present = (converted_mark.present? and !converted_mark.is_absent)
          ind_marks = normal_marks(ind_marks, mark_present, converted_mark, batch_subject_group, false)
          marks << ind_marks
          #--------------------------------end-----------------------------------------------#
          filtered_subjects.each do |subject|
            next if subject.elective_group_id? and !(student_subjects.include? subject.id)
            ind_marks = ["<span class='level1'>#{subject.name}</span>"]
            converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == subject.id and 
                cam.markable_type == 'Subject' and cam.assessment_group_batch_id == batch_group.id}
            mark_present = (converted_mark.present? and !converted_mark.is_absent)
            attributes = []
            attribute_marks = []
            subject_attrs = @attribute_assessments.select{|a| a.subject_id == subject.id}
            subject_attrs.each do |s_attr|
              s_attr.attribute_assessments.each do |attr|
                attributes << attr.assessment_attribute.name_with_max_mark
                attribute_marks << (mark_present ? (((converted_mark.actual_mark||{})[attr.assessment_attribute_id].present? and 
                        (converted_mark.actual_mark||{})[attr.assessment_attribute_id][:mark].present?) ? 
                      (converted_mark.actual_mark||{})[attr.assessment_attribute_id][:mark] : '-') : '-')
              end
            end
            ind_marks << (attributes.present? ? attributes : '-')
            ind_marks << (attribute_marks.present? ? attribute_marks : '-') unless group.hide_marks
            case group.scoring_type
            when 1
              ind_marks << (mark_present ? converted_mark.mark_with_omm : '-')
            when 3
              ind_marks << (mark_present ? converted_mark.mark_with_omm : '-') unless group.hide_marks
              ind_marks << (mark_present ? converted_mark.grade : '-')
              ind_marks << (mark_present ? converted_mark.credit_points.to_f : '-') if grade_set.enable_credit_points
            end
            ind_marks << fetch_subject_wise_remark(subject,student.s_id,group.id) if subject_wise_remark_enabled?
            marks << ind_marks
          end
          
        else
          next if subject.elective_group_id? and !(student_subjects.include? subject.id)
          ind_marks = [subject.name]
          converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == subject.id and 
              cam.markable_type == 'Subject' and cam.assessment_group_batch_id == batch_group.id}
          mark_present = (converted_mark.present? and !converted_mark.is_absent)
          attributes = []
          attribute_marks = []
          subject_attrs = @attribute_assessments.select{|a| a.subject_id == subject.id}
          subject_attrs.each do |s_attr|
            s_attr.attribute_assessments.each do |attr|
              attributes << attr.assessment_attribute.name_with_max_mark
              attribute_marks << (mark_present ? (((converted_mark.actual_mark||{})[attr.assessment_attribute_id].present? and 
                      (converted_mark.actual_mark||{})[attr.assessment_attribute_id][:mark].present?) ? 
                    (converted_mark.actual_mark||{})[attr.assessment_attribute_id][:mark] : '-') : '-')
            end
          end
          ind_marks << (attributes.present? ? attributes : '-')
          ind_marks << (attribute_marks.present? ? attribute_marks : '-') unless group.hide_marks
          case group.scoring_type
          when 1
            ind_marks << (mark_present ? converted_mark.mark_with_omm : '-')
          when 3
            ind_marks << (mark_present ? converted_mark.mark_with_omm : '-') unless group.hide_marks
            ind_marks << (mark_present ? converted_mark.grade : '-')
            ind_marks << (mark_present ? converted_mark.credit_points.to_f : '-') if grade_set.enable_credit_points
          end
          ind_marks << fetch_subject_wise_remark(subject,student.s_id,group.id) if subject_wise_remark_enabled?
          marks << ind_marks
          
        end
      end
      marks
    end
    
    def fetch_subject_wise_remark(subject,s_id,g_id)
      gradebook_remark = GradebookRemark.find_by_student_id_and_remarkable_id_and_remarkable_type_and_reportable_id_and_reportable_type(s_id,subject.id,"Subject",g_id,"AssessmentGroup")
      return gradebook_remark.present? ? gradebook_remark.remark_body : ""
    end
    
    def get_col_count(subject)
      col_count = 1 + subject.subject_skill_set.subject_skills.count
      sub_skill_count = 0
      subject.subject_skill_set.subject_skills.each{|skill| sub_skill_count += skill.sub_skills.count if skill.sub_skills.present?}
      col_count += sub_skill_count
    end
    
  end
end
