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
class Timetable < ActiveRecord::Base
  has_many :timetable_entries , :dependent=>:destroy
  has_many :time_table_weekdays, :dependent => :destroy
  has_many :time_table_class_timings, :dependent => :destroy
  has_one :classroom_allocation, :dependent => :destroy
  validates_presence_of :start_date
  validates_presence_of :end_date
  default_scope :order=>'start_date ASC'
  accepts_nested_attributes_for :time_table_weekdays
  accepts_nested_attributes_for :time_table_class_timings
  after_save :update_timetable_summary_status
  serialize :timetable_summary
  include CsvExportMod
  named_scope :active, :conditions => ["end_date >= ?",Date.today]

  def is_active?
    return (self.end_date >= Date.today)
  end

  def duration
    (self.end_date - self.start_date).to_i + 1
  end

  def timetable_weekdays args = {}
    sdate = args[:start_date] || self.start_date
    edate = args[:end_date] || self.end_date

    num_days = (edate - sdate + 1).to_i
    if num_days < 7
      wk_days = (sdate..edate).to_a.map{|x| x.strftime('%w').to_i }.uniq
    else
      wk_days = [0,1,2,3,4,5,6]
    end
    return wk_days
  end

  def update_timetable_summary_status
    if (self.changed & ['start_date','end_date']).present?
      Timetable.mark_summary_status({:model => self})
    end
  end
  
  def self.mark_summary_status args = {}
    if args[:model].present?
      case args[:model].class.to_s
      when "EmployeeGrade"
        timetable_ids = Timetable.active.map(&:id)
      when "EmployeesSubject"
        timetable_ids = Timetable.active.map(&:id)
      when "TimetableEntry"
        timetable_ids = args[:model].timetable_id.to_a
      when "Subject"
        timetable_ids = Timetable.active.map(&:id)
      when "TimeTableClassTiming"
        timetable_ids = args[:model].timetable_id.to_a
      when "Timetable"
        timetable_ids = args[:model].id.to_a
      else
        timetable_ids = Timetable.active.map(&:id)
      end
      begin
        if timetable_ids.present?
          timetable_summary_status_update = "Update `timetables` set `timetable_summary_status` = 1 where `id` in (#{timetable_ids.join(',')})"
          RecordUpdate.connection.execute(timetable_summary_status_update) 
        end
      rescue Exception => e
        
      ensure

      end
    end
  end

  def update_timetable_summary
    this_timetable = self.time_table_class_timings.loaded? ? self : Timetable.find(self.id, :include => [
        { :time_table_class_timings =>
            {:batch => [
              :course,
              {:weekday_set => :weekday_sets_weekdays},
              {:timetable_entries => [{:employees => {:timetable_entries => :class_timing}},:class_timing]},
              {:subjects => [:elective_group,{:employees => :employee_grade}]},
              {:elective_groups => {:subjects => {:employees => :employee_grade}}},
              {:batch_class_timing_sets => {:class_timing_set => :class_timings}},
              :batch_timetable_summaries ]
          }
        },
        {:timetable_entries => [:employees, :class_timing]} ])
    wk_days = timetable_weekdays
    total_hours = []
    all_employees = []    
    hash_keys = [:batches, :employees, :subjects, :courses, :weekly_classes]
    batch_hash_keys = [:employees, :subjects, :weekly_classes]
    employee_hash_keys = [:fully_utilized_hours, :over_utilized_hours, :under_utilized_hours]
    subject_hash_keys = [:completely_allocated, :partially_allocated, :not_allocated]
    batch_status_hash_keys = [:completely_allocated, :partially_allocated, :not_allocated, :not_eligible]
    batch_summaries = {}
    batch_summary_hash_struct = {}
    summary_hash = Hash.new
    hash_keys.map {|x| summary_hash[x] = Hash.new.merge({:total_count => 0}) }                 # initialize
    batch_hash_keys.map {|x| batch_summary_hash_struct[x] = Hash.new.merge({:total_count => 0}) }     # initialize
    employee_hash_keys.map {|x| summary_hash[:employees].merge!({x => {:total => 0, :employee_ids => []}});batch_summary_hash_struct[:employees].merge!({x => {:total => 0, :employee_ids => []}})}
    batch_status_hash_keys.map {|x| summary_hash[:batches].merge!({x => {:total => 0, :batch_ids => []}}) }
    subject_hash_keys.map {|x| batch_summary_hash_struct[:subjects].merge!({ x => {:total => 0, :subject_ids => [], :elective_group_ids => []}})}
    ttes = this_timetable.timetable_entries
    ttcts = this_timetable.time_table_class_timings
    #    .all(:include =>
    #        {:batch =>
    #          [{:subjects => {:employees => :timetable_entries}},
    #          {:elective_groups => {:subjects => :employees}},
    #          {:batch_class_timing_sets => {:class_timing_set => :class_timings }},
    #          :timetable_entries
    #        ]
    #      }
    #    )
    batches = ttcts.map {|x| x.batch if (x.batch.end_date >= self.start_date and x.batch.start_date <= self.end_date )}.compact
    unless batches.present?
      summary_hash = Hash.new
    else
      summary_hash[:batches][:total_count] = batches.length
      summary_hash[:courses][:total_count] = batches.map(&:course_id).uniq.length

      total_alloted_hours = 0

      batches.each do |batch|
        batch_status = batch.tte_status(this_timetable)
        batch_summary_hash = Marshal.load(Marshal.dump(batch_summary_hash_struct))

        ## normal active subjects
        all_subjects = batch.subjects.select { |x| (!x.elective_group_id.present? and !x.is_deleted)}
        ## active elective group with active subjects
        all_elective_groups = batch.elective_groups.select { |x| (x.subjects.present? and x.subjects.reject {|sub| sub.is_deleted }.compact.present? and !x.is_deleted)}
        subjects = all_subjects.reject {|x| x.elective_group_id.present? }
        elective_subjects = all_elective_groups.map {|x| x.subjects.select {|sub| (!sub.is_deleted) } }.flatten.compact
        #      electives = elective_subjects.map {|x| x.elective_group }

        emp_subject_hours = {}
        batch_ttes = batch.timetable_entries.select{|x| x.timetable_id == self.id}
        all_subjects.each do |subj| # normal subjects
          tte_subj_hours = batch_ttes.select {|x| x.entry_id == subj.id && x.entry_type == 'Subject'}
          subject_hours = subj.max_weekly_classes
          sub_emps = subj.employees
          #          all_employees += sub_empsview
          sub_emps.each {|emp| emp_subject_hours[emp] ||= {:allocated_hours => 0} }
          tte_subj_hours.each { |tte| tte.employees.each {|emp| emp_subject_hours[emp] ||= {:allocated_hours => 0}; emp_subject_hours[emp][:allocated_hours] += 1 } }

          if(tte_subj_hours.length == 0)
            batch_summary_hash[:subjects][:not_allocated][:total] += 1
            batch_summary_hash[:subjects][:not_allocated][:subject_ids] << subj.id
          elsif(subject_hours <= tte_subj_hours.length)
            batch_summary_hash[:subjects][:completely_allocated][:total] += 1
            batch_summary_hash[:subjects][:completely_allocated][:subject_ids] << subj.id
          elsif(subject_hours > tte_subj_hours.length)
            batch_summary_hash[:subjects][:partially_allocated][:total] += 1
            batch_summary_hash[:subjects][:partially_allocated][:subject_ids] << subj.id
          end
        end
        all_elective_groups.each do |elective_group| # elective groups
          tte_subj_hours = batch_ttes.select {|x| x.entry_id == elective_group.id && x.entry_type == 'ElectiveGroup'}
          elective_subjects = elective_group.subjects.select {|x| !x.is_deleted }
          # below evaluates if respective elective subject is mapped to students or not
          # subject_weekly_hours = elective_subjects.present? ? elective_subjects.collect{|x| x.max_weekly_classes if x.students.present? }.compact : [0]
          # below evaluates doesnt not check if respective elective subject is mapped to students or not
          #          subject_weekly_hours = elective_subjects.present? ? elective_subjects.collect{|x| x.max_weekly_classes }.compact : [0]
          #        subject_hours = subject_weekly_hours.flatten.present? ? (subject_weekly_hours.sum/subject_weekly_hours.length) :
          subject_hours = elective_subjects.map(&:max_weekly_classes).min

          sub_emps = elective_subjects.map {|x| es_emps = x.employees; es_emps.each {|emp| emp_subject_hours[emp] ||= {:allocated_hours => 0};  emp_subject_hours[emp][:allocated_hours] += subject_hours} }
          tte_subj_hours.each { |tte| tte.employees.each {|emp| emp_subject_hours[emp] ||= {:allocated_hours => 0}; emp_subject_hours[emp][:allocated_hours] += 1 } }
          if(tte_subj_hours.length == 0)
            batch_summary_hash[:subjects][:not_allocated][:total] += 1
            batch_summary_hash[:subjects][:not_allocated][:elective_group_ids] << elective_group.id
          elsif(subject_hours <= tte_subj_hours.length)
            batch_summary_hash[:subjects][:completely_allocated][:total] += 1
            batch_summary_hash[:subjects][:completely_allocated][:elective_group_ids] << elective_group.id
          elsif(subject_hours > tte_subj_hours.length)
            batch_summary_hash[:subjects][:partially_allocated][:total] += 1
            batch_summary_hash[:subjects][:partially_allocated][:elective_group_ids] << elective_group.id
          end
        end
        batch_employees = batch_ttes.collect {|batch_tte| batch_tte.employees }.flatten.uniq
        all_employees += batch_employees
        batch_summary_hash[:subjects][:total_count] = all_subjects.length + all_elective_groups.length
        batch_total_alloted_hours = 0
        emp_subject_hours.each_pair{ |employee,hour_data| batch_total_alloted_hours += hour_data[:allocated_hours] }        
        #        batch_summary_hash[:employees][:total_count] = emp_subject_hours.keys.length
        batch_summary_hash[:employees][:total_count] = batch_employees.length
        batch_total_alloted_hours = batch_ttes.length
        total_alloted_hours += batch_total_alloted_hours
        batch_summary_hash[:employees][:average_classes] = (batch_summary_hash[:employees][:total_count].zero? ? 0 : ((batch_total_alloted_hours.to_f) / (batch_summary_hash[:employees][:total_count])).round(2))
        batch_summary_hash[:employees][:overlaps] = {:details => {}, :total => 0}
        emp_overlaps = {}
        overlapped_emps = []
        #        batch_ttes = batch.timetable_entries.select{|x| x.timetable_id == self.id}
        batch_ttes.each do |batch_tte|          
          wk = batch_tte.weekday_id
          ct = [batch_tte.class_timing.start_time,batch_tte.class_timing.end_time]
          emps = batch_tte.employees
          #        all_employees += emps
          emps.each do |emp|
            e_ttes = emp.timetable_entries.select {|x| (x.timetable_id == batch_tte.timetable_id and x.batch_id != batch_tte.batch_id and x.weekday_id == wk )}
            e_ttes.each do |e_tte|
              e_ct = e_tte.class_timing
              emp_overlaps[emp.id] ||= {}
              emp_overlaps[emp.id][wk] ||= {:tts => [], :cts => []}
              if emp_overlaps[emp.id][wk][:tts].present?
                emp_overlaps[emp.id][wk][:cts].each do |x|
                  if(((e_ct.start_time..e_ct.end_time-1).include? x[0]) || ((e_ct.start_time+1..e_ct.end_time).include? x[1]) || ((x[0]..x[1]).include? e_ct.start_time+1) || ((x[0]..x[1]).include? e_ct.end_time-1))
                    emp_overlaps[emp.id][wk][:tts]<< e_tte.id unless emp_overlaps[emp.id][wk][:tts].include? e_tte.id
                    ct_el = [e_ct.start_time,e_ct.end_time]
                    emp_overlaps[emp.id][wk][:cts] << ct_el unless emp_overlaps[emp.id][wk][:cts].include? ct_el
                    overlapped_emps << emp.id
                  end
                end
              else
                if(((e_ct.start_time..e_ct.end_time-1).include? ct[0]) || ((e_ct.start_time+1..e_ct.end_time).include? ct[1]) || ((ct[0]..ct[1]).include? e_ct.start_time+1) || ((ct[0]..ct[1]).include? e_ct.end_time-1))
                  emp_overlaps[emp.id][wk][:tts] = [batch_tte.id,e_tte.id]
                  emp_overlaps[emp.id][wk][:cts] = [[e_ct.start_time,e_ct.end_time],ct]
                  overlapped_emps << emp.id
                end
              end
            end
          end
        end
        emp_overlaps.each_pair {|k,v| v.each_pair {|x,y| y.delete_if {|a,b| a == :cts}}}
        batch_summary_hash[:employees][:overlaps][:total] = overlapped_emps.uniq.length
        batch_summary_hash[:employees][:overlaps][:details] = emp_overlaps
        this_batch_class_timing_sets = batch.batch_class_timing_sets.select {|x| (wk_days.include? x.weekday_id)}
        batch_total_hours = this_batch_class_timing_sets.map {|x| x.class_timing_set.class_timings.select {|y| !y.is_break} }.flatten
        total_hours += batch_total_hours if batch_status[:eligibility_code] > 0
        batch_summary_hash[:weekly_classes][:total_count] = total_hours.present? ? batch_total_hours.length : 0
        batch_summary_hash[:weekly_classes][:total_allocated_classes] = batch_ttes.length

        summary_hash[:subjects][:total_count] += subjects.length + elective_subjects.length
        allocation_status = batch_status #batch.tte_status(self)
        case allocation_status[:eligibility_code]
        when 0
          summary_hash[:batches][:not_eligible][:total] += 1
          summary_hash[:batches][:not_eligible][:batch_ids] << batch.id
        when 1
          summary_hash[:batches][:not_allocated][:total]  += 1
          summary_hash[:batches][:not_allocated][:batch_ids] << batch.id
        when 2
          summary_hash[:batches][:partially_allocated][:total] += 1
          summary_hash[:batches][:partially_allocated][:batch_ids] << batch.id
        when 3
          summary_hash[:batches][:completely_allocated][:total] += 1
          summary_hash[:batches][:completely_allocated][:batch_ids] << batch.id
        end
        batch.update_or_create_timetable_summary(batch_summary_hash, self)
      end
      all_employees = all_employees.flatten.uniq
      all_employees.each do |employee|
        emp_ttes = employee.timetable_entries.reject {|x| x.timetable_id != self.id }
        emp_grade = employee.employee_grade
        if emp_grade.present? and emp_grade.max_hours_week.present?
          if emp_grade.max_hours_week == emp_ttes.length
            summary_hash[:employees][:fully_utilized_hours][:total] += 1
            summary_hash[:employees][:fully_utilized_hours][:employee_ids] << employee.id
          elsif emp_grade.max_hours_week < emp_ttes.length
            summary_hash[:employees][:over_utilized_hours][:total] += 1
            summary_hash[:employees][:over_utilized_hours][:employee_ids] << employee.id
          elsif emp_grade.max_hours_week > emp_ttes.length
            summary_hash[:employees][:under_utilized_hours][:total] += 1
            summary_hash[:employees][:under_utilized_hours][:employee_ids] << employee.id
          end
        end
      end
      summary_hash[:employees][:total_count] = (all_employees.length)
      summary_hash[:employees][:average_classes] = (all_employees.present? ? ((total_alloted_hours.to_f) / (all_employees.length)).round(2) : 0)
      summary_hash[:employees][:overlaps] = {}
      tte_sets = {}
      ttes.each do |tte|
        tte_sets[tte.weekday_id] ||= {}
        tte.employees.each do |emp|
          tte_sets[tte.weekday_id][emp] ||= []
          tte_sets[tte.weekday_id][emp] << tte
        end
      end
      emp_overlaps = {}
      overlap_check = {}
      overlap_total = []
      tte_sets.each_pair do |weekday_id,emps|
        emps.each_pair do |emp, tts|
          if tts.length > 1
            overlap_check = {}
            tts.each do |tt|
              ct = tt.class_timing
              unless overlap_check[emp.id].present?
                overlap_check[emp.id] = {:tts => [tt.id], :cts => [[ct.start_time,ct.end_time]] }
              else
                arr = Array.new
                flag = false
                overlap_check[emp.id][:cts].each do |x|
                  if(((ct.start_time..ct.end_time-1).include? x[0]) || ((ct.start_time+1..ct.end_time).include? x[1]) || ((x[0]..x[1]).include? ct.start_time+1) || ((x[0]..x[1]).include? ct.end_time-1))
                    flag = true
                  end
                end
                overlap_total << emp.id if flag == true
                overlap_check[emp.id][:tts] << tt.id if flag == true
                overlap_check[emp.id][:cts] << [ct.start_time, ct.end_time] if flag == true
                overlap_check[emp.id][:cts].uniq!
              end
            end
            emp_overlaps[emp.id] ||= {} if overlap_check[emp.id][:tts].length > 1
            emp_overlaps[emp.id][weekday_id] = overlap_check[emp.id] if overlap_check[emp.id][:tts].length > 1

          end
        end
      end
      emp_overlaps.each_pair {|k,v| v.each_pair {|x,y| y.delete_if {|a,b| a == :cts}}}
      summary_hash[:employees][:overlaps][:total] = overlap_total.uniq.length
      summary_hash[:employees][:overlaps][:details] = emp_overlaps
      summary_hash[:weekly_classes][:total_count] = total_hours.length
      summary_hash[:weekly_classes][:total_allocated_classes] = ttes.length #total_alloted_hours
    end
    
    update_attributes({:timetable_summary => summary_hash, :timetable_summary_status => 0})
  end

  def range
    return "#{format_date(self.start_date,:format=>:long)}  -  #{format_date(self.end_date,:format=>:long)}"
  end

  def check_allocation_status
    return 3.to_a if (self.timetable_status == 3)
    batches = self.time_table_class_timings.map {|x| x.batch if (x.batch.end_date.to_date >= self.start_date and x.batch.start_date.to_date <= self.end_date)}.compact
    #    if (x.batch.end_date.to_date >= self.start_date and x.batch.start_date.to_date <= self.end_date) }.compact
    #    return -1 if batches.length == 0
    return -2.to_a if batches.length == 0
    status = []
    batches.each do |batch|
      #      if (batch.end_date.to_date >= self.start_date and batch.start_date.to_date <= self.end_date)
      batch_status = batch.tte_status(self)
      status << (batch_status[:eligibility_code] > 0 ? (batch_status[:eligibility_code] - 1) : -1)
      #      end
      #      weekdays = batch.weekday_set.weekdays.map(&:weekday_id)
      #      ttes = batch.timetable_entries.reject {|x| x if x.timetable_id != id}
      #      periods = batch.batch_class_timing_sets.reject {|x| x if !weekdays.include? x.weekday_id }.map {|x| x.class_timing_set.class_timings } if ttes.present?
      #      status << (ttes.length == periods.length ? 2 : 1) if ttes.present?
      #      status << 0 unless ttes.present?
      #      batch_status = batch.tte_status(self)
      #      status << (batch_status[:eligibility_code] > 0 ? (batch_status[:eligibility_code] - 1) : -1)
    end
    status.uniq!
    #    return -1 if (status.include? -1)
    return [(status.length == 1 ? status.first : ((status & [1,2]).present? ? 1 : 0)), status.include?(-1) ? -1 : 0]  # 1 represents partial & 2 represents complete allocation status
  end
  #  def save_timetable_weekdays
  #    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date])
  #    batches.each do |batch|
  #      if time_table_weekdays.find_all_by_batch_id(batch.id).blank?
  #        batch_weekday_set = batch.weekday_set_id.nil? ? WeekdaySet.common : batch.weekday_set
  #        time_table_weekdays.build(:batch_id => batch.id,:weekday_set_id => batch_weekday_set.try(:id))
  #      end
  #    end
  #  end

  def save_timetable_class_timings
    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date])
    batches.each do |batch|
      if time_table_class_timings.find_all_by_batch_id(batch.id).blank?
        ttct=time_table_class_timings.build(:batch_id => batch.id)
        batch.batch_class_timing_sets.each do |cts|
          ttct.time_table_class_timing_sets.build(:batch_id=>batch.id,:class_timing_set_id=>cts.class_timing_set_id,:weekday_id=>cts.weekday_id)
        end
      end
    end
  end

  #  def save_timetable_weekdays_on_split(current_timetable)
  #    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date]).collect(&:id)
  #    current_time_table_weekdays=current_timetable.time_table_weekdays
  #    current_time_table_weekdays.each do |weekdays|
  #      if batches.include? weekdays.batch_id
  #        self.time_table_weekdays.build(:batch_id => weekdays.batch_id,:weekday_set_id => weekdays.weekday_set_id)
  #      end
  #    end
  #  end

  def save_timetable_classtimings_on_split(current_timetable)
    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date]).collect(&:id)
    current_time_table_class_timings=current_timetable.time_table_class_timings
    current_time_table_class_timings.each do |class_timings|
      wkdays = timetable_weekdays
      current_timetable_class_timing_sets=class_timings.time_table_class_timing_sets.select {|time_table_class_timing| (wkdays.include? time_table_class_timing.weekday_id) }
      if batches.include? class_timings.batch_id and current_timetable_class_timing_sets.present?
        ttct=self.time_table_class_timings.build(:batch_id => class_timings.batch_id)
        current_timetable_class_timing_sets.each do |ttcts|
          ttct.time_table_class_timing_sets.build(:batch_id=>class_timings.batch_id,:class_timing_set_id=>ttcts.class_timing_set_id,:weekday_id=>ttcts.weekday_id)
        end
      end
    end
    current_timetable.update_attribute(:timetable_summary_status, 1) # mark timetable summary for updation
  end

  def copy_timetable_entries(current_timetable)
    wkdays = timetable_weekdays
    entries=current_timetable.timetable_entries.select {|tte| (wkdays.include? tte.weekday_id) }
    batches = Batch.active.all(:conditions=>["batches.start_date <= ? and batches.end_date >= ?", self.end_date,self.start_date]).collect(&:id)
    entries.each do |e|
      if batches.include? e.batch_id
        new_timetable_entry=e.clone
        new_timetable_entry.timetable_id=self.id
        new_timetable_entry.save
        new_timetable_entry.employee_ids = e.employee_ids
      end
    end
  end

  def dependency_delete(start_date,end_date,tt_id)
    logger = Logger.new("#{RAILS_ROOT}/log/time_table_dependacy_delete.log")
    logger.info "=========Start Deleting #{Time.now.strftime("%d%b%Y%H%M%S")}==========="
    logger.info SubjectLeave.destroy_all(:month_date=>start_date.beginning_of_day..end_date.end_of_day)
    logger.info TimetableSwap.destroy_all(:date=>start_date.beginning_of_day..end_date.end_of_day)
    classroom_alloc_ids = ClassroomAllocation.find(:all, :conditions => {:allocation_type => "date_specific"}).collect{|ca| ca.id}
    tte_ids = Timetable.find(tt_id).timetable_entries.collect{|tte| tte.id}
    AllocatedClassroom.delete_all(["date between ? and ? and classroom_allocation_id IN (?) and timetable_entry_id IN (?)",start_date,end_date,classroom_alloc_ids,tte_ids])
    current_days = timetable_weekdays({:start_date => self.start_date, :end_date => self.end_date})
    TimetableEntry.delete_all(["weekday_id NOT IN (?) and timetable_id IN (?)", current_days, tt_id])
    logger.info "=========Deleted==========="
  end

  def self.tte_for_range(batch,date,subject,employee = nil)
    all_swaps = TimetableSwap.find(:all, :include => :subject, :conditions => ["subjects.batch_id = ?", batch.id])
    all_cancelled_swaps = TimetableSwap.find(:all, :include => :timetable_entry, :conditions => ["timetable_entries.batch_id = ? and is_cancelled = ?", batch.id, true])
    all_time_table_class_timings = TimeTableClassTiming.find_all_by_batch_id(batch.id)
    range = register_range(batch,date)
    holidays = batch.holiday_event_dates
    entries = Array.new
    search_id = subject.elective_group_id.nil?? subject.id : subject.elective_group_id
    subject_type = subject.elective_group_id.nil?? 'Subject':'ElectiveGroup'
    entered_timetables = all_time_table_class_timings.select{|attct| attct.batch_id == batch.id}.map(&:timetable_id)
    all_timetables = Timetable.find_all_by_id(entered_timetables,:conditions => ["((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))",range.first,range.last,range.first,range.last,range.first,range.last])
    default_timetables = all_timetables.dup
    all_timetable_entries = TimetableEntry.find_all_by_timetable_id_and_entry_id_and_entry_type(entered_timetables,search_id,subject_type)
    all_timetables.each do |timetable|
      time_table_class_timings=all_time_table_class_timings.select{|attct| attct.batch_id == batch.id and attct.timetable_id == timetable.id}.first
      class_timings =[]
      if time_table_class_timings.present?
        time_table_class_timings.time_table_class_timing_sets.each do |ttcts|
          class_timings += ttcts.class_timing_set.class_timings.map(&:id)
        end
      else
        []
      end
      weekdays = time_table_class_timings.present? ? time_table_class_timings.time_table_class_timing_sets.map(&:weekday_id) : []
      t_entries = all_timetable_entries.select{|atte| atte.timetable_id == timetable.id and atte.entry_id == search_id and (class_timings.include? atte.class_timing_id) and (weekdays.include? atte.weekday_id) and (atte.employee_ids.include? employee.id) }  if (employee.present? and employee.user.admin == false and !employee.user.privileges.map(&:name).include? "StudentAttendanceRegister")
      t_entries ||= all_timetable_entries.select{|atte| atte.timetable_id == timetable.id and (atte.entry_type == 'Subject' ? atte.entry_id == subject.id : (atte.assigned_subjects.map(&:id).include? subject.id)) and class_timings.include? atte.class_timing_id and weekdays.include? atte.weekday_id}
      entries.push(t_entries)
    end
    entries = entries.flatten.compact
    timetable_ids=[]
    timetable_ids << Timetable.all(:joins=>:timetable_entries,:conditions=>['timetable_entries.id IN (?) AND ((? BETWEEN start_date AND end_date) OR (? BETWEEN start_date AND end_date) OR (start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?))',all_swaps.collect(&:timetable_entry_id),range.first,range.last,range.first,range.last,range.first,range.last]).collect(&:id).uniq
    timetable_ids << entries.collect(&:timetable_id).uniq
    timetable_ids=timetable_ids.flatten.uniq
    hsh2=ActiveSupport::OrderedHash.new
    if timetable_ids.present?
      timetables = find(timetable_ids)
      hsh = ActiveSupport::OrderedHash.new
      entries_hash = entries.group_by(&:timetable_id)
      entries_hash.each do |k,val|
        hsh[k] = val.group_by(&:weekday_id)
      end
      timetables.each do |tt|
        ([tt.start_date,range.first].max..[tt.end_date,range.last].min).each do |d|
          swaps = all_swaps.select{|as| as.date == d.to_date and as.subject_id == subject.id and as.employee_id == employee.try(:id)} if (employee.present? and employee.user.admin == false and !employee.user.privileges.map(&:name).include? "StudentAttendanceRegister")
          swaps ||= all_swaps.select{|as| as.date == d.to_date and as.subject_id == subject.id}
          if swaps.present?
            hsh2[d] = swaps.map(&:timetable_entry)
          end          
        end
        ([tt.start_date,range.first].max..[tt.end_date,range.last].min).each do |d|
          hsh2[d] = hsh[tt.id][d.wday] unless hsh[tt.id].nil?
          date_swaps = all_swaps.dup
          if date_swaps.present?
            swaps = date_swaps.select{|ds| ds.date == d.to_date and ds.subject_id == subject.id and ds.employee_id == employee.id} if (employee.present? and employee.user.admin == false and !employee.user.privileges.map(&:name).include? "StudentAttendanceRegister")
            swaps ||= date_swaps.select{|ds| ds.date == d.to_date and ds.subject_id == subject.id}            
            hsh2[d] = hsh2[d].to_a.dup.reject{|x| date_swaps.any?{|s| s[:timetable_entry_id] == x.id and s[:date] == d}}
            hsh2[d] = (hsh2[d].to_a.dup + swaps.map(&:timetable_entry)).compact.flatten
          end
        end
      end
    else
      default_timetables.each do |tt|
        ([tt.start_date,range.first].max..[tt.end_date,range.last].min).each do |d|
          swaps = all_swaps.select{|as| as.date == d.to_date and as.subject_id == subject.id and as.employee_id == employee.id} if (employee.present? and employee.user.admin == false and !employee.user.privileges.map(&:name).include? "StudentAttendanceRegister")
          swaps ||= all_swaps.select{|as| as.date == d.to_date and as.subject_id == subject.id}
          if swaps.present?
            hsh2[d] = swaps.map(&:timetable_entry)
          end
        end
      end
    end
    holidays.each do |h|
      hsh2.delete(h)
    end
    acs = all_cancelled_swaps.group_by { |acs|  acs.date } if all_cancelled_swaps.present?
    hsh2.map {|dt, ttes| hsh2[dt] = ((acs.keys.include?(dt) and hsh2[dt].present?) ? hsh2[dt].reject{|tte| acs[dt].present? and acs[dt].map(&:timetable_entry_id).include?(tte.id)} : hsh2[dt]) } if all_cancelled_swaps.present?    
    hsh2
  end

  def self.tte_for_the_day(batch,date)
    weekday = date.wday
    timetable_class_timings = []
    timetable = Timetable.find(:first,:conditions => "timetables.start_date <= '#{date}' AND timetables.end_date >= '#{date}'")
    TimeTableClassTiming.find_all_by_batch_id(batch.id,:include => [:time_table_class_timing_sets],
      :conditions => ["time_table_class_timings.timetable_id = ? and ttcts.weekday_id = ? ",timetable.id,weekday],
      :joins => "INNER JOIN timetables t on t.id = time_table_class_timings.timetable_id and t.start_date <= '#{date}' AND t.end_date >= '#{date}'
                 LEFT OUTER JOIN time_table_class_timing_sets ttcts on ttcts.time_table_class_timing_id=time_table_class_timings.id and ttcts.weekday_id = #{weekday}").
      collect {|x| x.time_table_class_timing_sets}.flatten.each do |ttcts|
      timetable_class_timings += ttcts.class_timing_set.class_timings.timetable_timings.map(&:id)
    end

    timetable_class_timings.uniq!
    entries = TimetableEntry.find(:all,:joins=>[:timetable, :class_timing], :include => {:timetable_swaps => [:subject, :employee]},  :conditions=>["timetable_entries.weekday_id = ? and (timetables.start_date <= ? AND timetables.end_date >= ?) AND timetable_entries.batch_id = ? AND class_timings.is_deleted = false",weekday,date,date,batch.id], :order=>"class_timings.start_time")    
    timetable_swaps = Hash.new 
    entries.map {|x| timetable_swaps[x.id] = x.timetable_swaps.select {|swap| swap.date.to_s == date.to_s }}
    ttes = entries
    tswaps = timetable_swaps.values.flatten.present? ? timetable_swaps : []
    #    return (entries.empty? ? [] : entries)
    return {:timetable_entries => ttes, :timetable_swaps => tswaps }
    #    return (entries.empty? ? [] : entries.select{|a| a.weekday_id == date.wday})
  end

  def self.tte_for_the_weekday(batch,day)
    date = Date.today
    entries = TimetableEntry.find(:all,:joins=>[:timetable, :class_timing],:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) AND timetable_entries.batch_id = ? AND class_timings.is_deleted = false",date,date,batch.id],:order=>"class_timings.start_time",:include=>[:employees,:class_timing,:entry])
    return (entries.empty? ? [] : entries.select{|a| a.weekday_id == day})
  end

  def self.employee_tte(employee,date)
    subjects = employee.subjects.select{|sub| sub.elective_group_id.nil?}
    electives = employee.subjects.collect{|sub| sub.elective_group_id if sub.elective_group_id.present?}.compact
    #    elective_subjects=electives.map{|x| x.elective_group.subjects.first}
    #    entries =[]
    entries = TimetableEntry.find(:all,:joins=>[:timetable, :class_timing, :employees],
      :include => [:entry,:batch],
      :conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) AND 
                      ((timetable_entries.entry_id in (?) AND timetable_entries.entry_type = 'Subject') OR
                      (timetable_entries.entry_id in (?) AND  timetable_entries.entry_type = 'ElectiveGroup'))
                      AND teacher_timetable_entries.employee_id = (?) AND class_timings.is_deleted = false",date,date,subjects.map(&:id),electives,employee.id],
      :order=>"class_timings.start_time")
    #    entries += TimetableEntry.find(:all,:joins=>[:timetable, :class_timing, :employees],
    #      :conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) AND
    #                      ((timetable_entries.entry_id in (?) AND timetable_entries.entry_type = 'Subject') OR
    #                      (timetable_entries.entry_id in (?) AND  timetable_entries.entry_type = 'ElectiveGroup'))
    #                      AND class_timings.is_deleted = false#",
    #        date,date,elective_subjects], :order=>"class_timings.start_time")
    return (entries.empty? ? [] : entries.select{|a| a.weekday_id == date.wday})
    #    if
    #      today=[]
    #    else
    #      today=
    #    end
    #    today
  end

  def self.subject_tte(subject_id,date)
    subject=Subject.find(subject_id)
    #    unless subject.elective_group.nil?
    #      subject=subject.elective_group.subjects.first
    #    end
    date = date.to_date
    subject_id = subject.elective_group_id.present? ? subject.elective_group_id : subject_id
    subject_type = subject.elective_group_id.present? ? 'ElectiveGroup' : 'Subject'
    if Authorization.current_user.admin?
      entries = TimetableEntry.find(:all,:joins=>[:employees,:timetable, :class_timing],:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) AND timetable_entries.entry_id = ? AND timetable_entries.entry_type = ? AND class_timings.is_deleted = false",date,date,subject_id,subject_type], :include=>:timetable_swaps)
    else
      entries = TimetableEntry.find(:all,:joins=>[:employees,:timetable, :class_timing],:conditions=>["(timetables.start_date <= ? AND timetables.end_date >= ?) AND timetable_entries.entry_id = ? AND timetable_entries.entry_type = ? AND class_timings.is_deleted = false AND teacher_timetable_entries.employee_id=?",date,date,subject_id,subject_type,Authorization.current_user.employee_record.id], :include=>:timetable_swaps)
    end  
    entries=entries.reject{|e| e.timetable_swaps.present?}
    timetable_swaps=subject.timetable_swaps.all(:conditions=>{:date=>date},:include=>:timetable_entry)
    timetable_swaps.each{|ts| entries << ts.timetable_entry} if timetable_swaps.present?
    return (entries.empty? ? [] : entries.select{|a| a.weekday_id == date.wday})
    #    if entries.empty?
    #      today=[]
    #    else
    #      today=
    #    end
    #    today
  end

  def self.register_range(batch,date)
    start=[]
    start<<batch.start_date.to_date
    start<<date.beginning_of_month.to_date
    start<<find(:first,:select=>:start_date,:order=>:start_date).start_date.to_date
    stop=[]
    stop<<batch.end_date.to_date
    stop<<date.end_of_month.to_date
    stop<<find(:last,:select=>:end_date,:order=>:end_date).end_date.to_date
    range=(start.max..stop.min).to_a - batch.holiday_event_dates
  end

  def self.fetch_timetable_data(params)
    timetable_data params
  end

  def self.fetch_employee_timetable_data(params)
    employee_timetable_data params
  end
end