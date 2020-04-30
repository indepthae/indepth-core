class AddMonthValueToSalaryWorkingDay < ActiveRecord::Migration
  def self.up
    add_column :salary_working_days, :month_value, :integer
  end

  def self.down
    remove_column :salary_working_days, :month_value
  end
end
