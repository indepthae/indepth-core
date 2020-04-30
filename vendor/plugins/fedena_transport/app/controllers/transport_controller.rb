class TransportController < ApplicationController
  before_filter :login_required
  filter_access_to :employee_transport_details,:attribute_check => true,:load_method => lambda {Employee.find(params[:id]).user}
  filter_access_to :all,:except => [:student_transport_details]
  filter_access_to [:student_transport_details], :attribute_check => true, :load_method => lambda { Student.find(params[:id]) }
  before_filter  :set_precision
  before_filter :protect_other_student_data, :only =>[:student_transport_details]
  before_filter :currency, :only=>[:show_passengers, :assign_passenger, :show_transport_form, :show_transport_mode, :fetch_stops, :calculate_fare]
  before_filter :find_academic_year, :only=>[:dash_board, :index]
  before_filter :check_sms_settings, :only => [:send_notification]
  before_filter :get_academic_year, :only=>[:index, :show_batches, :show_passengers, :advanced_search, :assign_passenger, :show_stops, :unassign_passenger]
  check_request_fingerprint :settings, :assign_passenger, :unassign_passenger

  def dash_board

  end
  
  def configurations
    
  end
  
  def settings
    @config = Configuration.get_multiple_configs_as_hash ['DifferentRoutes', 'TransportFeeCollectionType', 'SingleRouteFeePercentage', 'UpdateUnpaidTransportFee']
    @config[:different_routes] = 1 if @config[:different_routes].nil?
    @config[:transport_fee_collection_type] = 1 if @config[:transport_fee_collection_type].nil?
    @config[:single_route_fee_percentage] = 50 unless @config[:single_route_fee_percentage].present?
    @academic_years = AcademicYear.all
    @active_year = session[:transport_academic_year]||AcademicYear.active.first.try(:id)
    if request.post?
      Configuration.set_config_values(params[:configuration])
      @active_year = session[:transport_academic_year] = params[:academic_year_id].to_i if params[:academic_year_id].present?
      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action => "settings"  and return
    end
  end
  
  def index
    if params[:passenger].present? and params[:passenger] == "employee"
      @departments = EmployeeDepartment.active_and_ordered
    else
      @courses = Course.active
    end
    @batches = []
    if request.xhr?
      render :update do |page|
        page.replace_html 'search_options', :partial => 
          ((params[:passenger].present? and params[:passenger] == "employee") ?  'select_department' : 'select_course')
        page.replace_html 'list_passengers', :text => ''
      end
    else
      @config = Configuration.get_multiple_configs_as_hash(['SingleRouteFeePercentage', 'DifferentRoutes', 'TransportFeeCollectionType'])
    end
  end
  
  
  def show_batches
    if params[:course_id].present?
      @course = Course.find(params[:course_id])
      @batches = @course.batches.active.all(:conditions => {:academic_year_id => @academic_year_id})
    end
    render :update do |page|
      page.replace_html 'list_batches', :partial => 'select_batch'
      page.replace_html 'list_passengers', :text => ''
    end 
  end
  
  def show_passengers
    @type = params[:passenger]
    @search_params = params[:search]||params[:advanced_search]||{}
    @passengers = Transport.fetch_values(@type, @search_params)
    render :update do |page|
      page.replace_html 'list_passengers', :partial => 'list_passengers'
      page << "remove_popup_box()" 
    end 
  end
  
  def advanced_search
    @filters = Transport.fetch_filter_values(params[:passenger],@academic_year_id)
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{t('advanced_search_text')}', 'popup_class' : 'search-form'})"
      page.replace_html 'popup_content', :partial => "advanced_search_#{params[:passenger]}"
    end
  end
  
  def assign_passenger
    @transport = Transport.find_or_initialize_by_receiver_id_and_receiver_type_and_academic_year_id(
      {:receiver_id => params[:passenger_id], :receiver_type => params[:passenger_type], 
        :academic_year_id => @academic_year_id})
    @routes = Route.in_academic_year(@academic_year_id)
    @transport.attributes = params[:transport]
    if @transport.pickup_route.present?
      @pickup_stops = VehicleStop.all_in_academic_year(@academic_year_id).with_selected_stop(@transport.pickup_route_id, @transport.pickup_stop_id)
      @pickup_stop_fares = Hash[(@transport.pickup_route.try(:route_stops)||[]).map{|s| [s.vehicle_stop_id, s.fare.to_f]}]
    end
    if @transport.drop_route.present? 
      @drop_stops = VehicleStop.all_in_academic_year(@academic_year_id).with_selected_stop(@transport.drop_route_id, @transport.drop_stop_id)
      @drop_stop_fares = Hash[(@transport.drop_route.try(:route_stops)||[]).map{|s| [s.vehicle_stop_id, s.fare.to_f]}]
    end
    @different_route = Configuration .get_config_value('DifferentRoutes')
    if request.post? or request.put?
      render :update do |page|
        if @transport.save
          @type = @transport.receiver_type.underscore
          page.replace_html "#{@transport.receiver_type.underscore}_#{@transport.receiver_id}", 
            :partial => 'passenger_details', :locals => {:p => @transport.receiver}
          page << "enable_clicks()"
        else
          page.replace_html 'vehicle_transport_form', :partial => 'transport_form'
        end
      end
    else
      @seat_status = Route.all_vehicle_seat_status(@academic_year_id, @transport, params[:common_route])
      render :partial => 'transport_form'
    end
  end
  
  def show_stops
    @seats_status = Route.vehicle_seat_status(@academic_year_id, params)
    @route = Route.find(params[:route_id]) if params[:route_id].present?
    @stops = (@route.present? ? @route.vehicle_stops.active : [])
    render :json => {:stops => Hash[@stops.map{|s| [s.id, s.name]}], :route_fare => @route.try(:fare)||0, 
      :stop_fares => Hash[(@route.try(:route_stops)||[]).map{|s| [s.vehicle_stop_id, s.fare.to_f]}], :status => @seats_status}
  end
  
  def unassign_passenger
    @transport = Transport.find(params[:id])
    @transport.archive_transport(params[:transport]) if request.put?
    render :update do |page|
      @type = @transport.receiver_type.underscore
      page.replace_html "#{@transport.receiver_type.underscore}_#{@transport.receiver_id}", 
        :partial => ((request.put? or params[:cancel].present?) ? 'passenger_details' : 'unassign_form'), 
        :locals => {:p => @transport.receiver, :transport => @transport}
      #      page << "complete_action()"
      page << "enable_clicks()" if (request.put? or params[:cancel].present?)
    end
  end
  
  def show_transport_form
    if (params[:value] == "true")
      academic_year_id = session[:transport_academic_year]||AcademicYear.active.first.try(:id)
      @transport = Transport.find_or_initialize_by_receiver_id_and_receiver_type_and_academic_year_id(
        {:receiver_id => params[:receiver_id], :receiver_type => params[:receiver_type], 
          :academic_year_id => academic_year_id})
      @receiver_type = params[:receiver_type].downcase
    end
    render :update do |page|
      if (params[:value] == "true")
        page.replace_html "transport_assign_form", :partial => "transport_assign_form", :locals => {:student => @student, :transport => @transport}
      else
        page.replace_html "transport_assign_form", :text => ''
      end
    end
  end
  
  def show_transport_mode
    academic_year_id = session[:transport_academic_year]||AcademicYear.active.first.try(:id)
    @routes = Route.in_academic_year(academic_year_id)
    @transport = Transport.find_or_initialize_by_receiver_id_and_receiver_type_and_academic_year_id(
      {:receiver_id => params[:receiver_id], :receiver_type => params[:receiver_type], 
        :academic_year_id => academic_year_id})
    @receiver_type = params[:receiver_type].downcase
    @mode = params[:mode]
    @different_route = Configuration .get_config_value('DifferentRoutes')
    @pickup_stops = @transport.pickup_route.vehicle_stops if @transport.pickup_route.present?
    @drop_stops = @transport.drop_route.vehicle_stops if @transport.drop_route.present?
    render :update do |page|
      if params[:mode].present?
        page.replace_html "transport_details", :partial => "transport_details", :locals => {:transport => @transport}
      else
        page.replace_html "transport_details", :text => ''
      end
    end
  end
  
  def fetch_stops
    route = Route.find(params[:route_id])
    @stops = route.vehicle_stops
    @receiver_type = params[:receiver_type].downcase
    render :update do |page|
      unless params[:route_type] == 'common'
        page.replace_html "#{params[:route_type]}_stops", :partial => "route_stops", :locals => {:mode => params[:mode], :route_type => params[:route_type]}
      else
        page.replace_html "pickup_stops", :partial => "route_stops", :locals => {:mode => params[:mode], :route_type => 'pickup'}
        page.replace_html "drop_stops", :partial => "route_stops", :locals => {:mode => params[:mode], :route_type => 'drop'}
      end
    end
  end
  
  def calculate_fare
    @bus_fare = Transport.calculate_fare(params)
    @receiver_type = params[:receiver_type].downcase
    render :update do |page|
      page.replace_html "transport_fare", :partial => "transport_fare", :locals => {:bus_fare => @bus_fare}
    end
  end
  
  def student_transport_details
    @current_user = current_user
    @available_modules = Configuration.available_modules
    @student = Student.find(params[:id])
    @transport = @student.transport
