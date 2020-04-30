class CreateHostelFees < ActiveRecord::Migration
  def self.up
    create_table :hostel_fees do |t|
      t.references  :student
      t.references  :finance_transaction
      t.references  :hostel_fee_collection
      t.decimal       :rent, :precision => 8, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :hostel_fees
  end
end