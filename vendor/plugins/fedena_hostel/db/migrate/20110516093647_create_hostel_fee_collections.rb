class CreateHostelFeeCollections < ActiveRecord::Migration
  def self.up
    create_table :hostel_fee_collections do |t|
      t.string :name
      t.references :batch
      t.date :start_date
      t.date :end_date
      t.date :due_date
      t.boolean    :is_deleted, :null => false, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :hostel_fee_collections
  end
end
