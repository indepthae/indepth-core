# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  
  #ToDo : Deperecated after custom report release, remove file after stable
  class TermReport
    
    attr_accessor :student, :students, :all_groups, :batch_groups, :batch, :headers, :main_header, :overall_marks, :overall_grades, :overall_percentage
    
    def initialize(term, final_assessment, batch_id)
      @term = term
      @final_assessment = final_assessment
      @batch = Batch.find(batch_id, :include => [:subjects,:course, {:students => :converted_assessment_marks}])
      @headers = []
    end
    
    def prepare_data
      #      @subjects = @batch.subjects.ordered.all(:conditions=>{:no_exams => false,:is_deleted => false})
      @subjects = batch.grouped_subjects
      @show_percentage = @final_assessment.show_percentage? if @final_assessment
      @term_groups = term_groups
      @display_groups = display_groups
      @display_group_ids = @display_groups.collect(&:id)
      @all_groups = ( !@final_assessment.no_exam ? @final_assessment.all_assessment_groups : @final_assessment.assessment_groups.without_derived)
      @batch_groups = @batch.assessment_group_batches
      @activity_group = @term.assessment_groups.all(:conditions => {:type => 'ActivityAssessmentGroup'}, 
        :include => {:assessment_group_batches => {:activity_assessments => :assessment_activity}})
      @students = batch.effective_students_for_reports
      fetch_aggregate_column_flags
      
      self
    end
    
    def effective_students
      if @batch.is_active?
        @batch.students.all(:include => [:subjects, :converted_assessment_marks])
      else
        @batch.effective_students
      end
    end
    
    def term_groups
      @final_assessment.assessment_groups
    end
    
    def display_groups
      childrens = []
      @final_assessment.assessment_groups.each do |group|
        childrens += group.all_assessment_groups_for_report('term') if group.derived_assessment? and group.show_child_in_term_report?
        childrens << group
      end
       return childrens.uniq
    end
    
    def derived_assessments
      @term_groups.select{|g| g.type == "DerivedAssessmentGroup"}
    end
    
    def build_header
      @display_groups.each{|group| @headers << group.display_name_with_max_marks}
      unless @final_assessment.no_exam
        @headers << @final_assessment.display_name_with_max_marks
        @headers << I18n.t('gb_grade') if @final_assessment.mark_and_grade_type? and !@final_assessment.hide_marks
        @headers << @final_assessment.display_name_with_percentage if @show_percentage
      end
      @headers << I18n.t('remarks') if subject_wise_remark_enabled?
    end
    
    def scholastic_data(subject, level)
      return if subject.elective_group_id? and !(@student_subjects.include? subject.id)
      ind_marks = ["<span class='level#{level}'>#{subject.name}</span>"]
      report_groups.each do |group|
        group_maximum = group.maximum_marks_for(subject,@batch.course)
        b_group = @batch_groups.detect{|g| g.assessment_group_id == group.id}
        converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == subject.id and 
            cam.markable_type == 'Subject' and cam.assessment_group_batch_id == b_group.id}
        if group == @final_assessment
          mark,grade = ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.mark_and_grades : '-')
          final_score = ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.mark : nil)
          if final_score.present?
            percentage = ((final_score.to_f.round(2)/group_maximum)*100)
            ind_marks << (subject.is_activity? ? '-' : mark) if !group.hide_marks or group.scoring_type != 3
            ind_marks << (subject.is_activity? ? '-' : (grade || '-')) if @final_assessment.mark_and_grade_type?
            ind_marks << (subject.is_activity? ? '-' : percentage.to_f.round(2)) if @show_percentage
          else
            ind_marks << "-"
            ind_marks << '-' if @show_percentage or (@final_assessment.mark_and_grade_type? and !@final_assessment.hide_marks)
          end
        else
          ind_marks << ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.mark_with_grade : '-')
          final_score = ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.mark : 0)
        end
        add_to_overrall_scores(group, final_score) if !subject.exclude_for_final_score
        add_to_subject_total(group, group_maximum) if converted_mark.present?
      end
      col_count = get_col_count(subject)
      ind_marks << {:remark => fetch_subject_wise_remark(subject,student.s_id,@term.id), :row_span => col_count} if subject_wise_remark_enabled?
      @marks << ind_marks
      
      if subject.subject_skill_set_id.present? and has_any_skill_groups?
        skill_set = subject.subject_skill_set
        skill_set.subject_skills.each do |skill|
          ind_marks = ["<span class='level#{level+1}'>#{skill.name}</span>"]
          @display_groups.each do |group|
            b_group = @batch_groups.detect{|g| g.assessment_group_id == group.id}
            converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == subject.id and 
                cam.markable_type == 'Subject' and cam.assessment_group_batch_id == b_group.id}
            ind_marks << ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.skill_mark_with_grade(skill.id) : '-')
          end
          unless @final_assessment.no_exam
            ind_marks << "-"
            ind_marks << '-' if @show_percentage or @final_assessment.mark_and_grade_type?
          end
          @marks << ind_marks
          skill.sub_skills.each do |sub_skill|
            ind_marks = ["<span class='level#{level+2}'>#{sub_skill.name}</span>"]
            @display_groups.each do |group|
              b_group = @batch_groups.detect{|g| g.assessment_group_id == group.id}
              converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == subject.id and 
                  cam.markable_type == 'Subject' and cam.assessment_group_batch_id == b_group.id}
              ind_marks << ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.skill_mark_with_grade(sub_skill.id) : '-')
            end
            unless @final_assessment.no_exam
              ind_marks << "-"
              ind_marks << '-' if @show_percentage or @final_assessment.mark_and_grade_type?
            end
            @marks << ind_marks
          end
        end
      end
    end
    
    def build_scholastic_report(flag)
      @marks = []
      @student_subjects = student.subjects.collect(&:id)
      if !flag
        @overrall_scores = {}
        @subject_total = {}
      end
      @subjects.select{|s| s.exclude_for_final_score == flag}.each do |subject|
        if subject.is_a? Array
          filtered_subjects = subject.reject{|s| s.elective_group_id? and !(@student_subjects.include? s.id) }
          next if filtered_subjects.empty?
          batch_subject_group = filtered_subjects.first.batch_subject_group
          next if batch_subject_group.nil?
          group_head = [filtered_subjects.first.batch_subject_group.name]
          @marks << get_group_marks(group_head, batch_subject_group)
          filtered_subjects.each do |s|
            scholastic_data(s, 1)
          end
        else
          scholastic_data(subject, 0)
        end
      end
      @marks
    end
    
    def add_to_overrall_scores(group, score)
      subject_group_score = @overrall_scores[group.id].present? ? @overrall_scores[group.id] : 0.0
      @overrall_scores[group.id] = subject_group_score + score.to_f.round(2)
    end
    
    def add_to_subject_total(group, maximum_score)
      subject_total = @subject_total[group.id].present? ? @subject_total[group.id] : 0.0
      @subject_total[group.id] = subject_total + maximum_score
    end
    
    def build_aggregate_scores
      if aggregate_score_enabled?
        build_overrall_marks if final_mark_enabled?
        build_overrall_grades if final_grade_enabled?
        build_overall_percentage if final_percentage_enabled?
      end
    end
    
    def build_coscholastic_report
      activities = []
      
      assessment_profiles = AssessmentActivityProfile.find(@activity_group.collect(&:assessment_activity_profile_id),:include=> :assessment_activities)
      @activity_group.group_by(&:assessment_activity_profile_id).each_pair do |key, groups|
        agbs = []
        activity_profile = []
        groups.each{|group| agbs << group.assessment_group_batches.detect{|g_b| g_b.batch_id == @batch.id}}
        agbs = agbs.compact
        header = []
        agbs.each do |agb|
          next unless agb.marks_added?
          header << agb.assessment_group.display_name
          header << I18n.t('gb_grade')
        end
        activity_profile << header
        profile = assessment_profiles.detect{|profile| profile.id == key}
        profile.assessment_activities.each do |activity|
          marks = []
          agbs.each do |agb|
            next unless agb.marks_added?
            converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == activity.id and 
                cam.markable_type == 'AssessmentActivity' and cam.assessment_group_batch_id == agb.id}
            marks << activity.name
            marks << converted_mark.try(:grade)|| '-'
          end
          activity_profile << marks if marks.present?
        end
        activities << activity_profile
      end
      
      
      activities
    end
    
    def build_student_records
      record_data_table = []
      return unless (is_records_enabled? and (is_term_frequent? or is_exam_frequent?))
      gradebook_record_groups = GradebookRecordGroup.find_all_by_id(@term.gradebook_records.collect(&:gradebook_record_group_id),:include=>{:gradebook_records=>{:record_group=>{:records=>:student_records}}}, :order=>:priority) if is_term_frequent?
      gradebook_record_groups = @term.assessment_plan.gradebook_record_groups.all(:include=>{:gradebook_records=>{:record_group=>{:records=>:student_records}}},:joins=>:gradebook_records,:group=>'id', :order=>:priority) if is_exam_frequent?
      gradebook_record_groups.each do |grg|
        record_data = []
        records = []
        if is_exam_frequent?
          gradebook_records = grg.gradebook_records.select{|obj| @term.assessment_groups.collect(&:id).include?obj.linkable_id}
          record_data << [[gradebook_records.length,'<span class="grg_name">'+grg.name+'</span>']]
          gradebook_records.each_with_index.each do |gr,i|
            data = gr.linkable.fetch_record_data(student.s_id,grg,true)#third argument determines whether to add additional blank rows in-order to equalize no.of rows
            records[i] = data unless data.empty?
            records[i].unshift([1,'<b>'+gr.linkable.display_name+'</b>']) unless data.empty?
          end
          arr = records.compact.transpose
          arr.each do |row|
            record_data<<row
          end
        elsif is_term_frequent? 
          record_data << [[1,'<span class="grg_name">'+grg.name+'</span>']]
          data = @term.fetch_record_data(student.s_id,grg,false)
          data.each do |row|
            record_data<<[row]
          end
        end
        record_data_table<<record_data
      end

      record_data_table
    end
    
    def build_student_remarks
      if general_remark_enabled?
        remarks_data = @term.fetch_remark_data(student.s_id)
        remarks_data
      end
    end
    
    def build_attendance(term)
      flag = false
      attendance_data = []
      if is_manual_attendance?
        if @score_settings[:term_report] == "1" and @score_settings[:term_attendance] == "1"
          attendance_entry = GradebookAttendance.all(:conditions=>["student_id = ? and linkable_id = ?  and linkable_type = ? and report_type = ? and batch_id = ?",student.id,@term.id,"term","term",batch.id])
          if attendance_entry.present?
            percentage = attendance_entry.first.total_days_present*100.0/attendance_entry.first.total_working_days if attendance_entry.first.total_days_present.present? and attendance_entry.first.total_working_days.to_f > 0
            percentage = 0.0 if attendance_entry.first.total_working_days.to_f == 0
            attendance_data<<[I18n.t('percentage_of_days'),percentage.present? ? "#{percentage.round(2)}%": "-"] if @score_settings[:percentage] == "1"
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
        elsif @score_settings[:term_report] == "0" and @score_settings[:term_attendance] == "1"
          exams = @term.assessment_groups.all(:conditions=>["consider_attendance = ?",true])
          row0 = [""]
          row1 = [I18n.t('percentage_of_days')]
          row2 = ["#{I18n.t('days_present')}/#{I18n.t('no_of_working_days')}"]
          row3 = [I18n.t('num_of_working_days')]
          row4 = [I18n.t('num_of_days_present')]
          row5 = [I18n.t('num_of_days_absent')]
          total_working_days = 0
          total_days_present = 0
          exams.each do |exam|
            attendance_entry = GradebookAttendance.all(:conditions=>["student_id = ? and linkable_id = ?  and linkable_type = ? and report_type = ? and batch_id = ?",student.id,exam.id,"exam","term",batch.id])
            if attendance_entry.present?
              flag = true
              percentage = -1
              percentage = attendance_entry.first.total_days_present*100.0/attendance_entry.first.total_working_days if attendance_entry.first.total_days_present.present? and attendance_entry.first.total_working_days.to_f > 0
              percentage = 0.0 if attendance_entry.first.total_working_days.to_f == 0
              row0<<exam.display_name if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
              row1<<(percentage != -1 ? "#{percentage.round(2)}%": "-") if @score_settings[:percentage] == "1"
              row2<<(attendance_entry.first.total_days_present.present? ? attendance_entry.first.total_days_present.to_s+"/"+attendance_entry.first.total_working_days.to_s : "-"+"/"+attendance_entry.first.total_working_days.to_s) if @score_settings[:days_present_by_working_days] == "1"
              row3<<attendance_entry.first.total_working_days if @score_settings[:working_days] == "1"
              row4<<(attendance_entry.first.total_days_present.present? ? attendance_entry.first.total_days_present :  "-") if @score_settings[:days_present] == "1"
              row5<<(attendance_entry.first.total_days_present.present? ? attendance_entry.first.total_working_days-attendance_entry.first.total_days_present : "-") if @score_settings[:days_absent] == "1"
            elsif exam.type == "DerivedAssessmentGroup"
              flag = true
              attendance_entry_present = false
              child_exams = exam.assessment_groups
              child_exams.each do |child_exam|
                attendance_entry = GradebookAttendance.all(:conditions=>["student_id = ? and linkable_id = ?  and linkable_type = ? and report_type = ?",student.id,child_exam.id,"exam","term"])
                if attendance_entry.present?
                  attendance_entry_present = true
                  total_working_days += attendance_entry.first.total_working_days
                  total_days_present += attendance_entry.first.total_days_present if attendance_entry.first.total_days_present.present?
                end
              end
              if attendance_entry_present
                percentage = -1
                percentage = total_days_present*100.0/total_working_days if total_days_present.present? and total_working_days.to_f > 0
                percentage = 0.0 if total_working_days.to_f == 0
                row0<<exam.display_name if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
                row1<<(percentage != -1 ? "#{percentage.round(2)}%": "-") if @score_settings[:percentage] == "1"
                row2<<(total_days_present.present? ? total_days_present.to_s+"/"+total_working_days.to_s : "-"+"/"+total_working_days.to_s) if @score_settings[:days_present_by_working_days] == "1"
                row3<<total_working_days if @score_settings[:working_days] == "1"
                row4<<(total_days_present.present? ? total_days_present :  "-") if @score_settings[:days_present] == "1"
                row5<<(total_days_present.present? ? total_working_days-total_days_present : "-") if @score_settings[:days_absent] == "1"
              else
                row0<<exam.display_name if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
                row1<<"-" if @score_settings[:percentage] == "1"
                row2<<"-" if @score_settings[:days_present_by_working_days] == "1"
                row3<<"-" if @score_settings[:working_days] == "1"
                row4<<"-" if @score_settings[:days_present] == "1"
                row5<<"-" if @score_settings[:days_absent] == "1"
              end
            else
              flag = true
              row0<<exam.display_name if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
              row1<<"-" if @score_settings[:percentage] == "1"
              row2<<"-" if @score_settings[:days_present_by_working_days] == "1"
              row3<<"-" if @score_settings[:working_days] == "1"
              row4<<"-" if @score_settings[:days_present] == "1"
              row5<<"-" if @score_settings[:days_absent] == "1"
            end
          end
          if flag
            attendance_data<<row0 if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
            attendance_data<<row1 if @score_settings[:percentage] == "1"
            attendance_data<<row2 if @score_settings[:days_present_by_working_days] == "1"
            attendance_data<<row3 if @score_settings[:working_days] == "1"
            attendance_data<<row4 if @score_settings[:days_present] == "1"
            attendance_data<<row5 if @score_settings[:days_absent] == "1"
          end
        end
      else #auto
        if @score_settings[:term_report] == "1" and @score_settings[:term_attendance] == "1"
          start_date = @term.start_date
          end_date = @term.end_date
          working_days = batch.date_range_working_days(start_date,end_date)
          working_days_count = working_days.count
          student_admission_date = student.admission_date
          student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,working_days,working_days_count)# if @score_settings[:include_exam_duration] == "1"
