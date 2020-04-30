class TransportGpsSetting < ActiveRecord::Base
  
  validates_presence_of :client_id, :client_secret, :vendor_name
  
  before_save :gps_server_verification
  
  # GPS api server handshake to fetch authorization details
  def gps_server_verification
    verification_details
  end
  
  def verification_details
    response = make_handshake
    if response.success
      make_authentication_details(response.body)
    else  
      errors.add_to_base("#{t('transport_gps_settings.gps_server_verification_failed')}")
    end
    return response.success
  end
  
  # Pass details to GPS adapter for handshake
  def make_handshake
    gps_api_adapter = GpsApiAdapter.new(self)
    gps_api_adapter.get_verification_details
  end
  
  # Assign authentication details to object
  def make_authentication_details(details)
    self.vendor_code = details['vendor_code']
    self.sync_applicable = details['sync_applicable']
    self.integration_id = details['integration_id']
    self.integration_vector = details['integration_vector']
  end

end