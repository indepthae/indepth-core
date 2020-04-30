require 'dispatcher'
# FedenaInstantFee
module FedenaInstantFee
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_instant_fee do
      ::Student.instance_eval { has_many :instant_fees, :as => 'payee' }
      ::ArchivedStudent.instance_eval { has_many :instant_fees, :primary_key => 'former_id',:foreign_key => 'payee_id', :conditions => "instant_fees.payee_type = 'Student'"}
      ::Employee.instance_eval { has_many :instant_fees, :as => 'payee' }
      ::Student.instance_eval { include StudentExtension }
      ::ArchivedStudent.instance_eval { include StudentExtension }
      ::TaxSlab.instance_eval { include TaxSlabExtension }
      ::TaxPayment.instance_eval { include TaxPaymentExtension }
      ::FinancialYear.instance_eval { include FinancialYearExtension }
    end
  end

  def self.student_profile_fees_by_batch_hook
    "instant_fees/student_profile_fees"
  end

  def self.student_profile_fees_hook
    "transport_fee/student_profile_fees"
  end
end

module FinancialYearExtension
  def self.included(base)
    base.instance_eval do
      has_many :instant_fee_categories
      has_many :instant_fees
    end
  end
end

module StudentExtension
  def find_instance_fees_by_batch(batch_id)
    # self.instant_fees.find_all_by_groupable_id(batch_id)
    # workaround for backward compatiability
    self.instant_fees.all(:select => "instant_fees.*, transaction_date",
      :conditions => ["groupable_id = ? AND groupable_type = ? AND (fa.id IS NULL OR fa.is_deleted = false)",
        batch_id, 'Batch'],
      :joins => "INNER JOIN finance_transactions ON finance_transactions.finance_id = instant_fees.id AND
                                                        finance_transactions.finance_type = 'InstantFee'
                      INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                       LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id")
  end
end

module TaxSlabExtension
  def self.included(base)
    base.instance_eval do 
      has_many :instant_fee_particulars, :through => :tax_assignments, :source => :taxable, 
        :source_type => 'InstantFeeParticular'
      
      has_many :tax_assignments, :dependent => :destroy
      has_many :finance_fee_particulars, :through => :tax_assignments, :source => :taxable, 
        :source_type => 'FinanceFeeParticular'
    end
  end
end

module TaxPaymentExtension
  def self.included(base)
    base.class_eval do
      def self.instant_fee_tax_payments(start_date, end_date)
        conds = ["transaction_date 
            BETWEEN '#{start_date}' AND '#{end_date}' AND finance_type = 'InstantFee' AND
            (ftrr.fee_account_id IS NULL OR fa.is_deleted = false)"]
        selects = "DISTINCT tax_payments.id as tax_payment_id, 
                             tax_payments.tax_amount AS tax_amount, ts.name AS slab_name, 
                             ts.rate AS slab_rate, ts.id AS slab_id, i_f.id AS collection_id, 
                             'Instant Fee' AS collection_name, fts.transaction_date as transaction_date"
        common_joins = "INNER JOIN finance_transactions fts ON fts.id = tax_payments.finance_transaction_id
                        INNER JOIN finance_transaction_receipt_records ftrr
                                   FORCE INDEX (index_by_transaction_and_receipt)
                                ON ftrr.finance_transaction_id = fts.id
                         LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                        INNER JOIN instant_fees i_f
                                ON i_f.id = tax_payments.taxed_fee_id AND tax_payments.taxed_fee_type = 'InstantFee'
                        INNER JOIN collectible_tax_slabs cts
                                ON cts.collection_id = i_f.id AND cts.collection_type = 'InstantFee'
                        INNER JOIN tax_slabs ts ON ts.id = cts.tax_slab_id"
        ifp_joins = "INNER JOIN instant_fee_particulars ifp 
                             ON ifp.id=tax_payments.taxed_entity_id AND
                                tax_payments.taxed_entity_type='InstantFeeParticular' AND
                                cts.collectible_entity_id = ifp.id AND
                                cts.collectible_entity_type = 'InstantFeeParticular'"
        ifd_joins = "INNER JOIN instant_fee_details ifd 
                             ON ifd.id=tax_payments.taxed_entity_id AND
                                tax_payments.taxed_entity_type='InstantFeeDetail' AND
                                cts.collectible_entity_id = ifd.id AND
                                cts.collectible_entity_type = 'InstantFeeDetail'"
        TaxPayment.all(:conditions => conds, :select => "#{selects}", :joins => "#{common_joins} #{ifp_joins}") +
          TaxPayment.all(:conditions => conds, :select => "#{selects}", :joins => "#{common_joins} #{ifd_joins}")
      end
    end
  end
end
