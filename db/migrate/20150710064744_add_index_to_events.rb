class AddIndexToEvents < ActiveRecord::Migration
  def self.up
    add_index :events, [:origin_id,:origin_type], :name => :polymorphic_origin_index
    add_index :employee_department_events, :employee_department_id
    add_index :user_events, :user_id
  end

  def self.down
    remove_index :events, :polymorphic_origin_index
    remove_index :employee_department_events, :employee_department_id
    remove_index :user_events, :user_id
  end
end
