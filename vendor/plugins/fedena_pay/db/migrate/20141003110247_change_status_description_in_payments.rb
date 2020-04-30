class ChangeStatusDescriptionInPayments < ActiveRecord::Migration
  def self.up
    change_column :payments, :status_description, :integer
  end

  def self.down
    change_column :payments, :status_description, :string
  end
end
