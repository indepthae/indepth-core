class AdvanceFeeCollection < ActiveRecord::Base
  validates_presence_of :fees_paid, :student_id, :date_of_advance_fee_payment
  has_many :advance_fee_category_collections
  has_many :advance_fee_categories, :through => :advance_fee_category_collections
  has_one :advance_fee_transaction_receipt_record

  accepts_nested_attributes_for :advance_fee_category_collections, :allow_destroy => true
  belongs_to :student
  belongs_to :advance_fee_category
  belongs_to :user
  belongs_to :transaction_receipt

  serialize :receipt_data, OpenStruct

  # after_save :create_the_transaction_data

  MULTI_CONFIGS = ['MultiReceiptNumberSetEnabled', 'MultiReceiptTemplateEnabled', 'MultiFeeAccountEnabled']

  # fetch cashier name
  def cashier_name
    user.present? ? user.full_name : "#{t('deleted_user')}"
  end

  # fetch cashier name
  def get_cashier_name
    user.present? ? ((user.user_type == "Parent" or user.user_type == "Student") ? '': user.full_name ) : " "
  end


  # fetch multi configuration for transaction
  def get_multi_configuration configs = nil
    configs ||= Configuration.get_multiple_configs_as_hash MULTI_CONFIGS
    return {} unless configs.select { |k, v| v.to_i == 1 }.present?
    {
        :account => configs[:multi_fee_account_enabled].to_i == 1,
        :template => configs[:multi_receipt_template_enabled].to_i == 1,
        :receipt_set => configs[:multi_receipt_number_set_enabled].to_i == 1
    }
  end

  # find advance fee category id 
  def fetch_advance_fee_category_id
    category = FinanceTransactionCategory.find_by_name("Advance Fees Credit")
    if category
      category.id
    end
  end


  # fetch receipt configuration for advance fee
  def fetch_receipt_config
    receipt_config = get_multi_configuration[:receipt_set].present? ? get_multi_configuration[:receipt_set] : nil
    if receipt_config
      receipt_set = FinanceCategoryReceiptSet.find_by_category_id_and_category_type(fetch_advance_fee_category_id, "FinanceTransactionCategory")
    end
    receipt_set
  end

  # fetch receipt configuration for advance fee
  def fetch_reciept_template_config
    reciept_template_config = get_multi_configuration[:template].present? ? get_multi_configuration[:template] : nil
    if reciept_template_config
      reciept_template_set = FinanceCategoryReceiptTemplate.find_by_category_id_and_category_type(fetch_advance_fee_category_id, "FinanceTransactionCategory")
    end
    reciept_template_set
  end

  # fetch receipt configuration for advance fee
  def fetch_account_config
    account_config = get_multi_configuration[:account].present? ? get_multi_configuration[:account] : nil
    if account_config
      account_set = FinanceCategoryAccount.find_by_category_id_and_category_type(fetch_advance_fee_category_id, "FinanceTransactionCategory")
    end
    account_set
  end

  # create the transaction data for advance fee collection
  def create_the_transaction_data
    receipt_set = fetch_receipt_config
    receipt_number_set = receipt_set.present? ? receipt_set.receipt_number_set : nil
    receipt = TransactionReceipt.safely_create(receipt_number_set)
    currency = Configuration.currency
    receipt_template_id = fetch_reciept_template_config.present? ? fetch_reciept_template_config.fee_receipt_template_id : nil
    receipt_data = OpenStruct.new(:reference_no => self.reference_no, :total_amount_to_pay => "---", :payment_mode => self.payment_mode,
      :template_id => receipt_template_id, :formated_date => self.date_of_advance_fee_payment, :transaction_date => self.date_of_advance_fee_payment,
      :receipt_title => "Advance Fee receipt", :amount => self.fees_paid, :total_payable => self.fees_paid, :total_amount_paid => self.fees_paid,
      :bank_name => self.bank_name, :cheque_date => self.cheque_date, :reference_no => self.reference_no,
      :receipt_no => receipt.ef_receipt_number, :wallet_mode_only => true, :finance_type => "AdvanceFees", :is_particular_wise => false, :currency => currency )
    default_config_hash = ['InstitutionName', 'InstitutionAddress', 'PdfReceiptSignature',
                             'PdfReceiptSignatureName', 'PdfReceiptCustomFooter', 'PdfReceiptAtow', 'PdfReceiptNsystem',
                             'PdfReceiptHalignment', 'FinanceTaxIdentificationLabel', 'FinanceTaxIdentificationNumber', 'EnableRollNumber']
    default_configs = OpenStruct.new(Configuration.get_multiple_configs_as_hash default_config_hash)
    default_configs.default_currency = Configuration.default_currency
    default_configs.currency_symbol = Configuration.currency
    default_configs.currency = Configuration.currency
    receipt_data.default_configs = default_configs
    advance_fee_category_collections = self.advance_fee_category_collections
    receipt_data.transactions = advance_fee_category_collections
    receipt_data.payee = OpenStruct.new(:full_name => self.student.full_name, :payee_type => "Student", :admission_no => self.student.admission_no,
                                   :roll_no => self.student.roll_number, :full_course_name => self.student.batch.course.full_name,
                                   :batch_full_name => self.student.batch.full_name, :guardian_name => self.student.try(:immediate_contact).try(:full_name)
                                  )
    self.update_attributes(:transaction_receipt_id => receipt.id, :receipt_data => receipt_data);
    create_advance_fee_transaction_record
  end
  
  # fetch template for transaction
  def fetch_template_id
    advance_fee_transaction_receipt_record.fee_receipt_template_id
  end

  # create advance fee transaction receipt data record
  def create_advance_fee_transaction_record
    receipt_template_id = fetch_reciept_template_config.present? ? fetch_reciept_template_config.fee_receipt_template_id : nil
    fees_account_id = fetch_account_config.present? ? fetch_account_config.fee_account_id : nil
    p_count = Configuration.precision_count
    a_f_t_receipt_record = AdvanceFeeTransactionReceiptRecord.new(:advance_fee_collection_id => self.id, :transaction_receipt_id => self.transaction_receipt_id,
                                                                  :fee_account_id => fees_account_id, :fee_receipt_template_id => receipt_template_id,
                                                                  :precision_count => p_count, :receipt_data => self.receipt_data)
    a_f_t_receipt_record.save
  end

  # reverting the advance fee collection
  def create_cancelled_transaction_data(adfc, reason)
    dup_transaction = adfc.clone
    dup_transaction = dup_transaction.attributes.except('created_at', 'updated_at', 'receipt_data')
    cancelled_advance_fee_transaction = CancelledAdvanceFeeTransaction.new(dup_transaction)
    transaction_hash = OpenStruct.new
    transaction_hash.transactions = adfc.advance_fee_category_collections
    cancelled_advance_fee_transaction.transaction_data = transaction_hash
    cancelled_advance_fee_transaction.reason_for_cancel = reason
    cancelled_advance_fee_transaction.advance_fee_collection_id = adfc.id
    student = adfc.student
    revert_status = adfc.fees_paid <= student.advance_fee_wallet.amount ? true : false
    if revert_status == true
      wallet = student.advance_fee_wallet
      cancelled_advance_fee_transaction.save
      wallet.update_attributes(:amount => (wallet.amount.to_f - adfc.fees_paid.to_f))
      return true
    else
      return false
    end
  end

  # fetch wallet expense details
  def self.fetch_wallet_expense_transaction_course_wise(start_date, end_date)
    FinanceTransaction.all(:joins => [[:finance_fees => [[:student => [[:batch => [:course]]]]]]],
      :select => "SUM(finance_transactions.wallet_amount) AS amount,students.id as student_id, courses.id AS course_id,batches.id AS batch_id,batches.name AS batch_name", 
    :conditions => ["finance_transactions.transaction_date BETWEEN '#{start_date}' and '#{end_date}' and finance_transactions.wallet_amount_applied = true"], :group => "batches.id")
  end

  # fetch wallet credit details
  def self.fetch_wallet_credit_transaction_details(start_date, end_date, account_id)
    conditions = []
    conditions << "AND advance_fee_transaction_receipt_records.fee_account_id IS NULL" if account_id == "0"
    conditions << "AND advance_fee_transaction_receipt_records.fee_account_id = '#{account_id}'" if (account_id != "0" && account_id != "") && !account_id.nil?
    conditions << nil if account_id.nil?
    transactions = AdvanceFeeCategoryCollection.all(:joins => [:advance_fee_category, [:advance_fee_collection => [:transaction_receipt, :advance_fee_transaction_receipt_record]]],
      :conditions => ["advance_fee_collections.date_of_advance_fee_payment between ? and ? #{conditions}", start_date, end_date] ,
      :select => "sum(advance_fee_category_collections.fees_paid) as amount, advance_fee_categories.name as category_name, advance_fee_collections.student_id as student, advance_fee_categories.id as advance_fee_category_id, advance_fee_collections.user_id",
      :group => "advance_fee_categories.id")
    transactions
  end

  # fetch student name
  def self.fetch_student_name(student_id)
      student = Student.find_by_id(student_id)
      return student.full_name
  end

  # generating advance fees receipt reports
  def self.fetch_advance_fees_receipts(start_date, end_date, params)
    if !params["query"].present? or params["query"] == "" or params["query"] == "advance fee" or params["query"] == "advance fees"
      conditions = []
      if params[:search].present?
        conditions << "AND (students.first_name like '#{params[:search][:student_info_like]}' OR students.middle_name like '#{params[:search][:student_info_like]}' OR students.last_name like '#{params[:search][:student_info_like]}')" if params[:search][:student_info_like].present?
        conditions << "AND advance_fee_collections.reference_no = '#{params[:search][:reference_no_like]}'" if params[:search][:reference_no_like].present?
        conditions << "AND transaction_receipts.ef_receipt_number = '#{params[:search][:receipt_no_as]}'" if params[:search][:receipt_no_as].present?
      end
      all(:joins => [:transaction_receipt, :advance_fee_transaction_receipt_record, [:student => [:batch => [:course]]]], 
        :select => "transaction_receipts.ef_receipt_number as receipt_no, 'AdvanceFeesCollection' as trans_type, advance_fee_collections.id as adfcid, advance_fee_collections.student_id as payer_no, 
        concat(students.first_name, students.middle_name, students.last_name) as payer_name, 'Student' as payer_type_info, concat(courses.course_name,' - ', batches.name) as payer_batch_dept, 'AdvanceFees' as fin_type,
        advance_fee_collections.date_of_advance_fee_payment as transaction_date, advance_fee_collections.fees_paid as amount, advance_fee_collections.reference_no as reference_no, advance_fee_collections.payment_mode as payment_mode, 'Advance Fees' as collection_name,
        advance_fee_collections.user_id",
      :conditions => ["advance_fee_collections.date_of_advance_fee_payment between ? AND ? #{conditions.to_s}",
        start_date, end_date.to_date+1.day])
    else
      []
    end
  end

  # batch wise monthly income report
  def self.batch_wise_monthly_income_report(start_date, end_date, category_id, batch_id, account_id)
    conditions = []
    conditions << "AND advance_fee_transaction_receipt_records.fee_account_id IS NULL" if account_id == "0"
    conditions << "AND advance_fee_transaction_receipt_records.fee_account_id = '#{account_id}'" if (account_id != "0" && account_id != "") && !account_id.nil?
    conditions << nil if account_id.nil?
    transactions = AdvanceFeeCategoryCollection.all(:joins => [:advance_fee_category, [:advance_fee_collection => [:advance_fee_transaction_receipt_record, [:student => [:batch => [:course]]]]]],
                       :conditions => ["advance_fee_collections.date_of_advance_fee_payment between ? and ? and advance_fee_category_collections.advance_fee_category_id = ? and batches.id = ? #{conditions}", start_date, end_date, category_id, batch_id],
                       :select => 'sum(advance_fee_category_collections.fees_paid) as amount, advance_fee_collections.date_of_advance_fee_payment as date_of_payment,students.id as student_id, advance_fee_collections.receipt_data, advance_fee_collections.id as advance_fee_collection_id,
      advance_fee_collections.payment_mode as payment_mode,advance_fee_collections.payment_note as payment_note, advance_fee_collections.user_id', :group => "students.id")
    transactions
  end

  # category wise collection report
  def self.category_wise_collection_report(start_date, end_date, category_id, student_id, batch_id, account_id)
    conditions = []
    conditions << "AND advance_fee_transaction_receipt_records.fee_account_id IS NULL" if account_id == "0"
    conditions << "AND advance_fee_transaction_receipt_records.fee_account_id = '#{account_id}'" if (account_id != "0" && account_id != "") && !account_id.nil?
    conditions << nil if account_id.nil?
    transactions = AdvanceFeeCategoryCollection.all(:joins => [:advance_fee_category, [:advance_fee_collection => [:transaction_receipt, :advance_fee_transaction_receipt_record, [:student => [:batch]]]]],
                                     :conditions => ["advance_fee_collections.student_id = ? AND advance_fee_category_collections.advance_fee_category_id = ? AND advance_fee_collections.date_of_advance_fee_payment BETWEEN ? AND ? AND batches.id = ? #{conditions}", student_id, category_id, start_date, end_date, batch_id],
                                     :select => "transaction_receipts.ef_receipt_number as receipt_no, advance_fee_collections.date_of_advance_fee_payment as transaction_date,
      advance_fee_collections.payment_note as payment_note, advance_fee_category_collections.fees_paid as amount, advance_fee_collections.payment_mode as payment_mode, advance_fee_collections.user_id")
    transactions
  end
  
end
