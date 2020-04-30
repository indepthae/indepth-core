class CreatePinNumbers < ActiveRecord::Migration
  def self.up
    create_table :pin_numbers do |t|
      t.string :number
      t.boolean :is_active
      t.boolean :is_registered
      t.references :pin_group

      t.timestamps
    end
  end

  def self.down
    drop_table :pin_numbers
  end
end
