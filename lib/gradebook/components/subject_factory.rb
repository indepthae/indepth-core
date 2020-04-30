module Gradebook
  module Components
    class SubjectFactory < ComponentFactory
      def process_and_build_components
        @subject_sets = new_collection
        return @subject_sets if activity_exam_report?
        student_subjects = student.subjects.collect(&:id)
        skill_assessments_present = has_exam_group_with_skill_enabled?
        applicable_subjects = []
        subjects.group_by(&:batch_subject_group).each_pair do |batch_group, batch_subjects|
          (batch_subjects << batch_group).compact.each do |sub|
            next if (sub.is_a? Subject and sub.elective_group_id? and !(student_subjects.include? sub.id))
            applicable_subjects << sub
          end
        end
        applicable_subjects.sort_by{|as| as.priority.to_i}.each do|sub|
          build_subjects(sub)
          process_skills(sub) if (skill_assessments_present and consider_skills_of_subjects(sub))
          process_attributes(sub) if  attribute_assessment_report? and sub.is_a?(Subject)
        end
        
        subject_sets
      end
      
      ##
      # Fetching skills and building subject components
      def process_skills(sub)
        skills = sub.fetch_skills
        skills.each{ |skill| build_subjects(skill, sub) }
      end
      
      ##
      # Fetching attributes associated with subject and building subject component
      def process_attributes(sub)
        sattrs = reportable.assessment_group_batches.to_a.find{|agb| agb.batch_id == batch.id}.try(:subject_attribute_assessments).to_a
        subject_attribute = sattrs.find{|sattr| sattr.subject_id == sub.id}
        return unless subject_attribute.present?
        subject_attribute.attribute_assessments.each do |attr|
          build_subjects(attr.assessment_attribute, sub)
        end
      end
      
      ##
      # Building subject component with information regarding the 
      # subject / skill / attribute
      def build_subjects(subject, parent = nil)
        subject_comp = new_subject(subject, parent)
        subject_sets.push subject_comp
      end
      
      def new_subject(subject, parent = nil)
        parent_name, parent_type, parent_id = subject.parent_name_and_type(parent)
        Models::Subject.new(
          :name => subject.name,
          :type => subject.class.name,
          :code => (subject.is_a?(Subject) ?  subject.code : ''),
          :parent_name => parent_name,
          :parent_type => parent_type,
          :parent_id => parent_id,
          :is_activity => subject.is_activity?,
          :obj_id => subject.id,
          :exclude_from_total => (subject.is_a?(Subject) ?  subject.exclude_for_final_score : false),
          :parent_subject_id => (parent.present? ? parent.id : nil)
        )
      end
      
      private
      
      attr_accessor :reportable, :student, :subject_sets
      
      ##
      # Checking whether subject has skills associated
      def consider_skills_of_subjects(sub)
        sub.is_a? Subject and sub.subject_skill_set_id.present?
      end
      
      def has_exam_group_with_skill_enabled?
        assessment_groups.select{|group| group.consider_skills? }.present?
      end
      
    end
  end
end
