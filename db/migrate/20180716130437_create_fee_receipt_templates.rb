class CreateFeeReceiptTemplates < ActiveRecord::Migration
  def self.up
    create_table :fee_receipt_templates do |t|
      t.integer :id
      t.string :name, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :fee_receipt_templates
  end
end
