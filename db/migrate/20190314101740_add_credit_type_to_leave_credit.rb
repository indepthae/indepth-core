class AddCreditTypeToLeaveCredit < ActiveRecord::Migration
  def self.up
    add_column :leave_credits, :credit_type, :integer
  end

  def self.down
    remove_column :leave_credits, :credit_type
  end
end
