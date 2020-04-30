class CreateFinanceCategoryReceiptSets < ActiveRecord::Migration
  def self.up
    create_table :finance_category_receipt_sets do |t|
      t.references :category, :polymorphic => true
      t.references :receipt_number_set

      t.timestamps
    end
  end

  def self.down
    drop_table :finance_category_receipt_sets
  end
end
