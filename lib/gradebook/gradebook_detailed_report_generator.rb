class GradebookDetailedReportGenerator
  attr_accessor :param
  def initialize(param)
    #    @id = param[:exam].split('_').last.to_i
    @type = param[:exam].split('_').first
    @param = param
  end

  def create_report
    case @type
    when "term"
      GenerateDetailedTermReport.new(@param)
    when "plan"
      GenerateDetailedPlannerReport.new(@param)
    end
  end
end
