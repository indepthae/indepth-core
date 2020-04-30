p = Palette.find_by_name("finance")
if p.present?
  p.palette_queries.destroy_all
end


p.instance_eval do
  user_roles [:admin,:finance_control,:finance_reports] do
    with do
      all(:conditions=>["(fa.id IS NULL OR fa.is_deleted = false) AND transaction_date = ?", :cr_date],
          :joins => "INNER JOIN finance_transaction_receipt_records ftrr
                             ON ftrr.finance_transaction_id = finance_transactions.id
                      LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
          :limit => 1)
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
      all(:conditions=>["((ffc.id IS NOT NULL AND (fa_fc.id IS NULL OR fa_fc.is_deleted = false)) OR
                          (hfc.id IS NOT NULL AND (fa_hfc.id IS NULL OR fa_hfc.is_deleted = false)) OR
                          (tfc.id IS NOT NULL AND (fa_tfc.id IS NULL OR fa_tfc.is_deleted = false))
                          ) AND (? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND
                          events.is_due = 1 AND origin_type <> 'BookMovement'", :cr_date],
          :joins => "LEFT OUTER JOIN finance_fee_collections ffc ON ffc.id = origin_id AND origin_type = 'FinanceFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_fc ON fa_fc.id = ffc.fee_account_id
                     LEFT OUTER JOIN hostel_fee_collections hfc ON hfc.id = origin_id AND origin_type = 'HostelFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_hfc ON fa_hfc.id = hfc.fee_account_id
                     LEFT OUTER JOIN transport_fee_collections tfc ON tfc.id = origin_id AND origin_type = 'TransportFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_tfc ON fa_tfc.id = tfc.fee_account_id",
          :limit => :lim, :offset => :off)
    end
  end
  user_roles [:student] do
    with do
      all(:conditions=>["((ffc.id IS NULL OR (fa_fc.id IS NULL OR fa_fc.is_deleted = false)) AND
                          (hfc.id IS NULL OR (fa_hfc.id IS NULL OR fa_hfc.is_deleted = false)) AND
                          (tfc.id IS NULL OR (fa_tfc.id IS NULL OR fa_tfc.is_deleted = false))) AND
                         events.is_due = 1 AND origin_type <> 'BookMovement' AND
                         (? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND
                         ((id IN (select event_id from batch_events where batch_id = ?)) OR
                         (id IN(select event_id from user_events where user_id = ?)))", :cr_date,
                        later(%Q{Authorization.current_user.student_record.batch_id}),
                        later(%Q{Authorization.current_user.id})],
          :joins => "LEFT OUTER JOIN finance_fee_collections ffc ON ffc.id = origin_id AND origin_type = 'FinanceFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_fc ON fa_fc.id = ffc.fee_account_id
                     LEFT OUTER JOIN hostel_fee_collections hfc ON hfc.id = origin_id AND origin_type = 'HostelFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_hfc ON fa_hfc.id = hfc.fee_account_id
                     LEFT OUTER JOIN transport_fee_collections tfc ON tfc.id = origin_id AND origin_type = 'TransportFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_tfc ON fa_tfc.id = tfc.fee_account_id",
          :limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:parent] do
    with do
      all(:conditions=>["((ffc.id IS NULL OR (fa_fc.id IS NULL OR fa_fc.is_deleted = false)) AND
                          (hfc.id IS NULL OR (fa_hfc.id IS NULL OR fa_hfc.is_deleted = false)) AND
                          (tfc.id IS NULL OR (fa_tfc.id IS NULL OR fa_tfc.is_deleted = false))) AND
                         events.is_due = 1 AND origin_type <> 'BookMovement' AND
                         (? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND
                         ((id IN (select event_id from batch_events where batch_id = ?)) OR
                         (id IN(select event_id from user_events where user_id = ?)))", :cr_date,
                        later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id}),
                        later(%Q{Authorization.current_user.guardian_entry.current_ward.user_id})],
          :joins => "LEFT OUTER JOIN finance_fee_collections ffc ON ffc.id = origin_id AND origin_type = 'FinanceFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_fc ON fa_fc.id = ffc.fee_account_id
                     LEFT OUTER JOIN hostel_fee_collections hfc ON hfc.id = origin_id AND origin_type = 'HostelFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_hfc ON fa_hfc.id = hfc.fee_account_id
                     LEFT OUTER JOIN transport_fee_collections tfc ON tfc.id = origin_id AND origin_type = 'TransportFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_tfc ON fa_tfc.id = tfc.fee_account_id",
          :limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:employee] do
    with do
      all(:conditions=>["((ffc.id IS NULL OR (fa_fc.id IS NULL OR fa_fc.is_deleted = false)) AND
                          (hfc.id IS NULL OR (fa_hfc.id IS NULL OR fa_hfc.is_deleted = false)) AND
                          (tfc.id IS NULL OR (fa_tfc.id IS NULL OR fa_tfc.is_deleted = false))) AND
                         events.is_due = 1 AND origin_type <> 'BookMovement' AND
                         (? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND
                         ((is_common = 1) OR (id IN (select event_id from employee_department_events where employee_department_id = ?)) OR
                         (id IN(select event_id from user_events where user_id = ?)))", :cr_date,
                        later(%Q{Authorization.current_user.employee_record.employee_department_id}),
                        later(%Q{Authorization.current_user.id})],
          :joins => "LEFT OUTER JOIN finance_fee_collections ffc ON ffc.id = origin_id AND origin_type = 'FinanceFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_fc ON fa_fc.id = ffc.fee_account_id
                     LEFT OUTER JOIN hostel_fee_collections hfc ON hfc.id = origin_id AND origin_type = 'HostelFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_hfc ON fa_hfc.id = hfc.fee_account_id
                     LEFT OUTER JOIN transport_fee_collections tfc ON tfc.id = origin_id AND origin_type = 'TransportFeeCollection'
                     LEFT OUTER JOIN fee_accounts fa_tfc ON fa_tfc.id = tfc.fee_account_id",
          :limit=>:lim,:offset=>:off)
    end
  end
