sql = "update observation_groups set di_count_in_report = 2 where di_count_in_report IS NULL"
ActiveRecord::Base.connection.execute(sql)