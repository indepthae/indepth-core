class ChangeHostelTables < ActiveRecord::Migration
  def self.up
    change_column :hostel_fees, :rent, :decimal, :precision => 8, :scale => 4
    change_column :room_details, :rent, :decimal, :precision => 15, :scale => 4
  end

  def self.down
  end
end
