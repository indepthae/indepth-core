# To change this template, choose Tools | Templates
# and open the template in the editor.

module PayrollGroupsHelper
  def payment_period_text(key)
    payment_period = PayrollGroup::PAYMENT_PERIOD
    case key
    when 1,2,5
      return t(payment_period[key])
    when 3
      return "#{t(payment_period[key])} - #{t('once_in_two_weeks')}"
    when 4
      return "#{t(payment_period[key])} - #{t('once_in_fifteen_days')}"
    end
  end
end