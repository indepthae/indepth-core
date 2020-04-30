message_template = MessageTemplate.find_all_by_template_name_and_template_type_and_automated_template_name("Sibling Addition", "AUTOMATED", "set_emergency_contact")
if message_template.present?
  message_template_contents = message_template.first.message_template_contents
  if message_template_contents.present?
    message_template_contents.first.update_attributes(:user_type => "Guardian")
  end
end

 
