class CreateEmailSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :email_subscriptions do |t|
      t.integer :student_id
      t.string :name
      t.integer :school_id
      t.timestamps
    end
  end

  def self.down
    drop_table :email_subscriptions
  end
end
