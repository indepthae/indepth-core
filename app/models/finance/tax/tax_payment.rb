class TaxPayment < ActiveRecord::Base
  # records tax collected during a transaction
  belongs_to :taxed_entity, :polymorphic => true
  belongs_to :taxed_fee, :polymorphic => true
  belongs_to :finance_transaction
  
  def self.finance_fee_tax_payments(start_date, end_date)
    TaxPayment.all(:conditions => ["transaction_date 
            BETWEEN '#{start_date}' AND '#{end_date}' AND finance_type = 'FinanceFee' AND
            (ftrr.fee_account_id IS NULL OR fa.is_deleted = false)"],
        :select => "DISTINCT tax_payments.id as tax_payment_id, 
                           tax_payments.tax_amount AS tax_amount, ts.name AS slab_name, 
                           ts.rate AS slab_rate,ts.id AS slab_id, ffc.id AS collection_id, 
                           ffc.name AS collection_name, fts.transaction_date as transaction_date",
        :joins => "INNER JOIN finance_transactions fts ON fts.id = tax_payments.finance_transaction_id
                   INNER JOIN finance_transaction_receipt_records ftrr
                              FORCE INDEX (index_by_transaction_and_receipt)
                           ON ftrr.finance_transaction_id = fts.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                   INNER JOIN finance_fee_particulars ffp
                           ON ffp.id=tax_payments.taxed_entity_id AND tax_payments.taxed_entity_type='FinanceFeeParticular'
                   INNER JOIN finance_fees ff
                           ON ff.id = tax_payments.taxed_fee_id AND tax_payments.taxed_fee_type = 'FinanceFee'
                   INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
                   INNER JOIN collectible_tax_slabs cts
                           ON cts.collection_id = ffc.id AND
                              cts.collection_type = 'FinanceFeeCollection' AND
                              cts.collectible_entity_type = 'FinanceFeeParticular' AND
                              cts.collectible_entity_id = ffp.id
                   INNER JOIN tax_slabs ts ON ts.id = cts.tax_slab_id")
  end
end
