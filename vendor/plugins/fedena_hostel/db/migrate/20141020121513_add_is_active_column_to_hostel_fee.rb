class AddIsActiveColumnToHostelFee < ActiveRecord::Migration
  def self.up
    add_column :hostel_fees,:is_active, :boolean,:default=>true
  end

  def self.down
    remove_column :hostel_fees,:is_active, :boolean
  end
end


