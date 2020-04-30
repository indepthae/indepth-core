privilege_tag=PrivilegeTag.create(:name_tag => 'finance_control', :priority => 6)
Privilege.create :name => 'Miscellaneous', :description => 'miscellaneous_privilege', :privilege_tag_id => privilege_tag.id, :priority => 407
Privilege.create :name => 'FinanceReports', :description => 'finance_reports_privilege', :privilege_tag_id => privilege_tag.id, :priority => 404
Privilege.create :name => 'ApproveRejectPayslip', :description => 'approve_reject_payslip_privilege', :privilege_tag_id => privilege_tag.id, :priority => 405
Privilege.create :name => 'FeeSubmission', :description => 'fee_submission_privilege', :privilege_tag_id => privilege_tag.id, :priority => 402
Privilege.create :name => 'ManageFee', :description => 'manage_fee_privilege', :privilege_tag_id => privilege_tag.id, :priority => 401
Privilege.create :name => 'RevertTransaction', :description => 'revert_transaction_privilege', :privilege_tag_id => privilege_tag.id, :priority => 406
Privilege.create :name => 'ManageRefunds', :description => 'manage_refunds_privilege', :privilege_tag_id => privilege_tag.id, :priority => 403
# Privilege.create :name => 'PayrollManagement' , :description => 'payroll_management_privilege', :privilege_tag_id=>privilege_tag.id,:priority=>408
fc=Privilege.find_by_name('FinanceControl')
fc.update_attributes(:privilege_tag_id => privilege_tag.id) if fc.present?

administration_cat = MenuLinkCategory.find_by_name("administration")
unless administration_cat.nil?
  a = administration_cat.allowed_roles
  a.push([ :manage_fee,:manage_refunds, :fee_submission, :approve_reject_payslip, :finance_reports, :revert_transaction, :miscellaneous, :payroll_management])
  a.flatten!
  administration_cat.allowed_roles = a.uniq
  administration_cat.save

end


data_and_reports_cat = MenuLinkCategory.find_by_name("data_and_reports")
unless data_and_reports_cat.nil?
  b = data_and_reports_cat.allowed_roles
  b.push([ :finance_reports,:finance_control])
  b.flatten!
  data_and_reports_cat.allowed_roles = b.uniq
  data_and_reports_cat.save

end