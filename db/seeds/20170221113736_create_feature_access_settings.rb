ActiveRecord::Base.transaction do
  schools = School.all
  schools.each do |school|
    MultiSchool.current_school = school
    FeatureAccessSetting.find_or_create_by_feature_name(:feature_name => "Gallery", :parent_can_access => false)
    FeatureAccessSetting.find_or_create_by_feature_name(:feature_name => "Hostel", :parent_can_access => false)
    FeatureAccessSetting.find_or_create_by_feature_name(:feature_name => "Transport", :parent_can_access => false)
    FeatureAccessSetting.find_or_create_by_feature_name(:feature_name => "Student Documents", :parent_can_access => false)
    FeatureAccessSetting.find_or_create_by_feature_name(:feature_name => "Assignment", :parent_can_access => false)
    FeatureAccessSetting.find_or_create_by_feature_name(:feature_name => "Tasks", :parent_can_access => false)
  end
end