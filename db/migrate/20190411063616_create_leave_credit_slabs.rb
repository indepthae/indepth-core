class CreateLeaveCreditSlabs < ActiveRecord::Migration
  def self.up
    create_table :leave_credit_slabs do |t|
      t.integer :employee_leave_type_id
      t.string :leave_label
      t.integer :leave_count
      t.integer :credit_frequency_type

      t.timestamps
    end
  end

  def self.down
    drop_table :leave_credit_slabs
  end
end
