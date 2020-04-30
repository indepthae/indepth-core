privilege_tag=PrivilegeTag.find_by_name_tag("finance_control")
Privilege.find_or_create_by_name :name => "FeesSubmissionWithoutDiscount", :description => "fees_submission_without_discount", :privilege_tag_id => privilege_tag.id, :priority => 812
