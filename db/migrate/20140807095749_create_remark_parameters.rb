class CreateRemarkParameters < ActiveRecord::Migration
  def self.up
    create_table :remark_parameters do |t|
      t.integer :remark_id
      t.string :param_name
      t.string :param_value

      t.timestamps
    end
    add_index :remark_parameters, :remark_id
  end

  def self.down
    drop_table :remark_parameters
  end
end
