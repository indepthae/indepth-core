class CreateAdvanceFeeCategoryCollections < ActiveRecord::Migration
  def self.up
    create_table :advance_fee_category_collections do |t|
      t.integer :advance_fee_collection_id, :default => nil
      t.integer :advance_fee_category_id, :default => nil
      t.decimal :fees_paid, :precision =>15, :scale => 2, :default => 0.00
      t.timestamps
    end
  end

  def self.down
    drop_table :advance_fee_category_collections
  end
end