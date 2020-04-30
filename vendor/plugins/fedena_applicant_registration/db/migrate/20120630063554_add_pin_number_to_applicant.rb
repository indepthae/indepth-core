class AddPinNumberToApplicant < ActiveRecord::Migration
  def self.up
    add_column :applicants, :pin_number, :text
  end

  def self.down
    remove_column :applicants, :pin_number
  end
end
