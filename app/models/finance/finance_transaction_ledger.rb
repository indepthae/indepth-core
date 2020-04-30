require 'ostruct'
class FinanceTransactionLedger < ActiveRecord::Base
  include FeeReceiptMod
  has_many :finance_transactions, :foreign_key => 'transaction_ledger_id'
  has_many :cancelled_finance_transactions, :foreign_key => 'transaction_ledger_id'
  belongs_to :payee, :polymorphic => true
  belongs_to :financial_year

  accepts_nested_attributes_for :finance_transactions

  before_validation :set_transaction_mode, :set_transaction_type
  validates_presence_of :transaction_type, :transaction_mode
  #  before_create :generate_and_set_receipt_no #generate_receipt_no
  attr_accessor :category_is_income
  attr_accessor :receipt_categories, :current_batch, :cheque_date, :bank_name, :gateway_response, :multi_fee_payment

  named_scope :active_transactions, {:conditions => "status = 'ACTIVE' or status = 'PARTIAL'"}
  named_scope :cancelled_transactions, {:conditions => {:status => 'CANCELLED'}}
  # after_create :verify_and_send_sms

  serialize :transaction_data, OpenStruct
  #  named_scope :cancelled_transactions
  #  Various codes for transaction ledger
  # modes for transaction receipt generation
  #  0  =>  SINGLE
  #  1  =>  MULTIPLE
  # transaction types
  #  0  =>  SINGLE
  #  1  =>  MULTIPLE
  # transaction status
  #  0  =>  CANCELLED
  #  1  =>  ACTIVE 
  #  2  =>  PARTIAL   # some transactions is reverted under a ledger record

  def self.receipt_number_settings
    # 0 : single receipt number for multi
    # 1 : individual receipt number for respective finance transactions
    Configuration.get_config_value('SingleReceiptNumber').try(:to_i) || 0
  end

  def set_transaction_mode
    # set mode of receipt generation while transaction execution was recorded
    # 0 : Multiple receipt 
    # 1 : Single receipt
    self.transaction_mode = FinanceTransactionLedger.receipt_number_settings.zero? ? "MULTIPLE" : "SINGLE" if new_record?
  end

  def set_transaction_type
    self.transaction_type = 'SINGLE' unless transaction_type.present?
  end

  def mark_cancelled(reason=nil, revert_mode = "FULL")
    if revert_mode == "PARTIAL"
      self.status = self.finance_transactions.count > 0 ? "PARTIAL" : "CANCELLED"
      self.transaction_data = nil
      self.save
    else
      self.destroy_finance_transactions reason if finance_transactions.present?
      update_hsh = {:transaction_data => nil}
      update_hsh[:status] = "CANCELLED" unless self.finance_transactions.reload.present?
      self.update_attributes(update_hsh)
      #      self.update_attribute('status', "CANCELLED") 
    end
  end

  def destroy_finance_transactions reason
    ActiveRecord::Base.transaction do
      #      ft= FinanceTransaction.find(params[:transaction_id])
      self.finance_transactions.each do |ft|
        ft.cancel_reason = reason
        if FedenaPlugin.can_access_plugin?("fedena_pay")
          finance_payment = ft.finance_payment
          unless finance_payment.nil?
            status = Payment.payment_status_mapping[:reverted]
            finance_payment.payment.update_attributes(:status_description => status)
            #            payment.save
          end
        end
        raise ActiveRecord::Rollback unless ft.destroy
      end
    end
  end

  #####
  # TO DO: If needed to added check to identify if transaction mode and transaction type is a valid value
  #####   either MULTIPLE or SINGLE

  def generate_and_set_receipt_no
    if transaction_mode == "SINGLE" and category_is_income.present? and category_is_income
      self.receipt_no = Time.now.to_i #FinanceTransactionLedger.generate_receipt_no        
    end
  end

  def send_sms
    AutomatedMessageInitiator.fee_submission(self)  
  end

  def notify_users
    user_ids = [payee.user_id]

    if payee_type == 'Student'
      payee_identifier = payee.admission_no
      user_ids.push payee.immediate_contact.user_id if payee.immediate_contact
    elsif payee_type == 'Employee'
      payee_identifier = payee.employee_number
    end

    collections = finance_transactions.collect(&:get_collection).collect(&:name).join(", ")

    translate_options = {:amount => amount, :collections => collections, :payee_full_name => payee.full_name,
                         :payee_identifier => payee_identifier, :transaction_date => format_date(transaction_date)}

    body = is_waiver ? t('fee_transaction_waiver_notification', translate_options) : t('fee_transaction_notification', translate_options)

    inform(user_ids, body, 'CollectFee')
  end

  def overall_receipt_data batch_id, clear_cache = false
    return generate_overall_receipt_data batch_id if clear_cache
    return self.transaction_data || generate_overall_receipt_data(batch_id)
  end

  def generate_overall_receipt_data batch_id
    overall_receipt = OverallReceipt.new(self.payee_id, self.id, batch_id)
    self.transaction_data = overall_receipt.fetch_details
    self.send(:update_without_callbacks)
    self.transaction_data
  end

  def generate_overall_receipt_cache clear_cache = false
    fee = finance_transactions.try(:first).try(:finance)
    if fee.present?
      batch_id = case fee.class.name
      when "FinanceFee"
        fee.batch_id
      when "HostelFee"
        fee.batch_id
      when "TransportFee"
        fee.groupable_id
      else
        nil
      end
      overall_receipt_data batch_id, clear_cache
    end
  end

  private

  #####
  #TO DO : Apply transaction_mode & transaction_type to receipt_no search logic
  #####
  class << self
    # creates safely in case of db duplication issues
    def safely_create (*args)
      ledger_data = args[0]
      transactions_data = args[1]
      log = Logger.new('log/failed_transaction.log')
      transactions_data.each do |key , val|
        ft=FinanceTransaction.new(val)
        unless ft.valid?
          log.info("fee transaction record: #{ft.inspect}")
          log.info("fee transaction error: #{ft.errors.full_messages}")
          return 
        end
      end
      begin
        retries ||= 0
        ledger = create(ledger_data)
      rescue ActiveRecord::StatementInvalid => ex
        retry if (retries += 1) < 2
        log.info("fee transaction ledger record: #{ledger.inspect}")
        log.info("fee transaction ledger error: #{ledger.errors.full_messages}")
        log.info("fee transaction ledger error: #{ex.inspect}")
        raise ex
      end
      # create transaction receipts
      unless ledger.new_record?
        ledger.gateway_response = args[2] if ledger.payment_mode == "Online Payment"
        create_receipt_transactions(ledger, transactions_data)
      end

      # trigger over all receipt cache generation if pay all payment was done
      begin
        ledger.generate_overall_receipt_cache if ledger.transaction_type == 'MULTIPLE' and ledger.finance_transactions.present?
      rescue Exception => e
        puts "Error occurred in making over all receipt"
        puts e.inspect
      end

      ledger
    end

    def create_receipt_transactions transaction_ledger, transactions
      # A. processing when multi fee receipt set is disabled
      #     1. using the default receipt number settings (from fee settings page)
      # B. processing when multi fee receipt set is enabled 
      #     1. if receipt number set is configured using that
      #     2. if not configured using the values from default receipt number settings (from fee settings page)
      # Note: either process follows receipt generation mode configuration, ie SINGLE / MULTIPLE

      multi_configs = FinanceTransactionCategory.get_multi_configuration
      #      receipt_mode = (Configuration.get_config_value 'SingleReceiptNumber').to_i == 1 ? 'SINGLEMODE' : 'MULTIMODE'
      # (multi_configs.present? and multi_configs[:receipt_set].present?) ?
      make_categorized_transaction_receipts(transactions, transaction_ledger) # :
      # make_transaction_receipts(transactions, transaction_ledger)
    end

    def make_transaction_receipts transactions, transaction_ledger #, receipt_mode = 'MULTIMODE'

    end

    def receipt_set_enabled
      multi_configs = FinanceTransactionCategory.get_multi_configuration
      (multi_configs.present? and multi_configs[:receipt_set].present?)
    end

    def make_categorized_transaction_receipts transactions, transaction_ledger #, receipt_mode = 'MULTIMODE'
      transaction_category_ids, fee_ids, all_categories = [], [], []
      waiver_receipt_check = Configuration.receipt_number_disabled?

      transactions.each do |k, v|
        case v[:finance_type]
        when 'FinanceFee' # finance fees
          fee_ids << v[:finance_id]
        else # fees
          transaction_category_ids << v[:category_id]
        end
      end

      all_categories += FinanceTransactionCategory.all(:conditions => {:id => transaction_category_ids},
        :include => :receipt_number_set)
      all_categories += FinanceFeeCategory.find(:all, :include => :receipt_number_set,
        :select => "finance_fee_categories.*, ff.id AS ff_id",
        :joins => "INNER JOIN finance_fee_collections ffc ON ffc.fee_category_id=finance_fee_categories.id
                        INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id",
        :conditions => ["ff.id IN (?)", fee_ids]) #s.map(&:id)])
      if transaction_ledger.transaction_mode == "MULTIPLE" # "MULTIPLE"
        receipt_set_group = all_categories.group_by { |x| x.receipt_number_set }

        # puts all_categories.inspect

        all_categories.each do |category|
          # puts category.inspect
          transactions_data = fetch_category_transaction transactions, category
          # puts transactions_data.inspect
          transactions_data.each do |transaction_data|
            unless (transaction_ledger.is_waiver and waiver_receipt_check)
              transaction_receipt = TransactionReceipt.safely_create(category.receipt_number_set)
            end
            make_transaction category, transaction_data, transaction_ledger, transaction_receipt
          end
        end
      else
        receipt_set_group = all_categories.group_by { |x| x.receipt_number_set }
        receipt_set_group.each do |receipt_set, categories|
          # puts categories.inspect
          unless (transaction_ledger.is_waiver and waiver_receipt_check)
            transaction_receipt = TransactionReceipt.safely_create(receipt_set)
          end
          categories.each do |category|
            # puts category.inspect
            transactions_data = fetch_category_transaction transactions, category
            transactions_data.each do |transaction_data|
              make_transaction category, transaction_data, transaction_ledger, transaction_receipt
            end
          end
        end
      end

    end

    def fetch_category_transaction transactions, category
      transactions_data = if category.is_a? FinanceFeeCategory
        transactions.collect { |k, v| v if v[:finance_type] == 'FinanceFee' and v[:finance_id] == category.ff_id }.compact #.try(:first)
      else # FinanceTransactionCategory
        transactions.collect { |k, v| v if v[:category_id].to_i == category.id }.compact #.try(:first)
      end #.try(:last)

      # puts transactions_data.inspect

      # transactions_data
    end

    def make_transaction category, transaction_data, transaction_ledger, transaction_receipt
      
      waiver_receipt_check = Configuration.receipt_number_disabled?

      transaction_data.merge!({:transaction_ledger_id => transaction_ledger.id,
          :transaction_type => transaction_ledger.transaction_type,
          :transaction_mode => transaction_ledger.transaction_mode})

      finance_transaction = FinanceTransaction.new(transaction_data)
      finance_transaction.cheque_date = transaction_ledger.cheque_date # if params[:multi_fees_transaction][:cheque_date].present?
      finance_transaction.bank_name = transaction_ledger.bank_name #if params[:multi_fees_transaction][:bank_name].present?              
      finance_transaction.batch_id = transaction_ledger.current_batch.id if transaction_ledger.current_batch.present?
      finance_transaction.fine_included = true if transaction_data[:fine_amount].present? and
        transaction_data[:fine_amount].to_f > 0
      # setting transaction receipt      
      finance_transaction.transaction_receipt = transaction_receipt
      unless finance_transaction.transaction_receipt.present?
        finance_transaction.build_finance_transaction_receipt_record
      end
      #############################################
      # Important NOTE ::
      # if block must be triggered only if pay all payment was done using online payment (using payment gateways)
      #
      #############################################
      if transaction_ledger.multi_fee_payment.present? and transaction_ledger.gateway_response.present?
        logger = Logger.new("#{RAILS_ROOT}/log/payment_processor_error.log")
        finance_transaction.payment_mode = transaction_ledger.payment_mode
        finance_transaction.reference_no = transaction_ledger.gateway_response[:transaction_reference]
        finance_transaction.transaction_date = Date.today_with_timezone.to_date
        begin
          finance_transaction.save
        rescue Exception => e
          logger.info "Errror-----#{e.message}------for---#{finance_transaction.inspect}"
        ensure
          # track online payment info for each transaction
          record_online_payment_info transaction_ledger, finance_transaction
        end
      else
        finance_transaction.save
      end

      # process_online_payment_info(transaction_ledger, finance_transaction) if transaction_ledger.multi_fee_payment.present? # TO DO :: add rollback
      # puts finance_transaction.inspect
    end

    def record_online_payment_info transaction_ledger, finance_transaction
      multi_fee_payment = transaction_ledger.multi_fee_payment
      finance_payment = transaction_ledger.multi_fee_payment.finance_payments.
        new(:fee_payment => finance_transaction.finance, :fee_collection => finance_transaction.get_collection,
        :finance_transaction_id => finance_transaction.id)
      finance_payment.save if multi_fee_payment.amount.to_f > 0.0 and finance_transaction.amount.to_f > 0.0

    end
  end
end
