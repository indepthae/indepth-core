class HostelsController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:except => [:student_hostel_details]
  filter_access_to [:student_hostel_details], :attribute_check => true, :load_method => lambda { Student.find(params[:id]) }
  before_filter :set_precision
  before_filter :protect_other_student_data, :only =>[:student_hostel_details]

  require 'fastercsv'
  def index
    @hostels = Hostel.all
  end

  def hostel_dashboard

  end

  def new
    @hostel = Hostel.new
    @additional_fields = HostelAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"hostel_additional_field_options")
    @hostel_additional_fields = @additional_fields.map{|a| @hostel.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id)}
    @departments = EmployeeDepartment.ordered
    @employees = []
  end

  def create
    @hostel = Hostel.new(params[:hostel])
    @departments = EmployeeDepartment.ordered
    @employees = []
    if @hostel.save
      redirect_to hostels_path, flash[:notice] = "#{t('hostel_added_successfully')}"
    else
      @additional_fields = HostelAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"hostel_additional_field_options")
      @additional_fields.each{|a| @hostel.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id) unless @hostel.hostel_room_additional_details.collect(&:hostel_room_additional_field_id).include? a.id}
      @hostel_additional_details=@hostel.hostel_room_additional_details
      @hostel_additional_details=@hostel_additional_details.sort_by { |x| x.hostel_room_additional_field.priority  }
      render :action => "new"
    end
  end

  def edit
    @hostel = Hostel.find(params[:id])
    @additional_fields = HostelAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"hostel_additional_field_options")
    @hostel_additional_details = @hostel.hostel_room_additional_details.all(:conditions=>"hostel_room_additional_fields.is_active = true and hostel_room_additional_fields.type='HostelAdditionalField'",:include=>"hostel_room_additional_field")
    @additional_fields.select{|a| @hostel_additional_details.push(@hostel.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id)) unless @hostel_additional_details.collect(&:hostel_room_additional_field_id).include?(a.id)}
    @hostel_additional_details=@hostel_additional_details.sort_by { |x| x.hostel_room_additional_field.priority  }
  end

  def update
    @hostel = Hostel.find(params[:id])
    @departments = EmployeeDepartment.ordered
    if @hostel.update_attributes(params[:hostel])
      flash[:notice]="#{t('hostel_details_successfully_updated')}"
      redirect_to hostels_path
    else
      @additional_fields = HostelAdditionalField.find(:all, :conditions=> "is_active = true", :order=>"priority ASC",:include=>"hostel_additional_field_options")
      @additional_fields.each{|a| @hostel.hostel_room_additional_details.build(:hostel_room_additional_field_id=>a.id) unless @hostel.hostel_room_additional_details.collect(&:hostel_room_additional_field_id).include? a.id}
      @hostel_additional_details=@hostel.hostel_room_additional_details.select{|a| a.hostel_room_additional_field.is_active==true}
      @hostel_additional_details=@hostel_additional_details.sort_by { |x| x.hostel_room_additional_field.priority  }
      render :action => "edit"
    end
  end

  def show
    @hostel = Hostel.find params[:id]
    @warden = Warden.find_all_by_hostel_id(@hostel.id)
    @total_rooms = RoomDetail.all(:conditions=>["hostel_id=#{params[:id]}"]).count
    @room_details = RoomDetail.paginate(:conditions=>["hostel_id=#{params[:id]}"], :page=>params[:page])
    @additional_details = @hostel.hostel_room_additional_details.all(:conditions=>"hostel_room_additional_fields.is_active = true and hostel_room_additional_fields.type='HostelAdditionalField'",:include=>"hostel_room_additional_field")
    @additional_details=@additional_details.sort_by { |x| x.hostel_room_additional_field.priority  }
  end



  def sort_by
    sort = params[:sort][:on]
    @hostels = Hostel.search(:status_like=>"#{sort}").paginate(:all,:page=>params[:page],:include=>:tags)
    @count = @hostels.total_entries
    render(:update) do |page|
      page.replace_html 'hostels', :partial=>'hostels'
    end
  end

  def add_additional_details
    @all_details = HostelAdditionalField.find(:all,:order=>"priority ASC")
    @additional_details = HostelAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = HostelAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = HostelAdditionalField.new
    @hostel_additional_field_option = @additional_field.hostel_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = HostelAdditionalField.new(params[:hostel_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "Additional field added successfully"
        redirect_to :controller => "hostels", :action => "add_additional_details"
      end
    end
  end

  def change_field_priority
    @additional_field = HostelAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = HostelAdditionalField.find(:all, :conditions=>{:is_active=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = HostelAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = HostelAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = HostelAdditionalField.new
    @additional_details = HostelAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = HostelAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields"
    end
  end

  def edit_additional_details
    @additional_details = HostelAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
    @inactive_additional_details = HostelAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
    @additional_field = HostelAdditionalField.find(params[:id])
    @hostel_additional_field_option = @additional_field.hostel_additional_field_options
    if request.get?
      render :action=>'add_additional_details'
    else
      if @additional_field.update_attributes(params[:hostel_additional_field])
        flash[:notice] = "Additional field updated successfully"
        redirect_to :action => "add_additional_details"
      else
        render :action=>"add_additional_details"
      end
    end
  end

  def delete_additional_details
    hostels = HostelRoomAdditionalDetail.find(:all ,:conditions=>"hostel_room_additional_field_id = #{params[:id]}")
    if hostels.blank?
      HostelRoomAdditionalField.find(params[:id]).destroy
      @additional_details = HostelRoomAdditionalField.find(:all, :conditions=>{:is_active=>true},:order=>"priority ASC")
      @inactive_additional_details = HostelRoomAdditionalField.find(:all, :conditions=>{:is_active=>false},:order=>"priority ASC")
      flash[:notice]="Additional field deleted successfully"
      redirect_to :action => "add_additional_details"
    else
      flash[:notice]="Additional field is in use and cannot be deleted"
      redirect_to :action => "add_additional_details"
    end
  end


  def room_delete
    @room_detail = RoomDetail.find(params[:id])
    hostel = @room_detail.hostel_id
    @vacant = RoomAllocation.find_all_by_room_detail_id(params[:id], :conditions=>["is_vacated is false"])
    if @vacant.size == 0
      @room_detail.destroy
      flash[:message2]=''
      flash[:message]="#{t('room_has_been_successfully_deleted')}"
    else
      flash[:message]=''
      flash[:message2]="#{t('unable_to_delete_the_room_when_allocated')}"
    end
    redirect_to :action => 'show', :id=>hostel
  end

  def destroy
    @hostel = Hostel.find(params[:id])
    if @hostel.destroy
      flash[:notice] = "Hostel has been successfully deleted"
      redirect_to :action => 'index'
    else
      @hostels = Hostel.all
      render :action=> 'index'
    end
  end

  def update_employees
    @employees = Employee.find_all_by_employee_department_id params[:department_id]
    render :update do |page|
      page.replace_html 'employee_list', :partial => 'employee_list'
    end
  end

  def student_hostel_details
    @current_user = current_user
    @available_modules = Configuration.available_modules
    @currency = currency
    @student = Student.find(params[:id])
    @room_allocation = @student.current_allocation
    unless @room_allocation.blank?
      @room_detail = @room_allocation.room_detail
      @hostel = @room_detail.hostel
    end
  end
  def room_availability_details
    @sort_order=params[:sort_order]
    if @sort_order.nil?
      @hostels=Hostel.paginate(:select=>"hostels.id as hostel_id,name,hostel_type,count(DISTINCT room_details.id) as total_rooms",:joins=>"LEFT OUTER JOIN `room_details` ON room_details.hostel_id = hostels.id LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'hostel_id',:page=>params[:page],:per_page=>20,:order=>'name ASC')
      h_ids=@hostels.collect(&:hostel_id)
      available={}
      RoomDetail.all(:select=>"hostel_id,room_details.id,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'id',:conditions=>{:hostel_id=>h_ids},:having=>'available > 0',:order=>'room_number ASC').group_by(&:hostel_id).each do |key,val|
        available[key]=val.count
      end
      @hostels.each do |h|
        h['available']=available[h.hostel_id.to_i]
        h['occupied']=h.total_rooms.to_i-h.available.to_i
      end
      @warden=Warden.all(:select=>"employee_id as emp_id,hostel_id,wardens.id,employees.first_name,employees.middle_name,employees.last_name",:joins=>[:employee],:conditions=>{:hostel_id=>h_ids},:order=>'first_name ASC').group_by(&:hostel_id)
    else
      @hostels=Hostel.paginate(:select=>"hostels.id as hostel_id,name,hostel_type,count(DISTINCT room_details.id) as total_rooms",:joins=>"LEFT OUTER JOIN `room_details` ON room_details.hostel_id = hostels.id LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'hostel_id',:page=>params[:page],:per_page=>20,:order=>@sort_order)
      h_ids=@hostels.collect(&:hostel_id)
      available={}
      RoomDetail.all(:select=>"hostel_id,room_details.id,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'id',:conditions=>{:hostel_id=>h_ids},:having=>'available > 0',:order=>'room_number ASC').group_by(&:hostel_id).each do |key,val|
        available[key]=val.count
      end
      @hostels.each do |h|
        h['available']=available[h.hostel_id.to_i]
        h['occupied']=h.total_rooms.to_i-h.available.to_i
      end
      @warden=Warden.all(:select=>"employee_id as emp_id,hostel_id,wardens.id,employees.first_name,employees.middle_name,employees.last_name",:joins=>[:employee],:conditions=>{:hostel_id=>h_ids},:order=>'first_name ASC').group_by(&:hostel_id)
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "room_details"
      end
    end
  end

  def room_availability_details_csv
    sort_order=params[:sort_order]
    if sort_order.nil?
      hostels=Hostel.all(:select=>"hostels.id as hostel_id,name,hostel_type,count(DISTINCT room_details.id) as total_rooms",:joins=>"LEFT OUTER JOIN `room_details` ON room_details.hostel_id = hostels.id LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'hostel_id',:order=>'name ASC')
      h_ids=hostels.collect(&:hostel_id)
      available={}
      RoomDetail.all(:select=>"hostel_id,room_details.id,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'id',:conditions=>{:hostel_id=>h_ids},:having=>'available > 0',:order=>'room_number ASC').group_by(&:hostel_id).each do |key,val|
        available[key]=val.count
      end
      hostels.each do |h|
        h['available']=available[h.hostel_id.to_i]
        h['occupied']=h.total_rooms.to_i-h.available.to_i
      end
      warden=Warden.all(:select=>"employee_id as emp_id,hostel_id,wardens.id,employees.first_name,employees.middle_name,employees.last_name",:joins=>[:employee],:conditions=>{:hostel_id=>h_ids},:order=>'first_name ASC').group_by(&:hostel_id)
    else
      hostels=Hostel.all(:select=>"hostels.id as hostel_id,name,hostel_type,count(DISTINCT room_details.id) as total_rooms",:joins=>"LEFT OUTER JOIN `room_details` ON room_details.hostel_id = hostels.id LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'hostel_id',:order=>sort_order)
      h_ids=hostels.collect(&:hostel_id)
      available={}
      RoomDetail.all(:select=>"hostel_id,room_details.id,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'id',:conditions=>{:hostel_id=>h_ids},:having=>'available > 0',:order=>'room_number ASC').group_by(&:hostel_id).each do |key,val|
        available[key]=val.count
      end
      hostels.each do |h|
        h['available']=available[h.hostel_id.to_i]
        h['occupied']=h.total_rooms.to_i-h.available.to_i
      end
      warden=Warden.all(:select=>"employee_id as emp_id,hostel_id,wardens.id,employees.first_name,employees.middle_name,employees.last_name",:joins=>[:employee],:conditions=>{:hostel_id=>h_ids},:order=>'first_name ASC').group_by(&:hostel_id)
    end
    csv_string=FasterCSV.generate do |csv|
      cols=["#{t('no_text')}","#{t('name')}","#{t('hostel_type') }","#{t('total_rooms') }","#{t('available_rooms')}","#{t('occupied_rooms')}","#{t('warden')}"]
      csv << cols
      hostels.each_with_index do |s,i|
        col=[]
        col<< "#{i+1}"
        col<< "#{s.name}"
        col<< "#{s.hostel_type}"
        col<< "#{s.total_rooms}"
        col<< "#{s.available.nil?? 0 : s.available }"
        col<< "#{s.occupied}"
        ward=warden[s.hostel_id.to_i]
        unless ward.nil?
          war=[]
          ward.each do |s|
            war << "#{s.first_name} #{s.middle_name} #{s.last_name}"
          end
          col << "#{war.join("\n")}"
        else
          col<< "--"
        end
        col=col.flatten
        csv<< col
      end
    end
    filename = "#{t('hostel_text')}#{t('room_details')}- #{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def room_list
    @sort_order=params[:sort_order]
    @hostel=Hostel.find_by_id(params[:id],:select=>'name,hostel_type')
    if params[:type].nil?
      if @sort_order.nil?
        @rooms=RoomDetail.paginate(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:per_page=>20,:page=>params[:page],:conditions=>{:hostel_id=>params[:id]},:order=>'room_number ASC')
      else
        @rooms=RoomDetail.paginate(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:per_page=>20,:page=>params[:page],:conditions=>{:hostel_id=>params[:id]},:order=>@sort_order)
      end
    else
      if params[:type]=='available'
        room_count=RoomDetail.all(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>params[:id]},:having=>'available > 0').count
        if @sort_order.nil?
          @rooms=RoomDetail.paginate(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>params[:id]},:having=>'available > 0',:per_page=>20,:page=>params[:page],:total_entries=>room_count,:order=>'room_number ASC')
        else
          @rooms=RoomDetail.paginate(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>params[:id]},:having=>'available > 0',:per_page=>20,:page=>params[:page],:total_entries=>room_count,:order=>@sort_order)
        end
      else
        room_count=RoomDetail.all(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>params[:id]},:having=>'available = 0').count
        if @sort_order.nil?
          @rooms=RoomDetail.paginate(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>params[:id]},:having=>'available = 0',:per_page=>20,:page=>params[:page],:total_entries=>room_count,:order=>'room_number ASC')
        else
          @rooms=RoomDetail.paginate(:select=>"hostel_id,rent,room_details.id,room_number,students_per_room,(students_per_room-count(IF(is_vacated=0,1,NULL))) as available" ,:joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",:group=>'room_number',:conditions=>{:hostel_id=>params[:id]},:having=>'available = 0',:per_page=>20,:page=>params[:page],:total_entries=>room_count,:order=>@sort_order)
        end
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "room_list_details"
      end
    end
  end

  def room_list_csv
    parameters={:sort_order=>params[:sort_order],:type=>params[:type],:hostel_id=>params[:id]}
    model='room_detail'
    method='room_list'
    csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model,method)
    if csv_report.nil?
      csv_report=AdditionalReportCsv.new(:model_name => model, :method_name => method, :parameters => parameters, :status => true)
      if csv_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
      end
    else
      unless csv_report.status
        if csv_report.update_attributes(:parameters => parameters, :csv_report => nil, :status => true)
          Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
        end
      end 
    end
    flash[:notice]="#{t('csv_report_is_in_queue')}"
    redirect_to :controller=>:report,:action=>:csv_reports,:model=>model,:method=>method
  end

  def individual_room_details
    @room_details=RoomDetail.first(:select=>"room_number,students_per_room,hostel_id,hostels.name",:joins=>[:hostel],:conditions=>{:id=>params[:id]})
    @students=RoomAllocation.all(:select=>"students.id as student_id,courses.code as course_code,courses.course_name,students.first_name,students.middle_name,students.last_name,students.admission_no,batches.name as batch_name",:conditions=>{:room_detail_id=>params[:id],:is_vacated=>false},:joins=>"INNER JOIN `students` ON `students`.id = `room_allocations`.student_id INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN courses on courses.id = batches.course_id")
  end
end
