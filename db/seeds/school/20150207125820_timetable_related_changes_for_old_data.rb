
multischool=MultiSchool rescue nil
default_batch_cts=[]
default_batch_cts_count=0
timetable_cts=[]
timetable_cts_count=0
batch_cts=[]
batch_cts_count=0
configurations=[]
#*******************************************************************************
#inserting default weekdayset_id to batches where its not present

default_weekday_set_id=WeekdaySet.first.try(:id)
Batch.find_in_batches(:conditions=>{:weekday_set_id=>nil},:batch_size=>500) do |batches|
  batches.each do |batch|
    batch.update_attribute(:weekday_set_id,default_weekday_set_id)
  end
end

#*******************************************************************************
#inserting default batch class timing sets

default_batch_class_timing_sets_query=unless(multischool)
  "INSERT INTO batch_class_timing_sets (`class_timing_set_id`,`weekday_id`)"
else
  "INSERT INTO batch_class_timing_sets (`class_timing_set_id`,`weekday_id`,`school_id`)"
end

default_weekday_set=WeekdaySet.common
unless ClassTimingSet.count == 0
  class_timing_set_id=ClassTimingSet.first.try(:id)
else
  class_timing_set_id=ClassTimingSet.find_or_create_by_name(:name=>'Default').try(:id)
end
default_weekday_set.weekdays.each do |weekday|
  default_batch_cts << "(#{class_timing_set_id}, #{weekday.weekday_id}#{(', '+multischool.current_school.id.to_s) if multischool})"
  default_batch_cts_count=default_batch_cts_count+1
  if(default_batch_cts_count) >= 500
    insert_batch_class_timing_sets="#{default_batch_class_timing_sets_query} VALUES #{default_batch_cts.join(', ')} ;"
    RecordUpdate.connection.execute(insert_batch_class_timing_sets)
    default_batch_cts_count=0
    default_batch_cts=[]
  end
  if weekday==default_weekday_set.weekdays.last
    unless default_batch_cts.empty?
      insert_batch_class_timing_sets="#{default_batch_class_timing_sets_query} VALUES #{default_batch_cts.join(', ')} ;"
      RecordUpdate.connection.execute(insert_batch_class_timing_sets)
      default_batch_cts_count=0
      default_batch_cts=[]
    end
  end
end

#*******************************************************************************
#inserting batch class timing sets for existing batches

batch_class_timing_sets_query=unless(multischool)
  "INSERT INTO batch_class_timing_sets (`batch_id`,`class_timing_set_id`,`weekday_id`)"
else
  "INSERT INTO batch_class_timing_sets (`batch_id`,`class_timing_set_id`,`weekday_id`,`school_id`)"
end
Batch.all.each do |b|
  if(b.weekday_set_id.present? and b.class_timing_set_id.present?)
    b.weekday_set.weekdays.each do |weekday|
      batch_cts << "(#{b.id}, #{b.class_timing_set_id}, #{weekday.weekday_id}#{(', '+multischool.current_school.id.to_s) if multischool})"
    end
  elsif(b.weekday_set_id.present? and !b.class_timing_set_id.present?)
    unless ClassTimingSet.count==0
      default_class_timing_set=ClassTimingSet.find_by_name('Default')
      unless default_class_timing_set.present?
        default_class_timing_set=ClassTimingSet.first
      end
      b.weekday_set.weekdays.each do |weekday|
        batch_cts << "(#{b.id}, #{default_class_timing_set.id}, #{weekday.weekday_id}#{(', '+multischool.current_school.id.to_s) if multischool})"
      end
    else
      ClassTimingSet.create(:name=>'Default')
      new_class_timing_set=ClassTimingSet.find_by_name('Default')
      b.weekday_set.weekdays.each do |weekday|
        batch_cts << "(#{b.id}, #{new_class_timing_set.id}, #{weekday.weekday_id}#{(', '+multischool.current_school.id.to_s) if multischool})"
      end
    end
  end
  batch_cts_count=batch_cts_count+1
  if(batch_cts_count) >= 500
    insert_batch_class_timing_sets="#{batch_class_timing_sets_query} VALUES #{batch_cts.join(', ')} ;"
    RecordUpdate.connection.execute(insert_batch_class_timing_sets)
    batch_cts_count=0
    batch_cts=[]
  end
  if b==Batch.last
    unless batch_cts.empty?
      insert_batch_class_timing_sets="#{batch_class_timing_sets_query} VALUES #{batch_cts.join(', ')} ;"
      RecordUpdate.connection.execute(insert_batch_class_timing_sets)
      batch_cts_count=0
      batch_cts=[]
    end
  end
end

#*******************************************************************************
#inserting timetable class timing sets
timetable_class_timing_sets_query=unless(multischool)
  "INSERT INTO time_table_class_timing_sets (`time_table_class_timing_id`,`batch_id`,`class_timing_set_id`,`weekday_id`)"
else
  "INSERT INTO time_table_class_timing_sets (`time_table_class_timing_id`,`batch_id`,`class_timing_set_id`,`weekday_id`,`school_id`)"
end
if TimeTableClassTiming.count >0
  TimeTableClassTiming.all(:conditions=>["class_timing_set_id IS NOT NULL"]).each do |ttct|
    timetable_weekday=TimeTableWeekday.find_by_batch_id_and_timetable_id(ttct.batch_id,ttct.timetable_id,:include=>{:weekday_set=>:weekday_sets_weekdays})
    if timetable_weekday.present?
      timetable_weekday.weekday_set.weekdays.each do |wd|
        timetable_cts << "(#{ttct.id}, #{ttct.batch_id}, #{ttct.class_timing_set_id}, #{wd.weekday_id}#{(', '+multischool.current_school.id.to_s) if multischool})"
        timetable_cts_count=timetable_cts_count+1
        if(timetable_cts_count>=500)
          insert_timetable_class_timing_sets="#{timetable_class_timing_sets_query} VALUES #{timetable_cts.join(', ')} ;"
          RecordUpdate.connection.execute(insert_timetable_class_timing_sets)
          timetable_cts_count=0
          timetable_cts=[]
        end
        if wd=timetable_weekday.weekday_set.weekdays.last
          unless timetable_cts.empty?
            insert_timetable_class_timing_sets="#{timetable_class_timing_sets_query} VALUES #{timetable_cts.join(', ')} ;"
            RecordUpdate.connection.execute(insert_timetable_class_timing_sets)
            timetable_cts_count=0
            timetable_cts=[]
          end
        end
      end
    end
  end
end

#*******************************************************************************
#start_day_of_the_week
configuration_query=unless(multischool)
  "INSERT INTO configurations (`config_key`,`config_value`)"
else
  "INSERT INTO configurations (`config_key`,`config_value`,`school_id`)"
end
configurations<<"('StartDayOfWeek','0'#{(', '+multischool.current_school.id.to_s) if multischool})"
insert_configuration="#{configuration_query} VALUES #{configurations.join(', ')} ;"
RecordUpdate.connection.execute(insert_configuration)
configurations=[]


