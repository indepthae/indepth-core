class ChangePrecisionInHostelFees < ActiveRecord::Migration
  def self.up
    change_column :hostel_fees, :rent, :decimal, :precision => 15, :scale => 4
  end

  def self.down
  end
end
