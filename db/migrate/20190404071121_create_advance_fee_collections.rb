class CreateAdvanceFeeCollections < ActiveRecord::Migration
  def self.up
    create_table :advance_fee_collections do |t|
      t.decimal :fees_paid, :precision =>15, :scale => 2
      t.string :payment_mode
      t.date :date_of_advance_fee_payment
      t.string :reference_no, :default => nil
      t.string :payment_note, :default => nil
      t.string :bank_name, :default => nil
      t.date :cheque_date, :default => nil
      t.references :user
      t.references :student
      t.timestamps
    end
  end

  def self.down
    drop_table :advance_fee_collections
  end
end
