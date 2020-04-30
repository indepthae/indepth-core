require 'logger'
start_time = Time.now
unless File.exist?("log/seed")
  FileUtils.mkpath "log/seed"
end
log = Logger.new("log/seed/old_receipt_no_config_to_new_receipt_configs-#{start_time.to_i}.log")
tbl_name = 'configurations'
sql = "INSERT INTO #{tbl_name} (school_id, config_key, config_value, created_at, updated_at)

       SELECT school_id, 'FeeReceiptPrefix',
              SUBSTRING(config_value, 1, LENGTH(config_value) - LENGTH(REGEXP_SUBSTR(config_value,'[0-9]*$'))) AS prefix,
              created_at, updated_at

         FROM configurations

        WHERE `config_key` = 'FeeReceiptNo' AND config_value IS NOT NULL"

log.info(sql)
ActiveRecord::Base.connection.execute(sql)

sql = "INSERT INTO #{tbl_name} (school_id, config_key, config_value, created_at, updated_at)

       SELECT school_id, 'FeeReceiptStartingNumber', REGEXP_SUBSTR(config_value,'[0-9]*$') AS suffix,
              created_at, updated_at

         FROM configurations

        WHERE `config_key` = 'FeeReceiptNo' AND config_value IS NOT NULL"
log.info(sql)
ActiveRecord::Base.connection.execute(sql)

end_time = Time.now

log.info "execution time:"
log.info "Start : #{start_time}"
log.info  "End : #{end_time}"
log.info  "duration : #{(end_time - start_time).seconds}"

FeatureLock.unlock_feature :finance_multi_receipt_data_updation