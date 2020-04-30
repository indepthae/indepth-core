class DonationAdditionalDetail < ActiveRecord::Base
  belongs_to :finance_donation
  belongs_to :donation_additional_field, :foreign_key=>'additional_field_id'

end
