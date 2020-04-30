module AssessmentAttributesHelper
  
  def fetch_attributes_path(profile)
    profile.new_record? ? assessment_attributes_path : assessment_attribute_path
  end
  
end
