class ChangeColumnTransportFee < ActiveRecord::Migration
  def self.up
      rename_column :transport_fees ,:user_id ,:receiver_id
      add_column :transport_fees, :receiver_type , :string
      rename_column :transports ,:user_id ,:receiver_id
      add_column :transports, :receiver_type , :string
  end

  def self.down
    change_table :transport_fees do |x|
      x.rename_column :receiver_id ,:user_id
      x.remove_column :receiver_type
    end
    change_table :transports do |y|
      y.rename_column :receiver_id ,:user_id
      y.remove_column :receiver_type
    end
  end
end
