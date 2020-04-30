class CreateInstantFeeParticulars < ActiveRecord::Migration
  def self.up
    create_table :instant_fee_particulars do |t|
      t.string :name
      t.string :description
      t.decimal :amount, :precision => 15, :scale => 2
      t.references :instant_fee_category
      t.boolean    :is_deleted, :default => false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :instant_fee_particulars
  end
end
