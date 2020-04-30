# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    class RecordFactory < ComponentFactory
      def process_and_build_components
        # returns collection of Record objects
        return unless records_enabled?
        record_collection = new_collection
        gradebook_record_groups.to_a.each do |grg|
          if is_exam_frequent?
            gradebook_records = grg.gradebook_records.select{|obj| all_assessment_groups.collect(&:id).include?obj.linkable_id}
          elsif is_term_frequent?
            gradebook_records = grg.gradebook_records.select{|obj| @reportable.assessment_term_of_reportable.collect(&:id).include?obj.linkable_id}
          else
            gradebook_records = grg.gradebook_records.select{|obj| @reportable.id == obj.linkable_id}
          end
          gradebook_records.to_a.each do |gr|
            record_group = gr.record_group
            records = record_group.records.to_a.select{|r| r.input_type != "attachment"}
            records.to_a.each do |record|
              student_record = record.student_records.to_a.find{|sa| sa.student_id==@student.s_id}
              data = student_record.present? ? student_record.additional_info : nil
              record_collection.push(Models::Record.new(:key=>record.name,:suffix=>record.suffix,:value=>data,:parent=>gr.linkable.display_name,:record_group=>grg.name))
            end
          end
        end
        record_collection
      end
      
      private
      
      def records_enabled?
        # activation status for student records for a planner.
        # Managed in Student Report settings page
        settings[:enable_student_records] == "1"
      end
      
      def is_exam_frequent?
        # Records will be shown as exam wise, in all reports.
        # Managed in Student Report settings page
        settings[:frequency] == "0"
      end
      
      def is_term_frequent?
        # Records will be shown as term wise.
        # Managed in Student Report settings page
        settings[:frequency] == "1"
      end
      
    end
  end
end