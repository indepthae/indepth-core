class ModifyPrecisionForAssetsAndLiabilities < ActiveRecord::Migration
  def self.up
    change_column :assets, :amount, :decimal,:precision =>15, :scale => 4
    change_column :liabilities, :amount, :decimal,:precision =>15, :scale => 4
  end

  def self.down
    change_column :assets, :amount, :decimal,:precision =>10, :scale => 4
    change_column :liabilities, :amount, :decimal,:precision =>10, :scale => 4
  end
end
