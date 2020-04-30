module VehicleAdditionalDetailsHelper
  
  def fetch_path(addl_detail)
    addl_detail.new_record? ? vehicle_additional_details_path : vehicle_additional_detail_path
  end
  
end
