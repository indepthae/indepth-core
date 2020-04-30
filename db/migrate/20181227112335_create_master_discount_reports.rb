class CreateMasterDiscountReports < ActiveRecord::Migration
  def self.up
    create_table :master_discount_reports do |t|
      t.date :date
      t.integer :master_fee_discount_id, :null => false
      t.integer :student_id, :null => false
      t.integer :batch_id, :null => false
      t.decimal :amount, :default => 0, :precision => 15, :scale => 4
      t.integer :school_id, :null => false

      t.timestamps
    end
    add_index :master_discount_reports, :school_id
  end

  def self.down
    remove_index :master_discount_reports, :school_id
    drop_table :master_discount_reports
  end
end
