class CreateSchoolGroupUsers < ActiveRecord::Migration
  def self.up
    create_table :school_group_users do |t|
      t.integer :admin_user_id
      t.integer :school_group_id

      t.timestamps
    end
  end

  def self.down
    drop_table :school_group_users
  end
end
