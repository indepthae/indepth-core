finance_report_menu = MenuLink.last(:conditions => ["target_action = ? and target_controller = ?",
                                                    'finance_reports', 'finance'])
if finance_report_menu.present?
  finance_report_menu.name = "finance_reports.finance_reports_text"
  finance_report_menu.target_controller = "finance_reports"
  finance_report_menu.target_action = "index"
  finance_report_menu.save
end