#    different_route = Configuration .get_config_value('DifferentRoutes')
#    @common_route = (different_route.nil? ? false : (different_route.to_i == 0))
  end

  def employee_transport_details
    @current_user = current_user
    @available_modules = Configuration.available_modules
    @employee = Employee.find(params[:id])
    @transport = @employee.transport
#    different_route = Configuration .get_config_value('DifferentRoutes')
#    @common_route = (different_route.nil? ? false : (different_route.to_i == 0))
  end
  
  def send_notification
    @tempalte_edit_setting = MultiSchool.current_school.edit_sms_template
    @routes =  Route.all
  end
  
  def load_stops_selector
    @route = Route.find(params[:route_id])
    @stops = @route.vehicle_stops
    render :update do |page|
      page.replace_html "stop_selector", :partial => "stops_selector"
    end
  end
  
  def load_stop_recievers
    @user_type = "GroupMembers"
    @templates = MessageTemplate.all(:conditions=>["template_type = 'TRANSPORT'"])
    if params[:stop_type]=="pickup"
      @receivers = Transport.all(:conditions => ["(pickup_route_id = ? AND pickup_stop_id = ?)",params[:route_id] , params[:vehicle_stop_id]]).collect(&:receiver)
    elsif params[:stop_type]=="drop"
      @receivers = Transport.all(:conditions => ["(drop_route_id = ? AND drop_stop_id = ?)",params[:route_id] , params[:vehicle_stop_id]]).collect(&:receiver)
    else 
    end
    @user_list = @receivers.map { |u| {"id"=>u.user.id ,"value"=>u.user.full_name ,"child_count"=>0} }.sort_by{|x| x["value"].downcase}
    render :update do |page|
      page.replace_html "send_portion", :partial => "/sms/group_sms_send"
    end
  end
  
  def initiate_notification_send
    recipients = {:student_ids => student_ids, :employee_ids => employee_ids } 
    template_contents = {:employee => template_message[:employee], :student => template_message[:student]}
  end

  private
  
    def get_academic_year
      @academic_year_id = session[:transport_academic_year]||AcademicYear.active.first.try(:id)
    end
  
end
