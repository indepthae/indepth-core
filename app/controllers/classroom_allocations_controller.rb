include WeekdayArranger
class ClassroomAllocationsController < ApplicationController
  before_filter :login_required
  after_filter :check_allocation_exist, :only => :delete_allocation
  filter_access_to :all
  before_filter :check_building_defined, :only => [:weekly_allocation,:date_specific_allocation]
  
  def index
    @user = current_user
  end

  def new
    @classroom_allocation = ClassroomAllocation.new
    timetable_entries = TimetableEntry.all.map{|tte| tte.timetable_id }.uniq
    @timetables = Timetable.find(:all, :joins=> :timetable_entries, :select => 'distinct timetables.*', :conditions =>['timetables.id IN (?)', timetable_entries]).uniq
  end

  def view
    @timetables = Timetable.find(:all, :joins=> "LEFT OUTER JOIN timetable_entries tte ON tte.timetable_id = timetables.id", :select => 'distinct timetables.*')
    @current_timetable=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", Time.now.to_date, Time.now.to_date])
    if params[:allocation_type] == "weekly"
      render(:update) do |page|
        page.replace_html "render_partial", :partial => "select_timetable", :locals => {:allocation_type => params[:allocation_type]}
      end
    elsif params[:allocation_type] == "date_specific"
      render(:update) do |page|
        page.replace_html "render_partial", :partial => "select_month_year"
      end
    end
  end

  def weekly_allocation
    unless @building.empty? or @classroom.empty?
      @tte_id = params[:timetable_id]
      @alloc_type = params[:alloc_type]
      if params[:timetable_id].present?
        hsh = make_data_hash
        if hsh["timetable_entries"].empty?
          flash[:notice] = "#{t('no_tte')}"
          render(:update) do|page|
            page.replace_html "flash", :partial => "warning"
          end
          return
        end
        hsh['days'] = weekday_hash
        respond_to do |fmt|
          fmt.json {render :json=> hsh}
        end
      else
        flash[:notice] = "#{t('select_tt')}"
        render(:update) do|page|
          page.replace_html "flash", :partial => "warning"
        end
      end
    else
      flash[:notice] = "#{t('define_building_continue')}"
      render(:update) do|page|
        page.replace_html "flash", :partial => "warning"
      end
    end
  end

  def date_specific_allocation
    unless @building.empty? or @classroom.empty?
      @alloc_type = params[:alloc_type]
      if params[:date].length > 1
        hsh = make_data_hash
        if hsh["timetable_entries"].empty?
          flash[:notice] = "#{t('no_tte')}"
          render(:update) do|page|
            page.replace_html "flash", :partial => "warning"
          end
          return
        end
        hsh['days'] = []
        month = params[:date].split("-")[1]
        year = params[:date].split("-")[0]
        days_of_month = (Date.new(year.to_i,12,31) << (12-month.to_i)).day
        i=1
        while(i<= days_of_month)
          day = Date.parse("#{params[:date]}-#{i}").strftime("%a")
          hsh['days'] << i.to_s + " " + t(day.downcase)
          i+=1
        end
        respond_to do |fmt|
          fmt.json {render :json=> hsh}
        end
      else
        flash[:notice] = "#{t('select_month_year')}"
        render(:update) do|page|
          page.replace_html "flash", :partial => "warning"
        end
      end
    else
      flash[:notice] = "#{t('define_building_continue')}"
      render(:update) do|page|
        page.replace_html "flash", :partial => "warning"
      end
    end
  end

  def render_classrooms
    @buildings =  Building.find(:all, :order => "name")
    @rooms = @buildings.first.classrooms.paginate(:per_page => 10, :page => params[:page])
    render :partial => "classrooms" 
  end

  def display_rooms
    @building = Building.find(params[:building_id])
    @rooms = @building.classrooms.paginate(:per_page => 10, :page => params[:page])
    render :partial => "display_rooms"
  end

  def delete_allocation
    classroom_allocation = ClassroomAllocation.find(:first,:conditions => ["allocation_type = ? and (date = ? or timetable_id = ?)",params[:alloc_type],params[:date],params[:tt_id]])
    AllocatedClassroom.destroy_all("classroom_id = #{params[:room_id]} and subject_id = #{params[:sub_id]} and timetable_entry_id = #{params[:tte_id]} and classroom_allocation_id = #{classroom_allocation.id}")
    respond_to do |fmt|
      fmt.json {render :json=> ""}
    end
  end

  def find_allocations
    allocated_classrooms = AllocatedClassroom.find(:all, :select => "id,classroom_allocation_id,classroom_id,subject_id,timetable_entry_id,date")
    classroom_allocations = ClassroomAllocation.find(:all, :select => "id,allocation_type,timetable_id,date")
    hsh = {:allocations => allocated_classrooms, :classroom_alloc => classroom_allocations}
    respond_to do |fmt|
      fmt.json {render :json => hsh}
    end
  end
  
  def update_allocation_entries
    @flag = true
    timetable_entry = TimetableEntry.find(params[:tte_id]) 
    batch_strength = Batch.find(params[:batch_id]).students.count
    classroom_capacity = Classroom.find(params[:classroom_id]).capacity
    if params[:alloc_type] == "weekly"
      allocation = ClassroomAllocation.find_or_create_by_allocation_type_and_timetable_id(params[:alloc_type],params[:timetable])
    elsif params[:alloc_type] == "date_specific"
      allocation = ClassroomAllocation.find_or_create_by_allocation_type_and_date(params[:alloc_type],params[:date])
    end
    @allocated_warning = []
    validate_allocation(allocation.id,timetable_entry,params[:alloc_type],batch_strength,classroom_capacity) 
    allocation_status = false
    if @allocated_warning.empty? && @flag == true
      if params[:alloc_type] =="weekly"
        create_allocation = AllocatedClassroom.create(:classroom_id => params[:classroom_id], :timetable_entry_id => params[:tte_id], :classroom_allocation_id => allocation.id, :subject_id => params[:subject_id])
