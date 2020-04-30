
authorization do
  role :custom_report_control do
    has_permission_on [:custom_reports],:to=>[:generate,:show,:index,:delete,:select_school,:to_csv,:dashboard]
  end
  role :custom_report_view do
    has_permission_on [:custom_reports],:to=>[:show,:index,:to_csv]
  end
  role :admin do
    includes :custom_report_control
  end
 
end
