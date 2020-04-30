module Gradebook
  module Components
    mattr_accessor :batch, :subjects, :students, :assessment_groups, :holiday_event_dates, :settings,
      :activity_groups, :attendance_entries, :assessment_date, :gradebook_remarks,
      :gradebook_record_groups, :overall_grade_set, :all_assessment_groups, :attendances, :scores_hash,
      :exam_totals_hash, :grade_sets
      
    class ComponentFactory
      
      ##
      # Struct of formating report build status
      
      Status = Struct.new(:success,:failed, :errors)
      
      def initialize(attributes)
        attributes.each do |attribute_name, attribute_value|
          self.instance_variable_set("@#{attribute_name}", attribute_value)
        end
      end
      
      ##
      # Stub for `process_and_build_components` for not breaking while accessing
      # from child classes
      def process_and_build_components 
      end
        
      ##
      # Return final assessment for report.
      # If reportable is a `assessment group` then function will return reportable
      # itself
      def final_assessment
        @final_assessment ||= case @reportable.class.table_name            
        when 'assessment_groups'
          @reportable
        when 'assessment_plans'
          final_assessment = @reportable.final_assessment
          final_assessment if !final_assessment.new_record? or !final_assessment.no_exam
        when 'assessment_terms'
          @reportable.final_assessment
        end
      end
        
      ##
      # Returns assessment plan object for the reportable
      def assessment_plan
        @assessment_plan ||= if @reportable.is_a? AssessmentPlan
          @reportable
        else
          @reportable.assessment_plan
        end
      end
      
      # => params: nil
      # => returns: true if reportable is assessment group else false
      def is_assessment_group?
        @reportable.class.table_name == 'assessment_groups'
      end
      
      # => params: nil
      # => returns: true if reportable is assessment term else false
      def is_assessment_term?
        @reportable.class.table_name == 'assessment_terms'
      end
      
      # => params: nil
      # => returns: true if reportable is assessment plan else false
      def is_assessment_plan?
        @reportable.class.table_name == 'assessment_plans'
      end
      
      def activity_exam_report?
        is_assessment_group? and @reportable.exam_type.activity
      end
      
      ##
      # returns  Term name for the group given
      # params: assessment group
      # Used for storing term name information in components
      def term_name(group)
        return if is_assessment_group?
        group.parent.name if group.parent_type == 'AssessmentTerm'
      end
        
      ##
      # Building methods for each mattr_accessors of Components for accessing
      # across factories
      [:batch, :students, :subjects, :assessment_groups, :holiday_event_dates, :settings, :activity_groups,
        :attendance_entries, :assessment_date, :gradebook_remarks, :gradebook_record_groups,
        :overall_grade_set, :all_assessment_groups, :attendances, :scores_hash, :grade_sets, :exam_totals_hash
      ].each do |method_name|
        define_method method_name do
          Components.send(method_name)
        end
      end
      
      ##
      # Returns new collection component
      def new_collection
        Models::Collection.new
      end
      
      
      def attribute_assessment_report?
        is_assessment_group? and @reportable.subject_assessment? and !@reportable.is_single_mark_entry?
      end
      
      def is_final_exam_with_no_exam?(group)
        group.is_final_term? and group.no_exam and (group.parent_type == @reportable.class.name)
      end
      
      # => params: nil
      # => returns: true if general remarks enabled else false
      def general_remark_enabled?
        settings[:general_remarks] == "1"
      end
      
      # => params: nil
      # => returns: true if subject wise remarks enabled else false
      def subject_wise_remark_enabled?
        settings[:subject_wise_remarks] == "1"
      end
      
      class << self
        def build(attributes)
          new(attributes).process_and_build_components
        end
      end
        
    end
  end
end
