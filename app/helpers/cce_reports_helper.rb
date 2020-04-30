module CceReportsHelper
  def get_assessment_group(assessment_text)
    if assessment_text.present?
      if assessment_text=='ASL1'
        assessment_group = 'ASL - SA1' 
      elsif assessment_text== 'ASL2' 
        assessment_group = 'ASL - SA2' 
      elsif assessment_text== 'ASLO' 
        assessment_group = 'ASL - SA1 + SA2' 
      else 
        assessment_group = assessment_text
      end
    end
    return assessment_group
  end
end
