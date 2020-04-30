class AdvanceFeeDeduction < ActiveRecord::Base
  belongs_to :student
  belongs_to :finance_transaction
  
  # reverting deduction record by finance transaction
  def self.destroy_deduction_record(f_id)
    self.find_by_finance_transaction_id(f_id).destroy
  end
end
