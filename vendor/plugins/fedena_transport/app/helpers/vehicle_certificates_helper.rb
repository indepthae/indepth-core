module VehicleCertificatesHelper
  
  def fetch_path(certificate)
    certificate.new_record? ? vehicle_vehicle_certificates_path : vehicle_vehicle_certificate_path
  end
  
  
  def fetch_method(certificate)
    certificate.new_record? ? :post : :put
  end
end
