class CreateDonationAdditionalFieldOptions < ActiveRecord::Migration
  def self.up
    create_table :donation_additional_field_options do |t|
      t.integer :donation_additional_field_id
      t.string :field_option

      t.timestamps
    end
  end

  def self.down
    drop_table :donation_additional_field_options
  end
end
