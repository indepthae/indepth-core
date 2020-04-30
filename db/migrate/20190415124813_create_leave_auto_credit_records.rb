class CreateLeaveAutoCreditRecords < ActiveRecord::Migration
  def self.up
    create_table :leave_auto_credit_records do |t|
      t.integer :leave_type_id
      t.date :date

      t.timestamps
    end
  end

  def self.down
    drop_table :leave_auto_credit_records
  end
end
