class AddColumnBulkGeneratedCertificateIdToGeneratedCertificates < ActiveRecord::Migration
  def self.up
    add_column :generated_certificates, :bulk_generated_certificate_id, :integer
  end

  def self.down
    remove_column :generated_certificates, :bulk_generated_certificate_id
  end

end
