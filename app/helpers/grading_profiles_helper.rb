module GradingProfilesHelper
  
  def fetch_grade_profile_path(grade_set)
    grade_set.new_record? ? grading_profiles_path : grading_profile_path
  end
 
end
