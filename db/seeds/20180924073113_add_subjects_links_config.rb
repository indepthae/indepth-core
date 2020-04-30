ActiveRecord::Base.transaction do
  schools = School.all(:joins => "INNER JOIN subjects ON subjects.school_id = schools.id", :group => "schools.id")
  schools.each do |school|
    MultiSchool.current_school = school
    Configuration.find_or_create_by_config_key({"config_key" => "EnabledConnectSubject" , "config_value" => "0"})
  end
end