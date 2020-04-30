class AssessmentForm < Tableless
  
  column :assessment_group_id, :integer
  column :scoring_type, :integer
  #  column :max_marks, :decimal
  #  column :min_marks, :decimal
  
  belongs_to :assessment_group
  has_many :assessment_form_fields
  
  accepts_nested_attributes_for :assessment_form_fields, :allow_destroy => true#, :reject_if => lambda { |l| l[:selected] == "0" }
  
  def save_assessments(schedule)
    group_batches = {}
    assessment_created = false;
    fields = assessment_form_fields.inject({}){|m, field| m.merge(field => field.subject_assessments) }
    fields.each do |field, subjects|
      subjects.each do |subject|
        if subject.subject_list.present? and subject.batch_id.present?
          group_batch = group_batches[subject.batch_id]
          unless group_batch.present?
            group_batch = AssessmentGroupBatch.find_or_create_by_assessment_group_id_and_batch_id(
              :assessment_group_id => assessment_group_id, :batch_id => subject.batch_id, :course_id => subject.course_id, :mark_entry_last_date => schedule.mark_entry_last_date.present? ? schedule.mark_entry_last_date[subject.batch_id] : '' )
            group_batches[subject.batch_id] = group_batch
          end
          subjects = subject.subject_list.split(",")
          subjects.each do |sub|
            sub_list = sub.split("-")
            subject_id = sub_list.first
            elective_group_id = (sub_list.length > 1 ? sub_list.last : nil)
            subjekt = Subject.find subject_id
            has_skill_assessments = (assessment_group.skill_assessment? and subjekt.subject_skill_set_id.present?)
            subject_assessment  = SubjectAssessment.new(:assessment_group_batch => group_batch, :exam_date => field.date,
                :start_time => field.start_time,:end_time => field.end_time, :maximum_marks => field.max_marks, 
                :minimum_marks => field.min_marks, :subject_id => subject_id, :elective_group_id => elective_group_id,
                :has_skill_assessments => has_skill_assessments, :subject_skill_set_id => ( assessment_group.skill_assessment? ? subjekt.subject_skill_set_id : nil))
            assessment_created = true if subject_assessment.save and !assessment_created
          end
        end
      end
    end
    schedule.update_attribute(:schedule_created, true) if assessment_created
    batches = schedule.batches.all(:include => :assessment_group_batches)
    batches.each do |b|
      agb = b.assessment_group_batches.detect{|ag| ag.assessment_group_id == assessment_group_id}
      schedule.batches.delete(b) if agb.nil?
    end
  end
  
  class << self
  
    def build_form(schedule, group, batches)
      form = new(:assessment_group_id => group.id, :scoring_type => group.scoring_type)
      (schedule.start_date..schedule.end_date).each do |date|
        schedule.no_of_exams_per_day.times.each do |i|
          start_time = schedule.exam_timings[i+1][:start_time]
          end_time = schedule.exam_timings[i+1][:end_time]
          max_marks = (([1, 3].include? group.scoring_type) ? group.maximum_marks : nil)
          min_marks = ((group.scoring_type == 1) ? group.minimum_marks : nil)
          field = form.assessment_form_fields.build(:date => date, :start_time => start_time, 
            :end_time => end_time, :max_marks => max_marks, :min_marks => min_marks)
          batches.each do |batch|
            field.subject_assessments.build(:batch_id => batch.id, :course_id => batch.course_id)
          end
        end
      end
      form
    end
    
    def fetch_subjects(batches)
      subjects_list = {}
      batch_ids = batches.collect(&:id)
      normal_subjects = Subject.find_all_by_batch_id(batch_ids, :conditions => {:no_exams => false, :elective_group_id => nil,:is_deleted => false}).group_by(&:batch_id)
      elective_subjects = Subject.find_all_by_batch_id(batch_ids, :group => "id", :joins => :students_subjects,
        :conditions => ["no_exams = false and elective_group_id IS NOT NULL and is_deleted = false"], :include => :elective_group).group_by(&:batch_id)
      batch_ids.each do |id|
        core_subjects = (normal_subjects[id]||[]).select{|n| n.batch_subject_group_id == nil}.map{|s| [s.name, s.id, s.priority]}
        core_subjects_with_group = (normal_subjects[id]||[]).select{|n| n.batch_subject_group_id != nil}.group_by(&:batch_subject_group_id)
        elec_sub = (elective_subjects[id]||[]).group_by(&:elective_group_id)
        list = core_subjects
        core_subjects_with_group.each do |s_id, subj|
          n_sub = [subj.first.batch_subject_group.name, subj.map{|s| [s.name, s.id]}, subj.first.batch_subject_group.priority]
          list.push(n_sub)
        end
        elec_sub.each do |e_id, subj|
          e_sub = [subj.first.elective_group.name, [[t("all_subjects"), subj.map{|s| "#{s.id}-#{e_id}"}.join(",")]] + 
              subj.map{|s| [s.name, "#{s.id}-#{e_id}"]},subj.first.elective_group.priority]
          list.push(e_sub)
        end 
        list.sort_by{|sub| sub.last.to_i}.select { |x| x.delete_at(2) } 
        subjects_list[id] = list
      end
      subjects_list
    end
    
    def fetch_batch_subjects(batch)
      normal_subjects = Subject.find_all_by_batch_id(batch.id, :conditions => {:no_exams => false, :elective_group_id => nil,:is_deleted => false})
      list = normal_subjects.select{|n| n.batch_subject_group_id == nil}.map{|s| [s.name, "#{s.id}-#{s.elective_group_id}", s.priority]}
      core_subjects_with_group = normal_subjects.select{|n| n.batch_subject_group_id != nil}.group_by(&:batch_subject_group_id)
      core_subjects_with_group.each do |s_id, subj|
          n_sub = [subj.first.batch_subject_group.name, subj.map{|s| [s.name, "#{s.id}-#{s.elective_group_id}"]}, subj.first.batch_subject_group.priority]
          list.push(n_sub)
      end
      elective_subjects = Subject.find_all_by_batch_id(batch.id, :group => "id", :joins => :students_subjects,
        :conditions => ["no_exams = false and elective_group_id IS NOT NULL and is_deleted = false"], :include => :elective_group).group_by(&:elective_group_id)
      elective_subjects.each do |e_id, subj|
          e_sub = [subj.first.elective_group.name, subj.map{|s| [s.name, "#{s.id}-#{e_id}"]}, subj.first.elective_group.priority]
          list.push(e_sub)
      end
#      (normal_subjects+elective_subjects).map{|s| [s.name, "#{s.id}-#{s.elective_group_id}"]}
      list.sort_by{|sub| sub.last.to_i}.select { |x| x.delete_at(2) }
      list
    end
    
  end

end