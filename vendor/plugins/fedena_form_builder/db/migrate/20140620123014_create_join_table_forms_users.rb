class CreateJoinTableFormsUsers < ActiveRecord::Migration
  def self.up
    create_table :forms_users, :id => false do |t|
      t.references :form
      t.references :user
    end
  end

  def self.down
    drop_table  :forms_users
  end
end
