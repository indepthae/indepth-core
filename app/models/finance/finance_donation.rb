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

class FinanceDonation < ActiveRecord::Base
  belongs_to :transaction, :class_name => 'FinanceTransaction'
  validates_presence_of :donor, :amount
  validates_numericality_of :amount, :greater_than => 0, :message =>:should_be_non_zero, :unless => "amount.nil?"

  after_create :create_finance_transaction
  #  after_create :create_finance_transaction
  before_save :verify_precision
  has_many   :donation_additional_details, :dependent => :destroy
  accepts_nested_attributes_for :donation_additional_details, :reject_if => lambda { |a| a[:content].blank? }, :allow_destroy => true

  before_create :set_financial_year

  def set_financial_year
    self.financial_year_id = FinancialYear.current_financial_year_id
  end

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end

  def create_finance_transaction
    transaction = FinanceTransaction.create(
      :title => "#{t('donation_from')}" + donor,
      :description => description,
      :amount => amount,
      :transaction_date => transaction_date,
      :finance_type => "FinanceDonation",
      :finance_id => self.id,
      :category => FinanceTransactionCategory.find_by_name('Donation')
    )
    self.transaction_id = transaction.id
    self.send(:update_without_callbacks)
  end
  
  def self.donors_list(params)
    conditions = []
    conds = "(ftrr.fee_account_id IS NULL OR fa.is_deleted = false) "
    if params.present?
      conditions << "#{conds} AND finance_donations.transaction_date BETWEEN ? AND ?"
      conditions << params[:from].to_date.beginning_of_day
      conditions << params[:to].to_date.end_of_day
    else
      conditions << conds
    end

    @donations = FinanceDonation.all(:include => {:transaction => :transaction_receipt}, :conditions => conditions,
        :joins => "INNER JOIN finance_transactions ft ON ft.finance_type = 'FinanceDonation' AND ft.finance_id = finance_donations.id
                   INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id", :order => "created_at ASC")
    data = []
    @addional_field_titles = DonationAdditionalField.all( :select => :name, :conditions => "status = true",
      :order => :priority)
    
    col_heads = ["#{t('donor')}", "#{t('description')}", "#{t('amount')}", "#{t('receipt_no')}",
      "#{t('transaction_date')}"]
    
    col_heads += @addional_field_titles.collect(&:name)
    data << col_heads
    @donations.each_with_index do |c,i|
      @additional_details = c.donation_additional_details.find(:all, :include => [:donation_additional_field],
        :order => "donation_additional_fields.priority ASC")
      col = []
      col << "#{c.donor}"
      col << "#{c.description}"
      col << "#{FedenaPrecision.set_and_modify_precision(c.amount)}"
      col << "#{c.transaction.receipt_number}"
      col << "#{format_date(c.transaction_date)}"
      col += @additional_details.collect(&:additional_info)
      col = col.flatten
      data << col
    end
    return data
  end

  def fetch_other_details_for_cancelled_transaction
    {:payee_name=>donor}
  end

end
