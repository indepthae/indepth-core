schools = School.all
schools.each do |school|
  MultiSchool.current_school = school
  attr_assessments = AttributeAssessment.all
  attr_assessments.group_by(&:assessment_group_batch_id).each_pair do |agb, assess|
    assess.group_by(&:subject_id).each_pair do |sub_id, assessments|
      saa = SubjectAttributeAssessment.find_by_subject_id_and_assessment_group_batch_id(agb, sub_id)
      unless saa
        saa = SubjectAttributeAssessment.new(:subject_id => sub_id, :assessment_group_batch_id => agb, :assessment_attribute_profile_id => assessments.first.assessment_attribute_profile_id)
        saa.send :create_without_callbacks
      end
      unless saa.new_record?
        assessments.each do |a| 
          a.subject_attribute_assessment = saa
          a.send :update_without_callbacks
        end
      end
    end
  end
end