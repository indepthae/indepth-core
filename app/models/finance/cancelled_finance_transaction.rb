class CancelledFinanceTransaction < ActiveRecord::Base
  belongs_to :category, :class_name => 'FinanceTransactionCategory', :foreign_key => 'category_id'
  belongs_to :student ,:primary_key => 'payee_id'
  belongs_to :employee ,:primary_key => 'payee_id'
  belongs_to :instant_fee,:foreign_key=>'finance_id',:conditions=>'payee_id is NULL'
  belongs_to :finance, :polymorphic => true
  belongs_to :payee, :polymorphic => true
  belongs_to :master_transaction,:class_name => "FinanceTransaction"
  belongs_to :transaction_ledger, :class_name => "FinanceTransactionLedger", :foreign_key => 'transaction_ledger_id'
  belongs_to :user
  has_one :transaction_report_sync, :as => :transaction
  serialize  :other_details, Hash
  include CsvExportMod

  after_create :mark_finance_payment_data_inactive, :if => Proc.new{|x| x.category.is_income }
  after_create :clear_report_marker

  # marks payment related records inactive for processing job for collections with linked masters
  # otherwise flush those records straight away.
  # Note: make inactive only for students
  # Like 1) FinanceFee   :: ParticularPayment / ParticularDiscount / TaxPayment
  #      2) HostelFee    :: TaxPayment
  #      3) TransportFee :: TransportTransactionDiscount/ TaxPayment
  #      4) InstantFee   :: InstantFeeDetail / TaxPayment

  def mark_finance_payment_data_inactive
    if finance_type == 'FinanceFee'
      particular_payments = ParticularPayment.all(:conditions => ["finance_transaction_id = ?", finance_transaction_id],
      :include => :finance_fee_particular)
      unless particular_payments.map {|pp| pp.finance_fee_particular.master_fee_particular_id }.include?(nil)
        pp_ids = particular_payments.map(&:id)
        ParticularPayment.update_all({:is_active => false}, {:finance_transaction_id => finance_transaction_id})
        ParticularDiscount.update_all({:is_active => false}, {:particular_payment_id => pp_ids})
        TaxPayment.update_all({:is_active => false}, {:finance_transaction_id => finance_transaction_id})
      else
        ParticularPayment.delete_all({:finance_transaction_id => finance_transaction_id})
        ParticularDiscount.delete_all({:particular_payment_id => particular_payments.map(&:id)})
        TaxPayment.delete_all({:finance_transaction_id => finance_transaction_id})
      end
    elsif finance_type == 'InstantFee'
      if payee_type == 'Student'
        instant_fee_details = InstantFeeDetail.all(:conditions => {:instant_fee_id => finance_id, :master_fee_particular_id => nil})
        if instant_fee_details.present?
          InstantFeeDetail.update_all({:is_active => false}, {:instant_fee_id => finance_id})
          TaxPayment.update_all({:is_active => false}, {:finance_transaction_id => finance_transaction_id})
        else
          InstantFeeDetail.delete_all({:instant_fee_id => finance_id})
          TaxPayment.delete_all({:finance_transaction_id => finance_transaction_id})
        end
      else
        InstantFeeDetail.delete_all({:instant_fee_id => finance_id})
      end
    elsif finance_type == 'TransportFee'
      ## mark TTD is_active = false
      if payee_type == 'Student'
        fee = self.finance
        collection = fee.transport_fee_collection
        if collection.master_fee_particular_id.present?
          TransportTransactionDiscount.update_all({:is_active => false}, {:finance_transaction_id => finance_transaction_id})
          TaxPayment.update_all({:is_active => false}, {:finance_transaction_id => finance_transaction_id})
        else
          TransportTransactionDiscount.delete_all({:finance_transaction_id => finance_transaction_id})
          TaxPayment.delete_all({:finance_transaction_id => finance_transaction_id})
        end
      end
    elsif finance_type == 'HostelFee'
      ## mark TTD is_active = false
      if payee_type == 'Student'
        fee = self.finance
        collection = fee.hostel_fee_collection
        if collection.master_fee_particular_id.present?
          TaxPayment.update_all({:is_active => false}, {:finance_transaction_id => finance_transaction_id})
        else
          TaxPayment.delete_all({:finance_transaction_id => finance_transaction_id})
        end
      end
    else
      # add more cases here as an when needed for master particular reports
    end
    TaxPayment.delete_all({:finance_transaction_id => finance_transaction_id}) if payee_type != 'Student'
  end

  # remove inactive payment data after reverse sync cycle completes
  def delete_inactive_finance_payment_data(status = false)
    # particular & discounts data for payments to be flushed
    if finance_type == 'FinanceFee'
      particular_payments = ParticularPayment.all(:conditions => ["finance_transaction_id = ? AND is_active = ?", finance_transaction_id, status])
      pp_ids = particular_payments.map(&:id)
      ParticularDiscount.delete_all({:is_active => status, :particular_payment_id => pp_ids})
      ParticularPayment.delete_all({:is_active => status, :finance_transaction_id => finance_transaction_id})
    elsif finance_type == 'InstantFee' and payee_type == 'Student'
      InstantFeeDetail.delete_all({:is_active => status, :instant_fee_id => finance_id})
    elsif finance_type == 'TransportFee'
      ## destroy TTD records [ tfds remains unaffected ]
      TransportTransactionDiscount.delete_all({:is_active => status, :finance_transaction_id => finance_transaction_id})
    end
    # tax data to be flushed
    TaxPayment.delete_all({:is_active => status, :finance_transaction_id => finance_transaction_id})
  end

  # remove report sync marker
  def clear_report_marker
    # remove marker for a non-synced finance transaction
    trs = TransactionReportSync.last(:conditions => ["transaction_id = ? AND transaction_type = 'FinanceTransaction'",
                                                     finance_transaction_id])
    trs.destroy if trs.present?
  end

  def receipt_number
    receipt_no.present? ? receipt_no : (
      (transaction_ledger.present? and 
          transaction_ledger.transaction_mode == 'SINGLE') ? transaction_ledger.receipt_no : "")    
  end

  def get_archieved_payee_name
    if payee_type=='Student' or payee_type=='Employee'
      archived_payee=("Archived"+payee_type).constantize.find_by_former_id(payee_id)
      if archived_payee.present?
        return "#{archived_payee.full_name}-&#x200E; (#{payee_type=="Student" ? archived_payee.admission_no : archived_payee.employee_number })&#x200E;"
      else
        return "#{t('user_deleted')}"
      end
    else
      return nil
    end
  end
  
  def get_archieved_payee_name_csv
    if payee_type=='Student' or payee_type=='Employee'
      archived_payee=("Archived"+payee_type).constantize.find_by_former_id(payee_id)
      if archived_payee.present?
        return "#{archived_payee.full_name} - (#{payee_type=="Student" ? archived_payee.admission_no : archived_payee.employee_number })"
      else
        return "#{t('user_deleted')}"
      end
    else
      return nil
    end
  end

  def payee_name
    if payee_type.present? and payee_id.present?
      if payee.present?
        "#{payee.full_name}-&#x200E; (#{payee_type=="Student" ? payee.admission_no : payee.employee_number })&#x200E;"
      else
        get_archieved_payee_name
      end
    elsif finance_type.present? and !(finance_type.constantize.present? rescue false)
      return nil
    elsif payee.nil? and finance.nil?
      return "#{t('user_deleted')}"
    else payee.nil?
      finance.payee_name
    end
  end
  
  def payee_name_for_csv
    if payee_type.present? and payee_id.present?
      if payee.present?
        "#{payee.full_name} - (#{payee_type=="Student" ? payee.admission_no : payee.employee_number })"
      else
        get_archieved_payee_name_csv
      end
    elsif finance_type.present? and !(finance_type.constantize.present? rescue false)
      return nil
    elsif payee.nil? and finance.nil?
      return "#{t('user_deleted')}"
    else payee.nil?
      finance.payee_name
    end
  end
  
  def self.fetch_cancelled_transactions_advance_search_result(params)
    cancelled_transactions_advance_search params
  end
  
  def self.generate_cancelled_transactions_csv(params,transactions)
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      cols << "Cancelled Transactions"
      csv << cols
      cols = []
      cols << t('sl_no')
      unless params[:transaction_type] == t('payslips')
        cols << t('payee_name')
        cols << t('receipt_no')
      else
        cols << t('employee_name')
      end
      cols << t('amount')
      cols << t('cancelled_by')
      cols << t('reason')
      cols << t('date_text')
      if (params['transaction_type'].nil? or params['transaction_type'] == "" or params['transaction_type']==t('fees_text'))
        cols << t('fee_collection_name')
      end
      unless params[:transaction_type] == t('payslips')
        cols << t('finance_type')
      end
      csv << cols
      cols = []
      i=0
      transactions.each do |f|
        cols <<  (i +=1)
        cols << f.payee_name_for_csv
        unless params[:transaction_type] == t('payslips')
          cols << f.receipt_number
        end
        cols << (precision_label(f.amount))
        cols << (f.user.present?? f.user.full_name  : t('user_deleted'))
        cols << (f.cancel_reason.present? ? f.cancel_reason :  "-")
        cols << (format_date(f.created_at,:format=>:short_date))
        if (params['transaction_type'].nil? or params['transaction_type'] == "" or params['transaction_type']==t('fees_text'))
          cols << f.collection_name
        end
        unless params[:transaction_type] == t('payslips')
          cols << f.finance_type.underscore.humanize()
        end
        csv << cols
        cols =[]
      end
    end
    return csv_string
  end
  
end
