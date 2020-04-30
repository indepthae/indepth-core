class CreateFeeAccounts < ActiveRecord::Migration
  def self.up
    create_table :fee_accounts do |t|
      t.integer :id
      t.string :name, :null => false
      t.string :description

      t.timestamps
    end    
  end

  def self.down
    drop_table :fee_accounts
  end
end
