class CreateDonationAdditionalFields < ActiveRecord::Migration
  def self.up
    create_table :donation_additional_fields do |t|
      t.string :name
      t.boolean :status
      t.boolean :is_mandatory
      t.string :input_type
      t.integer :priority

      t.timestamps
    end
  end

  def self.down
    drop_table :donation_additional_fields
  end
end