#          student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (working_days.select {|x| x >= student_admission_date }.length) : (start_date >= student_admission_date ? (working_days.count) : 0)# if @score_settings[:include_exam_duration] == "1"
          leaves_forenoon = Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date,:student_id=>student.id}).count
          leaves_afternoon = Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date,:student_id=>student.id}).count
          leaves_full = Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date,:student_id=>student.id}).count
          leaves_full =  leaves_full.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
          leaves_full=  leaves_full.count
          leaves_total = leaves_full + 0.5*(leaves_afternoon+leaves_forenoon)
          percentage = student_academic_days == 0 ? "0" : (((student_academic_days-leaves_total)*100.0/student_academic_days).round(2)).to_s+"%"
          attendance_data<<[I18n.t('percentage_of_days'),percentage] if @score_settings[:percentage] == "1"
          attendance_data<<["#{I18n.t('days_present')}/#{I18n.t('no_of_working_days')}",(student_academic_days-leaves_total).to_s+"/"+student_academic_days.to_f.to_s] if @score_settings[:days_present_by_working_days] == "1"
          attendance_data<<[I18n.t('num_of_working_days'),student_academic_days.to_f] if @score_settings[:working_days] == "1"
          attendance_data<<[I18n.t('num_of_days_present'),student_academic_days-leaves_total] if @score_settings[:days_present] == "1"
          attendance_data<<[I18n.t('num_of_days_absent'),leaves_total] if @score_settings[:days_absent] == "1"
        elsif @score_settings[:term_report] == "0" and @score_settings[:term_attendance] == "1"
          exams = @term.assessment_groups.all(:conditions=>["consider_attendance = ? and type = ? and is_single_mark_entry = ?",true,"SubjectAssessmentGroup",true])
          row0 = [""]
          row1 = [I18n.t('percentage_of_days')]
          row2 = ["#{I18n.t('days_present')}/#{I18n.t('no_of_working_days')}"]
          row3 = [I18n.t('num_of_working_days')]
          row4 = [I18n.t('num_of_days_present')]
          row5 = [I18n.t('num_of_days_absent')]
          exams.each do |exam|
            assessment_date = exam.assessment_dates.all(:conditions=>{:batch_id=>batch.id}).first
            if assessment_date.present?
              flag = true
              start_date = assessment_date.start_date
              end_date = assessment_date.end_date
              student_admission_date = student.admission_date
              working_days = batch.date_range_working_days(start_date,end_date)
              working_days_count = working_days.count
              student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,working_days,working_days_count)
