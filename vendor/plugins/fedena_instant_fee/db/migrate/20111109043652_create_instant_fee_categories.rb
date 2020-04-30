class CreateInstantFeeCategories < ActiveRecord::Migration
  def self.up
    create_table :instant_fee_categories do |t|
      t.string :name
      t.string :description
      t.boolean    :is_deleted, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :instant_fee_categories
  end
end
