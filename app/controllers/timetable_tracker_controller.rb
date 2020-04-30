class TimetableTrackerController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index 
  end

  def class_timetable_swap
    @batches = Batch.active.all(:include=>:course)
  end

  def batch_timetable
    unless params[:batch][:batch_id].blank?
      @batch = Batch.find params[:batch][:batch_id]
      weekday = params[:batch][:date].to_date.strftime("%u").to_i
      weekday=0 if weekday==7
      @timetable_entries=@batch.timetable_entries.all(:conditions=>["timetable_entries.weekday_id=#{weekday} and
       class_timings.is_deleted=0 and (timetables.start_date <= '#{params[:batch][:date].to_date}' and
       timetables.end_date >='#{params[:batch][:date].to_date}')"],
        :joins=>[:class_timing,:timetable],:order=>'start_time ASC',:include=>[:class_timing,:employees,{:timetable_swaps=>[:employee,:subject]}])
      @timetable_swaps=TimetableSwap.all(:conditions=>{:date=>params[:batch][:date],:timetable_entry_id=>@timetable_entries.collect(&:id)},
        :include=>[:employee,:subject]).group_by(&:timetable_entry_id)
      render :update do |page|
        page.replace_html "timetable", :partial => "batch_timetable"
        page.replace_html "error", :text => ""
      end
    else
      flash[:warn_notice]="#{t('batch_cant_be_blank')}"
      render :update do |page|
        page.replace_html "error", :partial => "error"
      end
    end
  end
 
  def employee_wise_timetable
    unless params[:employee][:employee_id].blank?
      @employee  = Employee.find params[:employee][:employee_id]
      weekday = params[:employee][:date].to_date.strftime("%u").to_i
      weekday=0 if weekday==7
      @timetable_entries= @employee.timetable_entries.all(:conditions=>["timetable_entries.weekday_id=#{weekday} and
         class_timings.is_deleted=0 and batches.is_active = 1 and  (timetables.start_date <= '#{params[:employee][:date].to_date}' and
         timetables.end_date >='#{params[:employee][:date].to_date}')"],
        :joins=>[:class_timing, :batch , :timetable],:order=>'start_time ASC',
        :include=>[:class_timing, :batch ,:employees,{:timetable_swaps=>[:employee,:subject]}])
      @timetable_swaps=TimetableSwap.all(:conditions=>{:date=>params[:employee][:date],:timetable_entry_id=>@timetable_entries.collect(&:id)},
        :include=>[:employee,:subject]).group_by(&:timetable_entry_id)
      @timetable_entries = @timetable_entries.group_by(&:batch_id) 
      @emp_swaps = TimetableSwap.all(:select => "timetable_swaps.*, batches.id as batch_id,batches.name as batch_name, class_timings.start_time as start_time, class_timings.end_time as end_time ",  :conditions => {:date => params[:employee][:date], 
          :employee_id => params[:employee][:employee_id]},
        :joins=>{:timetable_entry => [:batch, :timetable, :class_timing]},
        :include=>[:employee,:subject, {:timetable_entry =>[:batch, :timetable, :class_timing]}])
      @swapping_type = "emp_wise"
      render :update do |page|
        page.replace_html "timetable1", :partial => "employee_wise_timetable"
        page.replace_html "error", :text => ""
      end
    else
      flash[:warn_notice]="#{t('employee_cant_be_blank')}"
      render :update do |page|
        page.replace_html "error", :partial => "error"
      end
    end 
  end
 
  
  def timetable_swap_from
    batch = Batch.find params[:batch_id]
    if validate_batch(batch)
      @emp_wise_id = params[:employee_wise_id]
      @employees = params[:employees]
      @subjects = batch.subjects.active.all(:conditions=>{:elective_group_id=>nil})
      @departments = EmployeeDepartment.ordered(:joins=>[{:employees=>:employees_subjects}]).uniq
      render :update do |page|
        page.replace_html "link_#{params[:timetable_entry_id]}", :partial => "timetable_swap_form"
        page << "$('cancel_entry_#{params[:timetable_entry_id]}').hide()"
        page << "update_options(#{params[:timetable_entry_id]})"
      end  
    end
  end

  def batch_wise
    @batches = Batch.active.all(:include=>:course)
    render :update do |page|
      page.replace_html "batch_wise_swap", :partial => "batch_wise"
    end
  end
  
  def employee_wise
    @departments = EmployeeDepartment.ordered
    render :update do |page|
      page.replace_html "employee_wise_swap", :partial => "employee_wise"
    end
  end
  
  def cancel_timetable_period
    batch=Batch.find params[:batch_id] 
    if validate_batch(batch)
      error=true
      alert_notify = params[:notify].present? ? params[:notify].to_i : 0
      unless params[:timetable_swap_id].present?
        @timetable_swap=TimetableSwap.new(:alert_notify => alert_notify, :date=>params[:date],:timetable_entry_id=>params[:timetable_entry_id],
          :is_cancelled => true)
        if @timetable_swap.save        
          error=false
        end
      else
        @timetable_swap=TimetableSwap.find params[:timetable_swap_id]
        if @timetable_swap.update_attributes(:alert_notify => alert_notify, :date=>params[:date],:timetable_entry_id=>params[:timetable_entry_id],:employee_id=> nil,:subject_id=>  nil, :is_cancelled => true, :prev_subject => @timetable_swap.subject_id, :prev_employee => @timetable_swap.employee_id)
          error=false
        end
      end
      unless error
        @timetable_entry = @timetable_swap.timetable_entry if @timetable_swap.present?
        render :update do |page|
          page.replace_html "entry_#{params[:timetable_entry_id]}", :partial => "new_timetable_entry"
          page.replace_html "error", :text => ""
          page << "update_tte_cancel(#{params[:timetable_entry_id]})"
        end
      else
        render :update do |page|
          page.replace_html "error", :partial => "error"
          page << "reset_timetable_period_options(#{params[:timetable_entry_id]});"
        end
      end
   end
  end
  
  
  
  
  def list_employees
    @department = params[:department_id]
    @employees=Employee.all(:joins=>[:employee_department,:employees_subjects],:conditions=>{:employee_departments=>{:id=>params[:department_id]}}).uniq
    render :update do |page|
      page.replace_html "employee_list_#{params[:timetable_entry_id]}", :partial => "list_employees"
      page << "update_submit(j('#link_'+#{params[:timetable_entry_id]}).find('#timetable_employee_id'))"
    end
  end
  
  def list_employee_wise
    @employees=Employee.all(:joins=>[:employee_department,:employees_subjects],:conditions=>{:employee_departments=>{:id=>params[:department_id]}}).uniq
    @department = params[:department_id]
    render :update do |page|
      page.replace_html "employee_employee_id", :partial => "list_employee_wise"
    end
  end
  
  
  def validate_swap_employees
    @current_timetable_entry = TimetableEntry.find(params[:timetable_entry_id], :include => :class_timing)
    @current_class_timing = @current_timetable_entry.class_timing
    wkday_id = @current_timetable_entry.weekday_id
    emp_id = params[:employee_id]
    dated = params[:date]
    start_date = dated+" "+"00:00:01"
    end_date = dated+ " "+"23:59:59"
    department = params[:department_id]
    employee  = Employee.find params[:employee_id]
    weekday = params[:date].to_date.strftime("%u").to_i
    weekday=0 if weekday==7
    @timetable_entries= employee.timetable_entries.all(:conditions=>["timetable_entries.weekday_id=#{weekday} and
      class_timings.is_deleted=0 and batches.is_active = 1 and (timetables.start_date <= '#{params[:date].to_date}' and
      timetables.end_date >='#{params[:date].to_date}')"],
      :joins=>[:class_timing, :batch, :timetable],:order=>'start_time ASC',
      :include=>[:class_timing, :batch ,:employees,{:timetable_swaps=>[:employee,:subject]}]) 
    @class_timings = @timetable_entries
    @timetable_entries = @timetable_entries.group_by(&:batch_id) 
    @emp_swaps = TimetableSwap.all(:select => "timetable_swaps.*, batches.id as batch_id,batches.name as batch_name, 
    class_timings.start_time as start_time, class_timings.end_time as end_time ",  :conditions => {:date => params[:date], 
        :employee_id => params[:employee_id]},:joins=>{:timetable_entry => [:batch, :timetable, :class_timing]},
      :include=>[:employee,:subject, {:timetable_entry =>[:batch, :timetable, :class_timing]}])
    @employee = Employee.find(params[:employee_id])
   
    @events = Event.all(:conditions => ["(employee_department_id = ? or is_common = ? ) and ((start_date between ?  and ? ) or
 (end_date between  ? and ? )) or( ? between start_date and end_date and (employee_department_id = ? or is_common = ? )) ",
        department, true, start_date , end_date, start_date, end_date,  dated ,  department, true],
      
      
      
      :joins => "left outer join employee_department_events ede on ede.event_id = events.id ", :group => "events.id")
    render :update do |page|      
      page.replace_html "status_record_#{params[:timetable_entry_id]}" , :partial => "status_of_teacher"
      page << ("j('#timetable_employee_id').addClass('overlap_validated');update_submit(j('#link_'+#{params[:timetable_entry_id]}).find('#timetable_employee_id'));")
    end 
  end
 
  def timetable_swap
    @emp_wise_id = params[:employee_wise_id]
    batch = Batch.find params[:batch_id]
    if validate_batch(batch)
      error=true
      if params[:timetable_swap_id].nil?
        @timetable_swap=TimetableSwap.new(:alert_notify => params[:timetable][:notify].to_i, :date=>params[:date],
          :timetable_entry_id=>params[:timetable_entry_id],:employee_id=>params[:timetable][:employee_id],:subject_id=>params[:timetable][:subject_id])      
        if @timetable_swap.save
          error=false 
        end
      else
        @timetable_swap=TimetableSwap.find(params[:timetable_swap_id], :include => :timetable_entry)
        if @timetable_swap.update_attributes(:alert_notify => params[:timetable][:notify].to_i, :date=>params[:date],:timetable_entry_id=>params[:timetable_entry_id],:employee_id=>params[:timetable][:employee_id],:subject_id=>params[:timetable][:subject_id])
          error=false
        end
      end
      @timetable_entry = @timetable_swap.timetable_entry if @timetable_swap.present?
    
      unless error
        render :update do |page|
          page.replace_html "link_#{params[:timetable_entry_id]}", :partial => "new_timetable_entry"
          page.replace_html "entry_#{params[:timetable_entry_id]}", :partial => "new_timetable_entry"
          page.replace_html "error", :text => ""
          page << "set_swap_data(#{params[:timetable_entry_id]});"
        end
      else
        render :update do |page|
          page.replace_html "error", :partial => "error"
        end
      end
    end
  end
  

  def timetable_swap_delete
    batch = Batch.find params[:batch_id]
    if validate_batch(batch)
      @swapping_type = params[:type]
      if @swapping_type == "emp_wise"
         @employee = Employee.find params[:employee_wise_id]
      end
      @timetable_swap=TimetableSwap.find_by_id(params[:timetable_swap_id], :include => :timetable_entry)
      @timetable_entry = @timetable_swap.timetable_entry
      if @timetable_swap.present? and @timetable_swap.destroy
        params[:timetable_swap_id]=nil if params[:action_type].present?
        render :update do |page|
          page.replace_html "entry_#{params[:timetable_entry_id]}", :partial => "timetable_swap_link"
          page.replace_html "cancel_entry_#{params[:timetable_entry_id]}", :partial => "cancel_timetable_entry_link"
          page << "reset_timetable_period_options(#{params[:timetable_entry_id]}, true);"
        end
      else
        render :update do |page|
          page.replace_html "error", :partial => "error"
        end
      end
    end
  end

  def swaped_timetable_report
    @date={}
    @date[:from]=Date.today
    @date[:to]=Date.today
    @employees=swaped_timetable_details(@date)
    if request.xhr?
      @date=params[:employee_details]
      @employees=swaped_timetable_details(@date)
      render :update do |page|
        page.replace_html "information", :partial => "employee_details"
      end
    end
  end

  def employee_report_details
    @over_time_details=TimetableSwap.all(:conditions=>{:employee_id=>params[:employee_id],:date=>params[:date][:from].to_date.beginning_of_day..params[:date][:to].to_date.end_of_day}, :include=>[:employee,:subject,{:timetable_entry=>[:employees,:entry,:class_timing,{:batch=>:course}]}])
    @lagging_details=TimetableEntry.all(:select=>"timetable_entries.*,ts.date,ts.is_cancelled",:conditions=>{"ttte.employee_id"=>params[:employee_id], "ts.date"=>params[:date][:from].to_date.beginning_of_day..params[:date][:to].to_date.end_of_day},:joins=>"INNER JOIN timetable_swaps ts ON ts.timetable_entry_id = timetable_entries.id INNER JOIN teacher_timetable_entries ttte ON ttte.timetable_entry_id = timetable_entries.id",:include=>[:employees,:class_timing,{:batch=>:course},{:timetable_swaps=>[:subject,:employee]}])
    render :update do |page|
      page.replace_html "list_#{params[:employee_id]}", :partial => "employee_report_details"
    end
  end

  def swaped_timetable_report_csv
    employees=swaped_timetable_details(params[:employee_details])
    csv_string=FasterCSV.generate do |csv|
      cols=["#{t('employee_text')}","#{t('department')}","#{t('replacement_status')}"]
      csv << cols
      employees.each do |employee|
        col=[]
        col<< "#{employee.first_name} #{employee.middle_name} #{employee.last_name} - #{employee.emp_id}"
        col<< "#{employee.department}"
        count=[]
        unless employee.over_time.blank?
          count<< "#{employee.over_time} + "
        end
        unless employee.lagging.blank?
          count<< "#{employee.lagging} -"
        end
        col << count.join("  ")
        col=col.flatten
        csv<< col
      end
    end
    filename = "#{t('swaped_timetable')} #{t('report')}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end
  
end
private

def swaped_timetable_details(date)
  employees_ot=TimetableSwap.all(:select=>"timetable_swaps.is_cancelled,employees.first_name,employees.last_name,employees.middle_name,employees.id as eid,count(employees.id) as over_time,employee_departments.name as department,employees.employee_number as emp_id",:group=>"employee_id",:joins=>{:employee=>:employee_department},:conditions=>{:date=>date[:from].to_date.beginning_of_day..date[:to].to_date.end_of_day})
  employees_lag=TimetableEntry.all(:select=>"timetable_swaps.is_cancelled,employees.first_name,employees.last_name,employees.middle_name,employees.employee_number as emp_id,employees.id as eid ,count(timetable_entries.id) as lagging , employee_departments.name as department",:joins=>[{:employees=>:employee_department},:timetable_swaps],:group=>"employees.id",:conditions=>{:timetable_swaps=>{ :date=>date[:from].to_date.beginning_of_day..date[:to].to_date.end_of_day}})
  emp_lag=employees_lag.group_by(&:emp_id)
  emp_ot=employees_ot.group_by(&:emp_id)
  employees_ot.each do|emp|
    emp["lagging"] = emp_lag[emp.emp_id].nil? ? "" : emp_lag[emp.emp_id][0].lagging
  end
  employees_lag.each do |emp|
    emp["over_time"] = emp_ot[emp.emp_id].nil? ? "" : emp_ot[emp.emp_id][0].over_time
  end
  employees=employees_ot+employees_lag
  employees= Hash[*(employees).map {|obj| [obj.emp_id, obj]}.flatten].values
  employees=employees.sort_by{|emp| emp.first_name.downcase}
  return employees
end

def validate_batch(batch)
  unless batch.is_active
    render :update do |page|
      flash[:notice] = "#{ t('batch_inactivate') }"
      page.redirect_to :controller => :timetable_tracker, :action => 'class_timetable_swap'
    end
    return
  else
    return 1
  end
end