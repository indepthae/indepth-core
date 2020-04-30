schools = School.all
schools.each do |school|
  MultiSchool.current_school = school
  attachments = MessageAttachment.all(:conditions => ['message_id is NOT NULL'])
  attachments.each do  |attachment|
    message = Message.find_by_id attachment.message_id
    message.build_message_attachments_assoc(:message_attachment_id => attachment.id).save if message
  end
end