class ChangeRoom < ActiveRecord::Migration
  def self.up
    change_column :room_details, :rent, :decimal, :precision =>15, :scale => 2
  end

  def self.down
  end
end
