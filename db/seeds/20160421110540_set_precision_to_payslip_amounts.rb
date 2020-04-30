ActiveRecord::Base.transaction do
  schools = School.all(:joins => "INNER JOIN employee_payslips ON employee_payslips.school_id = schools.id", :group => "schools.id")
  log = Logger.new("log/payslip_precision_errors.log")
  log.debug("#{Time.now}")
  schools.each do |school|
    MultiSchool.current_school = school
    if FedenaPlugin.can_access_plugin? "fedena_audit"
      FedenaAudit.disable_audit = true
    end
    payslips = EmployeePayslip.all(:include => [{:employee_payslip_categories => :payroll_category}, :individual_payslip_categories, :finance_transaction, :payslip_additional_leaves])
    payslips.each do |payslip|
      begin
        if payslip.is_approved
          valid = payslip.valid?
          if valid
            if payslip.finance_transaction_id.present?
              transaction = payslip.finance_transaction
              if transaction.nil?
                payslip.save
                canceled_trans = CancelledFinanceTransaction.find_by_finance_transaction_id payslip.finance_transaction_id
                if canceled_trans.present?
                  log.debug("#{payslip.id} - Transaction reverted")
                else
                  log.debug("#{payslip.id} - No finance transaction and no canceled transaction")
                end
              elsif payslip.net_pay.to_f == transaction.amount.to_f
                payslip.save
                transaction.finance = payslip
                transaction.send(:update_without_callbacks)
              else
                log.debug("#{payslip.id} - Amount mismatch - net_pay = #{payslip.net_pay.to_f} finance_transaction_amount #{transaction.amount.to_f}")
                payslip.reload
                total_earnings = payslip.earning_categories.map{|cat| cat.amount}.map(&:to_f).sum
                categories = payslip.individual_payslip_categories.select{|k| !k.marked_for_destruction?}
                total_earnings += categories.select{|i| !i.is_deduction}.inject(0){|res,ele| res + ele.amount.to_f}
                total_deductions = payslip.deduction_categories.map{|cat| cat.amount}.map(&:to_f).sum
                categories = payslip.individual_payslip_categories.select{|k| !k.marked_for_destruction?}
                total_deductions += categories.select{|i| i.is_deduction}.inject(0){|res,ele| res + ele.amount.to_f}
                payslip.attributes = {:total_earnings => total_earnings, :total_deductions => total_deductions}
                payslip.send(:update_without_callbacks)
                transaction.finance = payslip
                transaction.send(:update_without_callbacks)
              end
            else
              log.debug("#{payslip.id} - Finance transaction id is null")
              payslip.save
            end
          else
            log.debug("#{payslip.id} - #{payslip.errors.full_messages}")
          end
        else
          unless payslip.save
            log.debug("#{payslip.id} - #{payslip.errors.full_messages}")
          end
        end
      rescue Exception => e
        log.debug(payslip.id)
        log.debug(e.message)
        next
      end
    end
    if FedenaPlugin.can_access_plugin? "fedena_audit"
      FedenaAudit.disable_audit = nil
    end
  end
  log.debug("#{Time.now}")
end