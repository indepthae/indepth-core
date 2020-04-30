class GradebookReportGenerator
  attr_accessor :param
  def initialize(param,agb_id)
    @agb_id = agb_id
    @param = param
    @assessment_group = AssessmentGroup.find param[:exam].split('_').last.to_i
  end
  
  def create_report
    case @assessment_group.assessment_group_type
    when 'Derived'
      GenerateDerivedExamReport.new(@param,@agb_id)
    when 'Subject'
      GenerateSubjectExamReport.new(@param,@agb_id,@assessment_group.maximum_marks)
    when 'Subject Attributes'
      if @param[:type] == "attribute"
        GenerateAttributeExamReport.new(@param,@agb_id)
      elsif ["planner","percent"].include? @param[:type] 
        GenerateSubjectExamReport.new(@param,@agb_id,@assessment_group.maximum_marks)
      end
    when 'Activity'
      GenerateActivityExamReport.new(@param,@agb_id)
    end
  end
  
end
