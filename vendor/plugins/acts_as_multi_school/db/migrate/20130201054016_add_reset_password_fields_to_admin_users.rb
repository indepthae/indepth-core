class AddResetPasswordFieldsToAdminUsers < ActiveRecord::Migration
  def self.up
    add_column :admin_users, :reset_password_code, :string
    add_column :admin_users, :reset_password_code_until, :datetime
  end

  def self.down
    remove_column :admin_users, :reset_password_code_until
    remove_column :admin_users, :reset_password_code
  end
end
