class CreateLeaveYears < ActiveRecord::Migration
  def self.up
    create_table :leave_years do |t|
      t.string :name
      t.date :start_date
      t.date :end_date
      t.boolean :is_active, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :leave_years
  end
end
