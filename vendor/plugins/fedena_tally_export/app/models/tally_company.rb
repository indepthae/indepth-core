class TallyCompany < ActiveRecord::Base
  has_many :tally_ledgers

  validates_presence_of :company_name
  validates_uniqueness_of :company_name
end
