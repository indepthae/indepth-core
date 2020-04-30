class CreateBulkGeneratedCertificates < ActiveRecord::Migration
  def self.up
    create_table :bulk_generated_certificates do |t|
      t.references :certificate_template
      t.references :academic_year
      t.date :issued_on
      t.integer :school_id

      t.timestamps
    end
    add_index :bulk_generated_certificates,[:school_id]
  end

  def self.down
    drop_table :bulk_generated_certificates
  end
end
