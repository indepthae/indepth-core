tbl_name = "number_sequences"
fetch_tbl_name = "fee_invoices"
sub_query = "SELECT name 
                        FROM `#{tbl_name}` 
                     WHERE `#{tbl_name}`.school_id = #{fetch_tbl_name}.school_id"
sql   = "INSERT INTO #{tbl_name} (school_id, sequence_type, created_at, updated_at, next_number, name) "
sql += "SELECT school_id, 'invoice_no' AS sequence_type, MIN(created_at), MAX(updated_at),
                         MAX(CAST(REGEXP_SUBSTR(invoice_number,'[0-9]*$') AS SIGNED)) AS suffix, 
                         SUBSTRING(invoice_number, 1, LENGTH(invoice_number) - LENGTH(REGEXP_SUBSTR(invoice_number,'[0-9]*$'))) AS prefix
               FROM `#{fetch_tbl_name}`
        GROUP BY school_id, prefix  
            HAVING prefix NOT IN (#{sub_query})
        ORDER BY `#{fetch_tbl_name}`.`school_id` ASC"

ActiveRecord::Base.connection.execute(sql)