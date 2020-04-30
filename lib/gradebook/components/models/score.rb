module Gradebook
  module Components
    module Models
      class Score < Base
        include Rounding

        properties :activity, :subject, :score, :grade, :max_score, :min_score, :credit_points, :remarks, :credit_hours, :is_absent
        properties :class_highest, :class_lowest, :class_average, :class_position, :is_overrided_max_mark

        round_off_properties :score, :class_highest, :class_lowest, :class_average, :class_position, :min_score, :max_score
        # round_off_properties :class_highest, :class_lowest, :class_average, :class_position, :min_score, :max_score

        def failed?
          if score.present? and min_score.present?
            score < min_score
          end
        end
        
        def passed?
          if score.present? and min_score.present?
            score > min_score
          end
        end
        
       def marks_and_grade(round=nil,round_marks=nil)
          if score.present?
            "#{marks_with_overrided_max_mark(round,round_marks)}#{grade.present? ? " &#x200E;(#{grade})&#x200E;" : ""}"
          else
            grade
          end
        end
        
        def marks_with_overrided_max_mark(round=nil,round_marks=nil)
            unless score.blank?
                if (round.present? and !round_marks.present?)
                    "#{score.ceil} #{overrided_max_mark}"
                elsif (!round.present? and round_marks.present?)
                    "#{score.round} #{overrided_max_mark}"
                else
                    "#{score} #{overrided_max_mark}"
                end
                
            end
        end
        
        def percentage
          ((score * 100).to_f/max_score.to_f).round(2) if score.present? and max_score.present?
        end
        
         def fetch_score_for_exam_set(set,round=nil,round_marks=nil,activity_total=nil)
          if set.is_a_final_exam?
            if ((set.scoring_type == 'marks') or (set.scoring_type == 'marks_and_grades')) and !set.hide_marks
              if activity_total == true
                "-"
              else
                marks_with_overrided_max_mark(round,round_marks)
              end
            elsif set.scoring_type == 'grades' or set.hide_marks
                grade
            end
          else
            set.hide_marks ? grade : marks_and_grade(round,round_marks)
          end
        end
        
        private
        
        def overrided_max_mark
          is_overrided_max_mark ? " &#x200E;(#{max_score})&#x200E;" : ''
        end
        
      end
    end
  end
end