#        create_allocation = AllocatedClassroom.create(:classroom_id => params[:classroom_id], :timetable_entry_id => timetable_entry_id, :classroom_allocation_id => allocation.id, :subject_id => params[:subject_id])
      elsif params[:alloc_type] == "date_specific"
        create_allocation = AllocatedClassroom.create(:classroom_id => params[:classroom_id], :timetable_entry_id => params[:tte_id], :classroom_allocation_id => allocation.id, :subject_id => params[:subject_id], :date => params[:date])
#        create_allocation = AllocatedClassroom.create(:classroom_id => params[:classroom_id], :timetable_entry_id => timetable_entry_id, :classroom_allocation_id => allocation.id, :subject_id => params[:subject_id], :date => params[:date])
      end
    end

    if create_allocation.present?
      if create_allocation.save
        allocation_status = true
      end
    end
    respond_to do |fmt|
      fmt.json {render :json=> {:status => allocation_status,:flag => @flag,:msg => @allocated_warning,:classroom => params[:classroom_id], :timetable_entry=> timetable_entry.id, :allocation => allocation.id, :subject => params[:subject_id]}}
    end
  end

  
  def override_allocations
    unless @flag == false
      if params[:alloc_type] == "weekly"
        allocation = AllocatedClassroom.create(:classroom_id => params[:classroom], :timetable_entry_id => params[:timetable_entry], :classroom_allocation_id => params[:allocation], :subject_id => params[:subject])
      elsif params[:alloc_type] == "date_specific"
        allocation = AllocatedClassroom.create(:classroom_id => params[:classroom], :timetable_entry_id => params[:timetable_entry], :classroom_allocation_id => params[:allocation], :subject_id => params[:subject], :date => params[:date])
      end
    end
    
    respond_to do |fmt|
      fmt.json {render :json=> {}}
    end
    
  end

  private

  def check_building_defined
    @building = Building.all
    @classroom = Classroom.all
  end
  
  def check_allocation_exist
    classroom_allocation = ClassroomAllocation.find(:first,:conditions => ["allocation_type = ? and (date = ? or timetable_id = ?)",params[:alloc_type],params[:date],params[:tt_id]])
    allocations = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id", :conditions => {:classroom_allocation_id => "#{classroom_allocation.id}"})
    classroom_allocation.destroy if allocations.empty?
  end
  
  def validate_allocation(alloc_id,timetable_entry,alloc_type,batch_strength,classroom_capacity)
    unless timetable_entry.nil?
      allocation = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id", :conditions => [' timetable_entry_id = ? and subject_id = ? and classroom_allocation_id = ? and classroom_id = ?',timetable_entry.id,params[:subject_id],alloc_id,params[:classroom_id]])
      if allocation.present?
        @flag = false
        @allocated_warning << "#{t('same_room_allocated')}"
        return
      end
      current_class_timing = timetable_entry.class_timing
      allocation = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id", :joins=> "Left outer join timetable_entries on timetable_entries.id = allocated_classrooms.timetable_entry_id Left outer join class_timings ct on timetable_entries.class_timing_id = ct.id", :conditions =>["timetable_entries.weekday_id= ? and ((ct.start_time BETWEEN ? and ?) or (ct.end_time BETWEEN ? and ?) or (? BETWEEN ct.start_time and ct.end_time) or (? BETWEEN ct.start_time and ct.end_time)) and timetable_entries.id != ? and allocated_classrooms.classroom_allocation_id = ?  and allocated_classrooms.classroom_id= ? and allocated_classrooms.is_deleted = ?", timetable_entry.weekday_id, (current_class_timing.start_time).strftime("%H:%M:%S"), (current_class_timing.end_time-1).strftime("%H:%M:%S"), (current_class_timing.start_time+1).strftime("%H:%M:%S"), (current_class_timing.end_time).strftime("%H:%M:%S"), (current_class_timing.start_time+1).strftime("%H:%M:%S"), (current_class_timing.end_time-1).strftime("%H:%M:%S"), timetable_entry.id, alloc_id, params[:classroom_id], false])
      if allocation.present?
        @allocated_warning << "#{t('same_class_timing_allocation')}"
      end

      allocation = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id",:conditions => ['timetable_entry_id = ? and subject_id = ? and classroom_allocation_id = ?',timetable_entry.id,params[:subject_id],alloc_id])
      if allocation.present?
        @allocated_warning << "#{t('multiple_room_allocation')} "
      end

      allocation = AllocatedClassroom.find(:all,:select => "allocated_classrooms.id", :joins => :classroom_allocation, :conditions => ["allocated_classrooms.timetable_entry_id = ? and allocated_classrooms.subject_id = ? and classroom_allocations.allocation_type = ?",timetable_entry.id,params[:subject_id],'weekly'])
      if allocation.present?
        @allocated_warning << "#{t('allocated_weekly')} "
      end

      @allocated_warning << "#{t('capacity_less')}" if batch_strength > classroom_capacity
