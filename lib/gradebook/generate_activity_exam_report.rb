class GenerateActivityExamReport
  def initialize(param,agb_id)
    @agb_id = agb_id
    @param = param
    @assessment_group = AssessmentGroup.find @param[:exam].split('_').last.to_i
  end
  
  def fetch_report_data
    @score_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    ConvertedAssessmentMark.find(:all,:conditions=>["assessment_group_batch_id= ?",@agb_id]).each do |obj|
      @score_hash[obj. markable_id][obj.student_id] = {:grade=>obj.grade}
    end
    @score_hash
  end
  
  def fetch_report_headers
    @header_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @header_hash = {:names=>@assessment_group.assessment_activity_profile.assessment_activities.collect(&:name),:ids=>@assessment_group.assessment_activity_profile.assessment_activities.collect(&:id)}
  end
end