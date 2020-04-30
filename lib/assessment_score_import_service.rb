# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class AssessmentScoreImportService
 attr_accessor :students, :assessment_group, :batch, :import_id
 CSV_HEADERS = ['SI', 'Name', 'Admission No'].freeze


  @@import_logger = Logger.new('log/gradebook_imports.log')
    
  def initialize(import_id = nil)
    @import_id = import_id
  end
  
  def download_form(batch_id, assessment_group_id)
      load_assessment_data(assessment_group_id, batch_id)
      make_csv_structure
  end
  
  def make_csv_structure
    csv_data = make_csv_data
    FasterCSV.generate do |csv|
      csv_data.each do |row|
        csv << row
      end
    end
  end

  def delayed_import
    Delayed::Job.enqueue(self,{:queue => "gradebook"})
  end

  def perform
    import = AssessmentScoreImport.find import_id
    import.update_attributes(:status => 1)  
    load_assessment_data(import.assessment_group_id, import.batch_id)
    @rollback = false
    @errors = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    ActiveRecord::Base.transaction do
      import_csv(import.attachment.to_file)
      raise ActiveRecord::Rollback if @rollback
    end
    if @errors.present?
      import.update_attributes(:status => 3, :last_message => @errors)
    else
      import.update_attributes(:status => 2, :last_message => nil)
    end
  rescue Exception => e
