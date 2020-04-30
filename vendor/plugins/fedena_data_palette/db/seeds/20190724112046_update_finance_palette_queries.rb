p = Palette.find_by_name("finance")
if p.present?
  p.palette_queries.destroy_all
end


p.instance_eval do
  user_roles [:admin,:finance_control,:finance_reports] do
    with do
      all(:conditions=>["(fa.id IS NULL OR fa.is_deleted = false) AND transaction_date = ?", :cr_date],
          :joins => "LEFT JOIN finance_transaction_receipt_records ftrr
                             ON ftrr.finance_transaction_id = finance_transactions.id
                      LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
          :limit => 1)
    end
  end
end

p.save
