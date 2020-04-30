class PopulateBatchIdInTransactionsForLibrary < ActiveRecord::Migration
  def self.up

    update <<-SQL
      update finance_transactions ft
      inner join students st on st.id=ft.payee_id and ft.payee_type = 'Student'
      set ft.batch_id = ifnull((select batch_id from batch_students bs where bs.student_id=ft.payee_id and ft.created_at < bs.created_at 	order by bs.created_at desc limit 1	), st.batch_id)
      where ft.finance_type = 'BookMovement' and ft.batch_id is null;
    SQL

    update <<-SQL
      update finance_transactions ft
      inner join archived_students st on st.former_id=ft.payee_id and ft.payee_type = 'Student'
      set ft.batch_id=ifnull((select batch_id from batch_students bs where bs.student_id=ft.payee_id and ft.created_at < bs.created_at 	order by bs.created_at desc limit 1	), st.batch_id)
      where ft.finance_type = 'BookMovement' and ft.batch_id is null;
    SQL

  end

  def self.down
  end
end
