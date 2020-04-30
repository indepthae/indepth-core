class CreateTallyLedgers < ActiveRecord::Migration
  def self.up
    create_table :tally_ledgers do |t|
      t.references :school
      t.string :ledger_name
      t.references :tally_company
      t.references :tally_voucher_type
      t.references :tally_account

      t.timestamps
    end
  end

  def self.down
    drop_table :tally_ledgers
  end
end
