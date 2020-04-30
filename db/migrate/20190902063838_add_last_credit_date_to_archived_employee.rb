class AddLastCreditDateToArchivedEmployee < ActiveRecord::Migration
 def self.up
    add_column :archived_employees, :last_credit_date, :date
  end

  def self.down
    remove_column :archived_employees, :last_credit_date
  end
end
