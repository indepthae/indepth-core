class TallyLedger < ActiveRecord::Base
  has_many :finance_transaction_categories
  belongs_to :tally_company
  belongs_to :tally_voucher_type
  belongs_to :tally_account

  delegate :company_name, :to => :tally_company
  delegate :voucher_name, :to => :tally_voucher_type
  delegate :account_name, :to => :tally_account

  validates_presence_of :ledger_name, :tally_company_id, :tally_voucher_type_id, :tally_account_id

end
