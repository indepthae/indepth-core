module TransportGpsSettingsHelper
  def fetch_path(obj)
    obj.new_record? ? transport_gps_settings_path : transport_gps_setting_path
  end
end
