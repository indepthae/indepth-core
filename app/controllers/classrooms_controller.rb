class ClassroomsController < ApplicationController

  before_filter :login_required
  before_filter :has_no_allocations, :only => [:destroy]
  before_filter :find_classroom, :only => [:edit,:show,:update,:destroy]
  before_filter :default_time_zone_present_time
  filter_access_to :all

  def new
    @building = Building.find(params[:building_id])
    @classroom = @building.classrooms.build
  end

  def show
    @building = @classroom.building
    @timetables = Timetable.all
  end

  def create
    @building = Building.find(params[:building_id])
    @classroom = @building.classrooms.build(params[:classroom])

    if @classroom.save
      flash[:notice] = "#{t('classroom_added')}"
      redirect_to :controller => "buildings", :action => "show", :id => params[:building_id]
    else
      render :action => 'new'
    end
  end


  def edit
    @building = @classroom.building
  end

  def update
    if @classroom.update_attributes(params[:classroom])
      flash[:notice] = "#{t('classroom_edited')}"
      redirect_to building_path(@classroom.building.id)
    else
      render :action => "edit"
    end
  end

  def view
    render :partial => "allocations"
  end

  def destroy
    if @allocations.count > 0
      flash[:notice] = "#{t('allocation_exist')}"
    else
      @classroom.destroy
      flash[:notice] = "#{t('classroom_deleted')}"
    end
    rooms = @classroom.building.classrooms
    if rooms.empty?
      @classroom.building.destroy
      redirect_to :controller => "buildings", :action => "index"
    else
      redirect_to building_path(params[:building_id])
    end
  end

  def list_date_specific_activities
    tte = AllocatedClassroom.find(:all,:joins => :timetable_entry,:conditions => ["allocated_classrooms.date LIKE (?) and allocated_classrooms.classroom_id = ?", "#{params[:date]}%", params[:id]])
    @hash = {}
    i = 0
    tte.each do |e|
     emp_sub = EmployeesSubject.find_by_subject_id(e.subject_id)
     sub = emp_sub.nil? ? Subject.find(e.subject_id).name : emp_sub.subject.name
     emp = emp_sub.nil? ? "#{t('no_teacher')}"  : emp_sub.employee.full_name
     subject = emp_sub.nil? ? Subject.find(e.subject_id) : emp_sub.subject
     employees=subject.employees.collect{ | employee| employee.full_name }.join(",")
     @hash[i+=1] = {
       :day => "#{e.date}" ,
       :class_timing => e.timetable_entry.class_timing.start_time.strftime("%H:%M %p") + '-' + e.timetable_entry.class_timing.end_time.strftime("%H:%M %p"),
       :batch => e.timetable_entry.batch.full_name,
       :subject => sub ,
       :employee => employees
     }
    end
    if @hash.empty?
      render(:update) do|page|
        page.replace_html "date_specific", :text => "#{t('no_activities')}"
      end
    else
      render(:update) do|page|
        page.replace_html "date_specific", :partial => "list_date_specific_activities"
      end
    end
  end

  def list_weekly_activities
    if params[:timetable] != ""
      tt_ids = Timetable.find(params[:timetable]).id
      tte = AllocatedClassroom.find(:all, :joins => :timetable_entry, :conditions => "allocated_classrooms.date is null and allocated_classrooms.classroom_id = #{params[:id]} and timetable_entries.timetable_id = #{params[:timetable]}")
      @hash = {}
      i = 0
      weekdays = ["#{t('sunday')}", "#{t('monday')}", "#{t('tuesday')}", "#{t('wednesday')}", "#{t('thursday')}", "#{t('friday')}","#{t('saturday')}"]
      tte.each do |e|
        emp_sub = EmployeesSubject.find_by_subject_id(e.subject_id)
        sub = emp_sub.nil? ? Subject.find(e.subject_id).name : emp_sub.subject.name
        subject = emp_sub.nil? ? Subject.find(e.subject_id) : emp_sub.subject
        employees=subject.employees.collect{ | employee| employee.full_name }.join(",")
        emp = emp_sub.nil? ? "#{t('no_teacher')}"  : emp_sub.employee.full_name
        @hash[i+=1] = {:weekday => "#{weekdays[e.timetable_entry.weekday_id]}" ,
                      :class_timing => e.timetable_entry.class_timing.start_time.strftime("%H:%M %p") + '-' + e.timetable_entry.class_timing.end_time.strftime("%H:%M %p"),
                      :batch => e.timetable_entry.batch.full_name,
                      :subject => sub ,
                      :employee => employees
                    }
      end
      if @hash.empty?
        render(:update) do|page|
          page.replace_html "weekly", :text => "#{t('no_activities')}"
        end
      else
        render(:update) do|page|
          page.replace_html "weekly", :partial => "list_weekly_activities"
        end
      end
    else
     render(:update) do|page|
       page.replace_html "weekly", :text => ""
     end
    end
  end

  def year
    @year = @local_tzone_time.to_date.year
    if params[:month] == ""
      render(:update) do |page|
        page.replace_html "year", :text => ""
        page.replace_html "date_specific", :text => ""
      end
    else
      render(:update) do |page|
        page.replace_html "year", :partial => "year"
        page.replace_html "date_specific", :text => ""
      end
    end
  end

  private

  def has_no_allocations
    classroom_id = Classroom.find(params[:id]).id
    @allocations = AllocatedClassroom.find(:all,:conditions =>["classroom_id = ?",classroom_id])
  end

  def find_classroom
    @classroom = Classroom.find(params[:id])
  end
end
