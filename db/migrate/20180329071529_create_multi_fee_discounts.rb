class CreateMultiFeeDiscounts < ActiveRecord::Migration
  def self.up
    create_table :multi_fee_discounts do |t|
      t.references :receiver, :polymorphic => true, :null => false
      t.decimal :discount, :precision => 15, :scale => 4, :null => false
      t.boolean :is_amount, :default => 0
      t.string :name, :null => false

      t.timestamps
    end
    add_index :multi_fee_discounts, [:receiver_type, :receiver_id], :name => "index_by_receiver"
  end

  def self.down
    remove_index :multi_fee_discounts, :name => "index_by_receiver"
    drop_table :multi_fee_discounts
  end
end
