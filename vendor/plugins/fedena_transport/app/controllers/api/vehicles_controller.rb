class Api::VehiclesController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @vehicles = Vehicle.all

    respond_to do |format|
      format.xml  { render :vehicles }
    end
  end

  def vehicle_details
    @xml = Builder::XmlMarkup.new
    @vehicles = Vehicle.search(params[:search])

    respond_to do |format|
      unless params[:search].present? ? params[:search].has_key?("vehicle_no_equals") ? !params[:search]["vehicle_no_equals"].empty? ? true:false:false:false
        render "single_access_tokens/500.xml"  and return
      else
        format.xml  { render :vehicle_details }
      end
    end
  end

  def route_vehicles
    @xml = Builder::XmlMarkup.new
    @vehicles = Vehicle.search(params[:search])

    respond_to do |format|
      unless params[:search].present? ? params[:search].has_key?("main_route_destination_equals") ? !params[:search]["main_route_destination_equals"].empty? ? true:false:false:false
        render "single_access_tokens/500.xml"  and return
      else
        format.xml  { render :vehicles }
      end
    end
  end
  
  def student_vehicle
    @xml = Builder::XmlMarkup.new
    if current_user.admin? or current_user.privileges.map(&:name).include?('TransportAdmin')
      @vehicles = Vehicle.search(params[:search])
    else
      if current_user.student?
        @vehicles = Vehicle.search(:transports_receiver_student_type_admission_no_equals => current_user.username)
      elsif current_user.parent?
        ward_ids=current_user.guardian_entry.ward_ids
        @vehicles = Vehicle.search(:transports_receiver_student_type_id_in => ward_ids).uniq
      end
    end
    respond_to do |format|
      if current_user.admin? or current_user.privileges.map(&:name).include?('TransportAdmin')
        unless params[:search].present? ? params[:search].has_key?("transports_receiver_student_type_admission_no_equals") ? !params[:search]["transports_receiver_student_type_admission_no_equals"].empty? ? true:false:false:false
          render "single_access_tokens/500.xml"  and return
        else
          format.xml  { render :vehicles }
        end
      else
        format.xml  { render :vehicles }
      end
    end
  end

  def employee_vehicle
    @xml = Builder::XmlMarkup.new
    if current_user.admin? or current_user.privileges.map(&:name).include?('TransportAdmin')
      @vehicles = Vehicle.search(params[:search])
    else
      if current_user.employee?
        @vehicles = Vehicle.search(:transports_receiver_employee_type_employee_number_equals => current_user.username)
      end
    end
    respond_to do |format|
      if current_user.admin? or current_user.privileges.map(&:name).include?('TransportAdmin')
        unless params[:search].present? ? params[:search].has_key?("transports_receiver_employee_type_employee_number_equals") ? !params[:search]["transports_receiver_employee_type_employee_number_equals"].empty? ? true:false:false:false
          render "single_access_tokens/500.xml"  and return
        else
          format.xml  { render :vehicles }
        end
      else
        format.xml  { render :vehicles }
      end
    end
  end
end