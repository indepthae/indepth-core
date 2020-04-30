class AddStatusDescriptionToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :status_description, :string
  end

  def self.down
    remove_column :payments, :status_description
  end
end
