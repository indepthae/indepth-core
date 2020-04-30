class_timing_set_batches=Batch.all(:conditions=>{:class_timing_set_id=>nil})
class_timing_set_id=ClassTimingSet.first.try(:id)
class_timing_set_batches.each do |batch|
  batch.update_attribute(:class_timing_set_id,class_timing_set_id)
end
batches= Batch.all
batches.each do |batch|
  batch.attendance_weekday_sets.create(:weekday_set_id=>batch.weekday_set_id,:start_date=>batch.start_date,:end_date=>batch.end_date)
end
