class CreateGeneratedCertificates < ActiveRecord::Migration
  def self.up
    create_table :generated_certificates do |t|
      t.text :certificate_html
      t.references :issued_for, :polymorphic => true
      t.date :issued_on
      t.string :manual_serial_no
      t.integer :serial_no, :limit => 8
      t.references :certificate_template
      t.integer :school_id
      t.timestamps
    end
    add_index :generated_certificates,[:school_id]
  end

  def self.down
    drop_table :generated_certificates
  end
end
