# Insert A MasterFeeParticular for Hostel Fee
mfp = MasterFeeParticular.find_or_create_by_name_and_particular_type('Rent', 'HostelFee')
mfp.save false if mfp.new_record?