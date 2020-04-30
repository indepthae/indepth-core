#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class FinanceTransaction < ActiveRecord::Base
  include FeeReceiptMod
  belongs_to :category, :class_name => 'FinanceTransactionCategory', :foreign_key => 'category_id'
  delegate :name, :to => :category, :allow_nil => true, :prefix => true
  belongs_to :student
  belongs_to :finance, :polymorphic => true
  delegate :name, :to => :finance, :allow_nil => true, :prefix => true
  belongs_to :payee, :polymorphic => true
  belongs_to :master_transaction, :class_name => "FinanceTransaction"
  belongs_to :user
  belongs_to :batch
  belongs_to :transaction_ledger, :class_name => "FinanceTransactionLedger"
  has_many :finance_fees, :through => :fee_transactions
  has_many :fee_transactions
  has_one :fee_refund, :dependent => :destroy
  has_one :finance_donation, :foreign_key => 'transaction_id', :dependent => :destroy
  has_one :finance_transaction_receipt_record
  has_one :transaction_receipt, :through => :finance_transaction_receipt_record
  has_one :fee_account, :through => :finance_transaction_receipt_record
  has_one :transaction_report_sync, :as => :transaction

  cattr_reader :per_page
  attr_accessor :cancel_reason
  attr_accessor :receipt_categories
  attr_accessor :transaction_type, :transaction_mode, :precision_count, :ledger_status, :removal_fine_amt
  attr_accessor_with_default :full_fine_paid, false
  attr_accessor_with_default :pay_all_manual_fine, false
  attr_accessor_with_default :is_waiver, false
  validates_presence_of :title, :amount, :transaction_date
  validates_uniqueness_of :receipt_no, :scope => :school_id, :allow_blank => true, :allow_nil => true
  validates_presence_of :category, :message => :not_specified
  validates_numericality_of :amount, :greater_than_or_equal_to => 0, :message => :must_be_positive, :allow_blank => true

  before_save :verify_fine_amount
  before_create :make_transaction_ledger
  after_create :add_voucher_or_receipt_number
  before_save :verify_precision, :set_transaction_stamp
  validate :set_fine
  after_create :save_pay_all_manual_fine, :if => Proc.new {|ft| ft.pay_all_manual_fine and ft.transaction_type == 'MULTIPLE' and ft.fine_amount > 0}
  #  after_create :save_pay_all_manual_fine, :if => Proc.new {|ft| ft.transaction_type == 'MULTIPLE' and ft.fine_amount > 0}
  after_create :add_user
  before_destroy :refund_check
  #  before_save :check_data_correctnes
  after_destroy :create_cancelled_transaction
  has_many :monthly_payslips
  has_many :employee_payslips
  # Dependent destroy is commented, as these records shall be deleted after reverse sync of master particular report
  # has been performed from delayed job of TransactionReportSync objects
  has_many :particular_payments #, :dependent => :destroy
  #tax associations
  has_many :tax_payments #, :dependent => :destroy

  has_and_belongs_to_many :multi_fees_transactions, :join_table => "multi_fees_transactions_finance_transactions"
  has_many :finance_transaction_fines, :dependent => :destroy
  has_many :multi_transaction_fines, :through => :finance_transaction_fines
  has_many :successor_transactions, :foreign_key => 'finance_id', :primary_key => 'finance_id',
    :class_name => 'FinanceTransaction',
    :conditions => 'id > #{self.id} and finance_type="#{self.finance_type}"'
  after_create :verify_and_send_sms , :if => Proc.new { |ft| FinanceTransaction.send_sms and ( ft.transaction_type == 'SINGLE' or ft.transaction_ledger.transaction_type == "SINGLE" ) }
  after_create :notify_users, :if => Proc.new { |ft| ft.transaction_type == 'SINGLE' or ft.transaction_ledger.transaction_type == 'SINGLE'  }
  # update fee payment records for core fees
  after_create :add_particular_amount, :if => Proc.new { |ft| !FinanceTransaction.particular_wise_pay_lock and
      ft.finance_type=='FinanceFee' and (ft.amount > ft.fine_amount) }

  #trigger over all receipt cache build for finance fee
  after_create :build_over_all_receipt_cache, :if => Proc.new {|ft| ft.finance_type == 'FinanceFee' and ft.transaction_ledger.transaction_type == "SINGLE"}
  before_create :set_financial_year

  # advance fee deduction
  after_create :update_advance_fee_status
  before_create :update_transation_mode, :if => :wallet_amount_applied?
  has_one :advance_fee_deduction
  before_destroy :update_advance_fee_wallet
  before_create :handle_wallet_amount


  eligible_finance_types=["TransportFee", "HostelFee", "FinanceFee", "InstantFee"]
  named_scope :eligible, :conditions => ["finance_type IN (?)", eligible_finance_types]
  #  named_scope :receipt_no_as, lambda { |query| {:conditions => ["receipt_no LIKE ?", "%#{query}%"]} }
  named_scope :receipt_no_equals, lambda { |query| {
      #      :joins => :transaction_ledger, :include => :transaction_ledger,
      :conditions => ["CONCAT(IFNULL(tr.receipt_sequence,''),
                              tr.receipt_number) LIKE ?", "#{query}"]}}
  #        "finance_transactions.receipt_no = ? or finance_transaction_ledgers.receipt_no = ?",
  #        "#{query}", "#{query}"]} }
  named_scope :receipt_no_as, lambda { |query| {:conditions =>
        ["CONCAT(IFNULL(tr.receipt_sequence,''),
                 tr.receipt_number) LIKE ?", "%#{query}%"]} }
  named_scope :reference_no_like, lambda { |query| {:conditions => ["finance_transactions.reference_no LIKE ?", "%#{query}%"]} }
  named_scope :start_date_as, lambda { |query| {:conditions => ["finance_transactions.transaction_date >= ?", "#{query}"]} }
  named_scope :end_date_as, lambda { |query| {:conditions => ["finance_transactions.transaction_date <= ?", "#{query}"]} }
  named_scope :fee_account_equals, lambda { |query|
    account_id = query.present? ? (query.to_i > 0 ? query.to_i : nil) : 0;
    conditions = joins = "";
    if account_id.nil?
      conditions = "ftrr.fee_account_id IS NULL"
          # joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id"
    elsif account_id > 0
      conditions = ["ftrr.fee_account_id = #{account_id}"]
          # joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id"
    else
      conditions = ""
          joins = ""
    end

    {:conditions => conditions}
  }
  named_scope :payment_mode_equals, lambda { |query| {:conditions => ["finance_transactions.payment_mode = ?", "#{query}"]} }
  named_scope :user_name_equals, lambda { |user_id| {:joins => :user, :conditions => ["finance_transactions.user_id = ?", user_id]} }
  named_scope :collection_id_equals, lambda { |ftid| fid, ftype, fname = ftid.split(':');
    {:joins => "LEFT OUTER JOIN finance_fees ON finance_fees.id=finance_transactions.finance_id
                      LEFT OUTER JOIN transport_fees ON transport_fees.id=finance_transactions.finance_id
                      LEFT OUTER JOIN hostel_fees ON hostel_fees.id=finance_transactions.finance_id
                      LEFT OUTER JOIN instant_fees on instant_fees.id=finance_transactions.finance_id",
      :conditions => ["(finance_fees.fee_collection_id = ? and finance_transactions.finance_type = ?) or
                                 (transport_fees.transport_fee_collection_id = ? and finance_transactions.finance_type = ?) or
                                 (hostel_fees.hostel_fee_collection_id = ? and finance_transactions.finance_type = ?) or
                                 (instant_fees.instant_fee_category_id = ? and finance_transactions.finance_type = ?) or
                                 (instant_fees.instant_fee_category_id IS NULL and finance_transactions.finance_type = ? and
                                  instant_fees.custom_category=?)", fid, ftype, fid, ftype, fid, ftype, fid, ftype, ftype, fname]} }

  named_scope :collection_name_type_equals, lambda { |ftid| fname, ftype = ftid.split(/\ - ([^ - ]*)$/);
    feec_ids = (ftype=='InstantFee') ? InstantFeeCategory.find_all_by_name(fname).collect(&:id):
      "#{ftype}Collection".constantize.find_all_by_name(fname).collect(&:id) ;
    {:joins => "LEFT OUTER JOIN finance_fees ON finance_fees.id=finance_transactions.finance_id
                       LEFT OUTER JOIN transport_fees ON transport_fees.id=finance_transactions.finance_id
                       LEFT OUTER JOIN hostel_fees ON hostel_fees.id=finance_transactions.finance_id
                       LEFT OUTER JOIN instant_fees ON instant_fees.id=finance_transactions.finance_id",
      :conditions => ["(finance_fees.fee_collection_id IN (?) and finance_transactions.finance_type IN (?)) or
                                 (transport_fees.transport_fee_collection_id IN (?) and finance_transactions.finance_type IN (?)) or
                                 (hostel_fees.hostel_fee_collection_id IN (?) and finance_transactions.finance_type = ?) or
                                 (instant_fees.instant_fee_category_id IN (?) and finance_transactions.finance_type = ?) or
                                 (instant_fees.instant_fee_category_id IS NULL and finance_transactions.finance_type = ? and
                                  instant_fees.custom_category=?)",
        feec_ids, ftype, feec_ids, ftype, feec_ids, ftype, feec_ids, ftype, ftype, fname]} }

  named_scope :employee_info_like, lambda { |search_string| {
      :joins => "LEFT OUTER JOIN employees es
                                           ON es.id = finance_transactions.payee_id AND
                                                 finance_transactions.payee_type='Employee'
                      LEFT OUTER JOIN archived_employees ars
                                           ON finance_transactions.payee_type='Employee' AND
                                                 ars.former_id = finance_transactions.payee_id",
      :conditions => ["finance_transactions.payee_type = 'Employee' and
                                (finance_transactions.payee_id IN (?) OR finance_transactions.payee_id in (?))",
        Employee.find(:all, :conditions => ["(LTRIM(first_name) LIKE ? OR LTRIM(middle_name) LIKE ? OR
                                                                  LTRIM(last_name) LIKE ? OR employee_number = ? OR
                                                                  (CONCAT(TRIM(first_name), \" \", TRIM(last_name)) LIKE ? ) OR
                                                                  (CONCAT(TRIM(first_name), \" \", TRIM(middle_name), \" \",
                                                                                 TRIM(last_name)) LIKE ? ))", "%#{search_string}%",
            "%#{search_string}%", "%#{search_string}%", "#{search_string}", "%#{search_string}%",
            "%#{search_string}%"]).collect(&:id).uniq.join(','),
        ArchivedEmployee.find(:all,
          :conditions => ["(LTRIM(first_name) LIKE ? OR LTRIM(middle_name) LIKE ? OR
                                      LTRIM(last_name) LIKE ? OR employee_number = ? OR
                                      (CONCAT(trim(first_name), \" \", TRIM(last_name)) LIKE ? ) OR
                                      (CONCAT(TRIM(first_name), \" \", TRIM(middle_name), \" \",
                                      TRIM(last_name)) LIKE ? ))", "%#{search_string}%", "%#{search_string}%",
            "%#{search_string}%", "#{search_string}", "%#{search_string}%",
            "%#{search_string}%"]).collect(&:former_id).uniq.join(',')]} }

  named_scope :student_info_like, lambda { |search_string| {
      :joins => "LEFT OUTER JOIN students ss
                                            ON ss.id = finance_transactions.payee_id and
                                                  finance_transactions.payee_type='Student'
                      LEFT OUTER JOIN archived_students ars
                                            ON finance_transactions.payee_type='Student' and
                                                  ars.former_id = finance_transactions.payee_id",
      :conditions => ["finance_transactions.payee_type = 'Student' and
                                (finance_transactions.payee_id in (?) or finance_transactions.payee_id in (?))",
        Student.find(:all,
          :conditions => ["(LTRIM(first_name) LIKE ? OR LTRIM(middle_name) LIKE ? OR
                                      LTRIM(last_name) LIKE ? OR admission_no = ? OR
                                      (CONCAT(TRIM(first_name), \" \", TRIM(last_name)) LIKE ? ) OR
                                      (CONCAT(TRIM(first_name), \" \", TRIM(middle_name), \" \",
                                                     TRIM(last_name)) LIKE ? ))", "%#{search_string}%",
            "%#{search_string}%", "%#{search_string}%", "#{search_string}",
            "%#{search_string}%", "%#{search_string}%"]).collect(&:id).uniq.join(','),
        ArchivedStudent.find(:all,
          :conditions => ["(LTRIM(first_name) LIKE ? OR LTRIM(middle_name) LIKE ? OR
                                      LTRIM(last_name) LIKE ? OR admission_no = ? OR
                                      (CONCAT(TRIM(first_name), \" \", TRIM(last_name)) LIKE ? ) OR
                                      (CONCAT(TRIM(first_name), \" \", TRIM(middle_name), \" \",
                                                     TRIM(last_name)) LIKE ? ))", "%#{search_string}%",
            "%#{search_string}%", "%#{search_string}%", "#{search_string}", "%#{search_string}%",
            "%#{search_string}%"]).collect(&:former_id).uniq.join(',')]} }

  include CsvExportMod


  class << self
    attr_accessor_with_default :send_sms, true
    attr_accessor_with_default :particular_wise_pay_lock, false
  end

  def set_financial_year
    self.financial_year_id = FinancialYear.inclusive_of(self.transaction_date).try(:last).try(:id)
  end

  def save_pay_all_manual_fine
    mtf = MultiTransactionFine.new({:receiver_id => self.payee_id, :receiver_type => self.payee_type,
        :amount => (self.fine_amount - self.auto_fine.to_f), :fee_id => self.finance_id})
    mtf.name = case self.finance_type
    when "FinanceFee"
      FinanceFee.find(self.finance_id).finance_fee_collection.name
    when "TransportFee"
      TransportFee.find(self.finance_id).transport_fee_collection.name
    when "HostelFee"
      HostelFee.find(self.finance_id).hostel_fee_collection.name
    end
    self.multi_transaction_fines << mtf if mtf.save
  end

  def make_transaction_ledger
    if !transaction_type.present? || (transaction_type.present? and transaction_type == 'SINGLE')
      self.transaction_ledger = FinanceTransactionLedger.create({
          :payment_note => self.payment_note,
          :payment_mode => self.payment_mode,
          :transaction_date => self.transaction_date,
          :transaction_type => transaction_type || 'SINGLE',
          :payee_id => self.payee_id,
          :payee_type => self.payee_type,
          :reference_no => self.reference_no,
          :amount => self.amount.to_f,
          :category_is_income => self.category.is_income,
          :is_waiver => self.is_waiver,
          :status => self.ledger_status || 'ACTIVE'
        })
    end
  end

  def build_over_all_receipt_cache
    begin
      self.transaction_ledger.generate_overall_receipt_cache
    rescue Exception => e
      puts "Error occurred in making overall receipt cache"
      puts e.inspect
    end
  end

  def verify_and_send_sms
    AutomatedMessageInitiator.fee_submission(self.transaction_ledger)  
  end

  def notify_users
    return unless ['FinanceFee', 'TransportFee', 'HostelFee'].include? finance_type
    return unless payee.respond_to? :user_id
    user_ids = [payee.user_id]

    if payee_type == 'Student'
      payee_identifier = payee.admission_no
      user_ids.push payee.immediate_contact.user_id if payee.immediate_contact
    elsif payee_type == 'Employee'
      payee_identifier = payee.employee_number
    end

    translate_options = {:amount => amount, :collections => get_collection.name, :payee_full_name => payee.full_name,
                         :payee_identifier => payee_identifier, :transaction_date => format_date(transaction_date)}

    body = transaction_ledger.is_waiver ? t('fee_transaction_waiver_notification', translate_options) :
              t('fee_transaction_notification', translate_options)

    inform(user_ids, body, 'CollectFee')
  end

  def set_transaction_stamp
    self.transaction_stamp = Time.now.to_i
  end

  def verify_precision
    unless finance_type == 'EmployeePayslip'
      self.amount = FedenaPrecision.set_and_modify_precision self.amount
      self.fine_amount = FedenaPrecision.set_and_modify_precision self.fine_amount
    end
  end

  def self.report(start_date, end_date, page)
    cat_names = ['Fee', 'Salary', 'Donation']
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "#{category[:category_name]}"
    end
    fixed_cat_ids = FinanceTransactionCategory.find(:all, :conditions => {:name => cat_names}).collect(&:id)
    self.find(:all,
      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id NOT IN (#{fixed_cat_ids.join(",")})"],
      :order => 'transaction_date')
  end

  def self.grand_total(start_date, end_date)
    fee_id = FinanceTransactionCategory.find_by_name("Fee").id
    donation_id = FinanceTransactionCategory.find_by_name("Donation").id
    cat_names = ['Fee', 'Salary', 'Donation']
    plugin_name = []
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "#{category[:category_name]}"
      plugin_name << "#{category[:category_name]}"
    end
    fixed_categories = FinanceTransactionCategory.find(:all, :conditions => {:name => cat_names})
    fixed_cat_ids = fixed_categories.collect(&:id)
    fixed_transactions = FinanceTransaction.find(:all,
      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id IN (#{fixed_cat_ids.join(",")})"])
    other_transactions = FinanceTransaction.find(:all,
      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id NOT IN (#{fixed_cat_ids.join(",")})"])
    #    transactions_fees = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id ='#{fee_id}'"])
    #    donations = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id ='#{donation_id}'"])
    trigger = FinanceTransactionTrigger.find(:all)
    hr = Configuration.find_by_config_value("HR")
    income_total = 0
    expenses_total = 0
    fees_total =0
    salary = 0

    unless hr.nil?
      salary = FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => start_date..end_date}).to_f
      expenses_total += salary
    end

    transactions_fees = fixed_transactions.reject { |tr| tr.category_id != fee_id }
    donations = fixed_transactions.reject { |tr| tr.category_id != donation_id }

    donations.each do |d|
      if d.master_transaction_id == 0
        income_total +=d.amount
      else
        expenses_total +=d.amount
      end

    end
    transactions_fees.each do |fees|
      income_total +=fees.amount
      fees_total += fees.amount
    end

    # plugin transactions
    plugin_name.each do |p|
      category = fixed_categories.reject { |cat| cat.name.downcase != p.downcase }
      unless category.blank?
        cat_id = category.first.id
        transactions_plugin = fixed_transactions.reject { |tr| tr.category_id != cat_id }
        transactions_plugin.each do |t|
          if t.category.is_income?
            income_total +=t.amount
          else
            expenses_total +=t.amount
          end
        end
      end
    end
    other_transactions.each do |t|
      if t.category.is_income? and t.master_transaction_id == 0
        income_total +=t.amount
      else
        expenses_total +=t.amount
      end
    end
    income_total-expenses_total

  end

#for generate csv report
  def self.fee_reciepts_export(parameters)
    data = []
    unless parameters[:search].present?
      @start_date=@end_date=FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    else
      @start_date=FinanceTransaction.date_fetch('start_date_as',parameters)
      @end_date=FinanceTransaction.date_fetch('end_date_as',parameters)
    end
    @search_parameters = parameters[:search] || Hash.new
    @search_parameters[:start_date_as] = @start_date
    @search_parameters[:end_date_as] = @end_date
    @search = FinanceTransaction.new.fetched_fee_receipts.search(@search_parameters)
    receipts=@search.all.concat AdvanceFeeCollection.fetch_advance_fees_receipts(@start_date, @end_date, @search_parameters)
    @fee_receipts = receipts.sort_by{|o| o.transaction_date.to_date}.reverse
    @grand_total = 0.00
    @fee_receipts.each {|f| @grand_total += f.amount.to_f }

    search_by_reciept_no = parameters[:start_date_as].present? or parameters[:end_date_as].present?
    data=[]
    cols=[]
    data << "Fee Reciepts"
    cols = []
    unless search_by_reciept_no
        cols << "Start Date"
        cols << @start_date
        data << cols
        cols = []
        cols << "End Date"
        cols << @end_date
        data << cols
        data << ""
        cols = []
      end

    col_heads=["#{t('receipt')}", "#{t('payee_name')}", "#{t('payee_type')}", "#{t('batch')} / #{t('department')}", "#{t('collection')}", "#{t('payment_date')}", "#{t('amount')}(#{Configuration.currency})", "#{t('payment_mode')}", "#{t('cashier')}(#{t('employee_text')})"]
    data << col_heads
    @fee_receipts.each do |fr|
        cols = []
        cols << fr.receipt_no
        if fr.payer_no.present?
          cols << "#{fr.payer_name}(#{fr.payer_no})"
        else
          cols << fr.payer_name
        end
        cols << fr.payer_type_info
        cols << (fr.payer_batch_dept.present? ? fr.payer_batch_dept : "-")
        cols << fr.collection_name
        cols << format_date(fr.transaction_date)
        cols << precision_label(fr.amount)
        if fr.reference_no.present?
          cols << "#{fr.payment_mode} - #{fr.reference_no}"
        else
          cols << fr.payment_mode
        end
        fr.payment_mode=='Online Payment' ? cols << fr.get_cashier_name : cols << fr.cashier_name
        cols=cols.flatten
        data << cols
    end
    data << ""
      cols=[]
      cols=["", "", "", "", "Total", "", "#{precision_label(@grand_total)}", "", ""]
      cols=cols.flatten
      data << cols
    return data

  end

  #for generating pdf report

  def self.fee_reciepts_export_to_pdf(parameters, opts)

    pdf = PdfMaker.new(parameters[:controller_name], parameters[:action_name])
    pdf.generate_pdf(parameters[:filename],opts ) do
      unless parameters[:search].present?
        @start_date=@end_date=FedenaTimeSet.current_time_to_local_time(Time.now).to_date
      else
        @start_date=FinanceTransaction.date_fetch('start_date_as',parameters)
        @end_date=FinanceTransaction.date_fetch('end_date_as',parameters)
      end
      @search_parameters = parameters[:search] || Hash.new
      @search_parameters[:start_date_as] = @start_date
      @search_parameters[:end_date_as] = @end_date
      @search = FinanceTransaction.new.fetched_fee_receipts.search(@search_parameters)
      receipts=@search.all.concat AdvanceFeeCollection.fetch_advance_fees_receipts(@start_date, @end_date, @search_parameters)
      @fee_receipts = receipts.sort_by{|o| o.transaction_date.to_date}.reverse
      @grand_total = 0.00
      @fee_receipts.each {|f| @grand_total += f.amount.to_f }
      @query=parameters[:query]
      @payment_mode_equals=@search.payment_mode_equals
      @reference_no_like=@search.reference_no_like
      @payee_type=parameters[:payee_type]
      @student_info= @search.student_info_like
      if @search.user_name_equals.present?
        user_name_equals=User.find_by_id(@search.user_name_equals.to_i)
        @name = user_name_equals.present? ? user_name_equals.full_name : "#{t('deleted_user')}"
      else
        @name = ""
      end
    end
  end

  def fetch_finance_batch
    batch = case self.finance_type
    when "TransportFee" then
      self.finance.groupable
    when "HostelFee" then
      self.finance.batch
    when "FinanceFee" then
      self.finance.batch
    when "InstantFee" then
      self.finance.groupable
    end
    batch
  end


  def get_collection
    collection_type = finance_type.underscore + "_collection"
    finance.send(collection_type)
  end

  def self.total_fees(start_date, end_date, filters = {})


    filter_conditions = filters[:conditions] || ""
    filter_values = filters[:values] || []
    joins = filters[:joins] || ""
    filter_select = filters[:select] || ""

    fee_id = FinanceTransactionCategory.find_by_name("Fee").id
    fees =[]
    fees = FinanceTransaction.find(:all,
      :joins => "#{joins} INNER JOIN batches on batches.id=finance_transactions.batch_id
                 INNER JOIN finance_fees on finance_fees.id=finance_transactions.finance_id and
                                            finance_transactions.finance_type='FinanceFee'",
      :conditions => ["finance_transactions.transaction_date >= '#{start_date}' and
                       finance_transactions.transaction_date <= '#{end_date}' and
                       finance_transactions.category_id='#{fee_id}' #{filter_conditions}"] + filter_values,
      :group => ["finance_fees.fee_collection_id,finance_transactions.batch_id"],
      :select => ["batches.*, SUM(finance_transactions.amount) as transaction_total,
                   finance_fees.fee_collection_id as collection_id ,batches.id as batch_id"])
    return fees
  end

  def self.total_other_trans(start_date, end_date, filters = {})
    filter_conditions = filters[:conditions] || ""
    filter_values = filters[:values] || []
    joins = filters[:joins] || ""

    cat_names = ['Fee', 'Salary', 'Donation']
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "#{category[:category_name]}"
    end
    fixed_cat_ids = FinanceTransactionCategory.find(:all, :conditions => {:name => cat_names}).collect(&:id)
    fees = 0
    transactions = FinanceTransaction.find(:all, :joins => joins,
     :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and
                      category_id NOT IN (#{fixed_cat_ids.join(",")}) #{filter_conditions}"] + filter_values)
    transactions_income = transactions.reject { |x| !x.category.is_income? }.compact
    transactions_expense = transactions.reject { |x| x.category.is_income? }.compact
    income = 0
    expense = 0
    transactions_income.each do |f|
      income += f.amount
    end
    transactions_expense.each do |f|
      expense += f.amount
    end
    [income, expense]
  end

  def self.donations_triggers(start_date, end_date, filters = {})
    filter_conditions = filters[:conditions] || ""
    filter_values = filters[:values] || []
    joins = filters[:joins] || ""
    filter_select = filters[:select] || ""
    donation_id = FinanceTransactionCategory.find_by_name("Donation").id
    FinanceTransaction.all(:select => "finance_transactions.amount #{filter_select}", :joins => joins,
      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'  and
                               category_id ='#{donation_id}' #{filter_conditions}"] + filter_values).map {|x| x.amount.to_f }.sum
  end


  def self.expenses(start_date, end_date)
    expenses = FinanceTransaction.find(:all, :select => 'finance_transactions.*', :joins => ' INNER JOIN finance_transaction_categories ON finance_transaction_categories.id = finance_transactions.category_id', \
        :conditions => ["finance_transaction_categories.is_income = 0 and finance_transaction_categories.id != 1 and transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'"])
    expenses=expenses.reject { |exp| (exp.category.is_fixed or exp.master_transaction_id != 0) }
  end

  def self.incomes(start_date, end_date)
    incomes = FinanceTransaction.find(:all,
      :select => 'finance_transactions.*',
      :joins => " INNER JOIN finance_transaction_categories
                          ON finance_transaction_categories.id = finance_transactions.category_id
                  INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND finance_transaction_categories.is_income = 1 and
                       transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}' "],
      :include => [:transaction_ledger,:category] )
    incomes = incomes.reject { |income| (income.category.is_fixed or income.master_transaction_id != 0) }
    incomes
  end


  def student_payee
    stu = self.payee
    stu ||= ArchivedStudent.find_by_former_id(self.payee_id)
  end

  def employee_payee
    stu = self.payee
    stu ||= ArchivedEmployee.find_by_former_id(self.payee_id)
  end

  def fetch_payee
    record = self.payee
    record ||= self.payee_type == "Employee" ? self.employee_payee : self.payee_type == "Student" ? self.student_payee : self.payee
  end

  def amount_with_precision
    return FedenaPrecision.set_and_modify_precision(self.amount)
  end


  def self.total_transaction_amount(transaction_category, start_date, end_date, filters = {})
    filter_conditions = filters[:conditions] || ""
    filter_values = filters[:values] || []
    joins = filters[:joins] || ""

    amount = 0
    finance_transaction_category = FinanceTransactionCategory.find_by_name("#{transaction_category}")
    category_type = finance_transaction_category.is_income ? "income" : "expense"
    transactions = FinanceTransaction.find(:all, :include => :category, :joins => joins,
      :conditions => ["transaction_date BETWEEN ? AND ? AND category_id = ? #{filter_conditions}",
        start_date, end_date, finance_transaction_category.id ] + filter_values)
    transactions.each { |transaction| amount += transaction.amount }
    return {:amount => amount, :category_type => category_type}
  end

  def self.get_refund_total_amount(cat, start_date, end_date)
    joins = "INNER JOIN fee_refunds fr ON fr.finance_transaction_id = finance_transactions.id
             INNER JOIN finance_fees ff ON ff.id = fr.finance_fee_id
             INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
              LEFT JOIN fee_accounts fa On fa.id = ffc.fee_account_id"
    cond = "(fa.id IS NULL OR fa.is_deleted = false) AND category_id = ? AND "
    FinanceTransaction.all(:select => "finance_transactions.amount", :joins => joins,
     :conditions => ["#{cond} transaction_date BETWEEN ? AND ?", cat.id, start_date, end_date]).map { |x| x.amount.to_f }.sum
  end

  def self.get_total_amount(category_name, date_range_1, date_range_2, options = {})
    cat_id=get_transaction_category(category_name)
    joins = options[:joins] || []
    conditions = options[:conditions] || ""
    conditions += " AND " if conditions.present?
    fees=FinanceTransaction.find(:first,
      :joins => joins,
      :conditions => ["#{conditions} finance_transactions.category_id = ? ", cat_id],
      :select => "ifnull(sum(case when transaction_date >= '#{date_range_1.first}' and transaction_date <= '#{date_range_1.last}' then finance_transactions.amount end),0)  as first,ifnull(sum(case when transaction_date >= '#{date_range_2.first}' and transaction_date <= '#{date_range_2.last}' then finance_transactions.amount end),0) as second")
    return fees
  end

  def self.get_transaction_category(category_type)
    cat_id=FinanceTransactionCategory.find_by_name(category_type).id
    return cat_id
  end

  #  def receipt_number_settings
  #    # 1 : single receipt number for multi
  #    # 0 : individual receipt number for respective finance transactions
  #    @receipt_number_settings ||= (Configuration.find_by_config_key 'SingleReceiptNumber').try(:to_i) || 1
  #  end

  #  def receipt_number
  #    if !FinanceTransactionReceipt.receipt_number_settings.zero? and multi_fees_transactions.present?
  #      multi_fees_transactions.last.finance_transaction_receipt.try(:receipt_number)
  #    else
  #      finance_transaction_receipt.try(:receipt_number)
  #    end
  #  end

  def fetch_template_id
    finance_transaction_receipt_record.fee_receipt_template_id
  end

  def receipt_data clear_cache = false
    # *** clear_cache should be only when needed to update transaction receipt cache data ***
    # TO DO :: fetch and return data hash
    #    _data = finance_transaction_receipt_record.try(:receipt_data) ||
    get_receipt_data clear_cache
    #    finance_transaction_receipt
  end

  def receipt_number
    # TO DO :: to be removed when seed is completed
    return "" unless transaction_receipt.present?
    (transaction_receipt.receipt_sequence || "") + transaction_receipt.receipt_number
    #    receipt_no.present? ? receipt_no : (
    #      (transaction_ledger.present? and
    #          transaction_ledger.transaction_mode == 'SINGLE') ? transaction_ledger.receipt_no : "")
  end

  def fetch_category_receipt_set

    (if self.finance_type == 'FinanceFee'
        self.finance.finance_fee_collection.fee_category
      else
        self.category
      end.try(:get_multi_config) || {})[:receipt_set]
  end

  def get_receipt_data clear_cache = false
    _data = finance_transaction_receipt_record.try(:receipt_data)
    if clear_cache or !_data.present?
      data_hash = get_student_fee_receipt_new({:transaction_ids => self.id,
          :particular_wise => self.particular_wise?, :include_tax => self.finance.respond_to?(:tax_collections)})
      _data = data_hash[self.id]
      finance_transaction_receipt_record.receipt_data = _data
      finance_transaction_receipt_record.save
    end
    _data
  end

  def add_voucher_or_receipt_number
    # trigger generation of reporting marker for all transactions other than finance fees & transport fees
    waiver_receipt_check = Configuration.receipt_number_disabled?
    TransactionReportSync.create_for_transaction(self) unless ['FinanceFee', 'TransportFee'].include?(self.finance_type)
    self.precision_count = FedenaPrecision.get_precision_count
    if self.category.is_income and self.master_transaction_id == 0
      unless self.transaction_receipt.present?
        receipt_set = self.fetch_category_receipt_set
        unless (self.is_waiver and waiver_receipt_check)
          self.transaction_receipt ||= TransactionReceipt.safely_create(receipt_set.is_a?(ReceiptNumberSet) ? receipt_set : nil)
        else
          self.build_finance_transaction_receipt_record
          self.save
        end

        #        self.transaction_receipt ||= TransactionReceipt.new({:receipt_number_set =>
        #              (receipt_set.is_a?(ReceiptNumberSet) ? receipt_set : nil)}) #TransactionReceipt.safely_create(receipt_set)
        #        self.save unless self.transaction_receipt.present?
      else
        # puts "exists or created"
        # puts self.transaction_receipt.inspect
      end
      #      if FinanceTransactionLedger.receipt_number_settings.zero?
      #        self.receipt_no = FinanceTransactionLedger.generate_receipt_no
      #        self.receipt_categories.present?
      #        self.transaction_receipt = FinanceTransactionLedger.generate_receipt_no
      #      end
    else
      last_transaction = FinanceTransaction.last(:conditions => "voucher_no IS NOT NULL and TRIM(voucher_no) not like ''")
      last_voucher_no = last_transaction.voucher_no unless last_transaction.nil?
      if last_voucher_no.present?
        voucher_split = last_voucher_no.to_s.scan(/[A-Z]+|\d+/i)
        if voucher_split[1].blank?
          voucher_number = voucher_split[0].next
        else
          voucher_number = voucher_split[0]+voucher_split[1].next
        end
      else
        voucher_number = "1"
      end
      self.voucher_no = voucher_number
      self.save
    end
  end

  def refund_receipt_no
    receipt_numbers = FinanceTransaction.search(:receipt_no_not_like => "refund").map { |f| f.receipt_no }
    last_no = receipt_numbers.map { |k| k.scan(/\d+$/i).last.to_i }.max
    last_transaction = FinanceTransaction.last(:conditions => ["receipt_no NOT LIKE '%refund%' and receipt_no LIKE ?", "%#{last_no}"])
    last_receipt_no = last_transaction.receipt_no unless last_transaction.nil?
    unless last_receipt_no.nil?
      receipt_split = /(.*?)(\d+)$/.match(last_receipt_no)
      if receipt_split[1].blank?
        receipt_number = receipt_split[2].next
      else
        receipt_number = receipt_split[1]+receipt_split[2].next
      end
    else
      config_receipt_no = Configuration.get_config_value('FeeReceiptNo')
      receipt_number = config_receipt_no.present? ? config_receipt_no : "1"
    end
    return receipt_number
  end

  def set_fine
    # balance=finance.balance+fine_amount-(amount)
    self.pay_all_manual_fine = true if self.transaction_type == 'MULTIPLE' and self.fine_amount.present? and self.fine_amount.to_f > 0

    if finance_type == "FinanceFee"
      balance = finance.balance
      manual_fine = fine_amount.present? ? fine_amount.to_f : 0
      fee_balance = balance
      actual_amount = balance + finance.finance_transactions.sum(:amount) - finance.finance_transactions.sum(:fine_amount)
      date = finance.finance_fee_collection
      days = (transaction_date - date.due_date.to_date).to_i
      auto_fine = date.fine
      total_fine_amount = 0
      if auto_fine.present?
        amount_to_be_fined = actual_amount
        amount_to_be_fined -= FedenaPrecision.set_and_modify_precision(finance.tax_amount).to_f if finance.tax_enabled
        fine_rule = auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"],
                                              :order => 'fine_days ASC')
        total_fine_amount = fine_rule.is_amount ? fine_rule.fine_amount : (amount_to_be_fined * fine_rule.fine_amount)/100 if fine_rule
        paid_fine = finance.finance_transactions.find(:all, :conditions => ["description=?", 'fine_amount_included']).
            map {|x| x.auto_fine.to_f > 0 ? x.auto_fine : x.fine_amount }.sum #(&:fine_amount)
        total_fine_amount = total_fine_amount - paid_fine
      end
      # actual_balance=FedenaPrecision.set_and_modify_precision(finance.balance+fine_amount).to_f
      actual_balance = FedenaPrecision.set_and_modify_precision(finance.balance).to_f +
          FedenaPrecision.set_and_modify_precision(total_fine_amount).to_f
      # apply precision to fix any rounding off issues
      actual_balance = FedenaPrecision.set_and_modify_precision(actual_balance).to_f
      amount_paying = (amount - manual_fine).to_f
      # apply precision to fix any rounding off issues
      amount_paying = FedenaPrecision.set_and_modify_precision(amount_paying).to_f
      actual_balance = 0 if FinanceFee.find(finance.id).is_paid

      if amount_paying > actual_balance and description != 'fine_amount_included'
        errors.add_to_base(t('finance.flash19'))
        return false
      elsif amount_paying > (actual_balance + total_fine_amount - manual_fine) and description == 'fine_amount_included'
        errors.add_to_base(t('finance.flash19'))
        return false
      end

      # set manual fine & auto fines being paid from amount paid
      # amount_paying (after taking off fine amount)
      # set fine_amount to manual_fine (manual fine)
      # find extra amount from remaining fee balance and set to auto_fine and add to fine_amount (additional to manual fine)
      # if fine includes auto fine set description to fine_amount_included

      auto_fine_being_paid = FedenaPrecision.set_and_modify_precision(amount_paying > fee_balance ? (amount_paying - fee_balance) : 0).to_f
      if auto_fine_being_paid > 0
        self.auto_fine = auto_fine_being_paid
        self.fine_amount = manual_fine + auto_fine_being_paid
        self.description = 'fine_amount_included' if auto_fine_being_paid > 0
      end
#      self.description = 'waived_fine_amount' if fine_waiver.present? && fine_waiver == "true"

      self.fine_included = true if self.fine_amount.to_f > 0

    end
  end

  def add_user
    if Fedena.present_user.present?
      update_attributes(:user_id => Fedena.present_user.id)
      if finance_type == "FinanceFee"

        update_attributes(:batch_id => "#{payee.batch_id}")
        FeeTransaction.create(:finance_fee_id => finance.id, :finance_transaction_id => id)

        # find full fee payable balance
        actual_fee_balance = finance.balance + finance.finance_transactions.sum(:amount) -
            finance.finance_transactions.sum(:fine_amount) - (amount - fine_amount)
        remaining_fee_balance = finance.balance - (amount - fine_amount)
        # puts "actual_fee_balance: #{actual_fee_balance}"
        # puts "remaining_fee_balance: #{remaining_fee_balance}"
        # find auto fine left to pay

        amount_to_be_fined = actual_fee_balance
        # puts "amount_to_be_fined: #{amount_to_be_fined}"
        amount_to_be_fined -= FedenaPrecision.set_and_modify_precision(finance.tax_amount).to_f if finance.tax_enabled
        # puts "amount_to_be_fined: #{amount_to_be_fined}"
        date = finance.finance_fee_collection
        days = (transaction_date - date.due_date.to_date).to_i
        auto_fine_rec = date.fine
        fine_amount = 0
        auto_fine_amount = 0
        actual_fine_amount = nil

        paid_fine = finance.finance_transactions.find(:all,
                                                        :conditions => ["finance_transactions.id < ? and description=?", id, 'fine_amount_included']).map do |x|
            x.auto_fine > 0 ? x.auto_fine : x.fine_amount
          end.sum



        fee_balance = remaining_fee_balance > 0 ? remaining_fee_balance : 0
        if Configuration.is_fine_settings_enabled? && finance.balance_fine.to_f > 0 &&  remaining_fee_balance == 0
          actual_fine_amount = finance.balance_fine + paid_fine
          auto_fine_amount = (amount > finance.balance)? (finance.balance_fine - (amount - finance.balance)) : finance.balance_fine
        elsif auto_fine_rec.present? and amount_to_be_fined > 0
          fine_rule = auto_fine_rec.fine_rules.find(:last, :order => 'fine_days ASC',
                                                :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"])
          auto_fine_amount = fine_rule.is_amount ? fine_rule.fine_amount :
              (amount_to_be_fined * fine_rule.fine_amount) / 100 if fine_rule
          actual_fine_amount = auto_fine_amount
          # auto_fine_amount = fine_amount

          auto_fine_amount = auto_fine_amount - paid_fine - auto_fine.to_f
        end
        track_fine_calculation(finance_type, auto_fine_amount, finance.id, id) if fine_waiver == true
        # paid_auto_fine = finance.finance_transactions.find(:all, :conditions => ["description=?", 'fine_amount_included']).
        #     map {|x| x.auto_fine.to_f > 0 ? x.auto_fine : x.fine_amount }.sum
        # puts "auto_fine_amount : #{auto_fine_amount}"
#        fee_balance = remaining_fee_balance > 0 ? remaining_fee_balance : 0
        # puts "fee_balance: #{fee_balance}"
        # puts "remaining_fee_balance: #{remaining_fee_balance}"
        auto_fine_amount_cond = (fine_waiver == true)? 0.0 : auto_fine_amount
        fee_paid = (remaining_fee_balance + auto_fine_amount_cond) <= 0
#        ======Check if Fine Settings enabled and is_fine_paid and balance_fine has values======
        unless Configuration.is_fine_settings_enabled?
        finance_fee_sql = "UPDATE `finance_fees`
                              SET `balance` = '#{fee_balance}',
                                                 `is_paid` = #{fee_paid},
                                                 `is_fine_waiver` = #{fine_waiver}
                                     WHERE `id` = '#{finance.id}'"

        else
          partial_fine = is_partial_fine_paid(fee_balance.to_f, actual_fine_amount.to_f, auto_fine_amount.to_f)
          balance_fine = check_balance_fine(fee_balance.to_f, auto_fine_amount.to_f, actual_fine_amount.to_f)
          finance_fee_sql = "UPDATE `finance_fees`
                              SET `balance` = '#{fee_balance}',
                                                 `is_paid` = #{fee_paid},
                                                 `is_fine_paid` = #{partial_fine},
                                                 `balance_fine` = #{balance_fine},
                                                 `is_fine_waiver` = #{fine_waiver}
                                     WHERE `id` = '#{finance.id}'"
        end
        ActiveRecord::Base.connection.execute(finance_fee_sql)

        # previous_fee_balance = finance.balance
        # balance = finance.balance + fine_amount - (amount)
        # if previous_fee_balance > 0
        #   fee_paid_amount = amount > previous_fee_balance  ? previous_fee_balance : amount # - previous_fee_balance)
        # else
        #   fee_paid_amount = 0
        # end
        #
        # fee_paid_amount = 0 if fee_paid_amount < 0
        # manual_fine = fine_amount.present? ? fine_amount.to_f : 0
        # fee_balance = balance
        #
        # actual_amount = balance + finance.finance_transactions.map do |x|
        #   x.amount - (x.tax_included ? x.tax_amount : 0).to_f
        # end.sum - finance.finance_transactions.sum(:fine_amount)
        #
        # if finance.tax_enabled?
        #   collected_tax_amount = finance.finance_transactions.sum(:tax_amount).to_f
        #   actual_amount -= (finance.tax_amount.to_f - collected_tax_amount)
        # end
        #
        # date = finance.finance_fee_collection
        # days = (transaction_date - date.due_date.to_date).to_i
        # auto_fine = date.fine
        # fine_amount = 0
        # if auto_fine.present?
        #   fine_rule=auto_fine.fine_rules.find(:last, :order => 'fine_days ASC',
        #                                       :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"])
        #   fine_amount = fine_rule.is_amount ? fine_rule.fine_amount :
        #       (actual_amount * fine_rule.fine_amount) / 100 if fine_rule
        #   auto_fine_amount = fine_amount
        #   paid_fine = finance.finance_transactions.find(:all,
        #                                                 :conditions => ["description=?", 'fine_amount_included']).map do |x|
        #     x.auto_fine > 0 ? x.auto_fine : x.fine_amount
        #   end.sum
        #   fine_amount = fine_amount - paid_fine
        # end
        # is_paid = false
        # balance = FedenaPrecision.set_and_modify_precision(balance).to_f
        # fine_amount = FedenaPrecision.set_and_modify_precision(fine_amount).to_f
        # if (balance <= 0)
        #   fee_balance = 0
        #   is_paid = (-(balance) == fine_amount)
        #
        #   self.full_fine_paid = (fine_amount <= 0)
        #   if -(balance) > 0
        #     if manual_fine > 0 # manual fine applied
        #       total_fine_paid = amount - fee_paid_amount
        #       auto_fine_amount = total_fine_paid - manual_fine
        #       if auto_fine_amount <= 0
        #         auto_fine_amount = nil
        #         set_description = ""
        #       else
        #         set_description = ", `description` = 'fine_amount_included'"
        #       end
        #       set_auto_fine = auto_fine_amount.present? ? "auto_fine = #{auto_fine_amount}," : ""
        #       sql = "UPDATE `finance_transactions`
        #                   SET `fine_amount` = #{total_fine_paid},
        #                          #{set_auto_fine}
        #                          `fine_included` = 1
        #                          #{set_description}
        #              WHERE `id` = #{id}"
        #
        #       ActiveRecord::Base.connection.execute(sql) if total_fine_paid > 0
        #     else # partial auto fine payment
        #       total_fine_paid = amount - fee_paid_amount
        #       auto_fine_amount = total_fine_paid > 0 ? total_fine_paid : 0
        #       sql = "UPDATE `finance_transactions`
        #                   SET `fine_amount` = #{auto_fine_amount},
        #                          `auto_fine` = #{auto_fine_amount},
        #                          `fine_included` = 1, `description` = 'fine_amount_included'
        #              WHERE `id` = #{id}"
        #
        #       ActiveRecord::Base.connection.execute(sql) if total_fine_paid > 0
        #     end
        #   end
        #
        # end
        # is_paid= ((balance.to_f==0.0) and (finance.finance_transactions.sum(:fine_amount).to_f) >= (fine_amount.to_f))
        # finance.update_attributes(:balance => fee_balance, :is_paid => is_paid)

        ## ONLY UPDATE FEE BALANCE AND STATUS ( is_paid true if completely paid including auto fine )

        # finance_fee_sql="UPDATE `finance_fees`
        #                                   SET `balance` = '#{fee_balance}',
        #                                          `is_paid` = #{is_paid}
        #                              WHERE `id` = '#{finance.id}'"
        #
        # ActiveRecord::Base.connection.execute(finance_fee_sql)
      elsif finance_type=="HostelFee"
        finance.update_attributes(:finance_transaction_id => id)
      elsif finance_type=="TransportFee"
        finance.update_attributes(:transaction_id => id)
      end

    end
  end

  # def _add_user
  #   if Fedena.present_user.present?
  #     update_attributes(:user_id => Fedena.present_user.id)
  #     if finance_type=="FinanceFee"
  #       #        update_attributes(:batch_id => "#{payee.batch_id}")
  #       FeeTransaction.create(:finance_fee_id => finance.id, :finance_transaction_id => id)
  #       balance=finance.balance+fine_amount-(amount)
  #       manual_fine= fine_amount.present? ? fine_amount.to_f : 0
  #       fee_balance=balance
  #       actual_amount=balance+finance.finance_transactions.sum(:amount)-
  #         finance.finance_transactions.sum(:fine_amount)
  #
  #       actual_amount -= finance.tax_amount.to_f if finance.tax_enabled?
  #
  #       actual_amount += finance.finance_transactions.sum(:tax_amount).to_f if finance.tax_enabled?
  #
  #       date=finance.finance_fee_collection
  #       days=(transaction_date-date.due_date.to_date).to_i
  #       auto_fine=date.fine
  #       fine_amount=0
  #       if auto_fine.present?
  #         fine_rule=auto_fine.fine_rules.find(:last, :order => 'fine_days ASC',
  #           :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"])
  #         fine_amount = fine_rule.is_amount ? fine_rule.fine_amount :
  #           (actual_amount * fine_rule.fine_amount) / 100 if fine_rule
  #         auto_fine_amount = fine_amount
  #
  #         paid_fine = finance.finance_transactions.find(:all,
  #           :conditions => ["description=?", 'fine_amount_included']).map do |x|
  #           x.auto_fine > 0 ? x.auto_fine : x.fine_amount
  #         end.sum #sum(&:fine_amount)
  #         fine_amount=fine_amount-paid_fine
  #       end
  #       is_paid=false
  #       balance=FedenaPrecision.set_and_modify_precision(balance).to_f
  #       fine_amount= FedenaPrecision.set_and_modify_precision(fine_amount).to_f
  #
  #       if (balance <= 0)
  #         fee_balance = 0
  #         is_paid = (-(balance) == fine_amount)
  #         self.full_fine_paid = (fine_amount <= 0)
  #         if -(balance)>0
  #           # self.fine_amount=-(balance)+manual_fine
  #           # self.fine_included=true
  #           # self.description="fine_amount_included"
  #           auto_fine_amount=nil unless is_paid
  #           sql="UPDATE `finance_transactions`
  #                          SET `fine_amount` = '#{-(balance)+manual_fine}',
  #                                 `auto_fine`='#{auto_fine_amount}',
  #                                 `fine_included` = 1,
  #                                 `description` = 'fine_amount_included'
  #                     WHERE `id` = #{id}"
  #           # self.save(false)
  #           ActiveRecord::Base.connection.execute(sql)
  #         end
  #       end
  #       # is_paid= ((balance.to_f==0.0) and (finance.finance_transactions.sum(:fine_amount).to_f) >= (fine_amount.to_f))
  #       # finance.update_attributes(:balance => fee_balance, :is_paid => is_paid)
  #       finance_fee_sql="UPDATE `finance_fees`
  #                                         SET `balance` = '#{fee_balance}',
  #                                                `is_paid` = #{is_paid}
  #                                    WHERE `id` = '#{finance.id}'"
  #
  #       ActiveRecord::Base.connection.execute(finance_fee_sql)
  #     elsif finance_type=="HostelFee"
  #       finance.update_attributes(:finance_transaction_id => id)
  #     elsif finance_type=="TransportFee"
  #       finance.update_attributes(:transaction_id => id)
  #     end
  #
  #   end
  # end

  def self.total(trans_id, fees)
    paid_fees = FinanceTransaction.find(:all, :conditions => "FIND_IN_SET(id,\"#{trans_id}\")", :order => "created_at ASC")
    total_fees=fees
    paid=0
    fine=0
    paid_fees.each do |p|
      paid += p.amount.to_f
      fine += p.fine_amount.to_f
    end
    total_fees =total_fees-paid
    total_fees =total_fees+fine
    #return @total_fees
  end

  def currency_name
    Configuration.currency
  end

  def date_of_transaction
    format_date(self.transaction_date, :format => :long)
  end

  def safely_create
    begin
      retries ||= 0
      return self.save
    rescue ActiveRecord::StatementInvalid => ex
      retry if (retries += 1) < 2
      raise ex
      #      return false
    end
  end

  def self.fetch_finance_payslip_data(params)
    finance_payslip_data(params)
  end

  def self.fetch_finance_transaction_data(params)
    finance_transaction_data(params)
  end

  def self.fetch_finance_tax_data(params)
    finance_tax_data(params)
  end

  def self.fetch_finance_batch_fee_transaction_data(params)
    finance_batch_fees_transaction_data(params)
  end

  def self.fetch_compare_finance_transactions_date(params)
    compare_finance_transactions_date(params)
  end

  def self.fetch_salary_with_department_data(params)
    salary_with_department_data(params)
  end

  def self.fetch_income_data(params)
    income_details_csv(params)
  end

  def create_cancelled_transaction
    trs = self.transaction_report_sync
    transaction_ledger.mark_cancelled(self.cancel_reason, "PARTIAL")
#    finance_transaction_attributes=self.attributes.except('id','created_at', 'updated_at','multi_fees_transaction_id')
# => Modified existing and excluded fine waiver attribute from finance transaction to delete the record
    finance_transaction_attributes=self.attributes.except('id','created_at', 'updated_at','multi_fees_transaction_id','fine_waiver')
    finance_transaction_attributes.merge!(:cancel_reason => self.cancel_reason)
    if finance_type=='FinanceFee'
      balance=finance.balance+(amount-fine_amount)
      finance.update_attributes(:is_paid => false, :balance => balance)

#     ==== Balance fine and Is fine paid will be calculated only for auto fine ==========
      actual_fee = finance.balance + finance.finance_transactions.sum(:amount) - finance.finance_transactions.sum(:fine_amount) - (amount - fine_amount)
      date = finance.finance_fee_collection
      days = (finance_transaction_attributes["transaction_date"] - date.due_date.to_date).to_i
      auto_fine_rec = date.fine
      auto_fine_amount = 0
      if auto_fine_rec.present?
        fine_rule = auto_fine_rec.fine_rules.find(:last, :order => 'fine_days ASC',
                                                :conditions => ["fine_days <= '#{days}' and created_at <= '#{date.created_at}'"])
        auto_fine_amount = fine_rule.is_amount ? fine_rule.fine_amount :
              (actual_fee * fine_rule.fine_amount) / 100 if fine_rule
      end
      if balance > 0
        balance_fine = nil
      else
        balance_fine = finance_transaction_attributes["auto_fine"].to_f + finance.balance_fine.to_f
      end
      fine_val = false
      if auto_fine_amount > 0 && balance_fine.present?
        balance_fine > 0 ? balance_fine == auto_fine_amount ? fine_val = false : fine_val = true : fine_val =true
      else
        fine_val = false
      end
      finance.update_attributes(:is_paid => false, :balance => balance, :balance_fine => balance_fine , :is_fine_paid => fine_val, :is_fine_waiver => false)

      remove_tracked_fine(finance.id, finance_type)
      FeeTransaction.destroy_all({:finance_transaction_id => id})
    end
    if finance.present? and ["FinanceFee", "HostelFee", "TransportFee", "InstantFee"].include? finance_type
      collection_name=finance.name
      finance_type_name=finance_type
    else
      if category_name=='Refund' and fee_refund.present? and fee_refund.finance_fee.present?
        collection_name=fee_refund.finance_fee.name
      else
        collection_name=nil
      end
      finance_type_name=category_name
    end
    finance_transaction_attributes.merge!(:user_id => Fedena.present_user.id, :finance_type => finance_type_name, :collection_name => collection_name)
    #    finance_transaction_attributes.delete "id"
    #    finance_transaction_attributes.delete "created_at"
    #    finance_transaction_attributes.delete "updated_at"
    #    finance_transaction_attributes.delete "multi_fees_transaction_id"
    finance_transaction_attributes.delete "finance_transaction_id"
    dependend_destroy_models=FinanceTransaction.reflect_on_all_associations.select { |a| a.options[:dependent]==:destroy }.map { |d| d.name }
    other_details={}
    dependend_destroy_models.each do |ddm|
      if instance_eval(ddm.to_s).respond_to? 'fetch_other_details_for_cancelled_transaction'
        other_details=instance_eval(ddm.to_s).fetch_other_details_for_cancelled_transaction
      end
    end
    finance_transaction_attributes.merge!(:other_details => other_details, :finance_transaction_id => id)
    if FedenaPlugin.can_access_plugin? :fedena_tally
      finance_transaction_attributes.merge!(:lastvchid => -(lastvchid.to_i.abs))
    end
    cancelled_transaction=CancelledFinanceTransaction.new(finance_transaction_attributes)
    #    cancelled_transaction.build_finance_transaction_receipt(finance_transaction_receipt_attributes.
    #        except('id','created_at','deleted_at').
    #        merge({:is_cancelled_transaction => true})) if finance_transaction_receipt_attributes.present?
    cancelled_transaction.save
    ## create sync marker only if transaction being reverted is already synced to MasterParticularReport
    unless trs.present?
      TransactionReportSync.create_for_transaction(cancelled_transaction)
    else
      # delete particular payments and particular discounts
      cancelled_transaction.delete_inactive_finance_payment_data(true) #particular_payments(true)
    end
  end

  def refund_check
    if finance_type=='FinanceFee'
      return finance.fee_refund.blank?
    elsif finance_type=="TransportFee"
      finance.update_attributes(:transaction_id => nil)
    elsif finance_type=="HostelFee"
      finance.update_attributes(:finance_transaction_id => nil)
    end
  end

  def cashier_name
    user.present? ? user.full_name : "#{t('deleted_user')}"
  end

  def get_cashier_name
    user.present? ? ((user.user_type == "Parent" or user.user_type == "Student") ? '': user.full_name ) : " "
  end

  def particular_wise?
    trans_type=="particular_wise"
  end

  def is_partial_fine_paid(fee_balance, actual_fine, auto_fine)
    fine_val = false
    if fee_balance == 0 && actual_fine.present?
      auto_fine > 0 ? auto_fine == actual_fine ? fine_val = false : fine_val = true : fine_val =true
    else
     fine_val = false
    end
    return fine_val
  end

  def check_balance_fine(fee_balance, auto_fine, actual_fine)
    fee_balance > 0 && !actual_fine.present? ? balance_val = nil : balance_val = auto_fine
    return balance_val
  end

  def track_fine_calculation(finance_type, amount, finance_id, transaction_id = nil)
    user_id = Fedena.present_user.id
    date = format_date(Date.today_with_timezone.to_date, :format => :long)
    FineCancelTracker.create(:user_id=> user_id, :amount => amount, :date=>date, :finance_id => finance_id, :finance_type => finance_type, :transaction_id=> transaction_id)
  end

  def remove_tracked_fine(finance_id, finance_type)
    @fine_tracker = FineCancelTracker.find_by_finance_id_and_finance_type(finance_id,finance_type)
    @fine_tracker.destroy if @fine_tracker.present?
  end
  
  # updating advance fee before destroy transaction
  def update_advance_fee_wallet
    if self.wallet_amount_applied == true
      AdvanceFeeDeduction.destroy_deduction_record(self.id)
      advance_fee_wallet = self.payee.advance_fee_wallet
      advance_fee_wallet.amount = advance_fee_wallet.amount.to_f + self.wallet_amount.to_f
      advance_fee_wallet.save
    end
  end

  private

  def check_receipt_number_in_cancel_transaction(receipt_number)
    cancel_transaction = CancelledFinanceTransaction.find_last_by_receipt_no(receipt_number)
    if cancel_transaction.nil?
      return receipt_number
    else
      data = /(.*?)(\d*)$/.match(receipt_number.to_s)
      receipt_number = data[1].to_s + data[2].next.to_s
      check_receipt_number_in_cancel_transaction(receipt_number)
    end
  end

  def check_data_correctnes
    self.finance.present?
  end

  def transactions_with_similar_receipt_number(config_receipt_num_prefix)
    FinanceTransaction.all(:conditions => " receipt_no IS NOT NULL and receipt_no REGEXP '(#{config_receipt_num_prefix})\d*' and receipt_no NOT LIKE 'refund%'")
  end

  def check_receipt_number_existance(next_receipt_number)
    updated_receipt_number = check_receipt_number_in_cancel_transaction(next_receipt_number)
    FeeReceiptLock.receipt_no(updated_receipt_number)
  end

  def is_available_in_cache?
    !FeeReceiptLock.cache_has_receipt_no?
  end

  def calculate_receipt_number
    config_receipt_no_format = Configuration.get_config_value('FeeReceiptNo').nil? ? "" : Configuration.get_config_value('FeeReceiptNo').delete(' ')
    config_receipt_number = /(.*?)(\d*)$/.match(config_receipt_no_format)
    config_receipt_num_prefix = config_receipt_number[1] =~ /^\d+$/ ? "" : config_receipt_number[1]
    config_receipt_num_sufix = config_receipt_number[2].to_i
    if config_receipt_num_prefix.present?
      finance_transactions = transactions_with_similar_receipt_number(config_receipt_num_prefix)
      if finance_transactions.present?
        last_receipt_number = finance_transactions.map { |k| k.receipt_no.scan(/\d+$/i).last.to_i }.max
        next_receipt_no_sufix = last_receipt_number > config_receipt_num_sufix ? last_receipt_number : config_receipt_num_sufix
        next_receipt_number = config_receipt_num_prefix + next_receipt_no_sufix.next.to_s
      else
        next_prefix = config_receipt_num_sufix.present? ? config_receipt_num_sufix : 0
        next_receipt_number = config_receipt_num_prefix + next_prefix.to_s
      end
    else
      #code for manage no prefix(string) condition
      finance_transactions = FinanceTransaction.search(:receipt_no_not_like => "refund", :receipt_no_greater_than => config_receipt_num_sufix.to_i).all
      if finance_transactions.present?
        last_receipt_number = finance_transactions.map { |k| k.receipt_no.to_i }.max
        # to find maximum value of receipt no
        next_receipt_number = last_receipt_number.next
      else
        # for the first transaction it will count from 1  else it will count from suffix.
        next_receipt_number = config_receipt_num_sufix.present? ? config_receipt_num_sufix.next : 1
      end
    end
    next_receipt_number
  end

  def add_particular_amount
    allocate_amount_to_particulars=AllocateAmountToParticulars.new(self, self.finance)
    allocate_amount_to_particulars.save_allocation
    receipt_data if trans_type == "particular_wise" and finance_type == "FinanceFee" # trigger cache generation for particular wise
    # trigger for all fees paid ( other than particular wise paid )
    TransactionReportSync.create_for_transaction(self) if trans_type != "particular_wise" and finance_type == "FinanceFee"
  end

  def verify_fine_amount
    self.fine_amount = (fine_amount > amount) ? amount : fine_amount
  end

  def fetch_report_marker
    trs = self.transaction_report_sync
  end

    #to fetch start and end date for fee receipt search
  def self.date_fetch(type,parameters)
      parameters[type.to_sym].try(:to_date) || parameters[:search][type.to_sym].try(:to_date) ||
      FedenaTimeSet.current_time_to_local_time(Time.now).to_date
  end

  # update finance transaction mode (if wallet amount used) 
  def update_transation_mode
    if self.payment_mode != "Advance Fees"
      self.payment_mode = self.payment_mode + " and "+t('advance_fees_text')
      self.transaction_ledger.update_attributes(:payment_mode => self.payment_mode)
    end
  end

  # update wallet amount if amount used in finance transaction
  def update_advance_fee_status
    if self.wallet_amount_applied
      student = Student.find_by_id(self.payee_id)
      advance_fee_wallet = student.advance_fee_wallet
      effective_amount = advance_fee_wallet.amount - self.wallet_amount
      if advance_fee_wallet.update_attributes(:amount => effective_amount)
        advance_fee_deduction = AdvanceFeeDeduction.new(:amount => self.wallet_amount,
                                :deduction_date => Date.today,
                                :student_id => student.id,
                                :finance_transaction_id => self.id)
        # transaction_ledger = self.transaction_ledger
        # transaction_ledger.amount = self.amount.to_f
        # transaction_ledger.save
        if advance_fee_deduction.save
          return true
        else
          return false
        end
      end
    end
  end


  # handle advance fee wallet amount nil case
  def handle_wallet_amount
    self.wallet_amount_applied = false if self.wallet_amount_applied.nil?
    self.wallet_amount = 0.to_f if self.wallet_amount.nil?
  end

  # fetch batch wise wallet expense report
  def self.fetch_batch_wise_expense_report_wallet(batch_id, start_date, end_date, page)
    transactions = FinanceTransaction.all(:joins => "INNER JOIN finance_transaction_receipt_records on finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id
    INNER JOIN transaction_receipts on transaction_receipts.id = finance_transaction_receipt_records.transaction_receipt_id
    INNER JOIN students on students.id = finance_transactions.payee_id
    INNER JOIN batches on students.batch_id = batches.id",
    :conditions => ['finance_transactions.transaction_date between ? and ? and batches.id = ? and finance_transactions.payee_type = ? and finance_transactions.wallet_amount_applied = true ',
                start_date, end_date, batch_id, 'Student'],
    :select => "finance_transactions.wallet_amount as amount, finance_transactions.transaction_date as transaction_date,
                students.id as student_id, finance_transactions.payment_mode as payment_mode, finance_transactions.payment_note as payment_note, CONCAT(IFNULL(transaction_receipts.receipt_sequence, '')
                ,transaction_receipts.receipt_number) AS receipt_no").paginate(:page => page, :per_page => 10)
    return transactions
  end

end
