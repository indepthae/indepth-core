class Api::RoutesController < ApiController
  filter_access_to :all
  def index
    @xml = Builder::XmlMarkup.new
    @routes = Route.search(params[:search])

    respond_to do |format|
      unless params[:search].present? ? params[:search].has_key?("destination_equals") ? !params[:search]["destination_equals"].empty? ? true:false:false:false
        render "single_access_tokens/500.xml"  and return
      else
        format.xml  { render :routes }
      end
    end
  end

  def students_route
    @xml = Builder::XmlMarkup.new
    if current_user.admin? or current_user.privileges.map(&:name).include?('TransportAdmin')
      @routes = Route.search(:transports_receiver_student_type_admission_no_equals=>params[:id])
    else
      if current_user.student?
        @routes = Route.search(:transports_receiver_student_type_admission_no_equals =>current_user.username)
      elsif current_user.parent?
        ward_ids=current_user.guardian_entry.ward_ids
        @routes = Route.search(:transports_receiver_student_type_id_in =>ward_ids).uniq
      end
    end
    respond_to do |format|
      if current_user.admin? or current_user.privileges.map(&:name).include?('TransportAdmin')
        unless params[:id].present? 
          render "single_access_tokens/500.xml"  and return
        else
          format.xml  { render :members_routes }
        end
      else
        format.xml  { render :members_routes }
      end
    end
  end
  def employees_route
    @xml = Builder::XmlMarkup.new
    if current_user.admin? or current_user.privileges.map(&:name).include?('TransportAdmin')
      @routes = Route.search(:transports_receiver_employee_type_employee_number_equals=>params[:id])
    else
      if current_user.employee?
        @routes = Route.search(:transports_receiver_employee_type_employee_number_equals =>current_user.username)
      end
    end
    respond_to do |format|
      if current_user.admin? or current_user.privileges.map(&:name).include?('TransportAdmin')
        unless params[:id].present?
          render "single_access_tokens/500.xml"  and return
        else
          format.xml  { render :members_routes }
        end
      else
        format.xml  { render :members_routes }
      end
    end
  end
end