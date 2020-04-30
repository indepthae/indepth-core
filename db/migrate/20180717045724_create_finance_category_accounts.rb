class CreateFinanceCategoryAccounts < ActiveRecord::Migration
  def self.up
    create_table :finance_category_accounts do |t|
      t.references :category, :polymorphic => true
      t.references :fee_account

      t.timestamps
    end
  end

  def self.down
    drop_table :finance_category_accounts
  end
end
