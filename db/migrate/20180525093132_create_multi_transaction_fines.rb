class CreateMultiTransactionFines < ActiveRecord::Migration
  def self.up
    create_table :multi_transaction_fines do |t|
      t.string :name
      t.decimal :amount, :precision => 15, :scale => 4, :null => false
      t.references :receiver, :polymorphic => true, :null => false

      t.timestamps
    end
    add_index :multi_transaction_fines, [:receiver_type, :receiver_id], :name => "index_by_receiver"
  end

  def self.down
    remove_index :multi_transaction_fines, :name => "index_by_receiver"
    drop_table :multi_transaction_fines
  end
end
