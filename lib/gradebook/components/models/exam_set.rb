module Gradebook
  module Components
    module Models
      class ExamSet < Base
        include Rounding

        properties :scores, :name, :planner_name, :aggregates, :attendance_report, :obj_id, :term_name, :term_exam,
                   :planner_exam, :group_exam, :scoring_type, :show_percentage, :maximum_mark, :hide_marks,
                   :consider_skills

        round_off_properties :maximum_mark
        
        def set_subject_rank_details(scores_hash)
          return if scoring_type == 'grades'
          scores.each do |score|
            subject_score = scores_hash[score.subject.try(:obj_id)]
            next unless subject_score
            
            score.class_highest = subject_score[:highest_score].present? ? subject_score[:highest_score] : nil
            score.class_lowest  = subject_score[:lowest_score].present? ? subject_score[:lowest_score] : nil
            score.class_average  = subject_score[:average_score].present? ? subject_score[:average_score] : nil
            score.class_position  = subject_score[:rank].present? ? subject_score[:rank] : nil
          end
        end

        def set_exam_set_rank_details(totals_hash)
          return if scoring_type == 'grades'

          add_aggregate('batch_highest', 'Highest Score', totals_hash[:highest_score].present? ? totals_hash[:highest_score] : nil)
          add_aggregate('batch_lowest', 'Lowest Score',  totals_hash[:lowest_score].present? ? totals_hash[:lowest_score] :  nil)
          add_aggregate('batch_average', 'Average Score', totals_hash[:average_score].present? ? totals_hash[:average_score] : nil)
          add_aggregate('batch_position', 'Rank', totals_hash[:rank].present? ? totals_hash[:rank] : nil)
        end

        def is_a_final_exam?
          term_exam or planner_exam or group_exam
        end
        
        def additional_final_column(options={})
          return if !is_a_final_exam? or hide_marks or (options[:final_grade].present? and term_exam)
          if scoring_type == 'marks_and_grades'
            I18n.t('gb_grade')
          elsif show_percentage
            I18n.t('percentage')
          end
        end
        
        def name_with_max_mark(round = nil,round_marks = nil)
          if hide_marks
            "#{name}"
          elsif round.present? and !round_marks.present?
            "#{name}#{maximum_mark.present? ? " &#x200E;(#{maximum_mark.to_f.ceil})&#x200E;" : ""}"
          elsif !round.present? and round_marks.present?
            "#{name}#{maximum_mark.present? ? " &#x200E;(#{maximum_mark.to_f.round})&#x200E;" : ""}"
          else
            "#{name}#{maximum_mark.present? ? " &#x200E;(#{maximum_mark})&#x200E;" : ""}"
          end
#          round.nil? ? "#{name}#{maximum_mark.present? ? " &#x200E;(#{maximum_mark.to_f})&#x200E;" : ""}" : "#{name}#{maximum_mark.present? ? " &#x200E;(#{maximum_mark.to_f.ceil})&#x200E;" : ""}" 
        end
        
        def build_message
          message = ""
          self.scores.each_with_index do |s, index|
            message = message + "#{s.subject.name} "  
            score = if self.scoring_type == "grades"
              s.grade.present? ? s.grade : "-"
            elsif self.scoring_type == "marks_and_grades"
              s.score.present? ? "#{s.score}/#{s.max_score} (#{s.grade})" : "-"
            else 
              s.score.present? ? "#{s.score}/#{s.max_score}" : "-" 
            end
            message = message + "#{score}"
            message = message + ", " if index < (self.scores.length-1)  
          end
          return message
        end

        def add_aggregate(aggregate_type, aggregate_name, value)
          aggregate = Models::Aggregate.new(
              :type => aggregate_type,
              :parent_name => name,
              :parent_type => 'AssessmentGroup',
              :name => aggregate_name,
              :value => value
          )
          aggregates.push aggregate
        end
        
      end
    end
  end
end
