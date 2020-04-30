class CreateObservationRemarks < ActiveRecord::Migration
  def self.up
    create_table :observation_remarks do |t|
      t.text :remark
      t.references :observation

      t.timestamps
    end
  end

  def self.down
    drop_table :observation_remarks
  end
end
