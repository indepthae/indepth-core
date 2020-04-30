class CreateDiscountParticularLogs < ActiveRecord::Migration
  def self.up
    create_table :discount_particular_logs do |t|
      t.boolean :is_amount
      t.string :receiver_type
      t.integer :finance_fee_id
      t.integer :user_id
      t.string :name
      t.decimal :amount,:precision=>15, :scale=>4

      t.timestamps
    end
  end

  def self.down
    drop_table :discount_particular_logs
  end
end
