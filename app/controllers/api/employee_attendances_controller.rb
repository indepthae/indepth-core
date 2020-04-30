class Api::EmployeeAttendancesController < ApiController
  lock_with_feature :hr_enhancement
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    @employee_attendances = EmployeeAttendance.search(params[:search]).all
    
    respond_to do |format|
      format.xml  { render :attendances }
    end

  end

  def create
    @xml = Builder::XmlMarkup.new
    @employee = Employee.first(:conditions => ["employee_number LIKE BINARY(?)",params[:employee_number]])
    @leave_type = EmployeeLeaveType.find_by_code(params[:leave_type_code])
    @attendance = EmployeeAttendance.new
    @attendance.employee_id = @employee.try(:id)
    @attendance.employee_leave_type_id = @leave_type.try(:id)
    @attendance.attendance_date = params[:date]
    @attendance.reason = params[:reason]
    @attendance.is_half_day = params[:is_half_day]
    @pending_application = ApplyLeave.find(:all, :conditions => ["employee_id = ? AND approved IS NULL AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))", @employee.id,params[:date],params[:date],params[:date],params[:date],params[:date],params[:date] ])
    @marked_attendance = EmployeeAttendance.first(:conditions => {:employee_id => @attendance.employee_id, :attendance_date => @attendance.attendance_date.to_date})
    respond_to do |format|
      if @marked_attendance.present?
        @attendance.errors.add_to_base('Attendance has been already marked for the selected date')       
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      elsif @pending_application.present?
        @attendance.errors.add_to_base("Pending leave application exist for the same date")
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      else
        @lop_status = @employee.lop_enabled && @leave_type.lop_enabled?
        @reset_count = EmployeeLeave.find_by_employee_id(@attendance.employee_id, :conditions=> "employee_leave_type_id = '#{@attendance.employee_leave_type_id}'")
        if @attendance.create_attendance
          is_deductable = params[:is_deductable].present? ? (@lop_status ? params[:is_deductable] : false ) : (@lop_status)
          additional_leave = EmployeeAdditionalLeave.find_by_employee_attendance_id(@attendance.id)
          additional_leave.update_attributes(:is_deductable => is_deductable) if additional_leave.present?
          flash[:notice] = 'Attendance was successfully created.'
          format.xml  { render :attendance, :status => :created }
        else
          format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def update
    @xml = Builder::XmlMarkup.new
    @employee = Employee.first(:conditions => ["employee_number LIKE BINARY(?)",params[:id]])
    @leave_type = EmployeeLeaveType.find_by_code(params[:leave_type_code])
    @attendance = EmployeeAttendance.find_by_employee_id_and_attendance_date(@employee.try(:id),params[:date])
    @att_id = @attendance.id
    @lop_status = @employee.lop_enabled && @leave_type.lop_enabled?
    @attendance.remove_additional_leaves
    respond_to do |format|
      if @attendance.update_attributes(:employee_leave_type_id => @leave_type.try(:id),:is_half_day => params[:is_half_day],:reason => params[:reason])
        @attendance.add_additional_leaves
        is_deductable = params[:is_deductable].present? ? (@lop_status ? params[:is_deductable] : false ) : (@lop_status)
        additional_leave = EmployeeAdditionalLeave.find_by_employee_attendance_id(@att_id)
        additional_leave.update_attributes(:is_deductable => is_deductable) if additional_leave.present?
        format.xml  { render :attendance }
      else
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @xml = Builder::XmlMarkup.new
    @employee = Employee.first(:conditions => ["employee_number LIKE BINARY(?)",params[:id]])
    @attendance = EmployeeAttendance.find_by_employee_id_and_attendance_date(@employee.try(:id),params[:date])
    @add_leave = EmployeeAdditionalLeave.find_by_employee_attendance_id(@attendance.id)
    respond_to do |format|
      unless @attendance.apply_leave_id.present?
        if @add_leave.present?
          unless @add_leave.is_deducted
            @attendance.destroy
            @attendance.remove_additional_leaves
            format.xml  { render :delete }
          else
            @attendance.errors.add_to_base("Lop is deducted cannot delete")
            format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
          end
        else
          @attendance.destroy
          @attendance.remove_additional_leaves
          format.xml  { render :delete }
        end
      else
        @attendance.errors.add_to_base("Leave marked through leave application.")
        format.xml  { render :xml => @attendance.errors, :status => :unprocessable_entity }
      end
    end
  end

end
