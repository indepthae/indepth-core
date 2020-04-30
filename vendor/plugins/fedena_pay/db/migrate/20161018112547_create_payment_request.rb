class CreatePaymentRequest < ActiveRecord::Migration
 def self.up
    create_table :payment_requests do |t|
      t.text :identification_token
      t.text :transaction_parameters
      t.integer :user_id
      t.boolean :is_processed,:default => false
      t.integer :school_id
      t.timestamps
    end
  end

  def self.down
    drop_table :payment_requests
  end
end
