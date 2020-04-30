authorization do

  role :admin do
    has_permission_on [:tally_exports],
      :to => [
      :index,
      :settings,
      :general_settings,
      :companies,
      :set_tally_company_company_name,
      :delete_company,
      :voucher_types,
      :set_tally_voucher_type_voucher_name,
      :delete_voucher,
      :accounts,
      :set_tally_account_account_name,
      :delete_account,
      :ledgers,
      :view_ledgers,
      :create_ledger,
      :edit_ledger,
      :delete_ledger,
      :manual_sync,
      :bulk_export,
      :schedule,
      :downloads,
      :download,
      :failed_syncs
    ]
  end

  role :miscellaneous do
    has_permission_on [:tally_exports],
      :to => [
      :index,
      :settings,
      :general_settings,
      :companies,
      :set_tally_company_company_name,
      :delete_company,
      :voucher_types,
      :set_tally_voucher_type_voucher_name,
      :delete_voucher,
      :accounts,
      :set_tally_account_account_name,
      :delete_account,
      :ledgers,
      :view_ledgers,
      :create_ledger,
      :edit_ledger,
      :delete_ledger,
      :manual_sync,
      :bulk_export,
      :schedule,
      :downloads,
      :download,
      :failed_syncs
    ]
  end

  role :employee do

  end

end