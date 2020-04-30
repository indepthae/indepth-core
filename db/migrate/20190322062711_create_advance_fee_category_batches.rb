class CreateAdvanceFeeCategoryBatches < ActiveRecord::Migration
  def self.up
    create_table :advance_fee_category_batches do |t|
      t.integer :advance_fee_category_id, :default => nil
      t.integer :batch_id, :default => nil
      t.timestamps
    end
  end

  def self.down
    drop_table :advance_fee_category_batches
  end
end