#              student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (working_days.select {|x| x >= student_admission_date }.length) : (start_date >= student_admission_date ? (working_days.count) : 0)
              leaves_forenoon = Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date,:student_id=>student.id}).count
              leaves_afternoon = Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date,:student_id=>student.id}).count
              leaves_full = Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date,:student_id=>student.id})
              leaves_full =  leaves_full.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
              leaves_full=  leaves_full.count
              leaves_total = leaves_full + 0.5*(leaves_afternoon+leaves_forenoon)
              percentage = student_academic_days == 0 ? "0" : (((student_academic_days-leaves_total)*100.0/student_academic_days).round(2)).to_s+"%"
              row0<<exam.display_name if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
              row1<<percentage if @score_settings[:percentage] == "1"
              row2<<(student_academic_days-leaves_total).to_s+"/"+student_academic_days.to_f.to_s if @score_settings[:days_present_by_working_days] == "1"
              row3<<student_academic_days.to_f if @score_settings[:working_days] == "1"
              row4<<student_academic_days-leaves_total if @score_settings[:days_present] == "1"
              row5<<leaves_total if @score_settings[:days_absent] == "1"
            elsif exam.type == "DerivedAssessmentGroup"
              child_exams = exam.assessment_groups
              leaves_forenoon = 0
              leaves_afternoon = 0
              leaves_full = 0
              student_academic_days = 0
              child_exams.each do |child_exam|
                assessment_date = child_exam.assessment_dates.all(:conditions=>{:batch_id=>batch.id}).first
                if assessment_date.present?
                  flag = true
                  start_date = assessment_date.start_date
                  end_date = assessment_date.end_date
                  student_admission_date = student.admission_date
                  working_days = batch.date_range_working_days(start_date,end_date)
                  working_days_count = working_days.count
                  student_academic_days += Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,working_days,working_days_count)
