class CreateAdvanceFeeCategories < ActiveRecord::Migration
  def self.up
    create_table :advance_fee_categories do |t|
      t.string :name
      t.string :description
      t.integer :financial_year_id
      t.boolean :online_payment_enabled, :default => true
      t.boolean :is_enabled, :default => true
      t.boolean :is_deleted, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :advance_fee_categories
  end
end
