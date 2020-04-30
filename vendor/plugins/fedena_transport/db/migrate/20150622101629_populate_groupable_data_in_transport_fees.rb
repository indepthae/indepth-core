class PopulateGroupableDataInTransportFees < ActiveRecord::Migration
  def self.up
    update <<-SQL
      update transport_fees tf 
      inner join transport_fee_collections tfc on tfc.id=tf.transport_fee_collection_id
      left outer join students st on st.id=tf.receiver_id and receiver_type like 'Student'
      set tf.groupable_id=tfc.batch_id, tf.groupable_type = 'Batch'
      where st.batch_id is not null and st.batch_id = ifnull(tfc.batch_id,0);
    SQL

    update <<-SQL
      update transport_fees tf 
      inner join transport_fee_collections tfc on tfc.id=tf.transport_fee_collection_id
      left outer join archived_students st on st.former_id=tf.receiver_id and receiver_type like 'Student'
      set tf.groupable_id=tfc.batch_id, tf.groupable_type = 'Batch'
      where st.batch_id is not null and st.batch_id = ifnull(tfc.batch_id,0);
    SQL

    update <<-SQL
      update  transport_fees tf 
      left outer join transport_fee_collections tfc on tfc.id=tf.transport_fee_collection_id 
      left outer join students st on st.id=tf.receiver_id and receiver_type like 'Student' 
      set tf.groupable_id=ifnull((select batch_id from batch_students bs where bs.student_id=tf.receiver_id and tf.created_at < bs.created_at 	order by bs.created_at desc limit 1	),st.batch_id),tf.groupable_type='Batch' 
      where st.batch_id is not null and st.batch_id <> ifnull(tfc.batch_id,0);
    SQL

    update <<-SQL
      update  transport_fees tf 
      left outer join transport_fee_collections tfc on tfc.id=tf.transport_fee_collection_id 
      left outer join archived_students st on st.former_id=tf.receiver_id and receiver_type like 'Student' 
      set tf.groupable_id=ifnull((select batch_id from batch_students bs where bs.student_id=tf.receiver_id and tf.created_at < bs.created_at 	order by bs.created_at desc limit 1	),st.batch_id),tf.groupable_type='Batch' 
      where st.batch_id is not null and st.batch_id <> ifnull(tfc.batch_id,0);
    SQL

    update <<-SQL
      update transport_fees tf
      left outer join employees em on em.id = tf.receiver_id and receiver_type = 'Employee'
      set tf.groupable_id = em.employee_department_id, tf.groupable_type='EmployeeDepartment'
      where em.employee_department_id is not null;
    SQL

    update <<-SQL
      update transport_fees tf
      left outer join archived_employees em on em.former_id = tf.receiver_id and receiver_type = 'Employee'
      set tf.groupable_id = em.employee_department_id, tf.groupable_type='EmployeeDepartment'
      where em.employee_department_id is not null;
    SQL
  end

  def self.down
  end
end
