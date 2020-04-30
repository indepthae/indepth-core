class MultiFeesTransaction < ActiveRecord::Base
  belongs_to :student
  has_and_belongs_to_many :finance_transactions, :join_table => "multi_fees_transactions_finance_transactions"
  attr_accessor :cancel_reason

  before_destroy :delete_finance_transactions


  def send_sms
    recipients = []
    payee=student
    payee_name=payee.full_name
    sms_setting = SmsSetting.new()
    if sms_setting.application_sms_active and sms_setting.fee_submission_sms_active and payee.present?
      if payee.is_a? Student and payee.is_sms_enabled
        if sms_setting.parent_sms_active
          guardian = payee.immediate_contact if payee.immediate_contact.present?
          recipients.push guardian.mobile_phone if (guardian.present? and guardian.mobile_phone.present?)
        end
        recipients.push payee.phone2 if (sms_setting.student_sms_active and payee.phone2.present?)
      end
      message = "#{t('multi_fee_sms_message_body', :payee_name => payee_name, :currency_name => Configuration.currency, :amount => FedenaPrecision.set_and_modify_precision(amount.to_f), :collection_name => finance_transactions.collect(&:finance_name).join(','), :payment_date => format_date(transaction_date))}"
      Delayed::Job.enqueue(SmsManager.new(message, recipients),{:queue => 'sms'}) if recipients.present?
    end
  end

  private
  def delete_finance_transactions
    finance_transactions.each do |ft|
      ft.cancel_reason = self.cancel_reason
      ft.destroy
    end
  end
end
