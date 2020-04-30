class CreateAllotmentLogDetails < ActiveRecord::Migration
  def self.up
    create_table :allotment_log_details do |t|
      t.string :name
      t.string :registration_no
      t.string :status
      t.string :description
      t.references :registration_course

      t.timestamps
    end
  end

  def self.down
    drop_table :allotment_log_details
  end
end