#      @allocated_warning << "#{t('override')}" # commented to remove unwanted initial warning
    end
  end

  def make_data_hash
    if @alloc_type == "date_specific"
      last_day = Date.parse(params[:date] + "-01").end_of_month.day
#      timetable_entries = TimetableEntry.find(:all,:include =>:entry, :joins => :timetable,:select => "timetable_entries.*",:conditions => ['timetables.start_date between ? and ? or timetables.end_date between ? and ? ', "#{params[:date]}-01","#{params[:date]}" + "-#{last_day}","#{params[:date]}-01", "#{params[:date]}" + "-#{last_day}"],:order => "timetable_entries.batch_id,timetable_entries.class_timing_id").uniq
      timetable_entries = TimetableEntry.find(:all,:include =>[:entry, :employees, {:timetable_swaps => [:employee, :subject]}], :joins => :timetable,:select => "timetable_entries.*",:conditions => ['timetables.start_date between ? and ? or timetables.end_date between ? and ? ', "#{params[:date]}-01","#{params[:date]}" + "-#{last_day}","#{params[:date]}-01", "#{params[:date]}" + "-#{last_day}"],:order => "timetable_entries.batch_id,timetable_entries.class_timing_id").uniq
    elsif @alloc_type == "weekly"
      timetable_entries = TimetableEntry.find(:all,:include =>:entry, :joins => :timetable, :select => "timetable_entries.*", :conditions => ['timetable_entries.timetable_id=?', @tte_id],:order => "timetable_entries.batch_id,timetable_entries.class_timing_id")
    end
