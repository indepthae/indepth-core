class CreateAdvanceFeeDeductions < ActiveRecord::Migration
  def self.up
    create_table :advance_fee_deductions do |t|
      t.decimal :amount, :precision =>15, :scale => 2
      t.date :deduction_date, :default => nil
      t.references :student
      t.references :finance_transaction
      t.timestamps
    end
  end

  def self.down
    drop_table :advance_fee_deductions
  end
end
