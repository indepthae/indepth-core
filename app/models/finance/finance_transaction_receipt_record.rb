class FinanceTransactionReceiptRecord < ActiveRecord::Base
  belongs_to :finance_transaction
  belongs_to :transaction_receipt
  belongs_to :fee_account
  belongs_to :fee_receipt_template

  before_create :set_initial_data
  after_create :set_receipt_data, :if => Proc.new { |ftrr|
                                  fee_type = ftrr.finance_transaction.finance_type
                                  case fee_type
                                    when 'FinanceFee'
                                      !(ftrr.finance_transaction.trans_type=="particular_wise" and ftrr.finance_transaction.finance_type == "FinanceFee")
                                    when 'TransportFee'
                                      false
                                    when 'HostelFee'
                                      false
                                    else
                                      true
                                  end
                                }
  serialize :receipt_data, OpenStruct
  has_attached_file :receipt_pdf,
                    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
                    :path => "uploads/:class/:attachment/:id_partition/:basename.:extension",
                    :max_file_size => 5242880,
                    :reject_if => proc { |attributes| attributes.present? }

  def set_initial_data
    transaction = finance_transaction

    collection, fee_category = transaction.finance_type.present? ?
        (
        case transaction.finance_type.underscore
          when "finance_fee"
            [transaction.finance.finance_fee_collection, transaction.finance.finance_fee_collection.fee_category]
          when "hostel_fee"
            [transaction.finance.hostel_fee_collection]
          when "transport_fee"
            [transaction.finance.transport_fee_collection]
          else
            []
        end) : []

    category = transaction.category
    configs = category.get_multi_config({:collection => collection, :fee_category => fee_category})

    self.fee_account_id = (configs[:account].is_a?(Fixnum) ? configs[:account] :
        (configs[:account].is_a?(FeeAccount) ? configs[:account].try(:id) : nil)) if configs.present?

    self.fee_receipt_template_id = configs[:template].try(:id) if configs.present? and configs[:template].is_a?(FeeReceiptTemplate)
    # precision count
    self.precision_count = finance_transaction.precision_count || FedenaPrecision.get_precision_count
  end

  def set_receipt_data
    # fetch and record receipt data as serialized data    
    begin
      self.receipt_data = finance_transaction.receipt_data
      self.save
    rescue Exception => e
      puts e.inspect
    end
  end

end