#    subjects = timetable_entries.map{|x| x.active_assigned_subjects}.flatten.compact.uniq
    extra_subjects = timetable_entries.map{|x| x.active_elective_subjects}.flatten.uniq
    tt = timetable_entries.map{|x| x.timetable }.uniq
#    employees = timetable_entries.map { |tte| time_table_swaps = tte.timetable_swaps; (@alloc_type == "date_specific" and time_table_swaps.present? ) ? (time_table_swaps.first.is_cancelled ? nil : time_table_swaps.first.employee ) : tte.employees }.flatten.compact.uniq
    employees = timetable_entries.map { |tte| time_table_swaps = tte.timetable_swaps; (@alloc_type == "date_specific" and time_table_swaps.present? ) ? (time_table_swaps.collect {|x| x.employee }.compact) : tte.employees }.flatten.compact.uniq
    class_timing_ids = timetable_entries.map{|tte| tte.class_timing_id}.uniq
    class_timings = ClassTiming.find(:all, :conditions => ["id IN (?)", class_timing_ids ] )

    batches = Batch.find(:all, :conditions =>["id IN (?) and is_active = ?",timetable_entries.map {|tte| tte.batch_id}.uniq,true])

    allocated_classrooms = AllocatedClassroom.find(:all,:select => "id,classroom_allocation_id,classroom_id,subject_id,timetable_entry_id,date", :conditions => ["timetable_entry_id IN (?)",timetable_entries.map{|tte| tte.id }.uniq ])
    classrooms = Classroom.find(:all, :select => "id,name")
    classroom_allocations = ClassroomAllocation.find(:all,:select => "id,allocation_type,timetable_id,date", :conditions => ["id IN (?)", allocated_classrooms.map { |ac| ac.classroom_allocation_id  }])

    hash = {'batches'=> {}, 'timetable_entries' => {}, 'subjects' => {}, 'classtimings' => {}, 'classrooms' => {}, 'timetable_swaps' => {}}
    
    batches.each do |b|
      hash['batches'][b.id] = b.full_name
#      hash['timetable_entries'][b.id] = timetable_entries.select{|tte| tte.batch_id == b.id and (tte.timetable_swaps.present? ? (tte.timetable_swaps.first.is_cancelled ? false : true) : true)}
      hash['timetable_entries'][b.id] = timetable_entries.select{|tte| tte.batch_id == b.id }
      if @alloc_type == "date_specific"
        hash['timetable_entries'][b.id].map {|tte| hash['timetable_swaps'][tte.id] = tte.timetable_swaps if tte.timetable_swaps.present? }
      end
      hash['subjects'][b.id] = b.subjects.flatten
    end
    hash['tt'] = tt
    hash['employees'] = employees
    hash['classrooms'] = classrooms
    hash['classtimings'] = class_timings
    hash['allocated_classrooms']= allocated_classrooms
    hash['classroom_allocations'] = classroom_allocations
    hash['emp_subjects'] = {}
    hash['cancelled_text'] = t('cancelled_text')
    hash['no_timetable_warning'] = t('no_tt_periods')
    hash['elective_subjects'] = {}
    hash['elective_emp_subjects'] = {}
    extra_subjects.map{ |subject| hash['elective_emp_subjects'].merge!({subject.id => subject.employees.map(&:full_name)})}
#    timetable_entries.map{|tte| time_table_swaps = tte.timetable_swaps; hash['emp_subjects'].merge!((@alloc_type == "date_specific" and time_table_swaps.present?) ? (time_table_swaps.first.is_cancelled ? {tte.id => tte.employees.map(&:full_name)} : {tte.id => time_table_swaps.first.employee.full_name.to_a}) : {tte.id => tte.employees.map(&:full_name)}) if tte.entry_type == 'Subject' }
    timetable_entries.map{|tte| hash['emp_subjects'].merge!({tte.id => tte.employees.map(&:full_name)}) if tte.entry_type == 'Subject' }
    timetable_entries.map{ |tte| hash['elective_subjects'].merge!({tte.entry_id => tte.active_elective_subjects.map(&:id)}) }
    return hash
  end

end
