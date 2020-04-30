module FedenaTransport
  module FinanceTransactionTransportExtension

    def self.included(base)
      base.instance_eval do
        has_one :transport_fee_finance_transaction, :dependent => :destroy
        has_many :transport_transaction_discounts #, :dependent => :destroy

        before_save :set_fine_for_transport, :if => Proc.new { |ft| ft.finance_type=='TransportFee' and ft.fine_included }
        after_create :update_transport_fee_data, :if => Proc.new { |ft| ft.finance_type=='TransportFee' }
        after_destroy :delete_transport_fee_data, :if => Proc.new { |ft| ft.finance_type=='TransportFee' }
        validate :check_amount_exceeds_balance_for_transport_fee , :if => Proc.new { |ft| ft.finance_type=='TransportFee' }
        after_create :build_transport_over_all_receipt_cache, :if => Proc.new {|ft| ft.finance_type == 'TransportFee' and ft.transaction_ledger.transaction_type == "SINGLE"}
      end
    end

    def build_transport_over_all_receipt_cache
      begin
        self.transaction_ledger.generate_overall_receipt_cache
      rescue Exception => e
        puts "Error occurred in making overall receipt cache"
        puts e.inspect
      end
    end

    def transport_student
      student = self.finance.receiver
      student ||= ArchivedStudent.find_by_former_id(self.finance.receiver_id)
      "#{student.full_name}- &#x200E;(#{student.batch.full_name})&#x200E;"
    end

    def transport_student_with_out_batch_name
      student = self.finance.receiver
      student ||= ArchivedStudent.find_by_former_id(self.finance.receiver_id)
      student
    end

    def transport_employee
      employee = self.finance.receiver
      employee ||= ArchivedEmployee.find_by_former_id(self.finance.receiver_id)
      employee
    end

    def get_payment_mode
      case self.payment_mode
      when "Online Payment"
        return 'transaction_id'
      when "Cheque"
        return 'cheque_no'
      when "DD"
        return 'dd_no'
      else
        return 'reference_no'
      end
    end

    def previous_fine_transactions_for_transport
      FinanceTransaction.find(:all,:conditions=>"fine_included=true and finance_type='TransportFee' and finance_id=#{self.finance_id} and id <= #{self.id}")
    end

    def check_balance_fine_for_transport(fine_amount, balance, balance_fine)
      fine = 0.00
      if balance > 0
        fine = fine_amount
      elsif balance_fine.present? && balance < 0
        fine = (balance_fine+balance).abs
      else
        fine = (fine_amount+balance).abs
      end
      return fine
    end
    private

    def check_amount_exceeds_balance_for_transport_fee
      balance=finance.balance
      manual_fine= fine_amount.present? ? fine_amount.to_f : 0
      fee_balance=balance
      actual_amount=FedenaPrecision.set_and_modify_precision(balance).to_f+FedenaPrecision.set_and_modify_precision(finance.finance_transactions.sum(:amount)).to_f-
        FedenaPrecision.set_and_modify_precision(finance.finance_transactions.sum(:fine_amount)).to_f
      date=finance.transport_fee_collection
      days=(transaction_date-date.due_date.to_date).to_i
      auto_fine=date.fine
      fine_amount=0
      if auto_fine.present?
        fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"], :order => 'fine_days ASC')
        fine_amount=fine_rule.is_amount ? fine_rule.fine_amount : (actual_amount*fine_rule.fine_amount)/100 if fine_rule
        fine_amount=FedenaPrecision.set_and_modify_precision(fine_amount).to_f
        paid_fine=finance.finance_transactions.find(:all, :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
        paid_fine=FedenaPrecision.set_and_modify_precision(paid_fine).to_f
        fine_amount=fine_amount-paid_fine
        fine_amount=FedenaPrecision.set_and_modify_precision(fine_amount).to_f
      end
      # actual_balance=FedenaPrecision.set_and_modify_precision(finance.balance+fine_amount).to_f
      actual_balance=FedenaPrecision.set_and_modify_precision(finance.balance).to_f+FedenaPrecision.set_and_modify_precision(fine_amount).to_f
      amount_paying=FedenaPrecision.set_and_modify_precision(amount-manual_fine).to_f
      actual_balance=0 if TransportFee.find(finance.id).is_paid
      if amount_paying.to_f > FedenaPrecision.set_and_modify_precision(actual_balance).to_f
        errors.add_to_base(t('finance.flash19'))
        return false
      end
    end

    def set_fine_for_transport
      self.fine_amount=[self.amount, self.fine_amount].min
    end

    def update_transport_fee_data
 
      transport_fee=self.finance
      discount_amount = 0
      transport_fee.transport_fee_discounts.each{|tfd| discount_amount = discount_amount + (tfd.is_amount ? tfd.discount : (transport_fee.bus_fare*(tfd.discount/100)))}
      balance=FedenaPrecision.set_and_modify_precision(finance.balance).to_f+FedenaPrecision.set_and_modify_precision(fine_amount).to_f-(FedenaPrecision.set_and_modify_precision(amount).to_f)
      manual_fine= fine_amount.present? ? fine_amount.to_f : 0.to_f
         fee_balance=balance.to_f
         actual_amount = FedenaPrecision.set_and_modify_precision(finance.bus_fare).to_f - FedenaPrecision.set_and_modify_precision(discount_amount).to_f
        date=finance.transport_fee_collection
        days=(transaction_date-date.due_date.to_date).to_i
        auto_fine=date.fine
        fine_amount=0.0
        paid_fine = 0.0
        auto_fine_amount = 0.0
        waiver_discount_check = (finance.finance_transactions.count == 0 && transaction_ledger.is_waiver)
        if days > 0 and auto_fine.present? and !finance.is_fine_waiver and !waiver_discount_check
          fine_rule=auto_fine.fine_rules.find(:last, :order => 'fine_days ASC',
            :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"])
          fine_amount=fine_rule.is_amount ? fine_rule.fine_amount :
            (actual_amount*fine_rule.fine_amount)/100 if fine_rule
#          auto_fine_amount=fine_amount.to_f
          paid_fine=finance.finance_transactions.find(:all,
            :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
          if Configuration.is_fine_settings_enabled? && balance <= 0 && finance.balance_fine.present?
            fine_amount = finance.balance_fine
          else
          fine_amount=FedenaPrecision.set_and_modify_precision(fine_amount).to_f-FedenaPrecision.set_and_modify_precision(paid_fine).to_f
#          end
          end
        end
        is_paid=false
        balance=FedenaPrecision.set_and_modify_precision(balance).to_f
        fine_amount= FedenaPrecision.set_and_modify_precision(fine_amount).to_f
        final_fine_amount = self.fine_waiver? ? 0.0 : fine_amount
#-------if balace <= 0 then Auto Fine may or may not be present (balance = transportfee.balance + manual_fine - amount_paid)
        if (balance <= 0)
          fee_balance=0
#---------if -(balance)>0 then the auto_fine is -(balance)-----------------

          if -(balance)>0
            is_paid=(-(balance)==final_fine_amount)
            auto_fine_amount = -(balance)
            manual_fine_copy = manual_fine
            manual_fine += auto_fine_amount
            set_clause ="SET `fine_amount` = '#{manual_fine}',
                                  `auto_fine`='#{auto_fine_amount}',
                                  `fine_included` = 1,
                                  `description` = 'fine_amount_included'"
#------------Updating tax collected----------------------------------------
            if transport_fee.tax_enabled? and transport_fee.tax_amount.present?
              tax_paying = FedenaPrecision.set_and_modify_precision(0.0).to_f
              tax_amount_included = false
              if transport_fee.balance <= transport_fee.tax_amount and transport_fee.balance > 0
#                total_tax_paid = transport_fee.finance_transactions.map(&:tax_amount).sum.to_f
                tax_paying = FedenaPrecision.set_and_modify_precision(amount).to_f - FedenaPrecision.set_and_modify_precision(manual_fine_copy).to_f - FedenaPrecision.set_and_modify_precision(auto_fine_amount).to_f
                tax_amount_included = true
              else
                tax_paying = FedenaPrecision.set_and_modify_precision(transport_fee.tax_amount).to_f
                tax_amount_included = true
              end
              set_clause = "SET `fine_amount` = '#{manual_fine}',
                                `auto_fine`='#{auto_fine_amount}',
                                `fine_included` = 1,
                                `description` = 'fine_amount_included',
                                `tax_amount` = '#{tax_paying}',
                                `tax_included` = #{tax_amount_included}"
              transport_fee.tax_payments.create({
                :taxed_entity_type => "TransportFee",
                :taxed_entity_id => transport_fee.id,
                :tax_amount => tax_paying,
                :finance_transaction_id => self.id
              })
            end

            sql="UPDATE `finance_transactions`
                           #{set_clause}
                      WHERE `id` = #{id}"
            ActiveRecord::Base.connection.execute(sql)
#---------if balance = 0 then no auto_fine amount is present in the transaction---------
          else
            is_paid=(-(balance)==final_fine_amount)
            set_clause = "SET `fine_amount` = '#{manual_fine}'"
#---------if balance = 0 and transport_fee.balance <=  tax_amount then tax_paying = (amount - manual_fine) or tax_paying ------
            if transport_fee.tax_enabled? and transport_fee.tax_amount.present?
              tax_paying = FedenaPrecision.set_and_modify_precision(0.0).to_f
              tax_amount_included = false
              if transport_fee.balance <= transport_fee.tax_amount and transport_fee.balance > 0
#                total_tax_paid = transport_fee.finance_transactions.map(&:tax_amount).sum.to_f
                tax_paying = FedenaPrecision.set_and_modify_precision(amount).to_f - FedenaPrecision.set_and_modify_precision(manual_fine).to_f
                tax_amount_included = true
#                tax_paying = tax_paying - total_tax_paid
              else
                tax_paying = FedenaPrecision.set_and_modify_precision(transport_fee.tax_amount).to_f
                tax_amount_included = true
              end
              set_clause = "SET `fine_amount` = '#{manual_fine}',
                               `tax_amount` = '#{tax_paying}',
                               `tax_included` = #{tax_amount_included}"
              transport_fee.tax_payments.create({
                :taxed_entity_type => "TransportFee",
                :taxed_entity_id => transport_fee.id,
                :tax_amount => tax_paying,
                :finance_transaction_id => self.id
              })
            end
            sql="UPDATE `finance_transactions`
                           #{set_clause}
                      WHERE `id` = #{id}"
            ActiveRecord::Base.connection.execute(sql)
          end
#-------if balance > 0 then the transaction contains only manual_fine if it is present--------
        else
#          fee_balance -= manual_fine
          set_clause = "SET `fine_amount` = '#{manual_fine}'"
#---------if balance > 0 and transport_fee.balance <=  tax_amount then tax_paying = amount------
          if transport_fee.tax_enabled? and transport_fee.tax_amount.present?
            tax_paying = FedenaPrecision.set_and_modify_precision(0.0).to_f
            tax_amount_included = false
            if transport_fee.balance <= transport_fee.tax_amount and transport_fee.balance > 0
              tax_paying = FedenaPrecision.set_and_modify_precision(amount).to_f - FedenaPrecision.set_and_modify_precision(manual_fine).to_f
              tax_amount_included = true
              set_clause = "SET `fine_amount` = '#{manual_fine}',
                               `tax_amount` = '#{tax_paying}',
                               `tax_included` = #{tax_amount_included}"
              transport_fee.tax_payments.create({
                :taxed_entity_type => "TransportFee",
                :taxed_entity_id => transport_fee.id,
                :tax_amount => tax_paying,
                :finance_transaction_id => self.id
              })
            end
          end

          sql="UPDATE `finance_transactions`
                           #{set_clause}
                      WHERE `id` = #{id}"
            ActiveRecord::Base.connection.execute(sql)

        end
        fine_waiver_flag = self.fine_waiver
        track_fine_calculation(finance_type, fine_amount, finance.id, id) if fine_waiver_flag
        balance_fine=check_balance_fine_for_transport(fine_amount,balance,finance.balance_fine)

=begin
        finance_fee_sql="UPDATE `transport_fees`
                                          SET `balance` = '#{fee_balance}',
                                           `is_paid` = #{is_paid}
                                     WHERE `id` = '#{finance.id}'"
=end
      finance_fee_sql="UPDATE `transport_fees`
                                          SET `balance` = '#{fee_balance}',
                                           `balance_fine` = #{balance_fine},
                                            `is_fine_waiver` = #{fine_waiver_flag},
                                           `is_paid` = #{is_paid}
                                     WHERE `id` = '#{finance.id}'"

        ActiveRecord::Base.connection.execute(finance_fee_sql)

#      if transport_fee.tax_enabled?
##        transport_fee=self.finance.reload
#        transactions = FinanceTransaction.all(:conditions =>
#            {:finance_id => transport_fee.id, :finance_type => "TransportFee" })
#        total_paid = transactions.map(&:amount).sum.to_f
#        total_fine_paid = transactions.map(&:fine_amount).sum.to_f
#        #        total_tax_to_collect = transport_fee.tax_collections.map(&:tax_amount).sum.to_f
#        total_tax_to_collect = transport_fee.tax_amount.to_f
#        total_tax_paid = transport_fee.tax_payments.map(&:tax_amount).sum.to_f
#        is_fee_paid = (total_paid - total_fine_paid - total_tax_paid).to_f >= transport_fee.bus_fare.to_f
#        is_tax_paid = transport_fee.tax_amount.to_f <= total_tax_paid
#        if is_fee_paid and !is_tax_paid
#          balance_tax = (total_tax_to_collect - total_tax_paid).to_f
#          transaction_amount_left = (total_paid - transport_fee.bus_fare - total_fine_paid).to_f
#          paying_for_tax = balance_tax - transaction_amount_left > 0 ? transaction_amount_left : balance_tax
#          if paying_for_tax.to_f > 0
#            # record tax payment
#            transport_fee.tax_payments.create({
#                :taxed_entity_type => "TransportFee",
#                :taxed_entity_id => transport_fee.id,
#                :tax_amount => paying_for_tax,
#                :finance_transaction_id => self.id
#              })
#            # update tax amount in finance transaction record
#            self.tax_amount = paying_for_tax
#            self.tax_included = true
#            self.send(:update_without_callbacks)
#          end
#        end
#      end
      create_transport_fee_finance_transaction(:transport_fee_id => transport_fee.id)
      receipt_data # trigger transaction fee cache generation
      build_transaction_discount_data
    end

    def build_transaction_discount_data
      tf = self.finance
      tfds = tf.transport_fee_discounts.all(:conditions => ["ttd.id IS NULL"],
                                           :joins => "LEFT JOIN transport_transaction_discounts ttd
                                                             ON ttd.transport_fee_discount_id = transport_fee_discounts.id")
      bus_fare = tf.bus_fare
      tfds.each do |tfd|
        ttds = self.transport_transaction_discounts.build(:transport_fee_discount_id => tfd.id)
        ttds.discount_amount = (tfd.is_amount ? tfd.discount : (bus_fare * tfd.discount * 0.01))
        ttds.save
      end
      # trigger generation of reporting marker
      TransactionReportSync.create_for_transaction(self)
    end

    def delete_transport_fee_data
      transport_fee=self.finance
      balance_amount=transport_fee.balance.to_f+(self.amount.to_f-self.fine_amount.to_f)
      fine = transport_fee.balance_fine
#      balance_fine= balance_amount > 0 ? nil : fine.present? && fine > 0 ? fine.to_f-self.fine_amount.to_f : self.fine_amount.to_f
      balance_fine = balance_amount >= 0 ? nil : (fine.to_f + self.fine_amount.to_f).abs
      transport_fee.update_attributes(:balance => balance_amount, :is_paid => false, :balance_fine => balance_fine, :is_fine_waiver => false)
      remove_tracked_fine(transport_fee.id, finance_type)
      transport_fee_finance_transaction.destroy
    end
    
    private
      
    def get_precision_count(val)
      precision_count ||= FedenaPrecision.get_precision_count
      return sprintf("%0.#{precision_count}f",val)
    end

  end
end
