class MailRecipientList < ActiveRecord::Base

  belongs_to :mail_message

  serialize :recipient_ids, Array

  validates_presence_of :recipient_type
  validates_presence_of :recipient_ids,
                        :if => lambda {|rec| ['student', 'guardian', 'employee'].include? rec.recipient_type}
  validates_inclusion_of :recipient_type,
                         :in => %w( student guardian employee all_users 
                            all_students all_guardians all_employees )

  def recipients
    @recipients ||=
      if recipient_type == "employee"
        Employee.find_all_by_id(recipient_ids)
      elsif recipient_type == "student" || recipient_type == "guardian"
        Student.find_all_by_id(recipient_ids)
      else
        []
      end
  end

end
