class FeeAccount < ActiveRecord::Base
  has_many :transaction_receipts

  has_many :finance_category_accounts
  has_many :finance_transaction_categories, :through => :finance_category_accounts, :source => :category,
           :source_type => "FinanceTransactionCategory"
  has_many :finance_fee_categories, :through => :finance_category_accounts, :source => :category,
           :source_type => "FinanceFeeCategory"

  has_many :finance_transaction_receipt_records
  has_many :finance_transactions, :through => :finance_transaction_receipt_records
  has_many :master_particular_reports

  validates_presence_of :name
  validates_uniqueness_of :name
  # validates_format_of :name, :with => /^[a-zA-Z0-9\s]*$/, :message => :special_characters_not_valid
  validates_format_of :name, :with => /^[^~`@%$*()\-\[\]{}"':;\/.,\\=+|]*$/i, :message => :special_characters_not_valid
  # TO DO :: remove/change default_scope to some other convenient way
  default_scope :conditions => {:is_deleted => false}, :order => "name ASC"

  # returns true if a fee account is linked to a FinanceFeeCategory or
  # income FinanceTransaction via FinanceTransactionReceiptRecord
  def has_assignments?
    ## TO DO add validation on link with categories and receipts
    return (self.finance_category_accounts.present? or self.finance_transaction_receipt_records.first.present?)
  end


  class << self

    # checks if fee account deletion is enabled
    def is_deletion_enabled
      (Configuration.get_config_value 'FeeAccountDeletionEnabled').to_i == 1
    end

    # Enables manage fee accounts page,
    # if called with true to enable account deletion for school
    # by default it will disable account deletion for school
    def enable_deletion(enabled = false)
      #FeeAccountDeletionEnabled true/false (boolean)
      Configuration.set_value('FeeAccountDeletionEnabled', enabled)
    end

    # checks if a FeeAccount has linked income FinanceTransaction records
    def has_active_transactions?
      FeeAccount.last(:joins => :finance_transaction_receipt_records).present?
    end

    # fetches all fee accounts ignoring default scope
    # return all fee accounts (either is_deleted true/false)
    def all_accounts
      with_exclusive_scope { self.all }
    end

    # activate / deactivate a FeeAccount
    # @params account_id : id of FeeAccount to be activated / deactivated
    #         operation : activate [activate fee account]; deactivate [deactivate fee account]
    # fetches and perform requested operation on FeeAccount if found
    def manage account_id, operation
      return 'error' unless ['activate', 'deactivate'].include?(operation)

      account = with_exclusive_scope { self.find(account_id) }
      return false unless account.present?

      status = operation == 'activate' ? false : true
      with_exclusive_scope { account.update_attributes({:is_deleted => status})}
    end

  end

end
