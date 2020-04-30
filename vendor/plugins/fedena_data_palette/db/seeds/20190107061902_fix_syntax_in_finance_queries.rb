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
                         ((events.id IN (select event_id from batch_events where batch_id = ?)) OR
                         (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,
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
                         ((events.id IN (select event_id from batch_events where batch_id = ?)) OR
                         (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,
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
                         ((is_common = 1) OR (events.id IN (select event_id from employee_department_events where employee_department_id = ?)) OR
                         (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,
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