class CreateDonationAdditionalDetails < ActiveRecord::Migration
  def self.up
    create_table :donation_additional_details do |t|
      t.integer :finance_donation_id
      t.integer :additional_field_id
      t.string :additional_info

      t.timestamps
    end
  end

  def self.down
    drop_table :donation_additional_details
  end
end
