class AddLastCreditDateToEmployee < ActiveRecord::Migration
  def self.up
    add_column :employees, :last_credit_date, :date
  end

  def self.down
    remove_column :employees, :last_credit_date
  end
end
