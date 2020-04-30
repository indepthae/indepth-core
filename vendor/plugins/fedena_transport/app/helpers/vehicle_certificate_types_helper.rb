module VehicleCertificateTypesHelper
  
  def fetch_path(certificate_type)
    certificate_type.new_record? ? vehicle_certificate_types_path : vehicle_certificate_type_path
  end
  
end