#    log("-----------------------------------#{Time.now}----:id=>#{MultiSchool.current_school.id}---------------------------------")
#    log (e.message)
#    log (e.backtrace)
#    log("-----------------------------------------------------------------------------------")
    errors = {'Error' => [e.message]}
    import.update_attributes(:status => 3, :last_message => errors)
  end

  def import_csv(csv)
    data, headers = parse_csv(csv)
    return if @rollback
    process_data(data, headers)
  end

  private

  def validate_general_details(general_details)
    details = []
    assessment_details.each {|a| details << a.drop(1)}
    general_details = general_details.each{|b|b.compact!; b.delete("")}
    log_error('General Details', ['General Details are Invalid']) unless (details == general_details)
  end

  def validate_sheet(headers, data, assessments, type)
    valid_headers = if type == 'Activity'
      activity_assessment_headers(assessments)
    else
      subject_assessment_headers(assessments)
    end

    students_adms =  data.keys
    valid_students = students
    students_valid = true

    #---------------------Students in the sheet validity check-------------------------------------#
    students_adms.each do |s|
      students_valid = false if s.blank? or valid_students.to_a.find{|st| st.admission_no == s}.nil?
    end

    students_valid = false if students_adms.uniq.sort != students_adms.sort
    #---------------------------------------END----------------------------------------------------#

    log_error('Header', ['Invalid Headers']) if valid_headers != headers
    log_error('Students', ['Student Details are Invalid']) unless students_valid
  end

  def parse_csv(csv_string)
    csv_data = FasterCSV.parse(csv_string)
    general_details = csv_data.shift(6)
    validate_general_details(general_details)
    headers = csv_data.shift
    [csv_data.map{|row| Hash[*headers.zip(row).flatten] }, headers]
  end

  def process_data(data, headers)
    data = modify_data(data)
    case @assessment_group.type
    when 'SubjectAssessmentGroup'
      if @assessment_group.is_single_mark_entry?
        process_for_subject_assessment(data, headers)
      else
        process_for_attribute_assessment(data, headers)
      end

    when 'ActivityAssessmentGroup'
      process_for_activity_assessment(data, headers)
    end

  end

  def make_csv_data
    case @assessment_group.type
    when 'SubjectAssessmentGroup'
      if @assessment_group.is_single_mark_entry?
        subject_assessment_data
      else
        subject_attr_assessment_data
      end
    when 'ActivityAssessmentGroup'
      activity_assessment_data
    end
  end

  def load_assessment_data(assessment_group_id, batch_id)
    @assessment_group = AssessmentGroup.find(assessment_group_id, :include => [:assessment_plan, {:grade_set => :grades}])
    @batch = Batch.find(batch_id, :include => :students)
    @assessment_batch =
      case @assessment_group.type
    when 'SubjectAssessmentGroup'
      @assessment_group.assessment_group_batches.first(:conditions => {:batch_id => @batch.id},
        :include => {:subject_assessments => :subject})
    when 'ActivityAssessmentGroup'
      @assessment_group.assessment_group_batches.first(:conditions => {:batch_id => @batch.id},
        :include => {:activity_assessments => :assessment_activity})
    end

    @students = batch.effective_students
  end

  def get_student_id (admission_no)
    @batch.students.detect{|student| student.admission_no.strip == admission_no.strip}.try(:id)
  end

  def get_grade_id (grade)
    return nil if grade.nil?
    grade_set = @assessment_group.grade_set || GradeSet.default
    grade_set.grades.detect{|g| g.name.strip == grade.strip}.try(:id)
  end

  def get_grade_string(mark, assessment)
    converted_mark = (mark.to_f * 100).round(2) /  max_mark_for(assessment)
    @assessment_group.grade_set.grade_string_for(converted_mark)
  end
  
  def max_mark_for(assessment)
    if assessment.is_a? SkillAssessment
      assessment.subject_skill.maximum_marks
    elsif assessment.is_a? AttributeAssessment
      assessment.assessment_attribute.maximum_marks
    else
      assessment.maximum_marks
    end
  end

  # subject_assessment methods

  def process_for_subject_assessment(data, headers)
    attr_method = attr_for_subject_make_method    
    assessments = @assessment_batch.subject_assessments.assessments_with_skills.order_by_exam_date_and_start_time
    validate_sheet(headers, data, assessments, 'Subject')
    return if @rollback

    assessments.each do |assessment|
      s_ids = assessment.subject.fetch_gradebook_students.collect(&:s_id)
      if assessment.has_skill_assessments?
        assessment.skill_assessments.each do |skill_assessment|
          subject_skill = skill_assessment.subject_skill
          if skill_assessment.sub_skill_assessments.present?
            skill_assessment.sub_skill_assessments.each do |sub_skill_ass|
              sub_subject_skill = sub_skill_ass.subject_skill
              head_text =  "#{sub_subject_skill.name}(#{sub_subject_skill.maximum_marks}) | #{subject_skill.name} | #{assessment.subject.try(:code)}"
              build_and_save_marks(sub_skill_ass, data, attr_method, head_text, sub_subject_skill.name, s_ids)
            end
          else
            head_text = "#{subject_skill.name}(#{subject_skill.maximum_marks}) | #{assessment.subject.try(:code)}"
            build_and_save_marks(skill_assessment, data, attr_method, head_text, subject_skill.name, s_ids)
          end
        end
      else
        head_text = ((@assessment_group.grade_type? or assessment.subject.is_activity?) ? assessment.subject.try(:code) : "#{assessment.subject.try(:code)} (#{assessment.maximum_marks})")
        ass_attr_method =  assessment.subject.is_activity? ? :attr_for_subject_with_grade : attr_method
        build_and_save_marks(assessment, data, ass_attr_method, head_text, assessment.subject.try(:code), assessment.subject.fetch_gradebook_students.collect(&:s_id))
      end
    end
  end

  def process_for_attribute_assessment(data, headers)
    attr_method = attr_for_subject_make_method

    assessments = @assessment_batch.subject_attribute_assessments
    validate_sheet(headers, data, assessments, 'Attribute')
    return if @rollback

    assessments.each do |sub_assessment|
      s_ids = sub_assessment.subject.fetch_gradebook_students.collect(&:s_id)
      sub_assessment.attribute_assessments.each do |assessment|
        attribute = assessment.assessment_attribute
        head_text =  "#{attribute.name}(#{attribute.maximum_marks}) | #{sub_assessment.subject.try(:code)}"

        build_and_save_marks(assessment, data, attr_method, head_text, attribute.name, s_ids)
      end
    end
  end

  def process_for_activity_assessment (data, headers)
    attr_method = :attr_for_subject_with_grade

    assessments = @assessment_batch.activity_assessments
    validate_sheet(headers, data, assessments, 'Activity')
    return if @rollback

    assessments.each do |assessment|
      head_text = "#{assessment.assessment_activity.try(:name)}"

      build_and_save_marks(assessment, data, attr_method, head_text, head_text)
    end
  end

  # WIP
  def subject_assessment_data
    csv_data = assessment_details
    assessments = @assessment_batch.subject_assessments.assessments_with_skills.order_by_exam_date_and_start_time  
    csv_data << subject_assessment_headers(assessments)

    students.each_with_index do |student,index|
      row = [index + 1, student.full_name, student.admission_no]
      row << student.roll_number if roll_number_enabled?

      assessments.each do |assessment|
        if assessment.has_skill_assessments?
          assessment.skill_assessments.each do |skill_ass|
            if skill_ass.sub_skill_assessments.present?
              skill_ass.sub_skill_assessments.each do |sub_skill_ass|
                assessment_mark = sub_skill_ass.assessment_marks.to_a.find{|am| am.student_id == student.s_id}
                if assessment_mark.try(:is_absent)
                  row << 'Absent'
                elsif @assessment_group.grade_type?
                  row << assessment_mark.try(:grade)
                else
                  row << assessment_mark.try(:marks).try(:to_f)
                end
              end
            else
              assessment_mark = skill_ass.assessment_marks.to_a.find{|am| am.student_id == student.s_id}
              if assessment_mark.try(:is_absent)
                row << 'Absent'
              elsif @assessment_group.grade_type?
                row << assessment_mark.try(:grade)
              else
                row << assessment_mark.try(:marks).try(:to_f)
              end
            end
          end
        else
          assessment_mark = assessment.assessment_marks.to_a.find{|am| am.student_id == student.s_id}
          if assessment_mark.try(:is_absent)
            row << 'Absent'
          elsif (@assessment_group.grade_type? or assessment.subject.is_activity?)
            row << assessment_mark.try(:grade)
          else
            row << assessment_mark.try(:marks).try(:to_f)
          end
        end
      end
      csv_data << row
    end

    csv_data
  end

  def subject_attr_assessment_data
    csv_data = assessment_details # New Init with headers

    assessments = @assessment_batch.subject_attribute_assessments.all(:include => [:subject, {:attribute_assessments => [:assessment_marks, :assessment_attribute]}])
    csv_data << subject_assessment_headers(assessments)

    students.each_with_index do |student,index|
      row = [index +1 , student.full_name, student.admission_no]
      row << student.roll_number if roll_number_enabled?

      assessments.each do |assessment|
        assessment.attribute_assessments.each do |attr_assessment|
          assessment_mark = attr_assessment.assessment_marks.to_a.find{|am| am.student_id == student.s_id}
          if assessment_mark.try(:is_absent)
            row << 'Absent'
          else
            row << assessment_mark.try(:marks).try(:to_f)
          end
        end
      end
      csv_data << row
    end

    csv_data
  end

  def activity_assessment_data
    csv_data = assessment_details # New Init with headers

    assessments = @assessment_batch.activity_assessments.all(:include => [:assessment_marks, :assessment_activity])
    csv_data << activity_assessment_headers(assessments)

    students.each_with_index do |student, index|
      row = [index + 1, student.full_name, student.admission_no]
      row << student.roll_number if roll_number_enabled?

      assessments.each do |assessment|
        assessment_mark = assessment.assessment_marks.to_a.find{|am| am.student_id == student.s_id}
        if assessment_mark.try(:is_absent)
          row << 'Absent'
        else
          row << assessment_mark.try(:grade)
        end
      end
      csv_data << row
    end

    csv_data
  end


  #Header Builders

  def activity_assessment_headers(assessments)
    header = default_headers
    assessments.each do |assessment|
      activity = assessment.assessment_activity
      header << "#{activity.name}"
    end

    header
  end

  def subject_assessment_headers(assessments)
    header = default_headers
    assessments.each do |assessment|
      if @assessment_group.is_single_mark_entry?
        if assessment.has_skill_assessments?
          assessment.skill_assessments.each do |skill_ass|
            subject_skill = skill_ass.subject_skill
            if skill_ass.sub_skill_assessments.present?
              skill_ass.sub_skill_assessments.each do |sub_skill_ass|
                sub_subject_skill = sub_skill_ass.subject_skill
                header << "#{sub_subject_skill.name}(#{sub_subject_skill.maximum_marks}) | #{subject_skill.name} | #{assessment.subject.try(:code)}"
              end
            else
              header << "#{subject_skill.name}(#{subject_skill.maximum_marks}) | #{assessment.subject.try(:code)}"
            end
          end
        else
          header << ((@assessment_group.grade_type? or assessment.subject.is_activity?) ? assessment.subject.try(:code) : "#{assessment.subject.try(:code)} (#{assessment.maximum_marks})")
        end
      else #For Atttribute Assessments
        assessment.attribute_assessments.each do |attribute_assessment|
          attribute = attribute_assessment.assessment_attribute
          header << "#{attribute.name}(#{attribute.maximum_marks}) | #{assessment.subject.try(:code)}"
        end
      end
    end
    header
  end

  #General Methods

  def build_and_save_marks(assessment, data,attr_method, head_text, col_name, s_ids = [])
    filtered_students = s_ids.present? ?  students.to_a.select{|s| s_ids.include? s.s_id } : students
    marks = assessment.assessment_marks.to_a
    filtered_students.each do |student|
      student_data = data[student.admission_no]
      next unless student_data.present?

      subject_score = student_data[head_text]

      present_mark = marks.find{|m| m.student_id == student.s_id}
      next if(present_mark.nil? and subject_score.nil?)

      attrs = send(attr_method, subject_score, student.s_id, assessment).merge(:from_import => true)
      if present_mark
        present_mark.attributes = attrs
      else
        assessment.assessment_marks.build(attrs)
      end
      log_error(col_name, assessment.errors.full_messages) unless assessment.save
    end
  end

  def attr_for_subject_with_mark (subject_score, student_id, assessment)
    if subject_score.present?
      absent = subject_score.strip.casecmp('absent') == 0
      {:student_id => student_id,
        :marks => (absent ? nil : subject_score),
        :is_absent => absent
      }
    else
      {:student_id => student_id,
        :marks => nil,
        :is_absent => false
      }
    end
  end

  def attr_for_subject_with_grade (subject_score, student_id, assessment)
    if subject_score.present?
      absent = subject_score.strip.casecmp('absent') == 0
      {:student_id => student_id,
        :grade => (absent ? nil : subject_score),
        :grade_id => (absent ? nil : get_grade_id(subject_score)),
        :is_absent => absent
      }
    else
      {:student_id => student_id,
        :grade => nil,
        :grade_id => nil,
        :is_absent => false
      }
    end
  end

  def attr_for_subject_with_mark_and_grade (subject_score, subject_id, assessment)
    if subject_score.present?
      absent = subject_score.strip.casecmp('absent') == 0
      grade = absent ? nil : get_grade_string(subject_score, assessment)
      grade_id = grade ? get_grade_id(grade) : nil
      attr_for_subject_with_mark(subject_score, subject_id, assessment).merge({
          :grade => grade,
          :grade_id => grade_id
      })
    else
      attr_for_subject_with_mark(subject_score, subject_id, assessment).merge({
          :grade => nil,
          :grade_id => nil
      })
    end
  end

  def attr_for_subject_make_method
    [:attr_for_subject_with_mark, :attr_for_subject_with_grade,
      :attr_for_subject_with_mark_and_grade][@assessment_group.scoring_type - 1]
  end

  def assessment_details
    [
      ["","Assessment Group", @assessment_group.name],
      ['',"Scoring", @assessment_group.score_type],
      ['',"Batch", @batch.full_name],
      ['',"Assessment Plan", @assessment_group.assessment_plan.name],
      ['',"Academic Year", @assessment_group.academic_year.name],
      []
    ]
  end

  def default_headers
    roll_number_enabled? ? (CSV_HEADERS + ['Roll No']) : CSV_HEADERS + []
  end

  def roll_number_enabled?
    @roll_num_enabled ||= Configuration.enabled_roll_number?
  end

  def modify_data(datas)
    mod = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    key_text = 'Admission No'
    datas.each do |data|
      mod[data[key_text]] = data
    end

    mod
  end


  def log (text)
    self.class.log(text)
  end

  def log_error(col_name, text)
    @rollback = true
    @errors[col_name] = text
  end
end
