class CreateFineCancelTrackers < ActiveRecord::Migration
  def self.up
    create_table :fine_cancel_trackers do |t|
      t.integer :user_id
      t.decimal :amount, :precision => 5, :scale => 1, :default => 0
      t.integer :finance_id
      t.string :finance_type
      t.date :date
      t.integer :transaction_id
      t.timestamps
    end
  end

  def self.down
    drop_table :fine_cancel_trackers
  end
end
