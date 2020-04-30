
sql="UPDATE finance_fees JOIN students st ON st.id = finance_fees.student_id SET finance_fees.student_category_id = st.student_category_id"
ActiveRecord::Base.connection.execute(sql)