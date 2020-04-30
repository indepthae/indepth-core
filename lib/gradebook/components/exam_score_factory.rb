module Gradebook
  module Components
    class ExamScoreFactory < ComponentFactory
      def process_and_build_components
        exam_sets = new_collection
        return exam_sets if activity_exam_report?
        assessment_groups.each do |assessment_group|
          @assessment_group = assessment_group
          @agb = assessment_group.assessment_group_batches.to_a.find{|agb| (agb.batch_id == batch.id) and agb.marks_added?}
          next unless agb
          exam_sets.push build_exam_set
        end
        
        exam_sets
      end
      
      ##
      # return exam set component for each assessment groups for the report
      # Having properties like score, aggregates
      def build_exam_set
        @scores = new_collection
        @total_max = 0
        @total_score = 0
        @overrided_subjects = assessment_group.override_assessment_marks.find_all_by_course_id(batch.course_id).collect(&:subject_code)
        process_scores
        
        Models::ExamSet.new(
          :obj_id => assessment_group.id,
          :name => assessment_group.display_name,
          :scores => @scores,
          :aggregates => process_aggregates,
          :term_name => term_name(assessment_group),
          :term_exam => assessment_group.is_final_term,
          :group_exam => is_assessment_group?,
          :planner_exam => (assessment_group.is_final_term and (assessment_group.parent_type == 'AssessmentPlan')),
          :attendance_report => process_attendance,
          :planner_name => assessment_plan.name,
          :scoring_type => AssessmentGroup::SCORE[assessment_group.scoring_type],
          :show_percentage => (assessment_group.is_final_term && assessment_group.show_percentage?),
          :maximum_mark => assessment_group.maximum_marks,
          :hide_marks => assessment_group.hide_marks,
          :consider_skills => assessment_group.consider_skills
        )
      end
      
      ##
      # Process and builds score components for each subjects , skills and attributes
      def process_scores
        applicable_subjects = []
        subjects.group_by(&:batch_subject_group).each_pair do |batch_group, batch_subjects|
          (batch_subjects << batch_group).compact.each do |sub|
            applicable_subjects << sub
          end
        end
        applicable_subjects.sort_by{|as| as.priority.to_i}.each do|sub|
          mark = student.converted_assessment_marks.detect{|cam| cam.markable_id == sub.id and 
              cam.markable_type == sub.class.name and cam.assessment_group_batch_id == agb.id}
          next unless mark
          build_score(sub, mark)
          process_skills(sub,mark) if consider_skills_of_subjects(sub)
          process_attributes(sub, mark, agb.subject_attribute_assessments) if agb.subject_attribute_assessments.present? and sub.is_a?(Subject)
        end

        add_to_exam_totals_hash(@total_score)
      end
      
      def process_skills(sub,mark)
        skills = sub.fetch_skills
        skills.each{ |skill| build_score(skill,mark, sub.id) }
      end
      
      def process_attributes(sub,mark, attributes)
        subject_attribute = attributes.to_a.find{|a| a.subject_id == sub.id}
        if subject_attribute.present?
          subject_attribute.attribute_assessments.each do |attr|
            build_score(attr.assessment_attribute,mark, sub.id)
          end
        end
      end
      
      def process_attendance
        if is_all_exam? and assessment_group.consider_attendance and assessment_group.is_single_mark_entry
          AttendanceFactory.build(:reportable => reportable, :student => student, :reportable_child => assessment_group )
        end  
      end
      
      ##
      # Process and builds aggregate objects for total, percentage and grade
      # returns Collection of aggregate components
      def process_aggregates
        aggregates = new_collection

        unless assessment_group.scoring_type == 2 # do except for scoring type 'grades'
          aggregates.push new_aggregate('score','Total Score',@total_score)
          percentage = @total_score.zero? ? nil : ((@total_score / @total_max) * 100).round(2)
          aggregates.push new_aggregate('percentage','Total Percentage', percentage)
          aggregates.push new_aggregate('grade','Overall Grade',overall_grade_set.grade_string_for(percentage)) if overall_grade_set.present?
        end

        aggregates
      end
      
      ##
      # Build score components for subjects, skills and attributes
      # adding calculated score to global score hash for aggregate calculation
      def build_score(sub, mark, parent_subject_id = nil)
        subject_comp = sub_components.find_by(:type => sub.class.name, :obj_id => sub.id, :parent_subject_id => parent_subject_id)
        return unless subject_comp
        score =   new_score(sub,mark,subject_comp)
        if sub.class.name == 'Subject'
          add_to_score_hash(sub, score.score.to_f)
          unless sub.exclude_for_final_score
            @total_score += score.score.to_f if sub.batch_subject_group_id.present? ? (sub.batch_subject_group.calculate_final ? false : true ) : true
            @total_max += score.max_score.to_f if (score.score.present? or score.is_absent) and (sub.batch_subject_group_id.present? ? (sub.batch_subject_group.calculate_final ? false : true ) : true)
          end
        elsif sub.class.name == 'BatchSubjectGroup' and sub.calculate_final
          @total_score += score.score.to_f 
          @total_max += score.max_score.to_f if (score.score.present? or score.is_absent)
        end
        @scores.push score
      end
      
      ##
      # Method builds aggregate component
      # params:
      # => type (total/ percentage/ grade)
      # => name
      # => value
      def new_aggregate(type,name, value)
        Models::Aggregate.new(
          :type => type,
          :parent_name => assessment_group.display_name,
          :parent_type => 'AssessmentGroup',
          :name => name,
          :value => value
        )
      end
      
      ##
      # Methods builds score component
      # params:
      # => markable (subject/ skill / attribute) object
      # => converted_mark (converted mark object for fetching marks)
      # => markable_component (subject/ skill / attribute) component
      def new_score(markable, converted_mark, markable_component = nil)
        Models::Score.new(
          :subject => markable_component,
          :grade => converted_mark.get_grade(markable),
          :score => converted_mark.get_mark(markable),
          :max_score => converted_mark.maximum_mark(markable, batch.course),
          :min_score => converted_mark.minimum_mark(markable),
          :credit_points => converted_mark.get_credit_point(markable),
          :credit_hours => credit_hours(markable),
          :is_absent => converted_mark.is_absent,
          :remarks => build_remark(markable),
          :is_overrided_max_mark => is_overrided_max_mark?(markable)
        )
      end
      
      def is_overrided_max_mark?(subject)
        subject.is_a? Subject and @overrided_subjects.include? subject.code
      end
      
      ##
      # returns remark component
      # params:
      # => markable (subject)
      def build_remark(markable)
        if subject_remarks_enabled? and markable.is_a? Subject
          RemarkFactory.build(:reportable => reportable, :student => student, :subject => markable)
        end
      end
      
      private
      
      attr_accessor :reportable, :student, :agb, :assessment_group, :sub_components
      
      def consider_skills_of_subjects(sub)
        sub.is_a? Subject and assessment_group.consider_skills and sub.subject_skill_set_id.present?
      end
      
      def is_all_exam?
        if is_assessment_group?
          settings[:exam_attendance] == "1"
        elsif is_assessment_term?
          settings[:term_attendance] == "1" and settings[:term_report] == "0"
        elsif is_assessment_plan?
          settings[:planner_attendance] == "1" and settings[:planner_report] == "0"
        end
      end
      
      def subject_remarks_enabled?
        settings[:subject_wise_remarks] == "1"
      end
      
      def credit_hours(markable)
        return unless markable.class.name == 'Subject'
        
        markable.credit_hours
      end
      
      ##
      # adds score to score hash for aggregate calculation
      # params:
      # => markable (subject)
      # => score (marks)
      def add_to_score_hash(markable, score)
        scores_hash[assessment_group.id][markable.id][student.id] = score
      end

      def add_to_exam_totals_hash(total)
        exam_totals_hash[assessment_group.id][student.id] = total
      end

    end
  end
end
