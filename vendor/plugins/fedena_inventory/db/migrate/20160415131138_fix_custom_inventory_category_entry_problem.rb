class FixCustomInventoryCategoryEntryProblem < ActiveRecord::Migration
  def self.up
    if ActiveRecord::Base.connection.table_exists? "schools"
      School.active.each do |school|
        MultiSchool.current_school=School.find(school.id)
        custom_category = FinanceTransactionCategory.all(:conditions=>{:name =>'Inventory',:is_income =>false})
        if custom_category.present?
          transactions = FinanceTransaction.all(:conditions=>{:finance_type=>nil,:finance_id=>nil,:category_id=>custom_category.first.id})
          if transactions.present?
            puts "------#{transactions.count} records found in #{school.id} - #{school.name}-----"
            category=FinanceTransactionCategory.create(:name=>"Custom Inventory Purchases",:is_income=>false)
            transactions.each do |transaction|
              sql = "UPDATE finance_transactions SET category_id='#{category.id}' WHERE id=#{transaction.id}"
              ActiveRecord::Base.connection.execute(sql)
            end
          end
        end
      end 
    end
  end

  def self.down
  end
end
