# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module ExamHelper
  def student_transcript_header args = {}
    arr = []
    if args.has_key? :subject_average
      args[:setting].show_grade and args[:subject_average].present? ? arr << GradingLevel.percentage_to_grade(args[:subject_average], args[:batch]).name : arr << ""
      args[:setting].show_percentage and args[:subject_average].present? ? arr << args[:subject_average] : arr << "" 
    else 
      arr << t('grade') if args[:setting].show_grade
      arr << t('percentage') if args[:setting].show_percentage
    end
    return arr
    
  end
end
