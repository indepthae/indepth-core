module FedenaHostel
  module FinanceTransactionExtension

    def self.included(base)
      base.instance_eval do
        has_one :hostel_fee_finance_transaction, :dependent => :destroy
        before_save :set_fine_for_hostel, :if => Proc.new { |ft| ft.finance_type=='HostelFee' and ft.fine_included }
        after_create :update_hostel_fee_data, :if => Proc.new { |ft| ft.finance_type=='HostelFee' }
        after_destroy :delete_hostel_fee_data, :if => Proc.new { |ft| ft.finance_type=='HostelFee' }
        validate :check_amount_exceeds_balance_for_hostel_fee, :if => Proc.new { |ft| ft.finance_type=='HostelFee' }
        after_create :build_hostel_over_all_receipt_cache, :if => Proc.new {|ft| ft.finance_type == 'HostelFee' and ft.transaction_ledger.transaction_type == "SINGLE"}
      end
    end

    def build_hostel_over_all_receipt_cache
      begin
        self.transaction_ledger.generate_overall_receipt_cache
      rescue Exception => e
        puts "Error occurred in making overall receipt cache"
        puts e.inspect
      end
    end

    def hosteller
      fee = self.finance
      student = fee.student
      student ||= ArchivedStudent.find_by_former_id(fee.student_id)
      student
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

    def previous_fine_transactions_for_hostel
      FinanceTransaction.find(:all,:conditions=>"fine_included=true and finance_type='HostelFee' and finance_id=#{self.finance_id} and id <= #{self.id}")
    end

    private


    def check_amount_exceeds_balance_for_hostel_fee
      amount_paid = FedenaPrecision.set_and_modify_precision(self.amount.to_f-self.fine_amount.to_f).to_f
      amount_to_pay = FedenaPrecision.set_and_modify_precision(finance.balance.to_f).to_f
      if amount_paid > amount_to_pay
#      if (self.amount.to_f-self.fine_amount.to_f) > finance.balance.to_f
        self.errors.add_to_base(t('finance.flash19'))
      end
    end

    def set_fine_for_hostel
      self.fine_amount=[self.amount, self.fine_amount].min
    end

    def update_hostel_fee_data
      hostel_fee=self.finance
      paying_fee = (self.amount.to_f-self.fine_amount.to_f)
#      balance_amount=hostel_fee.balance.to_f-paying_fee
      balance_amount = FedenaPrecision.set_and_modify_precision(hostel_fee.balance.to_f).to_f - paying_fee            
#      balance_amount=hostel_fee.balance.to_f-(self.amount.to_f-self.fine_amount.to_f)
      hostel_fee.update_attributes(:balance => balance_amount)
      if hostel_fee.tax_enabled?        
#        transport_fee=self.finance.reload
        transactions = FinanceTransaction.all(:conditions => 
            {:finance_id => hostel_fee.id, :finance_type => "HostelFee" })
        total_paid = transactions.map(&:amount).sum.to_f
        total_fine_paid = transactions.map(&:fine_amount).sum.to_f
        #        total_tax_to_collect = transport_fee.tax_collections.map(&:tax_amount).sum.to_f
        total_tax_to_collect = hostel_fee.tax_amount.to_f
        total_tax_paid = hostel_fee.tax_payments.map(&:tax_amount).sum.to_f
        is_fee_paid = (total_paid - total_fine_paid - total_tax_paid).to_f >= hostel_fee.rent.to_f
        is_tax_paid = hostel_fee.tax_amount.to_f <= total_tax_paid
        if is_fee_paid and !is_tax_paid
          balance_tax = (total_tax_to_collect - total_tax_paid).to_f     
          transaction_amount_left = (total_paid - hostel_fee.rent - total_fine_paid).to_f
          paying_for_tax = balance_tax - transaction_amount_left > 0 ? transaction_amount_left : balance_tax
          if paying_for_tax.to_f > 0
            # record tax payment
            hostel_fee.tax_payments.create({
                :taxed_entity_type => "HostelFee",
                :taxed_entity_id => hostel_fee.id,
                :tax_amount => paying_for_tax,
                :finance_transaction_id => self.id
              })
            # update tax amount in finance transaction record
            self.tax_amount = paying_for_tax 
            self.tax_included = true
            self.send(:update_without_callbacks)            
          end
        end
      end
      create_hostel_fee_finance_transaction(:hostel_fee_id => hostel_fee.id)
      receipt_data # trigger transaction fee cache generation
    end

    def delete_hostel_fee_data
      hostel_fee=self.finance
      balance_amount=hostel_fee.balance.to_f+(self.amount.to_f-self.fine_amount.to_f)
      hostel_fee.update_attributes(:balance => balance_amount)
      hostel_fee_finance_transaction.destroy
    end
  end
end