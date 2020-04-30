module AssessmentGroupsHelper
  
  def fetch_save_path(group)
    unless group.parent_type == "Course"
      group.new_record? ? assessment_groups_path : assessment_group_path(group)
    else
      group.new_record? ? create_course_exam_assessment_groups_path : update_course_exam_assessment_group_path(group)
    end
  end
  
  def fetch_final_term_path(group)
    group.new_record? ? create_final_term_assessment_group_path : update_final_term_assessment_group_path(group)
  end
  
  def fetch_method(group)
    (group.new_record? ? :post : :put)
  end
end
