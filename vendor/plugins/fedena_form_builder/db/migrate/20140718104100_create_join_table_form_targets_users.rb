class CreateJoinTableFormTargetsUsers < ActiveRecord::Migration
  def self.up
    create_table :form_targets_users, :id => false do |t|
      t.references :form
      t.references :user
    end
  end

  def self.down
    drop_table  :form_targets_users
  end
end
