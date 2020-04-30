class DelayedAssessmentMarksSubmission < Struct.new(:assessment_id, :assessment_type)
  attr_accessor :student_subjects, :batch, :all_groups, :group, :agb, :grades

  include Gradebook::Rounding

  def perform
    assessments = assessment_type.constantize.find(assessment_id)
    
    @rollback = false
    ActiveRecord::Base.transaction do
      begin
       with_round_off_size(current_planner(assessments).try(:round_off_size_from_settings) || 2) do
         send("#{assessment_type.underscore}_conversion", assessments)
       end
      rescue Exception=> e
        @rollback = true
      end
        raise ActiveRecord::Rollback if @rollback
    end
  ensure
    Array(assessments).each{|assessment| assessment.update_attributes(:submission_status => 3)} if @rollback
  end

  def current_planner (object)
    if object.is_a? AssessmentGroupBatch
      object.assessment_group.assessment_plan
    elsif object.is_a? Array
      current_planner(object.first)
    elsif object.nil?
      nil
    else
      current_planner(object.assessment_group_batch)
    end
  end

  def round_off (value)
    gb_round_off(value)
  end
  
  def assessment_group_batch_conversion(agb)
    @agb = agb
    @group = agb.assessment_group
    @batch = agb.batch
    @course = @batch.course
    @grade_set = group.grade_set
    @grades = @grade_set.grades.sorted_marks if @grade_set
    @all_groups = group.assessment_groups
    sub_ids = []
    group.all_assessment_groups.each do |gp|
      gp.assessment_group_batches.all(:conditions => {:batch_id => batch.id}).each do |agbs|
        sub_ids = sub_ids + agbs.subject_ids
      end
    end
    subjects = batch.grouped_subjects(sub_ids.uniq)
    begin
      retries ||= 0
      ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ?", agb.id])
    rescue Exception=> e
      retry if (retries += 1) < 4
      @rollback = true
    end
    students = batch.effective_students
    students.each do |student|
      @student_subjects = student.subjects.collect(&:id)
      subjects.each do |subject|
        if subject.is_a? Array
          filtered_subjects = subject.reject{|s| s.elective_group_id? and !(student_subjects.include? s.id) }
          next if filtered_subjects.empty?
          batch_subject_group = filtered_subjects.first.batch_subject_group
          next if batch_subject_group.nil?
           subject_conversion(batch_subject_group, student)
          filtered_subjects.each do |s|
            subject_conversion(s, student)
          end
        else
          subject_conversion(subject, student)
        end
      end
    end
    @rollback = true unless agb.update_attributes(:marks_added => true, :submission_status => 2)
  end
  
  def subject_conversion(subject, student)
    return if subject.is_a? Subject and subject.elective_group_id? and !(student_subjects.include? subject.id)
    all_marks = {}
    derived_maximum = subject.is_a?(Subject) ? group.maximum_marks_for(subject,@course) : group.maximum_marks.to_f
    all_groups.each do |ag|
      b_group = AssessmentGroupBatch.find(:first,:conditions=>{:assessment_group_id => ag.id, :batch_id => batch.id})
      group_maximum = subject.is_a?(Subject) ? ag.maximum_marks_for(subject,@course) : ag.maximum_marks.to_f
      
      converted_mark = ConvertedAssessmentMark.find(:first, 
        :conditions=>{:markable_id=>subject.id, :markable_type=>subject.class.name, :student_id=>student.id, :assessment_group_batch_id=>b_group.id})
      
      stu_mark = ((converted_mark.present? and !converted_mark.is_absent) ? converted_mark.mark.to_f : 0)
      all_marks[ag.id] = {:mark => round_off(stu_mark), :max_mark => group_maximum,
        :converted_mark => round_off((stu_mark/group_maximum)*derived_maximum), :grade => converted_mark.try(:grade), :credit_points => converted_mark.try(:credit_points)
      } if converted_mark.present?
    end
    final_score = all_marks.present? ? group.calculate_final_score(all_marks,derived_maximum) : nil
    if final_score.present?
      converted_mark = ConvertedAssessmentMark.new(:markable => subject, :assessment_group_batch_id => agb.id, 
        :assessment_group_id => group.id, :student_id => student.s_id, :mark => final_score, :actual_mark => all_marks)
      case group.scoring_type
      when 1
        converted_mark.passed = (converted_mark.mark >= group.minimum_marks.to_f)
      when 3
        percentage = ((final_score/derived_maximum)*100)
        if @grade_set
          mark_grade = @grade_set.select_grade_for(grades, percentage)
          converted_mark.grade = mark_grade.try(:name)
          converted_mark.passed = mark_grade.try(:pass_criteria)
          converted_mark.credit_points = mark_grade.try(:credit_points)
        end
      end
      #@rollback = true unless converted_mark.save
      begin
        retries ||= 0 
        @rollback = true unless converted_mark.save
      rescue Exception=> e
        retry if (retries += 1) < 4
        @rollback = true
      end
    end
    end
  
  def subject_attribute_assessment_conversion(subject_assessment)
    attribute_assessments = subject_assessment.attribute_assessments
    group_batch = subject_assessment.assessment_group_batch
    change_marks_added_status(group_batch, false)
    group = group_batch.assessment_group
    grade_set = group.grade_set
    grades = grade_set.grades.sorted_marks if grade_set
    attribute_profile = subject_assessment.assessment_attribute_profile
    subject = subject_assessment.subject
    group_maximum = group.maximum_marks_for(subject,group_batch.batch.course)
    student_marks = {}
    ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ? AND markable_id = ? AND markable_type = ?", 
        group_batch.id, subject.id, subject.class.to_s])
    attribute_assessments.each do |assessment|
      attribute = assessment.assessment_attribute
      assessment.assessment_marks.each do |assessment_mark|
        marks = student_marks[assessment_mark.student_id]||{}
        unless assessment_mark.is_absent
          grade = grades.detect{|g| g.id == assessment_mark.grade_id} if assessment_mark.grade_id
          marks[assessment.assessment_attribute_id] = {:mark => round_off(assessment_mark.marks), :grade => assessment_mark.grade, 
            :credit_points => grade.try(:credit_points), :max_mark => attribute.maximum_marks.to_f, 
            :converted_mark => round_off((assessment_mark.marks.to_f/attribute.maximum_marks.to_f)*attribute_profile.maximum_marks.to_f)}
        end
        student_marks[assessment_mark.student_id] = marks
      end
    end
    student_marks.each do |student_id, marks|
      is_absent = marks.blank?
      converted_mark = ConvertedAssessmentMark.new(:markable => subject, :assessment_group_batch_id => group_batch.id, 
        :assessment_group_id => group.id, :student_id => student_id, :is_absent => is_absent)
      unless is_absent
        subject_mark = attribute_profile.calculate_final_score(marks) 
        converted_mark.mark = round_off((subject_mark/attribute_profile.maximum_marks.to_f)*group_maximum)
        converted_mark.actual_mark = marks
        case group.scoring_type
        when 1
          converted_mark.passed = (converted_mark.mark >= group.minimum_marks.to_f)
        when 3
          percentage = ((converted_mark.mark/group_maximum)*100)
          mark_grade = grade_set.select_grade_for(grades, percentage) if grade_set
          converted_mark.attributes = {:grade => mark_grade.try(:name), :credit_points => 
              mark_grade.try(:credit_points), :passed => mark_grade.try(:pass_criteria)} if mark_grade
        end
      end
      @rollback = true unless converted_mark.save
    end
    attribute_assessments.each do |assessment|
      @rollback = true unless assessment.update_attributes(:marks_added => true, :submission_status => 2)
    end
    @rollback = true unless subject_assessment.update_attributes(:marks_added => true, :submission_status => 2 ) unless @rollback
    
    other_attributes = subject_assessment.attribute_assessments.all(:conditions => {:marks_added => false})
    if other_attributes.blank?
      subject_assessment.reload
      subject_assessment.marks_added = true
      subject_assessment.send(:update_without_callbacks)
    end
    other_assessments = group_batch.subject_attribute_assessments.all(:conditions => {:marks_added => false})
    if other_assessments.blank?
      change_marks_added_status(group_batch, true)
    end
    calculate_group_marks(subject, group_batch, grades)
  end
  
  def activity_assessment_conversion(assessments)
    group_batch = assessments.assessment_group_batch
    change_marks_added_status(group_batch, false)
    group = group_batch.assessment_group
    activity = assessments.assessment_activity
    grade_set = group.grade_set
    grades = grade_set.grades if grade_set
    ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ? AND markable_id = ? AND markable_type = ?", 
        group_batch.id, activity.id, activity.class.to_s])
    assessments.assessment_marks.each do |assessment_mark|
      converted_mark = ConvertedAssessmentMark.new(:markable => activity, :assessment_group_batch_id => group_batch.id, 
        :assessment_group_id => group.id, :student_id => assessment_mark.student_id, :is_absent => assessment_mark.is_absent)
      unless assessment_mark.is_absent
        grade = grades.detect{|g| g.id == assessment_mark.grade_id}
        converted_mark.grade = assessment_mark.grade
        converted_mark.credit_points = grade.credit_points
        converted_mark.passed = grade.pass_criteria
        converted_mark.actual_mark = {:grade => assessment_mark.grade, :credit_points => grade.credit_points, :passed => grade.pass_criteria}
      end
      @rollback = true unless converted_mark.save
    end
    @rollback = true unless assessments.update_attributes(:marks_added => true, :submission_status => 2)
    other_activities = group_batch.activity_assessments.all(:conditions => {:marks_added => false})
    if other_activities.blank?
      change_marks_added_status(group_batch, true)
    end
  end
  
  def subject_assessment_conversion(assessments)
    if assessments.has_skill_assessments?
      skill_subject_assessment_conversion(assessments)
    else
      normal_subject_assessment_conversion(assessments)
    end
  end
  
  def normal_subject_assessment_conversion(assessments)
    group_batch = assessments.assessment_group_batch
    change_marks_added_status(group_batch, false)
    group = group_batch.assessment_group
    subject = assessments.subject
    group_maximum = group.maximum_marks_for(subject,group_batch.batch.course)
    grade_set = group.grade_set || GradeSet.default
    grades = grade_set.grades if grade_set
    ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ? AND markable_id = ? AND markable_type = ?", 
        group_batch.id, subject.id, subject.class.to_s])
    assessments.assessment_marks.each do |assessment_mark|
      converted_mark = ConvertedAssessmentMark.new(:markable => subject, :assessment_group_batch_id => group_batch.id, 
        :assessment_group_id => group.id, :student_id => assessment_mark.student_id, :is_absent => assessment_mark.is_absent)
      scoring_type = subject.is_activity? ? 2 : group.scoring_type
      unless assessment_mark.is_absent
        case scoring_type
        when 1
          converted_mark.mark = round_off((assessment_mark.marks.to_f/assessments.maximum_marks.to_f)*group_maximum)
          converted_mark.passed = (converted_mark.mark >= group.minimum_marks.to_f)
          converted_mark.actual_mark = {:mark => round_off(assessment_mark.marks.to_f), :passed => (assessment_mark.marks.to_f >= assessments.minimum_marks.to_f)}
        when 2
          grade = grades.detect{|g| g.id == assessment_mark.grade_id}
          converted_mark.grade = assessment_mark.try(:grade)
          converted_mark.credit_points = grade.try(:credit_points)
          converted_mark.passed = grade.try(:pass_criteria)
          converted_mark.actual_mark = {:grade => assessment_mark.grade, :credit_points => grade.try(:credit_points), :passed => grade.try(:pass_criteria)}
        when 3
          converted_mark.mark = round_off((assessment_mark.marks.to_f/assessments.maximum_marks.to_f)*group_maximum)
          grade = grades.detect{|g| g.id == assessment_mark.grade_id}
          converted_mark.grade = assessment_mark.grade
          converted_mark.credit_points = grade.credit_points
          converted_mark.passed = grade.pass_criteria
          converted_mark.actual_mark = {:mark => round_off(assessment_mark.marks.to_f), :grade => assessment_mark.grade, 
            :credit_points => grade.credit_points, :passed => grade.pass_criteria}
        end
      end
      @rollback = true unless converted_mark.save
    end
    @rollback = true unless assessments.update_attributes(:marks_added => true, :submission_status => 2)
    other_subjects = group_batch.subject_assessments.all(:conditions => {:marks_added => false})
    if other_subjects.blank?
      change_marks_added_status(group_batch, true)
    end
    
    calculate_group_marks(subject, group_batch, grades)
  end
  
  def calculate_group_marks(subject, group_batch, grades = [])
    group = subject.batch_subject_group
    return if group.nil?
    ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ? AND markable_id = ? AND markable_type = ?", 
        group_batch.id, group.id, group.class.to_s])
    if calculate_group?(subject)
      student_ids = group_batch.batch.effective_students.collect(&:s_id)
      subjects = group.subjects
      converted_marks = ConvertedAssessmentMark.all(:conditions => {:assessment_group_batch_id => group_batch.id, :markable_id => subjects.collect(&:id), :markable_type => 'Subject'})
      student_marks = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      subjects.each do |subject|
        subject_marks = converted_marks.select{|c| c.markable_id == subject.id}
        subject_marks.each do |mark|
          marks = student_marks[mark.student_id]||Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
          marks[subject.id] = mark.attributes.slice('credit_points','passed','grade','mark','is_absent').merge({'subject_code'=> subject.code})
          student_marks[mark.student_id] = marks
        end
      end
      student_ids.each do |s_id|
        next unless student_marks[s_id].present?
        converted_mark = ConvertedAssessmentMark.new(:markable => group, :assessment_group_batch_id => group_batch.id, 
          :assessment_group_id => group.id, :student_id => s_id)
          # TODO : check this code. Attributes hash is seen to be reassigned.
        converted_mark.attributes = group.calculate_group_mark(student_marks[s_id],group_batch.assessment_group, grades) 
        converted_mark.save
      end
    end 
  end
  
  def calculate_group?(subject)
    batch_group = subject.batch_subject_group
    
    batch_group.present? and batch_group.calculate_final and batch_group.formula.present? 
  end
  
  def skill_subject_assessment_conversion(assessments)
    group_batch = assessments.assessment_group_batch
    change_marks_added_status(group_batch, false)
    student_ids = group_batch.batch.effective_students.collect(&:s_id)
    skill_assessments = assessments.skill_assessments.all(:include => 
        [:subject_skill, :assessment_marks, {:sub_skill_assessments => [:subject_skill , :assessment_marks]}])
    group = group_batch.assessment_group
    grade_set = group.grade_set
    grades = grade_set.grades.sorted_marks if grade_set
    skill_set = assessments.subject_skill_set
    subject = assessments.subject
    group_maximum = group.maximum_marks_for(subject,group_batch.batch.course)
    student_marks = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    ConvertedAssessmentMark.delete_all(["assessment_group_batch_id = ? AND markable_id = ? AND markable_type = ?", 
        group_batch.id, subject.id, subject.class.to_s])
    skill_assessments.each do |assessment|
      subject_skill = assessment.subject_skill
      if assessment.sub_skill_assessments.present?
        assessment.sub_skill_assessments.each do |assess|
          sub_subject_skill = assess.subject_skill
          assess.assessment_marks.each do |assessment_mark|
            marks = student_marks[assessment_mark.student_id]||Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
            unless assessment_mark.is_absent
              grade = grades.detect{|g| g.id == assessment_mark.grade_id} if assessment_mark.grade_id
              if group.grade_type?
                marks[assess.subject_skill_id] = {:grade => assessment_mark.grade, 
                  :credit_points => grade.try(:credit_points), :max_mark => sub_subject_skill.maximum_marks}
              else
                marks[assess.subject_skill_id] = {:mark => round_off(assessment_mark.marks), :grade => assessment_mark.grade, 
                  :credit_points => grade.try(:credit_points), :max_mark => sub_subject_skill.maximum_marks,
                  :converted_mark => round_off((assessment_mark.marks.to_f/sub_subject_skill.maximum_marks.to_f)*subject_skill.maximum_marks.to_f)}
              end
            end
            student_marks[assessment_mark.student_id] = marks
          end
        end
        student_ids.each do |student_id|
          next unless student_marks[student_id].present?
          mark = assessment.calculate_skill_mark(student_marks[student_id],group, assessments.maximum_marks , grades)
          student_marks[student_id][assessment.subject_skill_id] = mark if mark.present?
        end
      else
        assessment.assessment_marks.each do |assessment_mark|
          marks = student_marks[assessment_mark.student_id]||Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
          unless assessment_mark.is_absent
            grade = grades.detect{|g| g.id == assessment_mark.grade_id} if assessment_mark.grade_id
            marks[subject_skill.id] = if group.grade_type? 
              {:grade => assessment_mark.grade,
                :credit_points => grade.try(:credit_points),:max_mark => subject_skill.maximum_marks
              }
            else
              {:mark => round_off(assessment_mark.marks), :grade => assessment_mark.grade,
                :credit_points => grade.try(:credit_points),:max_mark => subject_skill.maximum_marks, 
                :converted_mark => round_off((assessment_mark.marks.to_f/subject_skill.maximum_marks.to_f)*assessments.maximum_marks.to_f)
              }
            end
          end
          student_marks[assessment_mark.student_id] = marks
        end
      end
    end
    
    student_marks.each do |student_id, marks|
      is_absent = marks.blank?
      converted_mark = ConvertedAssessmentMark.new(:markable => subject, :assessment_group_batch_id => group_batch.id, 
        :assessment_group_id => group.id, :student_id => student_id, :is_absent => is_absent)
      unless is_absent
        scoring_type = subject.is_activity? ? 2 : group.scoring_type
        subject_mark = skill_set.calculate_final_score(marks, scoring_type, assessments.maximum_marks,  group_maximum) 
        marks['subject_mark'] = subject_mark
        converted_mark.actual_mark = marks
        if subject_mark.present?
          converted_mark.mark = round_off(subject_mark[:converted_mark])
          case scoring_type
          when 1
            converted_mark.passed = (converted_mark.mark >= group.minimum_marks.to_f)
          when 3
            percentage = ((converted_mark.mark/group_maximum)*100)
            mark_grade = grade_set.select_grade_for(grades, percentage) if grade_set
            converted_mark.attributes = {:grade => mark_grade.try(:name), :credit_points => 
                mark_grade.try(:credit_points), :passed => mark_grade.try(:pass_criteria)} if mark_grade
          end
        end
      end
      @rollback = true unless converted_mark.save
    end
    skill_assessments.each do |assessment|
      assessment.sub_skill_assessments.each do |s_assessment|
        @rollback = true unless s_assessment.update_attributes(:marks_added => true, :submission_status => 2) unless @rollback
      end
      @rollback = true unless assessment.update_attributes(:marks_added => true, :submission_status => 2) unless @rollback
    end
    @rollback = true unless assessments.update_attributes(:marks_added => true, :submission_status => 2 ) unless @rollback
    
    other_skills_exams = assessments.skill_assessments.all(:conditions => {:marks_added => false})
    if other_skills_exams.blank?
      assessments.reload
      assessments.marks_added = true
      assessments.send(:update_without_callbacks)
    end
    other_assessments = group_batch.subject_assessments.all(:conditions => {:marks_added => false})
    if other_assessments.blank?
      change_marks_added_status(group_batch, true)
    end
    calculate_group_marks(subject, group_batch, grades)
  end
  
  def change_marks_added_status(group_batch, status)
    if group_batch
      group_batch.reload
      group_batch.marks_added = status
      group_batch.send(:update_without_callbacks)
    end
  end
end
