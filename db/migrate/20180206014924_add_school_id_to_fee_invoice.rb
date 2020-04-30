class AddSchoolIdToFeeInvoice < ActiveRecord::Migration
  # adding school id to add db uniquess
  def self.up
    add_column :fee_invoices, :school_id, :integer
  end

  def self.down
    remove_column :fee_invoices, :school_id
  end
end
