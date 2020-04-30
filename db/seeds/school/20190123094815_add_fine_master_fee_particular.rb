# Insert A MasterFeeParticular for Fine
mfp = MasterFeeParticular.find_or_create_by_name_and_particular_type('Fine', 'Fine')
mfp.save false if mfp.new_record?