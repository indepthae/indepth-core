class AdvanceFeeCategoryCollection < ActiveRecord::Base  
    belongs_to :advance_fee_collection
    belongs_to :advance_fee_category

    after_create :update_student_wallet

    # update student wallet amount after transactions
    def update_student_wallet
        student = self.advance_fee_collection.student
        wallet = AdvanceFeeWallet.find_or_create_by_student_id(student.id)
        wallet.update_attributes(:amount => (wallet.amount.to_f + self.fees_paid.to_f))
    end

    # deleting particular collections
    def self.delete_transactions(adfcc_ids)
      adfcc_ids.each do |adfcc|
        self.find(adfcc).destroy
      end
    end
end
