class ChangeLeaveCountToBeStringInLeaveCreditSlab < ActiveRecord::Migration
  def self.up
     change_column :leave_credit_slabs, :leave_count, :string
  end

  def self.down
    change_column :leave_credit_slabs, :leave_count, :inetger
  end
end
