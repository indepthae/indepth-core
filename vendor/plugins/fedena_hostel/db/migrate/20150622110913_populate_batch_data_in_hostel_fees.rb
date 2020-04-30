class PopulateBatchDataInHostelFees < ActiveRecord::Migration
  def self.up
    update <<-SQL
            update hostel_fees tf
            inner join hostel_fee_collections tfc on tfc.id=tf.hostel_fee_collection_id
            left outer join students st on st.id=tf.student_id
            set tf.batch_id=tfc.batch_id
            where st.batch_id is not null and st.batch_id = ifnull(tfc.batch_id,0);
    SQL

    update <<-SQL
            update hostel_fees tf
            inner join hostel_fee_collections tfc on tfc.id=tf.hostel_fee_collection_id
            left outer join archived_students st on st.former_id=tf.student_id
            set tf.batch_id = tfc.batch_id
            where st.batch_id is not null and st.batch_id = ifnull(tfc.batch_id,0);
    SQL

    update <<-SQL
            update hostel_fees tf
            left outer join hostel_fee_collections tfc on tfc.id=tf.hostel_fee_collection_id
            left outer join students st on st.id=tf.student_id
            set tf.batch_id=ifnull((select batch_id from batch_students bs where bs.student_id=tf.student_id and tf.created_at < bs.created_at order by bs.created_at desc limit 1	),st.batch_id)
            where st.batch_id is not null and st.batch_id <> ifnull(tfc.batch_id,0);
    SQL

    update <<-SQL
            update hostel_fees tf
            left outer join hostel_fee_collections tfc on tfc.id=tf.hostel_fee_collection_id
            left outer join archived_students st on st.former_id=tf.student_id
            set tf.batch_id=ifnull((select batch_id from batch_students bs where bs.student_id=tf.student_id and tf.created_at < bs.created_at order by bs.created_at desc limit 1	),st.batch_id)
            where st.batch_id is not null and st.batch_id <> ifnull(tfc.batch_id,0);
    SQL
  end

  def self.down
  end
end
