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

class FinanceTransactionCategory < ActiveRecord::Base
  has_many :finance_transactions, :class_name => 'FinanceTransaction', :foreign_key => 'category_id'
  has_one :trigger, :class_name => "FinanceTransactionTrigger", :foreign_key => "category_id"

  has_one :finance_category_account, :as => :category
  has_one :fee_account, :through => :finance_category_account, :class_name => "FeeAccount"

  has_one :finance_category_receipt_set, :as => :category
  has_one :receipt_number_set, :through => :finance_category_receipt_set, :class_name => "ReceiptNumberSet"

  has_one :finance_category_receipt_template, :as => :category
  has_one :fee_receipt_template, :through => :finance_category_receipt_template, :class_name => "FeeReceiptTemplate"

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false, :scope => :deleted, :if => 'deleted == false'
  #  validate :validate_category_name

  before_update :check_is_income
  before_save :validate_category_name, :if => lambda { |x| x.name_changed? }

  named_scope :expense_categories, :conditions => "is_income = false AND name NOT LIKE 'Salary'and deleted = 0"
  # named_scope :income_categories, :conditions => "is_income = true AND name NOT IN ('Fee','Salary','Donation','Library','Hostel','Transport') and deleted = 0"

  #  def self.expense_categories
  #    FinanceTransactionCategory.all(:conditions => "is_income = false AND name NOT LIKE 'Salary'")
  #  end
  #
  #  def self.income_categories
  #    FinanceTransactionCategory.all(:conditions => "is_income = true AND name NOT LIKE 'Fee' AND name NOT LIKE 'Donation'")
  #  end

  TRANSACTION_CATEGORIES = {
      "Applicant Registration" => {:plugin_name => "fedena_applicant_registration"},
      "Donation" => {},
      "Fee" => {},
      "Hostel" => {:plugin_name => "fedena_hostel"},
      "InstantFee" => {:plugin_name => "fedena_instant_fee"},
      "Inventory" => {:plugin_name => "fedena_inventory"},
      "Library" => {:plugin_name => "fedena_library"},
      "Refund" => {},
      "Salary" => {},
      "SalesInventory" => {:plugin_name => "fedena_inventory"},
      "Transport" => {:plugin_name => "fedena_transport"},
      "Dummy" => {},
      "Advance Fees Credit" => {},
      "Advance Fees Debit" => {}
  }

  MULTI_CONFIGS = ['MultiReceiptNumberSetEnabled', 'MultiReceiptTemplateEnabled', 'MultiFeeAccountEnabled']

  def validate_category_name
    restricted_names = TRANSACTION_CATEGORIES.keys

    unless new_record?
      errors.add(:name, :reserved_name) if restricted_names.include?(name)
    else
      errors.add(:name, :reserved_name) if name_was != name and restricted_names.include?(name)
    end
  end

  #  def verify_reserved_names
  #    
  #  end

  def self.get_multi_configuration configs = nil
    configs ||= Configuration.get_multiple_configs_as_hash MULTI_CONFIGS
    return {} unless configs.select { |k, v| v.to_i == 1 }.present?
    {
        :account => configs[:multi_fee_account_enabled].to_i == 1,
        :template => configs[:multi_receipt_template_enabled].to_i == 1,
        :receipt_set => configs[:multi_receipt_number_set_enabled].to_i == 1
    }
  end

  def get_multi_config args = {} #configs = nil, fee_category = nil
    configs = args[:configs]
    fee_category = args[:fee_category]
    collection = args[:collection]
    # if transaction category is expense
    return {} unless self.is_income
    configs ||= Configuration.get_multiple_configs_as_hash MULTI_CONFIGS
    # if all settings are disabled
    return {} unless configs.select { |k, v| v.to_i == 1 }.present?
    config = {
        :template => configs[:multi_receipt_template_enabled].to_i == 1 ? (fee_category.present? ?
            fee_category.fee_receipt_template : self.fee_receipt_template) || true : false,
        :receipt_set => configs[:multi_receipt_number_set_enabled].to_i == 1 ? (fee_category.present? ?
            fee_category.receipt_number_set : self.receipt_number_set) || true : false,
    }

    config[:account] = (
    if collection.present?
      collection.fee_account_id # works good for finance fee / hostel fee / transport fee (as only these have collections)
    elsif fee_category.present?
      (configs[:multi_fee_account_enabled].to_i == 1 ? (fee_category.fee_account.try(:id) || true) : false)
    else
      (configs[:multi_fee_account_enabled].to_i == 1 ? self.fee_account.try(:id) || true : false)
    end)

    config.select { |k, v| v != false }.present? ? config : {}
  end

  def save_configuration config_data
    configs = self.class.get_multi_configuration
    return [false, "multi_config_disabled"] unless configs.present?
    @fee_category = FinanceFeeCategory.find(config_data[:fee_category]) if config_data[:fee_category].present?

    if name == 'Fee'
      return [false, "fee_category_not_found", nil] unless @fee_category.present?
      category = @fee_category
    else
      category = self
    end

    if configs[:account].present?
#      return [false, "fee_account_not_selected"] unless config_data[:account].present?
      category.fee_account = config_data[:account].present? ? FeeAccount.find(config_data[:account]) : nil
    end

    if configs[:receipt_set].present?
#      return [false, "fee_receipt_set_not_selected"] unless config_data[:receipt_set].present?
      category.receipt_number_set = config_data[:receipt_set].present? ? ReceiptNumberSet.find(config_data[:receipt_set]) : nil
    end

    if configs[:template].present?
      category.fee_receipt_template = config_data[:template].present? ? FeeReceiptTemplate.find(config_data[:template]) : nil
    end

    return [true, "multi_configs_saved", @fee_category]
  end

  def accessible?
    return true unless (category_data.is_a? Hash)
    return false if category_data[:plugin_name].present? and !FedenaPlugin.can_access_plugin?(category_data[:plugin_name])
    return true
  end

  def is_protected?
    category_data.is_a? Hash
  end

  def category_data
    TRANSACTION_CATEGORIES[name]
  end

  def check_is_income
    return !(changed.include? 'is_income' and finance_transactions.present?)
  end

  def self.income_categories
    cat_names = ["'Fee'", "'Salary'", "'Donation'", "'Refund'"]
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "'#{category[:category_name]}'"
    end
    self.find(:all, :conditions => "is_income = true AND name NOT IN (#{cat_names.join(',')}) and deleted = 0")
  end

  def self.expense_categories
    cat_names = ["'Fee'", "'Salary'", "'Donation'", "'Refund'"]
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "'#{category[:category_name]}'"
    end
    self.find(:all, :conditions => "is_income = false AND name NOT IN (#{cat_names.join(',')}) and deleted = 0")
  end

  def is_fixed
    cat_names = ['fee', 'salary', 'donation', 'refund']
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      cat_names << "#{category[:category_name].downcase}"
    end
    return true if cat_names.include?(self.name.downcase)
    return false
  end

  def total_income(start_date, end_date)
    if is_income
      self.finance_transactions.sum('amount', :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}' and master_transaction_id=0"])
    else
      0
    end
  end

  def total_expense(start_date, end_date)
    if is_income
      self.finance_transactions.sum('amount', :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}' and master_transaction_id!=0"])
    else
      self.finance_transactions.sum('amount', :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'"])
    end
  end

end
