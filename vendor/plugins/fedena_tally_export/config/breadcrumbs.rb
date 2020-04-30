Gretel::Crumbs.layout do

  crumb :tally_exports_index do
    link I18n.t('tally_exports.tally_export_text'), {:controller=>"tally_exports",:action=>"index"}
    parent :finance_index
  end

  crumb :tally_exports_settings do
    link I18n.t('tally_exports.settings_text'), {:controller=>"tally_exports",:action=>"settings"}
    parent :tally_exports_index
  end

  crumb :tally_exports_general_settings do
    link I18n.t('tally_exports.general_settings_text'), {:controller=>"tally_exports",:action=>"general_settings"}
    parent :tally_exports_settings
  end

  crumb :tally_exports_companies do
    link I18n.t('tally_exports.companies'), {:controller=>"tally_exports",:action=>"companies"}
    parent :tally_exports_settings
  end

  crumb :tally_exports_voucher_types do
    link I18n.t('tally_exports.vouchers'), {:controller=>"tally_exports",:action=>"voucher_types"}
    parent :tally_exports_settings
  end

  crumb :tally_exports_accounts do
    link I18n.t('tally_exports.accounts_text'), {:controller=>"tally_exports",:action=>"accounts_text"}
    parent :tally_exports_settings
  end

  crumb :tally_exports_ledgers do
    link I18n.t('tally_exports.manage_ledgers'), {:controller=>"tally_exports",:action=>"ledgers"}
    parent :tally_exports_settings
  end

  crumb :tally_exports_create_ledger do
    link I18n.t('tally_exports.create_ledgers'), {:controller=>"tally_exports",:action=>"create_ledger"}
    parent :tally_exports_ledgers
  end

   crumb :tally_exports_view_ledgers do
    link I18n.t('tally_exports.view_ledgers'), {:controller=>"tally_exports",:action=>"view_ledgers"}
    parent :tally_exports_ledgers
  end

  crumb :tally_exports_manual_sync do
    link I18n.t('tally_exports.manual_sync_text'), {:controller=>"tally_exports",:action=>"manual_sync"}
    parent :tally_exports_index
  end

  crumb :tally_exports_bulk_export do
    link I18n.t('tally_exports.bulk_export_text'), {:controller=>"tally_exports",:action=>"bulk_export"}
    parent :tally_exports_index
  end

  crumb :tally_exports_schedule do
    link I18n.t('tally_exports.schedule_export'), {:controller=>"tally_exports",:action=>"schedule"}
    parent :tally_exports_bulk_export
  end

  crumb :tally_exports_downloads do
    link I18n.t('tally_exports.download_exports'), {:controller=>"tally_exports",:action=>"downloads"}
    parent :tally_exports_bulk_export
  end

  crumb :tally_exports_failed_syncs do
    link I18n.t('tally_exports.failed_syncs'), {:controller=>"tally_exports",:action=>"failed_syncs"}
    parent :tally_exports_index
  end

  crumb :tally_exports_edit_ledger do |ledger|
    link I18n.t('tally_exports.edit_ledger'), {:controller=>"tally_exports",:action=>"failed_syncs",:id=>ledger.id}
    parent :tally_exports_view_ledgers
  end

  crumb :tally_exports_manual_sync_schedule_jobs do
    link I18n.t('tally_exports.schedule_jobs'), {:controller=>"scheduled_jobs",:action=>"index"}
    parent :tally_exports_manual_sync
  end

  crumb :tally_exports_schedule_schedule_jobs do
    link I18n.t('tally_exports.schedule_jobs'), {:controller=>"scheduled_jobs",:action=>"index"}
    parent :tally_exports_schedule
  end
end