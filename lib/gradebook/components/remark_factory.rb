# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    # In case of General Remarks to implement inherited remarks do the following:
    # group the remarks returned by type_id and parent_type
    # those will be the inherited remark of that reportable 
    class RemarkFactory < ComponentFactory
      
      # => params: nil
      # => returns: Subject wise remark if subject is present else collection of general remarks
      def process_and_build_components
        unless subjects.present?
          return new_collection unless general_remark_enabled?
          fetch_general_remarks
        else
          return new_collection unless subject_wise_remark_enabled?
          fetch_subject_wise_remarks
        end
        
      end
            
      private
      attr_accessor :reportable, :student, :subjects
      
      # => params : nil
      # => returns : 
      #     remarks: Model::Collection object of all general remarks for the student and 
      #               for that particular reportable(AssessmentGroup, Term or Planner)
      def fetch_general_remarks
        @remarks = new_collection
        build_general_remark(reportable.class.table_name.classify,false,[reportable.id])  
        if is_assessment_term? and inherit_from_exam_enabled?
          inherited_exam_remarks
        elsif is_assessment_plan? and inherit_from_term_exam_enabled?
          inherited_exam_and_term_remarks
        end
        @remarks
      end
      
      # => params: nil
      # => Fetches all inherited exam remarks in case of Term Report
      def inherited_exam_remarks
        reportable_ids = reportable.assessment_groups.collect(&:id)
        build_general_remark("AssessmentGroup", true, reportable_ids)
      end
      
      # => params: nil
      # => Fetches all inherited exam and term remarks in case of Planner Report
      def inherited_exam_and_term_remarks
        reportable_ids = []
        terms = reportable.assessment_terms
        terms.each{ |at| reportable_ids << at.assessment_groups.collect(&:id)}
        build_general_remark("AssessmentGroup",true, reportable_ids.flatten)
        reportable_ids = terms.collect(&:id)
        build_general_remark("AssessmentTerm", true, reportable_ids)
      end
      
      # => params :
      #     report_type: Reportable type, can be  AssessmentGroup, AssessmentTerm, AssessmentPlan
      #     is_inherited: Whether the remark object to be build is inherited
      #     reportable_ids: The ids of reports for which remarks has to be found out.
      def build_general_remark(report_type, is_inherited, reportable_ids)
        g_remarks = gradebook_remarks.select{|gr| gr.remarkable_type == "RemarkSet" and 
            gr.student_id == student.s_id and gr.reportable_type == report_type and 
            reportable_ids.include? gr.reportable_id}
        g_remarks.each do |remark|
          add_to_remarks(remark, is_inherited)
        end
      end
      
      # => params : 
      #     remark: remark record to be pushed to @remarks
      #     is_inherited: Whether the remark object to be build is inherited
      def add_to_remarks(remark, is_inherited)
        remark_set = remark.remarkable
        @remarks.push(build_remark_object(remark, "general", remark_set.id, 
            remark_set.name, remark.reportable, is_inherited)) if remark.remark_body.present?
      end
      
      # => params: nil
      # => returns: 
      #     Models::Remark object for the student and for that particular reportable(AssessmentGroup, Term or Planner)
      def fetch_subject_wise_remarks
        @remarks = new_collection
        subjects.each do |subject|
          next unless subject.is_a? Subject
          remark = gradebook_remarks.detect{|gr| gr.remarkable_type == "Subject" and 
              gr.remarkable_id == subject.id and gr.student_id == student.s_id and 
              gr.reportable_type == reportable.class.table_name.classify and
              gr.reportable_id == reportable.id}
          @remarks.push(build_remark_object(remark, "subject", subject.id, subject.name, reportable)) if remark.present? and remark.remark_body.present?
          term_remark_for_planner_subjectwise(subject) if is_assessment_plan?
        end
        
        @remarks
      end
      
      # => params: nil
      # => Push term_remark to subject remarks collection if reportable is subjectwise
      def term_remark_for_planner_subjectwise(subject)
        assessment_terms = reportable.assessment_terms
        assessment_terms.each do |term|
          remark = gradebook_remarks.detect{|gr| gr.remarkable_type == "Subject" and 
              gr.remarkable_id == subject.id and gr.student_id == student.s_id and 
              gr.reportable_type == term.class.table_name.classify and
              gr.reportable_id == term.id}
          @remarks.push(build_remark_object(remark, "subject", subject.id, subject.name, term)) if remark.present? and remark.remark_body.present?
        end
      end
      
      # => params:
      #     remark: remark record to build Model::Remark object
      #     type: type of remark(general or subject)
      #     type_id: id of subject or remark set corressponding to type
      #     name: name of the subject or remark set corressponding to type
      #     is_inherited: Optional. true incase of inherit settings enabled 
      # => returns:
      #     Model::Remark object
      def build_remark_object(remark, type, type_id, name, parent, is_inherited=false)
        Models::Remark.new(:type => type, 
          :type_id => type_id, 
          :parent_name => parent.name, 
          :parent_type => parent.class.table_name.classify, 
          :name => name, 
          :remark => remark.remark_body, 
          :is_inherited => is_inherited) 
      end
      
      # => params: nil
      # => returns: true if remark enabled for AssessmentGroup else false
      def exam_report_remark_enabled?
        settings[:exam_report_remark] == "1"
      end
      
      # => params: nil
      # => returns: true if remark enabled for AssessmentTerm else false
      def term_report_remark_enabled?
        settings[:term_report_remark] == "1"
      end
      
      # => params: nil
      # => returns: true if remark enabled for AssessmentPlan else false
      def planner_report_remark_enabled?
        settings[:planner_report_remark] == "1"        
      end
      
      # => params: nil
      # => returns: true if inherit from exam remark enabled else false
      def inherit_from_exam_enabled?
        settings[:inherit_remark_from_exam] == "1"
      end
      
      # => params: nil
      # => returns: true if inherit from exam and term remark enabled else false
      def inherit_from_term_exam_enabled?
        settings[:inherit_remark_from_term_exam] == "1"
      end
      
    end
  end
end