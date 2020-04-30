class AddAcademicYearToGeneratedCertificate < ActiveRecord::Migration
  def self.up
    add_column :generated_certificates, :batch_id, :integer
  end

  def self.down
    remove_column :generated_certificates, :batch_id
  end
end
