class AddActionToLeaveAutoCreditRecord < ActiveRecord::Migration
  def self.up
    add_column :leave_auto_credit_records, :action, :string
  end

  def self.down
    remove_column :leave_auto_credit_records, :action
  end
end