#                  student_academic_days += (student_admission_date <= end_date && student_admission_date >= start_date) ? (working_days.select {|x| x >= student_admission_date }.length) : (start_date >= student_admission_date ? (working_days.count) : 0)
                  leaves_forenoon += Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date,:student_id=>student.id}).count
                  leaves_afternoon += Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date,:student_id=>student.id}).count
                  leaves_full = Attendance.find(:all,:conditions => {:batch_id=>batch.id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date,:student_id=>student.id})
                  leaves_full =  leaves_full.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
                  leaves_full +=  leaves_full.count
                  leaves_total = (leaves_full + 0.5*(leaves_afternoon+leaves_forenoon))
                end
              end
              if flag
                percentage = student_academic_days == 0 ? "-" : (((student_academic_days-leaves_total)*100.0/student_academic_days).round(2)).to_s+"%"
                row0<<exam.display_name if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
                row1<<percentage if @score_settings[:percentage] == "1"
                row2<<(student_academic_days-leaves_total).to_s+"/"+student_academic_days.to_f.to_s if @score_settings[:days_present_by_working_days] == "1"
                row3<<student_academic_days.to_f if @score_settings[:working_days] == "1"
                row4<<student_academic_days-leaves_total if @score_settings[:days_present] == "1"
                row5<<leaves_total if @score_settings[:days_absent] == "1"
              else
                flag = true
                row0<<exam.display_name if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
                row1<<"-" if @score_settings[:percentage] == "1"
                row2<<"-" if @score_settings[:days_present_by_working_days] == "1"
                row3<<"-" if @score_settings[:working_days] == "1"
                row4<<"-" if @score_settings[:days_present] == "1"
                row5<<"-" if @score_settings[:days_absent] == "1"
              end
            else
              flag = true
              row0<<exam.display_name if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
              row1<<"-" if @score_settings[:percentage] == "1"
              row2<<"-" if @score_settings[:days_present_by_working_days] == "1"
              row3<<"-" if @score_settings[:working_days] == "1"
              row4<<"-" if @score_settings[:days_present] == "1"
              row5<<"-" if @score_settings[:days_absent] == "1"
            end
          end
          if flag
            attendance_data<<row0 if @score_settings[:percentage] == "1" or @score_settings[:days_present_by_working_days] == "1" or @score_settings[:working_days] == "1" or @score_settings[:days_present] == "1" or @score_settings[:days_absent] == "1"
            attendance_data<<row1 if @score_settings[:percentage] == "1"
            attendance_data<<row2 if @score_settings[:days_present_by_working_days] == "1"
            attendance_data<<row3 if @score_settings[:working_days] == "1"
            attendance_data<<row4 if @score_settings[:days_present] == "1"
            attendance_data<<row5 if @score_settings[:days_absent] == "1"
          end
        end
      end
      attendance_data
    end
    
    private
    
    def is_manual_attendance?
      @score_settings[:calculation_mode] == "1"
    end
    
    def is_records_enabled?
      @score_settings[:enable_student_records] == "1"
    end
    
    def is_term_frequent?
      @score_settings[:frequency] == "1"
    end
    
    def is_exam_frequent?
      @score_settings[:frequency] == "0"
    end
    
    def get_column_count
      column_count = @display_groups.length
      unless @final_assessment.no_exam
        column_count += 1
        column_count += 1 if @show_percentage or @final_assessment.scoring_type == 3
      end
      column_count += 1 if subject_wise_remark_enabled?
      column_count
    end

    def get_group_marks(ind_marks, batch_subject_group)
      report_groups.each do |group|
        batch_group = @batch_groups.detect{|g| g.assessment_group_id == group.id}
        converted_mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == batch_subject_group.id and 
            cam.markable_type == 'BatchSubjectGroup' and cam.assessment_group_batch_id == batch_group.id}
        if group == @final_assessment
          mark,grade = ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.mark_and_grades : '-')
          final_score = ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.mark : nil)
          if final_score.present?
            ind_marks <<  mark
            ind_marks << (grade || '-') if @final_assessment.mark_and_grade_type?
          else
            ind_marks << "-"
            ind_marks << '-' if @final_assessment.mark_and_grade_type?
          end
          ind_marks << '-' if @show_percentage
          ind_marks << '-' if subject_wise_remark_enabled?
        else
          ind_marks << ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.mark_with_grade : '-')
        end
        
      end
      
      ind_marks
    end
    
    def fetch_aggregate_column_flags
      plan_id = @term.assessment_plan_id
      @score_settings = AssessmentReportSetting.get_multiple_settings_as_hash(AssessmentReportSetting::SCORE_SETTINGS+AssessmentReportSetting::ATTENDANCE_SETTINGS+AssessmentReportSetting::STUDENT_RECORD_SETTINGS+AssessmentReportSetting::MAIN_REMARK_SETTINGS+AssessmentReportSetting::SUB_REMARK_SETTINGS+AssessmentReportSetting::REMARK_INHERIT_SETTINGS, plan_id)
      @overall_grade_set =GradeSet.find_by_id(@score_settings[:grade_set_id], :include => :grades)
    end
    
    def aggregate_score_enabled?
      @score_settings[:enable_aggregate] == '1'
    end
    
    def final_score_for_all_exams_enabled?
      @score_settings[:all_exam_score] == '0'
    end
    
    def final_score_for_final_exam_enabled?
      @score_settings[:all_exam_score] == '1' and  !@final_assessment.no_exam
    end
    
    def final_mark_enabled?
      @score_settings[:show_total_score] == '1'
    end
    
    def final_grade_enabled?
      @score_settings[:show_final_grade] == '1'
    end
    
    def final_percentage_enabled?
      @score_settings[:show_final_percentage] == '1'
    end
    
    def general_remark_enabled?
      @score_settings[:general_remarks] == "1"
    end
    
    def subject_wise_remark_enabled?
      @score_settings[:subject_wise_remarks] == "1"
    end
    
    def build_overrall_marks
      if final_score_for_all_exams_enabled?
        @overall_marks = [I18n.t('total_score'),'1']
        marks = []
        @display_groups.each do |group|
          if @subject_total[group.id].present? and !@subject_total[group.id].zero?
            marks << (group.scoring_type == 2 ? '-' : @overrall_scores[group.id])
          else
            marks << '-'
          end
        end
        unless @final_assessment.no_exam
          if @subject_total[@final_assessment.id].present? and !@subject_total[@final_assessment.id].zero?
            marks << @overrall_scores[@final_assessment.id]
          else
            marks << '-'
          end
          marks << "-" if subject_wise_remark_enabled?
          marks << '-' if extra_final_column_required?
        end
        @overall_marks << marks
      elsif final_score_for_final_exam_enabled?
        @overall_marks = [I18n.t('total_score'),"#{@display_groups.count + 1}"]
        marks = []
        if @subject_total[@final_assessment.id].present? and !@subject_total[@final_assessment.id].zero?
          marks << @overrall_scores[@final_assessment.id] 
        else
          marks << '-'
        end
        marks << "-" if subject_wise_remark_enabled?
        marks << '-' if extra_final_column_required?
        @overall_marks << marks
      end
    end
    
    def build_overrall_grades
      if final_score_for_all_exams_enabled?
        @overall_grades = [I18n.t('overrall_grade'),'1']
        grades = []
        @display_groups.each do |group|
          if @overall_grade_set.present? and group.scoring_type != 2
            grades << final_grade(group)
          else
            grades << '-'
          end
        end
        if !@final_assessment.no_exam and @overall_grade_set.present?
          grades << final_grade(@final_assessment)
        elsif !@final_assessment.no_exam
          grades << '-'
        end
        grades << '-' if extra_final_column_required?
        grades << "-" if subject_wise_remark_enabled?
        @overall_grades << grades
      elsif final_score_for_final_exam_enabled?
        @overall_grades = [I18n.t('overrall_grade'),"#{@display_groups.count + 1}"]
        grades = []
        if @overall_grade_set.present?
          grades << final_grade(@final_assessment)
        else
          grades << '-'
        end
        grades << '-' if extra_final_column_required?
        grades << "-" if subject_wise_remark_enabled?
        @overall_grades << grades
      end
    end
    
    def build_overall_percentage
      if final_score_for_all_exams_enabled?
        @overall_percentage = [I18n.t('final_percentage'),'1']
        percentages = []
        @display_groups.each do |group|
          percentages << final_percentage(group)
        end
        unless @final_assessment.no_exam
          percentages << final_percentage(@final_assessment)
          percentages << '-' if extra_final_column_required?
          percentages << "-" if subject_wise_remark_enabled?
        end
        @overall_percentage << percentages
      else
        @overall_percentage = [I18n.t('final_percentage'),"#{@display_groups.count + 1}"]
        percentages = []
        unless @final_assessment.no_exam
          percentages << final_percentage(@final_assessment)
          percentages << '-' if extra_final_column_required?
          percentages << "-" if subject_wise_remark_enabled?
        end
        @overall_percentage << percentages
      end
    end
    
    def extra_final_column_required?
      !@final_assessment.no_exam and (@show_percentage or (@final_assessment.scoring_type == 3 and !@final_assessment.hide_marks))
    end
    
    def final_grade(group)
      if @subject_total[group.id].present?
        @subject_total[group.id].zero? ? '-' : @overall_grade_set.grade_string_for(((@overrall_scores[group.id] / @subject_total[group.id]) * 100).round(2))
      else
        '-'
      end
    end
    
    def final_percentage(group)
      if @subject_total[group.id].present?
        @subject_total[group.id].zero? ? '-' :  ((@overrall_scores[group.id] / @subject_total[group.id]) * 100).round(2) 
      else
        '-'
      end
    end
    
    def assessment_groups
      childrens = []
      @final_assessment.assessment_groups.each do |group|
        childrens += group.assessment_groups if group.derived_assessment? and group.show_child_in_term_report?
        childrens << group
      end
      return childrens.uniq
    end
    
    def has_any_skill_groups?
      @display_groups.collect{|d| d.consider_skills }.include? true
    end

    def report_groups
       !@final_assessment.no_exam ? @display_groups + [@final_assessment] : @display_groups
    end
    
    def fetch_subject_wise_remark(subject,s_id,t_id)
      gradebook_remark = GradebookRemark.find_by_student_id_and_remarkable_id_and_remarkable_type_and_reportable_id_and_reportable_type(s_id,subject.id,"Subject",t_id,"AssessmentTerm")
      return gradebook_remark.present? ? gradebook_remark.remark_body : ""
    end
    
    def get_col_count(subject)
      col_count = 1
      if subject.subject_skill_set_id.present? and has_any_skill_groups?
        skill_set = subject.subject_skill_set
        col_count += skill_set.subject_skills.count
        sub_skill_count = 0
        skill_set.subject_skills.each {|skill| sub_skill_count += skill.sub_skills.count if skill.sub_skills.present?}
        col_count += sub_skill_count
      end
      col_count
    end
    
  end
end
