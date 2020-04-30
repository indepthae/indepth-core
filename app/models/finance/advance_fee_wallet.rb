class AdvanceFeeWallet < ActiveRecord::Base
    belongs_to :student
    include CsvExportMod

    # fetch advance fees data
  	def self.fetch_advance_fees_data(params)
    	fetch_students_wallet_details(params)
    end
    
    # find the dependencies for disable the feature
    def self.fetch_dependencies
      advance_fee_amount = self.sum(:amount).to_f
      if advance_fee_amount > 0 
        return true
      else
        return false
      end
    end
end
