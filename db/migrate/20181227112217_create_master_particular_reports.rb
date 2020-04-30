class CreateMasterParticularReports < ActiveRecord::Migration
  def self.up
    create_table :master_particular_reports do |t|
      t.date :date
      t.integer :master_fee_particular_id, :null => false
      t.integer :fee_account_id
      t.integer :student_id, :null => false
      t.integer :batch_id, :null => false
      t.string :mode_of_payment, :null => false
      t.decimal :amount, :default => 0, :precision => 15, :scale => 4
      t.integer :school_id, :null => false

      t.timestamps
    end
    add_index :master_particular_reports, :school_id
  end

  def self.down
    remove_index :master_particular_reports, :school_id
    drop_table :master_particular_reports
  end
end
