class CreateLeaveCredits < ActiveRecord::Migration
  def self.up
    create_table :leave_credits do |t|
      t.integer :leave_year_id
      t.datetime :credited_date
      t.integer :credit_value
      t.string :remarks
      t.boolean :is_automatic
      t.integer :credited_by
      t.integer :status
      t.integer :employee_count
      t.text :leave_Type_ids

      t.timestamps
    end
  end

  def self.down
    drop_table :leave_credits
  end
end
