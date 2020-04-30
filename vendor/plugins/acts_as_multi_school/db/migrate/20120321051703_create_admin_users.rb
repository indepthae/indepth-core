class CreateAdminUsers < ActiveRecord::Migration
  def self.up
    create_table :admin_users do |t|
      t.string :username
      t.string :password_salt
      t.string :crypted_password
      t.string :email
      t.string :full_name

      t.timestamps
    end
#    AdminUser.create(:username=>"admin",:password=>"foradian",:email=>"info@foradian.com",:full_name=>"Administrator")
  end

  def self.down
    drop_table :admin_users
  end
end
