class AddIndexOnScidAndFtidOnCft < ActiveRecord::Migration
  def self.up
    if (ActiveRecord::Base.connection.execute("SHOW columns from cancelled_finance_transactions like 'school_id';").all_hashes.empty?)
      add_column :cancelled_finance_transactions, :school_id, :integer
      add_index :cancelled_finance_transactions, :school_id
    end
    add_index :cancelled_finance_transactions, [:school_id, :finance_transaction_id], :name => "index_by_school_id_and_ft_id"
  end

  def self.down
    remove_index :cancelled_finance_transactions, [:school_id, :finance_transaction_id], :name => "index_by_school_id_and_ft_id"
  end
end
