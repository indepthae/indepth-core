class CreateParticularDiscounts < ActiveRecord::Migration
  def self.up
    create_table :particular_discounts do |t|
      t.decimal :discount, :precision =>15, :scale => 2
      t.references :particular_payment
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :particular_discounts
  end
end
