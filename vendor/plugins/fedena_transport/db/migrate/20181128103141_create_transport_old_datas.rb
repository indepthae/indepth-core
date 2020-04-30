class CreateTransportOldDatas < ActiveRecord::Migration
  def self.up
    create_table :transport_old_datas do |t|
      t.string :model_name
      t.string :model_id
      t.text :data_rows
      t.references :school

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_old_datas
  end
end
