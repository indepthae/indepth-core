class ChangeDefaultStatusOfBook < ActiveRecord::Migration
  def self.up
    change_column_default(:books, :status, 'Available')
  end

  def self.down
    change_column_default(:books, :status, 'available')
  end
end
