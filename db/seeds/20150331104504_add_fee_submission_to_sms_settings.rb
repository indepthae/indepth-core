query_string = "INSERT INTO `sms_settings` (`school_id`, `is_enabled`, `updated_at`, `settings_key`, `created_at`) VALUES "

if(MultiSchool rescue false)
if(SmsSetting.first(:conditions=>{:settings_key=>'FeeSubmissionEnabled'},:skip_multischool=>true))

  School.find_in_batches(:batch_size=>500) do |schools|
    schools.each do |school|
      MultiSchool.current_school=school
      SmsSetting.find_or_create_by_settings_key({"settings_key" => "FeeSubmissionEnabled" ,"is_enabled" => false})
    end
  end

else

School.find_in_batches(:batch_size=>500) do |schools|
  MultiSchool.current_school=nil
  time = Time.now.in_time_zone('UTC').strftime('%Y-%m-%d %H:%M:%S')
  queries = []
  schools.each do |school|
    queries << "(#{school.id}, 0, '#{time}', 'FeeSubmissionEnabled', '#{time}')"
  end
  ActiveRecord::Base.connection.execute(query_string + queries.join(',')+';')
end

end

else
  SmsSetting.find_or_create_by_settings_key({"settings_key" => "FeeSubmissionEnabled" ,"is_enabled" => false})
end