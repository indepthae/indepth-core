class BulkGeneratedCertificate < ActiveRecord::Base
  belongs_to :certificate_template
  belongs_to :academic_year
  has_many :generated_certificates, :dependent=>:destroy
  has_one :generated_pdf, :as=> :corresponding_pdf, :dependent=>:destroy
end
