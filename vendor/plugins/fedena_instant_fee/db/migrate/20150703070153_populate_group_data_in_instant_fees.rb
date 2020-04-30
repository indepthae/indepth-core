class PopulateGroupDataInInstantFees < ActiveRecord::Migration
  def self.up

    update <<-SQL
      update instant_fees it
      inner join students st on st.id=it.payee_id and it.payee_type='Student'
      set it.groupable_id = ifnull((select batch_id from batch_students bs where bs.student_id=it.payee_id and it.created_at < bs.created_at 	order by bs.created_at desc limit 1	), st.batch_id), it.groupable_type = 'Batch'
      where it.groupable_id is null;
    SQL

    update <<-SQL
      update instant_fees it
      inner join archived_students st on st.former_id=it.payee_id and it.payee_type='Student'
      set it.groupable_id = ifnull((select batch_id from batch_students bs where bs.student_id=it.payee_id and it.created_at < bs.created_at 	order by bs.created_at desc limit 1	), st.batch_id), it.groupable_type = 'Batch'
      where it.groupable_id is null;
    SQL

    update <<-SQL
      update instant_fees it
      inner join employees st on st.id=it.payee_id and it.payee_type='Employee'
      set it.groupable_id = st.employee_department_id, it.groupable_type = 'EmployeeDepartment'
      where it.groupable_id is null;
    SQL

    update <<-SQL
      update instant_fees it
      inner join archived_employees st on st.former_id=it.payee_id and it.payee_type='Employee'
      set it.groupable_id = st.employee_department_id, it.groupable_type = 'EmployeeDepartment'
      where it.groupable_id is null;
    SQL

  end

  def self.down
  end
end
