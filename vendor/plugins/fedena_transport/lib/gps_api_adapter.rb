# This is an adapter class responsible for communications with gps gateway.
class GpsApiAdapter

  Response = Struct.new(:body, :success, :error) do
    def to_hash
      if self.success
        {:body=> self.body, :success => true}
      else
        {:success => false, :error => self.error}
      end
    end
  end
  
  GPS_CLIENT_SETTINGS = YAML.load_file(File.join(Rails.root,"vendor/plugins/fedena_transport","config","gps_settings.yml"))

  GPS_SETTING_FIELDS = %w{ client_id client_secret vendor_name integration_id
                            integration_vector vendor_code sync_applicable }

  attr_accessor *GPS_SETTING_FIELDS

  # @param [TransportGpsSetting] gps_setting gps_settings for the instance
  def initialize (gps_setting)
    @gps_setting = gps_setting

    GPS_SETTING_FIELDS.each do |field|
      send "#{field}=", @gps_setting.send(field)
    end
  end  
  
  # gets the handshake response from the gps gateway
  # @param [Hash] params Specific options to be passed to the gps apis,
  #   changes based on the various client settings
  # @returns [Hash] authorization details hash based on the query  
  def get_verification_details
    make_gps_server_handshake
  end

  private
  
  # Makes api call to gps gateway's handshake end-point
  def make_gps_server_handshake
    api_path = "/api/v1/services/handshake?api_key=#{client_id}"
    make_api_call(api_path)
  end

  # Makes api call to the gps gateway. Uses the client_id and client_secret of
  #   of the current school's gps settings
  # @param [String] api_path Path including uri params to the api endpoint to
  #   to which the api call will be made
  def make_api_call (api_path)
    uri = URI.parse(GPS_CLIENT_SETTINGS["url"] + api_path)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme=="https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(uri.request_uri)
    request['API-SECRET'] = client_secret
    response = http.request(request)    
    make_adapter_response(response)
  end

  
  #Humanize api response for better handling
  def make_adapter_response(response)
    adapter_response = Response.new
    case response
    when Net::HTTPSuccess 
      adapter_response.body = JSON.parse(response.body)
      adapter_response.success = true
    when Net::HTTPServerError 
      adapter_response.success = false
      adapter_response.error = :server_error
    when Net::HTTPClientError 
      adapter_response.success = false
      adapter_response.error = :client_error
    else
      adapter_response.success = false
      adapter_response.error = :unknown
    end
    adapter_response
  end

end