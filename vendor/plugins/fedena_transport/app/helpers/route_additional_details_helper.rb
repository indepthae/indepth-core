module RouteAdditionalDetailsHelper
  
  def fetch_path(addl_detail)
    addl_detail.new_record? ? route_additional_details_path : route_additional_detail_path
  end
  
end