end

q.save

q = Palette.find_by_name("events")
if q.present?
  q.palette_queries.destroy_all
end

q.instance_eval do
  user_roles [:admin,:event_management] do
    with do
      all(:select=>"events.*,exam_groups.is_published",
          :joins=>"LEFT OUTER JOIN exams on exams.id = events.origin_id AND events.origin_type='Exam'
                   LEFT OUTER JOIN exam_groups on exam_groups.id = exams.exam_group_id
                   LEFT OUTER JOIN finance_fee_collections ffc ON ffc.id = origin_id AND origin_type = 'FinanceFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_fc ON fa_fc.id = ffc.fee_account_id
                   LEFT OUTER JOIN hostel_fee_collections hfc ON hfc.id = origin_id AND origin_type = 'HostelFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_hfc ON fa_hfc.id = hfc.fee_account_id
                   LEFT OUTER JOIN transport_fee_collections tfc ON tfc.id = origin_id AND origin_type = 'TransportFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_tfc ON fa_tfc.id = tfc.fee_account_id",
          :group=>"events.id having exam_groups.is_published=1 or exam_groups.is_published is NULL",
          :conditions=>["((ffc.id IS NULL OR (fa_fc.id IS NULL OR fa_fc.is_deleted = false)) AND
                          (hfc.id IS NULL OR (fa_hfc.id IS NULL OR fa_hfc.is_deleted = false)) AND
                          (tfc.id IS NULL OR (fa_tfc.id IS NULL OR fa_tfc.is_deleted = false))) AND
                         ? BETWEEN DATE(events.start_date) AND DATE(events.end_date)", :cr_date],
          :limit => :lim, :offset => :off)
    end
  end
  user_roles [:student] do
    with do
      all(:select=>"events.*,exam_groups.is_published",
          :joins=>"LEFT OUTER JOIN exams on exams.id = events.origin_id AND events.origin_type='Exam'
                   LEFT OUTER JOIN exam_groups on exam_groups.id = exams.exam_group_id
                   LEFT OUTER JOIN finance_fee_collections ffc ON ffc.id = origin_id AND origin_type = 'FinanceFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_fc ON fa_fc.id = ffc.fee_account_id
                   LEFT OUTER JOIN hostel_fee_collections hfc ON hfc.id = origin_id AND origin_type = 'HostelFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_hfc ON fa_hfc.id = hfc.fee_account_id
                   LEFT OUTER JOIN transport_fee_collections tfc ON tfc.id = origin_id AND origin_type = 'TransportFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_tfc ON fa_tfc.id = tfc.fee_account_id",
          :group=>"events.id having exam_groups.is_published=1 or exam_groups.is_published is NULL",
          :conditions=>["((ffc.id IS NULL OR (fa_fc.id IS NULL OR fa_fc.is_deleted = false)) AND
                          (hfc.id IS NULL OR (fa_hfc.id IS NULL OR fa_hfc.is_deleted = false)) AND
                          (tfc.id IS NULL OR (fa_tfc.id IS NULL OR fa_tfc.is_deleted = false))) AND
                         (? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND
                         ((events.is_common = 1) OR (events.id IN (select event_id from batch_events where batch_id = ?)) OR
                         (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,
                        later(%Q{Authorization.current_user.student_record.batch_id}),
                        later(%Q{Authorization.current_user.id})],
          :limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:parent] do
    with do
      all(:select=>"events.*,exam_groups.is_published",
          :joins=>"LEFT OUTER JOIN exams on exams.id = events.origin_id AND events.origin_type='Exam'
                   LEFT OUTER JOIN exam_groups on exam_groups.id = exams.exam_group_id
                   LEFT OUTER JOIN finance_fee_collections ffc ON ffc.id = origin_id AND origin_type = 'FinanceFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_fc ON fa_fc.id = ffc.fee_account_id
                   LEFT OUTER JOIN hostel_fee_collections hfc ON hfc.id = origin_id AND origin_type = 'HostelFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_hfc ON fa_hfc.id = hfc.fee_account_id
                   LEFT OUTER JOIN transport_fee_collections tfc ON tfc.id = origin_id AND origin_type = 'TransportFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_tfc ON fa_tfc.id = tfc.fee_account_id",
          :group=>"events.id having exam_groups.is_published=1 or exam_groups.is_published is NULL",
          :conditions=>["((ffc.id IS NULL OR (fa_fc.id IS NULL OR fa_fc.is_deleted = false)) AND
                          (hfc.id IS NULL OR (fa_hfc.id IS NULL OR fa_hfc.is_deleted = false)) AND
                          (tfc.id IS NULL OR (fa_tfc.id IS NULL OR fa_tfc.is_deleted = false))) AND
                         (? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND ((events.is_common = 1) OR
                         (events.id IN (select event_id from batch_events where batch_id = ?)) OR
                         (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,
                        later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id}),
                        later(%Q{Authorization.current_user.guardian_entry.current_ward.user_id})],
          :limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:employee] do
    with do
      all(:select=>"events.*,exam_groups.is_published",
          :joins=>"LEFT OUTER JOIN exams on exams.id = events.origin_id AND events.origin_type='Exam'
                   LEFT OUTER JOIN exam_groups on exam_groups.id = exams.exam_group_id
                   LEFT OUTER JOIN finance_fee_collections ffc ON ffc.id = origin_id AND origin_type = 'FinanceFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_fc ON fa_fc.id = ffc.fee_account_id
                   LEFT OUTER JOIN hostel_fee_collections hfc ON hfc.id = origin_id AND origin_type = 'HostelFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_hfc ON fa_hfc.id = hfc.fee_account_id
                   LEFT OUTER JOIN transport_fee_collections tfc ON tfc.id = origin_id AND origin_type = 'TransportFeeCollection'
                   LEFT OUTER JOIN fee_accounts fa_tfc ON fa_tfc.id = tfc.fee_account_id",
          :group=>"events.id having exam_groups.is_published=1 or exam_groups.is_published is NULL",
          :conditions=>["((ffc.id IS NULL OR (fa_fc.id IS NULL OR fa_fc.is_deleted = false)) AND
                          (hfc.id IS NULL OR (fa_hfc.id IS NULL OR fa_hfc.is_deleted = false)) AND
                          (tfc.id IS NULL OR (fa_tfc.id IS NULL OR fa_tfc.is_deleted = false))) AND
                         (? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND ((events.is_common = 1) OR
                         (events.id IN (select event_id from employee_department_events where employee_department_id = ?)) OR
                         (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,
                        later(%Q{Authorization.current_user.employee_record.employee_department_id}),
                        later(%Q{Authorization.current_user.id})],
          :limit=>:lim,:offset=>:off)
    end
  end
end

q.save