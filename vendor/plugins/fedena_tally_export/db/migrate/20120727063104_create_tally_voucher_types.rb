class CreateTallyVoucherTypes < ActiveRecord::Migration
  def self.up
    create_table :tally_voucher_types do |t|
      t.references :school
      t.string :voucher_name

      t.timestamps
    end
  end

  def self.down
    drop_table :tally_voucher_types
  end
end
