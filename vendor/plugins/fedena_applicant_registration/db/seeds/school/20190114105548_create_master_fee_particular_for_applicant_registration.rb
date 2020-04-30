# Insert A MasterFeeParticular for Applicant Registration
mfp = MasterFeeParticular.find_or_create_by_name_and_particular_type('Application Fee', 'RegistrationCourse')
mfp.save false if mfp.new_record?