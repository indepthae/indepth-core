class CreateFinanceCategoryReceiptTemplates < ActiveRecord::Migration
  def self.up
    create_table :finance_category_receipt_templates do |t|
      t.references :category, :polymorphic => true
      t.references :fee_receipt_template

      t.timestamps
    end
  end

  def self.down
    drop_table :finance_category_receipt_templates
  end
end
