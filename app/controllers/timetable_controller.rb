#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
include WeekdayArranger
class TimetableController < ApplicationController
  before_filter :login_required
  before_filter :protect_other_student_data
  before_filter :default_time_zone_present_time
  filter_access_to [:employee_timetable,:employee_timetable_pdf, :update_employee_tt],:attribute_check => true ,:load_method => lambda {Employee.find(params[:id] || params[:employee_id]).user}
  filter_access_to :all
  before_filter :check_status
  check_request_fingerprint :new_timetable

  def index
    @user = current_user
  end
  def new_timetable
    @timetable=Timetable.new
    if request.post?
      @timetable=Timetable.new(params[:timetable])
      if @timetable.end_date < @timetable.start_date
        @error=true
        @timetable.errors.add_to_base("#{t('start_date_is_lower_than_end_date')}")
      end
      @conflicts=Timetable.find(:all, :conditions => ["(end_date BETWEEN ? AND ? ) OR (start_date BETWEEN ? AND ? ) OR (start_date <= ? AND end_date >= ?)", @timetable.start_date, @timetable.end_date, @timetable.start_date, @timetable.end_date,@timetable.start_date,@timetable.end_date])
      if @conflicts.present?
        @error=true
        @timetable.errors.add_to_base("#{t('timetable_in_between_given_dates')}")
      end
      class_timing_sets=ClassTimingSet.all(:select=>"distinct class_timing_sets.name cts_name",:joins=>"INNER JOIN `batch_class_timing_sets` ON batch_class_timing_sets.class_timing_set_id = class_timing_sets.id LEFT OUTER JOIN `class_timings` ON class_timings.class_timing_set_id = class_timing_sets.id",:conditions=>["class_timings.id IS NULL"])
      if class_timing_sets.present?
        @error=true
        @timetable.errors.add_to_base("#{t('assign_class_timings')} #{class_timing_sets.collect(&:cts_name).join(",")}")
      end
      unless @error
        #        @timetable.save_timetable_weekdays
        @timetable.save_timetable_class_timings
        if @timetable.save
          flash[:notice]="#{t('timetable_created_from')} #{format_date(@timetable.start_date,:format=>:long)} - #{format_date(@timetable.end_date,:format=>:long)}"
          redirect_to :controller => :timetable, :action => 'manage_timetables'
        else

          flash[:notice]='error_occured'
          render :action => 'new_timetable'
        end
      else
        render :action => 'new_timetable'
      end
    end
  end

  def update_timetable
    @timetable=Timetable.find(params[:id])
    if request.post?
      @error=false
      new_start_date=params[:start_date].to_date
      new_end_date=params[:end_date].to_date
      if new_end_date < new_start_date
        @error=true
        @timetable.errors.add_to_base("#{t('start_date_is_lower_than_end_date')}")
      end
      @conflicts=Timetable.find(:all, :conditions => ["((end_date BETWEEN ? AND ? ) AND id != ? ) OR ((start_date BETWEEN ? AND ? ) AND id != ? ) OR ((start_date <= ? AND end_date >= ?) AND id !=?)", new_start_date, new_end_date, @timetable.id, new_start_date, new_end_date, @timetable.id,new_start_date, new_end_date, @timetable.id])
      if @conflicts.present?
        @error=true
        @timetable.errors.add_to_base("#{t('timetable_in_between_given_dates')}")
      end
      unless @error
        unless (@timetable.start_date == new_start_date and @timetable.end_date == new_end_date)
          old_end_date=@timetable.end_date
          old_start_date=@timetable.start_date
          ActiveRecord::Base.transaction do
            if (new_start_date < old_end_date and new_end_date > old_end_date)
              if @timetable.update_attributes(:start_date=>new_start_date,:end_date=>old_end_date)
                @new_timetable=Timetable.new(:start_date=>old_end_date+1,:end_date=>new_end_date)
                @new_timetable.save_timetable_classtimings_on_split(@timetable)
                #                @new_timetable.save_timetable_weekdays_on_split(@timetable)
                @new_timetable.save!
                @new_timetable.copy_timetable_entries(@timetable)
                ## if after split of timetable, actual timetable becomes inactive, update timetable summary in background
                unless @timetable.is_active?
                  @timetable.update_attribute('timetable_summary_status', 1)
                  Delayed::Job.enqueue(DelayedTimetableSummaryGenerate.new(@timetable))
                end
                flash[:notice]=t('timetable_updated')
              else
                @save_error=true
              end
            else
              if @timetable.update_attributes(:start_date=>new_start_date,:end_date=>new_end_date)
                ## if after reducing date range of timetable, timetable becomes inactive, update timetable summary in background
                unless @timetable.is_active?
                  @timetable.update_attribute('timetable_summary_status', 1)
                  Delayed::Job.enqueue(DelayedTimetableSummaryGenerate.new(@timetable))
                end
                flash[:notice]=t('timetable_updated')
              else
                @save_error=true
              end
            end
            @timetable.dependency_delete(old_start_date, new_start_date-1,@timetable.id) if new_start_date.to_date > old_start_date.to_date
            @timetable.dependency_delete(new_end_date+1, old_end_date,@timetable.id) if new_end_date.to_date < old_end_date.to_date
            if @save_error
              raise ActiveRecord::Rollback
              flash[:warn_notice]=t("timetable_update_failure")
            end
          end
        end
        redirect_to :controller => :timetable, :action => :manage_timetables
      else
        flash[:warn_notice]=@timetable.errors.full_messages unless @timetable.errors.empty?
        render :action => "update_timetable" ,:id=>@timetable.id
      end
    end
  end

  def manage_batches
    @timetable=Timetable.find params[:id]
    @assigned_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
      :joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",
        @timetable.id,@timetable.end_date,@timetable.start_date], :include => :timetable_entries)
    assigned_batch_ids=@assigned_batches.present? ? @assigned_batches.collect(&:id) : [0]
    @available_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:batch_class_timing_sets=>[:class_timing_set=>:class_timings]],:conditions=>["batches.id NOT IN (?) AND batches.start_date <= ? AND batches.end_date >=?",assigned_batch_ids,@timetable.end_date,@timetable.start_date])
  end

  def add_batch_timetable
    @timetable=Timetable.find params[:id]
    batches=Batch.find_all_by_id(params[:batch_id])
    batches.each do |batch|
      if @timetable.time_table_class_timings.find_all_by_batch_id(batch.id).blank?
        ttct=@timetable.time_table_class_timings.build(:batch_id => batch.id)
        batch.batch_class_timing_sets.each do |cts|
          ttct.time_table_class_timing_sets.build(:batch_id=>batch.id,:class_timing_set_id=>cts.class_timing_set_id,:weekday_id=>cts.weekday_id)
        end
      end
    end
    if @timetable.save
      @assigned_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",@timetable.id,@timetable.end_date,@timetable.start_date])
      assigned_batch_ids=@assigned_batches.present? ? @assigned_batches.collect(&:id) : [0]
      @available_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:batch_class_timing_sets=>[:class_timing_set=>:class_timings]],:conditions=>["batches.id NOT IN (?) AND batches.start_date <= ? AND batches.end_date >=?",assigned_batch_ids,@timetable.end_date,@timetable.start_date])
      render :update do |page|
        page.replace_html 'flash-box',:text=>"<p class='flash-msg'> #{t('batch_timetable_assigned')}</p>"
        page.replace_html 'batch-list',:partial=>'assign_timetable_form'
      end
    else
      render :update do |page|
        page.replace_html 'flash-box',:text=>"<div id='error-box'><ul> <li>#{t('batch_assigned_with_error')}</li></ul></div>"
      end
    end
  end

  def remove_batch_timetable
    @timetable=Timetable.find params[:id]
    #    timetable_week_days = @timetable.time_table_weekdays.all(:conditions=>{:batch_id=>params[:batch_id]})
    all_timetable_class_timings=@timetable.time_table_class_timings.all(:conditions=>{:batch_id=>params[:batch_id]}, :select => "distinct time_table_class_timings.*")
    timetable_class_timings=@timetable.time_table_class_timings.all(:conditions=>["time_table_class_timings.batch_id IN (?)",params[:batch_id]],
      :joins => "INNER JOIN batches b on time_table_class_timings.batch_id = b.id  INNER JOIN timetable_entries tte on tte.timetable_id = #{@timetable.id} and tte.batch_id = b.id",
      :select => "distinct time_table_class_timings.*"
    )
    ActiveRecord::Base.transaction do
      TimeTableClassTiming.destroy((all_timetable_class_timings-timetable_class_timings).collect(&:id)) ? error=false : error=true
      #      TimeTableWeekday.destroy(timetable_week_days.collect(&:id)) ? error=false : error=true
      @assigned_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
        :joins=>[:time_table_class_timings],
        :conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",
          @timetable.id,@timetable.end_date,@timetable.start_date])
      assigned_batch_ids=@assigned_batches.present? ? @assigned_batches.collect(&:id) : [0]
      @available_batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:batch_class_timing_sets=>[:class_timing_set=>:class_timings]],:conditions=>["batches.id NOT IN (?) AND batches.start_date <= ? AND batches.end_date >=?",assigned_batch_ids,@timetable.end_date,@timetable.start_date])
      if error
        raise ActiveRecord::Rollback
        render :update do |page|
          page.replace_html 'flash-box',:text=>"<div id='error-box'><ul> <li>#{t('batch_removed_with_error')}</li></ul></div>"
          page.replace_html 'batch-list',:partial=>'assign_timetable_form'
        end
      else
        render :update do |page|
          page.replace_html 'flash-box',:text=>"<p class='flash-msg'> #{t('batch_timetable_removed')}</p>"
          page.replace_html 'batch-list',:partial=>'assign_timetable_form'
        end
      end
    end
  end

  def view
    @timetables=Timetable.all(:order => "start_date DESC")
    if @timetables.present?
      current_timetable=@timetables.select{|timetable| timetable.start_date <= @local_tzone_time.to_date && timetable.end_date >= @local_tzone_time.to_date}.first
      @current_timetable=current_timetable.present?? current_timetable : @timetables.first
      @batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >=?",@current_timetable.id,@current_timetable.end_date,@current_timetable.start_date])
    end
  end

  def edit_master
    @courses = Batch.active
    @timetables=Timetable.paginate(:order => "end_date DESC", :per_page => 20, :page => params[:page])
  end

  def update_batch_list
    @batches = Course.find(params[:course_id],:include => :batches).batches.active
    render :update do |page|
      page.replace_html "batches", :partial => "batch_list"
      page.replace_html "batch_details", :text => ""
      page.replace_html "manage_subject_employees", :text => ""
      page.replace_html "manage_assign", :text => ""
    end
  end

  def manage_timetables
    @active = params[:active].present? ? params[:active] : 1
    conditions = ((params[:active] == "1" or !params[:active].present?) ? "end_date >= '#{Date.today}'" : "end_date < '#{Date.today}'")
    @timetables=Timetable.paginate(:conditions => conditions, :order => "end_date DESC", :per_page => 20, :page => params[:page],
      :include => { :time_table_class_timings =>
          {:batch => [
            :course, 
            {:weekday_set => :weekday_sets_weekdays},
            :timetable_entries,
            {:subjects => [:elective_group,:employees]},
            { :elective_groups => :subjects },
            {:batch_class_timing_sets => {:class_timing_set => :class_timings}}
          ]}})
    if request.post?
      render :update do |page|
        page.replace_html "timetables", :partial => "timetables"
      end
    end
    if Timetable.respond_to?(:last_auto_allocation)
      last_auto_allocation = Timetable.last_auto_allocation
      if last_auto_allocation.present?
        last_allocated_timetable = last_auto_allocation.timetable
        if last_allocated_timetable.present?
          if last_allocated_timetable.timetable_status == 2 # success
            summary_link = "<a href='/timetable/summary/#{last_allocated_timetable.id}' class='themed_text'>#{t('view_summary')}</a>"
            flash.now[:notice] = t('auto_allocation_success',:timetable => last_allocated_timetable.range, :summary_link => summary_link)
          elsif last_allocated_timetable.timetable_status == 1 # failure
            reallocate_link = "<a href='/auto_timetablers/allocate/#{last_allocated_timetable.id}' class='themed_text'>#{t('see_reasons')}</a>"
            flash.now[:notice] = t('auto_allocation_failure',:timetable => last_allocated_timetable.range, :reallocate_link => reallocate_link)
          end
        end
      end
    end
  end

  def manage_allocations
    @timetable=Timetable.find(params[:id], :include => 
        {:time_table_class_timings =>
          {:batch => [
            {:course => :batches},
            {:weekday_set => :weekday_sets_weekdays},
            :timetable_entries,
            {:subjects => [:elective_group,:employees]},
            { :elective_groups => :subjects },
            {:batch_class_timing_sets => {:class_timing_set => :class_timings}}
          ] }})
    @batches = @timetable.time_table_class_timings.map {|x| x.batch if (x.batch.start_date <= @timetable.end_date and x.batch.end_date >= @timetable.start_date and !x.batch.is_deleted and x.batch.is_active) }.compact
    @courses = @batches.group_by {|x| x.course } if @batches.present?
    flash[:notice] = t('no_batches_in_this_timetable') unless @batches.present?
  end

  def summary
    @timetable=Timetable.find(params[:id], :include =>
        {:time_table_class_timings =>
          {:batch => [
            {:course => :batches},
            {:weekday_set => :weekday_sets_weekdays},
            :timetable_entries,
            {:subjects => [:elective_group,:employees]},
            { :elective_groups => :subjects },
            {:batch_class_timing_sets => {:class_timing_set => :class_timings}}
          ] }})
    @summary_update_progress = false
    @batches = @timetable.time_table_class_timings.map { |x| x.batch if (x.batch.end_date >= @timetable.start_date and x.batch.start_date <= @timetable.end_date and x.batch.tte_status(@timetable)[:eligibility_code] > 0)}.compact
    if @timetable.is_active?
      if @timetable.timetable_summary_status.zero?
        # timetable with upto date summary or inactive timetable
      elsif @timetable.timetable_summary_status == 2 # timetable summary updation in progress
        @summary_update_progress = true
      else # timetable summary marked for update
        @summary_update = true
        flash.now[:notice] = t('timetable_summary_regenerate')
      end
    end
    flash.now[:notice] = t('no_batches_in_this_timetable') unless @batches.present?
    @timetable_summary = @timetable.timetable_summary
  end

  def update_summary
    @timetable = Timetable.find(params[:id], :include => {:time_table_class_timings => :batch })
    @batches = @timetable.time_table_class_timings.map { |x| x.batch if (x.batch.end_date >= @timetable.start_date and x.batch.start_date <= @timetable.end_date and x.batch.tte_status(@timetable)[:eligibility_code] > 0)}.compact
    if request.xhr?
      @timetable_summary = @timetable.timetable_summary
      @summary_update_progress = false
      if @timetable_summary.present? and @timetable.timetable_summary_status.zero?
      else
        if (@batches.present? and (@timetable.timetable_summary_status == 1 or !@timetable_summary.present?))
          flash.now[:notice] = t('timetable_summary_update_notice')
          Delayed::Job.enqueue(DelayedTimetableSummaryGenerate.new(@timetable))
          @summary_update_progress = true
        elsif @timetable.timetable_summary_status == 2
          @summary_update_progress = true
        end
      end
      respond_to do |format|
        format.js { render :action => 'update_summary' }
      end
    end
  end

  def batch_allocation_list
    @timetable = Timetable.find(params[:id], :include => {:time_table_class_timings => {:batch => :course} })
    @utilization = params[:type]
    @initial = true
    @batches_total = @timetable.timetable_summary[:batches][:completely_allocated][:total] + @timetable.timetable_summary[:batches][:partially_allocated][:total] + @timetable.timetable_summary[:batches][:not_allocated][:total] + @timetable.timetable_summary[:batches][:not_eligible][:total]
    case @utilization
    when "0" # not allocated
      batch_ids = @timetable.timetable_summary[:batches][:not_allocated][:batch_ids]
    when "1" # partially allocated
      batch_ids = @timetable.timetable_summary[:batches][:partially_allocated][:batch_ids]
    when "2" # completely allocated
      batch_ids = @timetable.timetable_summary[:batches][:completely_allocated][:batch_ids]
    else # not eligible
      batch_ids = @timetable.timetable_summary[:batches][:not_eligible][:batch_ids]
    end
    @batches = Batch.find_all_by_id(batch_ids)
  end

  def batch_subject_utilization
    if(params[:batch_id].present?)
      @batch = Batch.find(params[:batch_id], :include => [:batch_timetable_summaries,:employees]) #, :include => [{:batch_class_timing_sets => {:class_timing_set => :class_timings}}, {:subjects => :employees }, {:elective_groups => {:subjects => :employees}}, {:timetable_entries => :employees}])
      @timetable=Timetable.find(params[:id])
      batch_summaries = @batch.batch_timetable_summaries.select {|x| (x.timetable_id == @timetable.id)}
      @timetable_summary = batch_summaries.last.timetable_summary if batch_summaries.present?
      @utilization = params[:type]
      @total_subjects = @timetable_summary[:subjects][:total_count]
      case @utilization
      when "0"
        subject_ids = @timetable_summary[:subjects][:not_allocated][:subject_ids]
        elective_group_ids = @timetable_summary[:subjects][:not_allocated][:elective_group_ids] #ElectiveGroup.find(@timetable_summary[:subjects][:not_allocated][:elective_group_ids] ,:include => :subjects).map {|x| x.subjects.map(&:id)}.flatten
      when "1"
        subject_ids = @timetable_summary[:subjects][:partially_allocated][:subject_ids]
        elective_group_ids = @timetable_summary[:subjects][:partially_allocated][:elective_group_ids] #ElectiveGroup.find(@timetable_summary[:subjects][:partially_allocated][:elective_group_ids],:include => :subjects).map {|x| x.subjects.map(&:id)}.flatten
      else
        subject_ids = @timetable_summary[:subjects][:completely_allocated][:subject_ids]
        elective_group_ids = @timetable_summary[:subjects][:completely_allocated][:elective_group_ids] #ElectiveGroup.find(@timetable_summary[:subjects][:completely_allocated][:elective_group_ids],:include => :subjects).map {|x| x.subjects.map(&:id)}.flatten
      end
      @subjects = Subject.find_all_by_id(subject_ids,:conditions => {:is_deleted => false}, :include => :timetable_entries)
      @elective_groups = ElectiveGroup.find_all_by_id(elective_group_ids,:conditions => {:is_deleted => false}, :include => [:subjects, :timetable_entries]).reject {|eg| (!eg.subjects.present? and !eg.subjects.select {|s| !s.is_deleted}.present?)}
    end
  end

  def employee_hour_overlaps
    @timetable = Timetable.find(params[:id])
    @initial = true
    @batch = Batch.find(params[:batch_id]) if params[:batch_id].present?
    @overlaps = (@batch.present? ? @batch.batch_timetable_summaries.find_by_timetable_id(@timetable.id).timetable_summary : @timetable.timetable_summary)[:employees][:overlaps]    
    include_list = @batch.present? ? [:entry, :class_timing] : [:batch, :entry, :class_timing]
    @timetable_entries = TimetableEntry.find(@overlaps[:details].values.map {|x| x.values.map {|y| y[:tts]} }.flatten, :include => include_list)
    @employees = Employee.find(@overlaps[:details].keys)
    respond_to do |format|
      format.js { render :action => 'employee_hour_overlaps' }
    end
  end
  
  def employees_hour_utilization
    @timetable = Timetable.find(params[:id])
    @utilization = params[:type]
    @initial = true
    @emp_total = @timetable.timetable_summary[:employees][:fully_utilized_hours][:total] + @timetable.timetable_summary[:employees][:under_utilized_hours][:total] + @timetable.timetable_summary[:employees][:over_utilized_hours][:total]
    if @utilization == "0" # fully utilized
      emp_ids = @timetable.timetable_summary[:employees][:fully_utilized_hours][:employee_ids]
    elsif @utilization == "1" # over utilized
      emp_ids = @timetable.timetable_summary[:employees][:over_utilized_hours][:employee_ids]
    else # under utilized
      emp_ids = @timetable.timetable_summary[:employees][:under_utilized_hours][:employee_ids]
    end
    @employees = Employee.find_all_by_id(emp_ids)
    respond_to do |format|
      format.js { render :action => 'employees_hour_utilization' }
    end
  end


  def load_batch_wise_summary
    if(params[:id].present?)
      @batch = Batch.find(params[:id], :include => :batch_timetable_summaries) #, :include => [{:batch_class_timing_sets => {:class_timing_set => :class_timings}}, {:subjects => :employees }, {:elective_groups => {:subjects => :employees}}, {:timetable_entries => :employees}])
      @timetable=Timetable.find(params[:timetable_id]) #, :include => {:time_table_class_timings => :batch })
      #    @timetable.update_timetable_summary unless @timetable.timetable_summary_status.zero?
      batch_summaries = @batch.batch_timetable_summaries.select {|x| (x.timetable_id == @timetable.id)}
      @timetable_summary = batch_summaries.last.timetable_summary if batch_summaries.present?
    end
    render :update do |page|
      page.replace_html "batch_summary", :partial => "summary_data" if @batch.present? and @timetable_summary.present?
      page.replace_html "batch_summary", :text => "" unless (@batch.present? and @timetable_summary.present?)      
    end
  end

  def manage_work_allocations
    if params[:batch_id].present?
      @batch = Batch.find(params[:batch_id], :include => {:subjects => :employees, :batch_class_timing_sets => {:class_timing_set => :class_timings } })
      @batch_weekly_classes = @batch.batch_class_timing_sets.map {|x| x.class_timing_set.class_timings.reject{|x| x.is_break } }.flatten.length
      @employee_departments = EmployeeDepartment.all
    end
    @courses = Course.active
  end

  def load_work_allocations
    @batch = Batch.find(params[:batch_id], :include => {:subjects => :employees, :batch_class_timing_sets => {:class_timing_set => :class_timings }  })
    @courses = Course.active
    @employee_departments = EmployeeDepartment.all
    @batch_weekly_classes = @batch.batch_class_timing_sets.map {|x| x.class_timing_set.class_timings.reject{|x| x.is_break } }.flatten.length
    render :update do |page|
      page.replace_html "batches", :partial =>  "batch_list"
      page.replace_html "batch_details", :partial => "batch_details"
      if @batch.subjects.present?
        page.replace_html "manage_subject_employees", :partial => "manage_subjects_employees"
        page.replace_html "manage_assign", :partial => "manage_assigned_employees" if @batch.subjects.present?
      else
        page.replace_html "manage_subject_employees", :text => ""
        page.replace_html "manage_assign", :text => ""
      end
      page.replace_html "flash-warning", :text => (@batch.subjects.present? ? "" : "<p class='flash-msg'> #{t('no_subjects')} </p>")
    end
  end

  def assign_employee
    emp_sub = EmployeesSubject.find_or_create_by_employee_id_and_subject_id(params[:emp_id], params[:subject_id])
    @employee_departments = EmployeeDepartment.all
    @subject = Subject.find(params[:subject_id], :include => :employees)
    @subject_id = params[:subject_id]
    render :update do |page|
      page.replace_html "subject-#{@subject_id}", :partial => "subject_row"
      page.replace_html "manage_assign", :partial => "manage_assigned_employees"
    end
  end

  def remove_employee
    Employee.find(params[:emp_id])
    subject = Subject.find(params[:subject_id], :include => [{:elective_group=>:timetable_entries},:timetable_entries])
    emp_sub = subject.employees_subjects.find_all_by_employee_id(params[:emp_id])
    emp_sub.map(&:destroy) if emp_sub.present?
    @employee_departments = EmployeeDepartment.all
    @subject = Subject.find(params[:subject_id], :include => :employees)
    @subject_id = params[:subject_id]

    render :update do |page|
      page.replace_html "subject-#{@subject_id}", :partial => "subject_row"
      page.replace_html "flash-warning", :text => (flash[:warning].present? ? flash[:warning]:'')
      page.replace_html "manage_assign", :partial => "manage_assigned_employees"
    end

  end

  def update_employee_list
    @employees_dept = EmployeeDepartment.find(params[:employee_department_id],:include => :employees)
    @subject = Subject.find(params[:subject_id], :include => :employees)
    @employees = @employees_dept.employees.sort_by{|x| x.full_name.downcase }.reject {|x| (@subject.employees.map(&:id).include? x.id)}
    render :update do |page|
      flash[:notice] = t('no_employees_in_this_dept') unless @employees.present?
      page.replace_html "available-employees-list", :partial => "available_employees_list"
    end
  end

  def load_manage_subject
    if params[:request] == '1' || params[:request] == '2'
      @subject = Subject.find(params[:id], :include => :employees)
      @employee_departments = EmployeeDepartment.all
    end
    
    render :update do |page|
      page.replace_html "manage_assign", :partial => "manage_assigned_employees"
    end
  end

  def teachers_timetable
    @timetables=Timetable.all(:order => "start_date desc")
    ## Prints out timetable of all teachers
    @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
    if @current
      @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
      classtimings = []
      @current.time_table_class_timings.all(:include=>{:time_table_class_timing_sets => {:class_timing_set => :class_timings}} ).each do |ttct|
        #      map(&:time_table_class_timing_sets).flatten.map(&:class_timing_set).map(&:class_timings).flatten.uniq
        ttct.time_table_class_timing_sets.each do |ttcts|
          classtimings += ttcts.class_timing_set.class_timings
        end
      end
      classtimings = classtimings.uniq
      @all_timetable_entries = @current.timetable_entries.all(:include=>[:employees,:entry],
        :conditions => ["ct.is_deleted = ? and b.is_active = ? and class_timing_id in (?)",false,true,classtimings.map(&:id)],
        :joins => "LEFT OUTER JOIN batches b on timetable_entries.batch_id=b.id and b.is_active=1
                 LEFT OUTER JOIN class_timings ct on ct.id=timetable_entries.class_timing_id and ct.is_deleted=0")
      @all_subjects = @all_timetable_entries.collect(&:assigned_subjects).flatten.uniq
      @all_teachers = @all_timetable_entries.collect(&:employees).flatten.uniq
      @all_subjects.each do |sub|
        unless sub.elective_group.nil?
          @all_teachers+=sub.elective_group.subjects.collect(&:employees).flatten
        end
      end
      @all_teachers = @all_teachers.uniq.sort_by{|x,i| x.full_name }
      if @all_teachers.present?
        @employee = @all_teachers.first
        employee_tt_builder
      end
    else
      @all_timetable_entries=[]
    end
  end

  def update_employee_timetable
    @employee=Employee.find(params[:id],:include=>[:employee_department,:timetable_entries,{:subjects => [{:elective_group => :subjects},:batch]}])
    @timet
    @blocked=true
    if permitted_to? :employee_timetable, :timetable
      @blocked=false
    elsif @current_user.employee_record==@employee
      @blocked=false
    elsif @current_user.admin?
      @blocked=false
    end
    unless @blocked

      @timetables=Timetable.all
      ## Prints out timetable of all teachers
      unless params[:timetable_id].present?
        @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
      else
        @current=Timetable.find(params[:timetable_id])
      end
      unless @current.nil?
        employee_tt_builder
      else
        flash[:notice]=t('no_entries_found')
      end
      render :update do |page|
        page.replace_html "teacher_timetable_view", :partial => "employee_timetable"
      end
    else
      flash[:notice]=t('flash_msg6')
      redirect_to :controller => :user, :action => :dashboard
    end
  end
  #    if request.xhr?
  def update_teacher_tt
    if params[:timetable_id].nil?
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
    else
      if params[:timetable_id]==""
        render :update do |page|
          page.replace_html "timetable_view", :text => ""
        end
        return
      else
        @current=Timetable.find(params[:timetable_id],:include => :timetable_entries)
      end
    end
    @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
    @all_timetable_entries = @current.timetable_entries.all(:include=>[:employees,:entry],
      :conditions => ["ct.is_deleted = ? and b.is_active = ?",false,true],
      :joins => "LEFT OUTER JOIN batches b on timetable_entries.batch_id=b.id and b.is_active=1
                 LEFT OUTER JOIN class_timings ct on ct.id=timetable_entries.class_timing_id and ct.is_deleted=0")
    @all_teachers = @all_timetable_entries.collect { |x| x.employees }.flatten.uniq
    @all_subjects = @all_timetable_entries.collect { |x| x.assigned_subjects([:batch]) }.flatten.uniq
    @all_subjects.each do |sub|
      unless sub.elective_group.nil?
        elective_teachers = sub.elective_group.subjects.collect(&:employees).flatten
        @all_teachers+=elective_teachers
      end
    end
    @all_teachers.uniq!
    if @all_teachers.present?
      @employee = @all_teachers.first
      employee_tt_builder
    end
    render :update do |page|
      page.replace_html "timetable_view_flash", :text => ((@all_timetable_entries.present? and @mployee.present?) ? "" : (@all_timetable_entries.present? ? (@employee.present? ? "" : "<p class='flash-msg'>#{t('no_timetable_associated_employees_found')}</p>") : "<p class='flash-msg'>#{t('no_entries_found')}</p>" ))
      page.replace_html "teachers_list_view", :partial => "teacher_list"
      page.replace_html "teacher_timetable_view", :partial => "employee_timetable" if @employee.present?
      page.replace_html "teacher_timetable_view", :text => "" unless @employee.present?
    end
  end

  def timetable_view_batches
    @timetable=Timetable.find params[:timetable_id]
    @batches=Batch.active.all(:select=>"DISTINCT `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",:joins=>[:time_table_class_timings],:conditions=>["time_table_class_timings.timetable_id=?  AND batches.start_date <= ? AND batches.end_date >= ?",@timetable.id,@timetable.end_date,@timetable.start_date])
    render :update do |page|
      page.replace_html "timetable_view", :text => ""
      page.replace_html "batches", :partial => "timetable_batches"
    end
  end

  def update_timetable_view
    if params[:batch_id].present?
      @timetable=Timetable.find(params[:timetable_id])
      @batch = Batch.find(params[:batch_id])
      tte_from_batch_and_tt(@timetable.id)
      render :update do |page|
        page.replace_html "timetable_view", :partial => "view_timetable"
      end
    else
      render :update do |page|
        page.replace_html "timetable_view", :text => "<p class='flash-msg'> #{t('select_one_batch')}</p>"
      end
    end
  end

  def destroy
    @timetable=Timetable.find(params[:id])
    ActiveRecord::Base.transaction do
      @timetable.dependency_delete(@timetable.start_date, @timetable.end_date,@timetable.id)
      if @timetable.destroy
        flash[:notice]=t('timetable_deleted')
        redirect_to :action=>"manage_timetables"
      else
        raise ActiveRecord::Rollback
      end
    end
  end

  def employee_timetable_pdf
    unless params[:timetable_id].present?
      flash[:notice] = t('timetable_not_found')
      redirect_to :controller => :user, :action => :dashboard
    else
      @current=Timetable.find_by_id(params[:timetable_id])
      @employee=Employee.find(params[:id])
      @timetables=Timetable.all
      if @current.present?
        employee_tt_builder
        if @all_timetable_entries.present?
          @config_value = Configuration.get_config_value('TimetablePdfSetting') || "1"          
          render :pdf => 'teacher_timetable_pdf', #:show_as_html => true,
            :orientation => 'Landscape',:margin =>{:top=>5,:bottom=>5,:left=>5,:right=>5}, :zoom=> 1,
            :header => {:html => { :content=> ''}},
            :footer => {:html => { :template=> 'layouts/pdf_footer.html'}}
        else
          flash[:notice] = t('no_entries_found')
          redirect_to :controller => :user, :action => :dashboard
        end
      else
        flash[:notice] = t('timetable_not_found')
        redirect_to :controller => :user, :action => :dashboard
      end
    end
  end

  def employee_timetable
    @employee=Employee.find(params[:id])
    @blocked=true
    if permitted_to? :employee_timetable, :timetable
      @blocked=false
    elsif @current_user.employee_record==@employee
      @blocked=false
    elsif @current_user.admin?
      @blocked=false
    end
    unless @blocked
      @timetables=Timetable.all(:order => "start_date desc")
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
      unless @current.nil?
        employee_tt_builder
      else
        flash[:notice]=t('no_entries_found')
      end
    else
      flash[:notice]=t('flash_msg6')
      redirect_to :controller => :user, :action => :dashboard
    end
  end

  #    if request.xhr?
  def update_employee_tt
    @employee=Employee.find(params[:employee_id])
    if params[:timetable_id].nil?
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
    else
      if params[:timetable_id]==""
        render :update do |page|
          page.replace_html "timetable_view", :text => ""
        end
        return
      else
        @current=Timetable.find(params[:timetable_id])
      end
    end
    employee_tt_builder
    render :update do |page|
      page.replace_html "teacher_timetable_view", :partial => "employee_timetable"
    end
  end

  def student_view
    @student = Student.find(params[:id])
    @batch=@student.batch
    if @batch.weekday_set_id.present?
      timetable_ids=@batch.timetable_entries.collect(&:timetable_id).uniq
      @timetables=Timetable.find(timetable_ids,:order => "start_date DESC")
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ? and id IN (?)", @local_tzone_time.to_date, @local_tzone_time.to_date, timetable_ids])
      @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
      unless @current.nil?
        @class_timing_sets=TimeTableClassTiming.find_by_batch_id_and_timetable_id(@batch.try(:id), @current.try(:id)).time_table_class_timing_sets(:joins=>{:class_timing_set=>:class_timings})
        #        @entries=@current.timetable_entries.find(:all, :conditions => {:batch_id => @batch.id, :class_timing_id => @class_timings})
        @entries=TimetableEntry.find(:all,:conditions=>{:batch_id=>@batch.id,:timetable_id=>@current.id},:include=>[:entry,:employees,:timetable_swaps])
        @all_timetable_entries = @entries.select { |s| s.class_timing.is_deleted==false }
        #        @all_weekdays = weekday_arrangers(@all_timetable_entries.collect(&:weekday_id).uniq)
        @all_weekdays = weekday_arrangers(@class_timing_sets.collect(&:weekday_id).uniq)
        #        @all_classtimings = @all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }
        @all_teachers = @all_timetable_entries.collect(&:employees).flatten.uniq
        @all_timetable_entries.each do |tt|
          @timetable_entries[tt.weekday_id][tt.class_timing_id] = tt
        end
      end
    else
      flash[:notice] = t('timetable_not_set')
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def update_student_tt
    @student = Student.find(params[:id])
    @batch=@student.batch
    @all_timetable_entries = Array.new
    if params[:timetable_id].nil?
      @current=Timetable.find(:first, :conditions => ["timetables.start_date <= ? AND timetables.end_date >= ?", @local_tzone_time.to_date, @local_tzone_time.to_date])
    else
      if params[:timetable_id]==""
        render :update do |page|
          page.replace_html "box", :text => ""
        end
        return
      else
        @current=Timetable.find(params[:timetable_id])
      end
    end
    @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
    unless @current.nil?
      ttct = TimeTableClassTiming.find_by_batch_id_and_timetable_id(@batch.try(:id), @current.try(:id))
      if ttct.present?
        @class_timing_sets=TimeTableClassTiming.find_by_batch_id_and_timetable_id(@batch.try(:id), @current.try(:id)).time_table_class_timing_sets(:joins=>{:class_timing_set=>:class_timings})
        #        @entries=@current.timetable_entries.find(:all, :conditions => {:batch_id => @batch.id, :class_timing_id => @class_timings})
        @entries=TimetableEntry.find(:all,:conditions=>{:batch_id=>@batch.id,:timetable_id=>@current.id},:include=>[:entry,:employees,:timetable_swaps])
        @all_timetable_entries = @entries.select { |s| s.class_timing.is_deleted==false }
        @all_weekdays = weekday_arrangers(@all_timetable_entries.collect(&:weekday_id).uniq.sort)
        #        @all_classtimings = @all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }
        @all_teachers = @all_timetable_entries.collect(&:employee).uniq
        @all_timetable_entries.each do |tt|
          @timetable_entries[tt.weekday_id][tt.class_timing_id] = tt
        end
      end
    end

    render :update do |page|
      page.replace_html "time_table", :partial => "student_timetable"
    end
  end

  def weekdays
    @batches = Batch.active
  end

  def timetable_pdf
    @tt=Timetable.find(params[:timetable_id])
    @batch = Batch.find(params[:batch_id]) if params[:batch_id].present?
    @batch = Student.find(params[:student_id],:include=>:batch).batch if params[:student_id].present?
    @config_value = Configuration.get_config_value('TimetablePdfSetting') || "1"
    tte_from_batch_and_tt(@tt.id)    
    @classtimingsets = @class_timing_sets.map {|x| x.class_timing_set }
    @classtimingsets_count = @class_timing_sets.uniq.length
    @class_timing_counts = Hash.new
    @classtimingsets.map {|x| @class_timing_counts[x.id] = {:breaks => x.class_timings.select{|y| y.is_break}.length, :periods => x.class_timings.select{|y| !y.is_break}.length}}
    @max_period_count = @class_timing_counts.values.collect{|x| x[:periods] }.max
    @zoom = @max_period_count > 14 ? 0.9 : 1    
    
    render :pdf => 'timetable_pdf', #:show_as_html => true,
    :orientation => 'Landscape',:margin =>{:top=>5,:bottom=>5,:left=>5,:right=>5}, :zoom=> @zoom,
      :header => {:html => { :content=> ''}}, :footer => {:html => { :template=> 'layouts/pdf_footer.html'}}
  end

  def settings
    @config_value = Configuration.get_config_value('TimetablePdfSetting') || "1"
    if request.post?
      config_value = params[:timetable_pdf][:config_value]
      @config = Configuration.set_value('TimetablePdfSetting', config_value)
      @config_value = @config.present? ? @config.config_value : @config_value
    end
  end
  
  def work_allotment
    batches = Batch.active(:include => [{:subjects => :employees},{:elective_groups => {:subjects => :employees}}])
    batches.map {|x| x.subject_totals}
    @courses = batches.group_by {|x| x.course }
    flash.now[:notice] = t('no_batches_present') unless @courses.present?
  end

  def update_course_work_allotment
    @course = Course.find(params[:id],:include => {:batches => [{:subjects => :employees},{:elective_groups => {:subjects => :employees}}]})
    render (:update) do |page|
      page.replace_html "#{@course.id}", :partial => 'course_work_allotment'
    end
  end

  def timetable
    @config = Configuration.available_modules
    @batches = Batch.active.all(:include=>[{:weekday_set=>:weekday_sets_weekdays},{:timetable_entries=>[:timetable,:class_timing,:entry,:employee]}])
    @week_day_set_ids=WeekdaySet.common.weekday_ids
    unless params[:next].nil?
      @today = params[:next].to_date
      render (:update) do |page|
        page.replace_html "timetable", :partial => 'table'
      end
    else
      @today = @local_tzone_time.to_date
    end
  end

  private

  def employee_tt_builder
    @employee.subjects.compact!
    @electives=@employee.subjects.group_by(&:elective_group_id)
    @timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
    @employee_subjects = @employee.subjects
    active_batches = @employee_subjects.collect {|s| s.batch if s.batch.is_active}.uniq.compact
    @entries = []
    active_batches.each do |batch|
      timetable_class_timings = []
      ttct = TimeTableClassTiming.find_by_timetable_id_and_batch_id(@current.id,batch.id,
        :include => {:time_table_class_timing_sets => {:class_timing_set => :class_timings}})
      if ttct.present?
        ttct.time_table_class_timing_sets.each do |ttcts|
          timetable_class_timings += ttcts.class_timing_set.class_timings.timetable_timings.map(&:id)
        end
        @entries += @employee.timetable_entries.all(:include => [:batch,:employees,:class_timing],
          :conditions=>["batch_id = ? and timetable_id = ? and class_timing_id in (?)",batch.id,@current,timetable_class_timings])
      end
    end
    @entries = @entries.reject { |t| t.entry_type=="ElectiveGroup" and (@employee_subjects.collect(&:id) & t.entry.subjects.collect(&:id)).empty? }
    @entries.uniq!
    @all_timetable_entries = @entries.select { |t| t.batch.is_active }.select { |s| s.class_timing.is_deleted==false }
    @all_weekdays = weekday_arrangers(@all_timetable_entries.collect(&:weekday_id).uniq)
    @all_classtimings = @all_timetable_entries.collect{|x| x.class_timing }.uniq.sort! { |a, b| a.start_time <=> b.start_time }
    @all_timetable_entries.each_with_index do |tt, i|
      @timetable_entries[tt.weekday_id][tt.class_timing_id][i] = tt
    end
  end

  def tte_from_batch_and_tt(tt)
    @tt=Timetable.find(tt)
    time_table_class_timings = TimeTableClassTiming.find_by_timetable_id_and_batch_id(@tt.id,@batch.id)
    @class_timing_sets = time_table_class_timings.nil? ? @batch.batch_class_timing_sets(:joins=>{:class_timing_set=>:class_timing}, :include => {:class_timing_set=>:class_timing}) : time_table_class_timings.time_table_class_timing_sets(:joins=>{:class_timing_set=>:class_timings}, :include => {:class_timing_set=>:class_timing})    
    if @tt.duration >= 7
      @weekday = weekday_arrangers(time_table_class_timings.time_table_class_timing_sets.collect(&:weekday_id))
    else
      weekdays=[]
      (@tt.start_date..@tt.end_date).each {|day| weekdays << day.wday if time_table_class_timings.time_table_class_timing_sets.collect(&:weekday_id).include?(day.wday)}
      @weekday = weekday_arrangers(weekdays)
    end
    timetable_entries=TimetableEntry.find(:all,:conditions=>{:batch_id=>@batch.id,:timetable_id=>@tt.id},:include=>[:entry,:employees,:timetable_swaps])
    @timetable= Hash.new { |h, k| h[k] = Hash.new(&h.default_proc)}
    timetable_entries.each do |tte|
      @timetable[tte.weekday_id][tte.class_timing_id]=tte
    end
    @subjects = Subject.find_all_by_batch_id(@batch.id, :conditions=>["elective_group_id IS NULL AND is_deleted = false"])
    @ele_subjects = Subject.find_all_by_batch_id(@batch.id, :conditions=>["elective_group_id IS NOT NULL AND is_deleted = false"], :group => "elective_group_id")
  end
end
class Hash
  def delete_blank
    delete_if { |k, v| v.empty? or v.instance_of?(Hash) && v.delete_blank.empty? }
  end
end
