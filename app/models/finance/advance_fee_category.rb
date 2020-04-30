class AdvanceFeeCategory < ActiveRecord::Base
  belongs_to :financial_year
  has_many :advance_fee_category_batches
  has_many :batches, :through => :advance_fee_category_batches

  # accepts_nested_attributes_for :advance_fee_category_batches
  has_many :advance_fee_category_collections
  has_many :advance_fee_collections, :through => :advance_fee_category_collections


  has_many :advance_fee_collections

  validates_presence_of :name, :financial_year_id
  validates_uniqueness_of :name, :scope => [:financial_year_id , :is_deleted], :if => Proc.new {|x| x.new_record? or x.name_changed? }

  # fetch all batches by filter
  def fetch_batches_by_collection(start_date, end_date, category_id, account_id)
    conditions = []
    conditions << "AND advance_fee_transaction_receipt_records.fee_account_id IS NULL" if account_id == "0"
    conditions << "AND advance_fee_transaction_receipt_records.fee_account_id = '#{account_id}'" if (account_id != "0" && account_id != "") && !account_id.nil?
    conditions << nil if account_id.nil?
    advance_fee_categories = AdvanceFeeCategoryCollection.all(:joins => [:advance_fee_category, [:advance_fee_collection => [:advance_fee_transaction_receipt_record, [:student => [:batch => [:course]]]]]],
      :conditions => ["advance_fee_category_collections.advance_fee_category_id = ? and (advance_fee_collections.date_of_advance_fee_payment BETWEEN ? and ?) #{conditions}", category_id, start_date, end_date],
      :select => "sum(advance_fee_category_collections.fees_paid) as amount, courses.course_name as course_name, courses.id as course_id, batches.name as batch_name, batches.id as batch_id, advance_fee_collections.user_id", 
      :group => "batches.id")
    return advance_fee_categories
  end

  # calculate total amount paid by advance fee category
  def calculate_total_amount_by_category(adfc_id, start_date, end_date)
    sql_for_fetching_category_amount = "select sum(fees_paid) as amount from advance_fee_collections as adfc
    where advance_fee_category_id = #{adfc_id} and date_of_advance_fee_payment between '#{start_date}' and '#{end_date}'"
    total_received_amount = ActiveRecord::Base.connection.execute(sql_for_fetching_category_amount)
    return total_received_amount.all_hashes[0]["amount"]
  end

  # checking the advance fee category dependancy
  def check_is_deletable
    is_deletable = (AdvanceFeeCategoryCollection.all.collect(&:advance_fee_category_id).include? self.id) ? false : true
  end

  # find the editable batches of advance fee category
  def check_the_batches_editable(adfc_id)
    batches = AdvanceFeeCategoryCollection.all(:select => "batches.id as batch_id", 
    :joins => "INNER JOIN advance_fee_collections on advance_fee_collections.id = advance_fee_category_collections.advance_fee_collection_id 
    INNER JOIN students on students.id = advance_fee_collections.student_id 
    INNER JOIN batches on batches.id = students.batch_id", 
    :conditions => {:advance_fee_category_id => adfc_id.to_i}, :group => 'batches.id')
    batches.collect(&:batch_id)
  end

  # batch status
  def batch_status(adfc_id, b_id)
    batch = AdvanceFeeCategoryBatch.find(:first, :conditions => {:advance_fee_category_id => adfc_id, :batch_id => b_id})
    batch.present? ? ((batch.is_active ? true : false)) : false
  end

  # batch validation
  def validate_category_batches(params)
    params.values.each do |b|
      batch = AdvanceFeeCategoryBatch.find_by_advance_fee_category_id_and_batch_id(b["advance_fee_category_id"], b["batch_id"])
      if batch
        batch.update_attributes(:is_active => b["is_active"])
      else
        AdvanceFeeCategoryBatch.create(b) if b["is_active"] == "true"
      end
    end
  end

  # advance fees transaction comparison
  def self.comparison_for_advance_fees(start_date, end_date, start_date_2, end_date_2, account_id)
    dy_condition_c = []
    dy_condition_c << 'AND advance_fee_transaction_receipt_records.fee_account_id is null' if account_id == "0"
    dy_condition_c << "AND advance_fee_transaction_receipt_records.fee_account_id = #{account_id}" if (!account_id.nil? && account_id != false && account_id != "" ) && !account_id.nil?
    dy_condition_c << nil if account_id.nil?
    w_c_amount, w_c_amount2, w_d_amount, w_d_amount2 = 0.00
    w_c_amount = AdvanceFeeCollection.all(:joins => [:advance_fee_transaction_receipt_record], :select => "sum(advance_fee_collections.fees_paid) as amount", 
    :conditions => ["date_of_advance_fee_payment >= ? and date_of_advance_fee_payment <= ?  #{(dy_condition_c unless dy_condition_c.nil?)}", start_date, end_date ]).first.amount
    w_c_amount2 = AdvanceFeeCollection.all(:joins => [:advance_fee_transaction_receipt_record], :select => "sum(advance_fee_collections.fees_paid) as amount", 
    :conditions => ["date_of_advance_fee_payment >= ? and date_of_advance_fee_payment <= ?  #{(dy_condition_c unless dy_condition_c.nil?)}", start_date_2, end_date_2 ]).first.amount
    w_d_amount = AdvanceFeeDeduction.all(:joins => [[:finance_transaction => [:finance_transaction_receipt_record]]], :select => "sum(advance_fee_deductions.amount) as amount", 
    :conditions => ["deduction_date >= ? and deduction_date <= ?", start_date, end_date ]).first.amount
    w_d_amount2 = AdvanceFeeDeduction.all(:joins => [[:finance_transaction => [:finance_transaction_receipt_record]]], :select => "sum(advance_fee_deductions.amount) as amount", 
    :conditions => ["deduction_date >= ? and deduction_date <= ? ", start_date_2, end_date_2 ]).first.amount
    #{(dy_condition_d unless dy_condition_d.nil?)}
    return (w_c_amount.nil? ? 0.00 : w_c_amount), (w_c_amount2.nil? ? 0.00 : w_c_amount2), (w_d_amount.nil? ? 0.00 : w_d_amount), (w_d_amount2.nil? ? 0.00 : w_d_amount2)
  end
end
