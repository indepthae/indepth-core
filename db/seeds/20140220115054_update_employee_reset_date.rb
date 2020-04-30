
sql_update = "update employee_leaves inner join employees on employee_leaves.employee_id = employees.id set employee_leaves.reset_date = employees.joining_date where employee_leaves.reset_date is null"
ActiveRecord::Base.connection.execute(sql_update)