p = Palette.find_by_name("finance")
if p.present?
  p.palette_queries.destroy_all
end


p.instance_eval do
  user_roles [:admin,:finance_control,:finance_reports] do
    with do
      all(:conditions=>["transaction_date = ?",:cr_date],:limit=>1)
    end
  end
end

p.save

q = Palette.find_by_name("fees_due")
if q.present?
  q.palette_queries.destroy_all
end


q.instance_eval do
  user_roles [:admin,:finance_control,:fee_submission,:finance_reports,:revert_transaction] do
    with do
      all(:conditions=>["(? BETWEEN DATE(start_date) AND DATE(end_date)) AND is_due = 1 AND origin_type <> 'BookMovement'", :cr_date],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:student] do
    with do
      all(:conditions=>["is_due = 1 AND origin_type <> 'BookMovement' AND (? BETWEEN DATE(start_date) AND DATE(end_date)) AND ((id IN (select event_id from batch_events where batch_id = ?)) OR (id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.student_record.batch_id}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:parent] do
    with do
      all(:conditions=>["is_due = 1 AND origin_type <> 'BookMovement' AND (? BETWEEN DATE(start_date) AND DATE(end_date)) AND ((id IN (select event_id from batch_events where batch_id = ?)) OR (id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id}),later(%Q{Authorization.current_user.guardian_entry.current_ward.user_id})],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:employee] do
    with do
      all(:conditions=>["is_due = 1 AND origin_type <> 'BookMovement' AND (? BETWEEN DATE(start_date) AND DATE(end_date)) AND ((is_common = 1) OR (id IN (select event_id from employee_department_events where employee_department_id = ?)) OR (id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.employee_record.employee_department_id}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
    end
  end
end

q.save