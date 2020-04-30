# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    module Models
      class Report < Base
        properties :exam_sets, :activity_sets, :aggregates, :student, :school_details, :subjects
        properties :title, :academic_year, :name, :remarks, :gradeset, :attendance_reports, :grade_scales, :report_template,
          :subject_remarks, :type, :header_name, :subjectwise_attendance, :cumulative_subjectwise_attendance, :display_name
        
        def main_subjects
          #          subjects.find_all_by(:parent_type => 'Batch')
          subjects.select{|s| ['Batch', 'ElectiveGroup'].include? s.parent_type}
        end
        
        def main_subjects_included_in_total
          subjects.select{|s| ['Batch', 'ElectiveGroup'].include?(s.parent_type) and !s.exclude_from_total}
        end
        
        def main_subjects_excluded_from_total
          subjects.select{|s| ['Batch', 'ElectiveGroup'].include?(s.parent_type) and s.exclude_from_total}
        end
        
        def subject_wise_remark_enabled?
          subject_remarks.present?
        end
        
        def term_names
          exam_sets.map{|e| e.term_name }.compact.uniq
        end
        
        def final_exam_sets(options={})
          final_sets_exam = deafult_final_exam_sets
          final_sets_exam = final_sets_exam.reject{|es| es.consider_skills } if without_skills_check(options)
          return final_sets_exam
        end
        
        def deafult_final_exam_sets
          exam_sets.find_all_by(:term_name => nil)
        end
      
        def final_exams(options={})
          exams = Collection.new
          without_skills_check(options) ? skill_final_exam_set(exams) : final_exam_set(exams)
          exams
        end
        
        def skill_final_exam_set(exams)
          exam_sets.reject{|es| es.consider_skills }.each{|es| exams.push(es) if es.is_a_final_exam?}
        end
        
        def final_exam_set(exams)
          exam_sets.each{|es| exams.push(es) if es.is_a_final_exam?}
        end
        
        def subject_remarks_of(options = {})
          remark = subject_remarks.find_by(:type_id => options[:subject].obj_id.to_i, :parent_name => options[:parent_name], :parent_type => options[:parent_type])
          remark.try(:remark)
        end
        
        def term_section_col_count(term_name = nil, options = {})
          mark_and_grade = options[:mark_and_grade] if options[:mark_and_grade].present?
          term_exam_sets = exam_sets_count(options)
          sets =  term_exam_sets[term_name]
          sets_name = sets.collect{|e| (!e.planner_exam and !e.term_exam and !e.group_exam) ? e.name.to_s : '-'}
          count = sets.count
          unless count.zero?
            count += 1  if sets.find{|e| e.is_a_final_exam? and e.additional_final_column.present?}.present?
            count += 1 if subject_remarks.present? and subject_remarks_present(term_name)
            if mark_and_grade.present? and mark_and_grade == true
              count_mark_and_grade_exam = 0
              exam_sets.each do |x| 
                count_mark_and_grade_exam += 1 if x.scoring_type == 'marks_and_grades' and sets_name.include? x.name.to_s and (!x.planner_exam and !x.term_exam and !x.group_exam)
              end
              count += count_mark_and_grade_exam if count_mark_and_grade_exam > 0
              
            end
          end
        
          count
        end
        
        def subject_remarks_present(term_name=nil)
          if term_name.present?
            return subject_remarks.select{|remark| remark.parent_type=="AssessmentTerm" and remark.parent_name== term_name}.present?
          else
            return subject_remarks.select{|remark| remark.parent_type==type}.present?
          end
        end
        
        def without_skills_check(options)
          (options.present? && options[:template].present? && options[:template] == 'd')
        end
        
        def exam_sets_without_skills
          exam_sets.reject{|es| es.consider_skills }
        end
        
        def exam_sets_count(options)
          without_skills_check(options) ? exam_sets_without_skills : exam_sets
        end
        
        def term_section_col_count_without_addl_col(term_name = nil, options = {})
          term_exam_sets = exam_sets_count(options)
          sets = term_exam_sets[term_name]
          count = sets.count
          
          count
        end
        
        def main_subjects_with_sub_skills
          subject_skills = subjects.find_all_by(:type => "SubjectSkill")
          parents = Collection.new
          subject_skills.each do |ss|
            parent_rec = ss.parent(self)
            parent_parent_rec = parent_rec.parent(self)
            unless parent_parent_rec.present?
              parents.push(parent_rec)
            else
              parents.push(parent_parent_rec)
            end
          end
          parents.uniq
        end

	      def exam_attendance_reports
          exam_sets.collect(&:attendance_report).compact
        end
        
        def subject_codes_for_graph
          subjects.reject{|subject| unwanted_subject(subject) or subject.is_activity }.collect(&:code)
        end
        
        def unwanted_subject(subject)
          ['BatchSubjectGroup','SubjectSkill'].include?(subject.type)
        end
        
        def term_exams
          exam_sets.map{|e| e.term_exam }
        end
        
        def term_exams_array
          exam_sets.select{|e| e.term_exam == true }
        end
        
        def last_exam
          exam_sets.map{|e| e }.last
        end
        
      end
    end
  end
end
