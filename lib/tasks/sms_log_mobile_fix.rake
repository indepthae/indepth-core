namespace :sms_log do |args|
  task :modify, [:school_id] => :environment do |t, args|    
    unless args.school_id.nil?
      block_size = 500
      process = true
      if args.school_id.downcase == 'all'
        puts "All school sms_logs"
        sms_logs = SmsLog.find_by_sql("select * from sms_logs where mobile like '%,%'")
      elsif (Integer(args.school_id) rescue false)
        puts "School id #{args.school_id}"
        sms_logs = SmsLog.find_by_sql("select * from sms_logs where school_id = #{args.school_id} and mobile like '%,%'")
        process = false unless sms_logs.length > 0
      else
        process = false
      end   
      unless process
        puts "Argument passed is not valid or no sms logs found for provided argument. Pass 'all' for all schools or a specific school id"
      else
        puts "Total sms logs found to rectify #{sms_logs.length}"
        cnt = 0
        t_cnt = (sms_logs.length / block_size.to_f).ceil
        sms_logs.in_groups_of(block_size) do |sms_logs_block|
          cnt = cnt.next
          puts "blocks of #{block_size} :: loop# #{cnt} of #{t_cnt}"
          sql_update_query = "UPDATE `sms_logs` SET `mobile` = CASE `id` "
          sms_log_ids = []
          #      puts sms_logs_block.compact
          sms_logs_block.compact.each do |sms_log|
            sms_log_ids << sms_log.id
            mobile_recipients = sms_log.mobile.split(',').map {|x| x.strip }.join(', ')
            sql_update_query += " WHEN #{sms_log.id} THEN '#{mobile_recipients}'"
          end
          sql_update_query += " END WHERE `id` in (#{sms_log_ids.join(',')});"
          RecordUpdate.connection.execute(sql_update_query)
        end        
      end
    else
      puts "No arguments provided"
    end    
  end
end