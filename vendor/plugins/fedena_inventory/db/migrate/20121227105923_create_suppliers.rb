class CreateSuppliers < ActiveRecord::Migration
  def self.up
    create_table :suppliers do |t|
      t.string :name
      t.string :contact_no
      t.text :address
      t.integer :tin_no
      t.string :region
      t.text :help_desk
      t.boolean :is_deleted, :default => false
      t.references :supplier_type

      t.timestamps
    end
  end

  def self.down
    drop_table :suppliers
  end
end
