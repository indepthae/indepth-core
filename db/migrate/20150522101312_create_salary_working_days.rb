class CreateSalaryWorkingDays < ActiveRecord::Migration
  def self.up
    create_table :salary_working_days do |t|
      t.integer :payment_period
      t.integer :working_days
      t.timestamps
    end
  end

  def self.down
    drop_table :salary_working_days
  end
end
