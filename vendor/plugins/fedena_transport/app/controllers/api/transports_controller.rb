class Api::TransportsController < ApiController
  filter_access_to :all
  def students
    @xml = Builder::XmlMarkup.new
    @students=Student.search(params[:search])
    respond_to do |format|
      unless params[:search].present?? params[:search].has_key?("transport_route_destination_equals")? !params[:search]["transport_route_destination_equals"].empty? ? true:false:params[:search].has_key?("transport_vehicle_vehicle_no_equals") ? !params[:search]["transport_vehicle_vehicle_no_equals"].empty? ? true:false:false:false
        render "single_access_tokens/500.xml"  and return
      else
        format.xml  { render :students }
      end
    end
  end

  def vehicle_members
    @xml = Builder::XmlMarkup.new
    @students=Student.search(params[:search])
    @employees=Employee.search(params[:search])
    
    respond_to do |format|
      unless params[:search].present? ? params[:search].has_key?("transport_vehicle_vehicle_no_equals") ? !params[:search]["transport_vehicle_vehicle_no_equals"].empty? ? true:false:false:false
        render "single_access_tokens/500.xml"  and return
      else
        format.xml  { render :members }
      end
    end
  end
end