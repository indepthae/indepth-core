# Insert A MasterFeeParticular for Transport Fee
mfp = MasterFeeParticular.find_or_create_by_name_and_particular_type('Bus Fare', 'TransportFee')
mfp.save false if mfp.new_record?