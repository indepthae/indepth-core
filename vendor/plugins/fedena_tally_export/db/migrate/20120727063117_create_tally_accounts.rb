class CreateTallyAccounts < ActiveRecord::Migration
  def self.up
    create_table :tally_accounts do |t|
      t.references :school
      t.string :account_name

      t.timestamps
    end
  end

  def self.down
    drop_table :tally_accounts
  end
end
