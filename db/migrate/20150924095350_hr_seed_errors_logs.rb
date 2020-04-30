class HrSeedErrorsLogs < ActiveRecord::Migration
  def self.up
    create_table :hr_seed_errors_logs do |t|
      t.string :model_name
      t.text :data_rows
      t.text :error_messages
      t.timestamps
    end
  end

  def self.down
    drop_table :hr_seed_errors_logs
  end
end
