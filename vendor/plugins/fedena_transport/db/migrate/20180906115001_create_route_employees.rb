class CreateRouteEmployees < ActiveRecord::Migration
  def self.up
    create_table :route_employees do |t|
      t.references :employee
      t.string :mobile_phone
      t.integer :task
      t.references :school

      t.timestamps
    end
  end

  def self.down
    drop_table :route_employees
  end
end
