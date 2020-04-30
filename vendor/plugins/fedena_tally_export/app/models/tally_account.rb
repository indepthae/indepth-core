class TallyAccount < ActiveRecord::Base
  has_many :tally_ledgers

  validates_presence_of :account_name
  validates_uniqueness_of :account_name
end
