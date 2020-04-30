class EmailSubscription < ActiveRecord::Base
  belongs_to :user
  named_scope :updated_at_on, lambda {|date| {:conditions => ['date(email_subscriptions.updated_at) = ?', date]} }

  before_destroy :enable_student_mail

  private

  def enable_student_mail
    if user.student
      user.student_entry.update_attribute(:is_email_enabled, true)
    end
  end
end
