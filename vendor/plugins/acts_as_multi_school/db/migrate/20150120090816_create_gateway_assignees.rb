class CreateGatewayAssignees < ActiveRecord::Migration
  def self.up
    create_table :gateway_assignees do |t|
      t.integer :custom_gateway_id
      t.integer :assignee_id
      t.string :assignee_type
      t.boolean :is_owner, :default=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :gateway_assignees
  end
end
