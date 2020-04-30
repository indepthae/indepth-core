class AddUserIdIndexToBiometricInformation < ActiveRecord::Migration
  def self.up
    add_index :biometric_informations, :user_id, :name => "index_on_user_id"
  end

  def self.down
    remove_index :biometric_informations, :name => "index_on_user_id"
  end
end
