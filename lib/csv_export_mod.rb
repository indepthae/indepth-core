
module CsvExportMod
  require 'advance_fee_collection.rb'

  def self.included(base)
    base.instance_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def student_advanced_search(params)
      params = params[:params] if params.key?(:params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_advanced_search"
      search = Student.search(params[:search])
      unless params[:search]
        batches = Batch.all
      else
        if params[:search].present?
          students = Array.new
          if params[:advv_search].present? and params[:advv_search][:course_id].present?
            unless params[:search][:batch_id_equals].present?
              params[:search][:batch_id_in] = Batch.find_all_by_course_id(params[:advv_search][:course_id]).collect { |b| b.id }
            end
          end
          if params[:search][:is_active_equals]=="true"
            students = Student.ascend_by_first_name.search(params[:search])
          elsif params[:search][:is_active_equals]=="false"
            students = ArchivedStudent.ascend_by_first_name.search(params[:search])
          else
            students1 = Student.ascend_by_first_name.search(params[:search]).all
            students2 = ArchivedStudent.ascend_by_first_name.search(params[:search]).all
            students = students1 + students2
          end
          data_hash[:students] = students
          searched_for = ''
          searched_for += "#{t('name')}: " + params[:search][:first_name_or_middle_name_or_last_name_like].to_s if params[:search][:first_name_or_middle_name_or_last_name_like].present?
          searched_for += "#{t('admission_no')}: " + params[:search][:admission_no_equals].to_s if params[:search][:admission_no_equals].present?
          if params[:advv_search] and params[:advv_search][:course_id].present?
            course = Course.find(params[:advv_search][:course_id])
            batch = Batch.find(params[:search][:batch_id_equals]) unless (params[:search][:batch_id_equals]).blank?
            searched_for += "#{t('course_text')}: " + course.full_name
            searched_for += "#{t('batch')}: " + batch.full_name unless batch.nil?
          end
          searched_for += "#{t('category')}: " + StudentCategory.find(params[:search][:student_category_id_equals]).name.to_s if params[:search][:student_category_id_equals].present?
          if params[:search][:gender_equals].present?
            if params[:search][:gender_equals] == 'm'
              searched_for += "#{t('gender')}: #{t('male')}"
            elsif params[:search][:gender_equals] == 'f'
              searched_for += " #{t('gender')}: #{t('female')}"
            else
              searched_for += " #{t('gender')}: #{t('all')}"
            end
          end
          searched_for += "#{t('blood_group')}: " + params[:search][:blood_group_like].to_s if params[:search][:blood_group_like].present?
          searched_for += "#{t('nationality')}: " + Country.find(params[:search][:nationality_id_equals]).name.to_s if params[:search][:nationality_id_equals].present?
          searched_for += "#{t('year_of_admission')}: " + params[:advv_search][:doa_option].to_s + ' '+ params[:adv_search][:admission_date_year].to_s if params[:advv_search].present? and params[:advv_search][:doa_option].present?
          searched_for += "#{t('year_of_birth')}: " + params[:advv_search][:dob_option].to_s + ' ' + params[:adv_search][:birth_date_year].to_s if params[:advv_search].present? and params[:advv_search][:dob_option].present?
          if params[:search][:is_active_equals]=="true"
            searched_for += " #{t('present_student')} "
          elsif params[:search][:is_active_equals]=="false"
            searched_for += " #{t('former_student')} "
          else
            searched_for += " #{t('all_students')} "
          end
        end
      end
      data_hash[:parameters] = params
      data_hash[:searched_for] = searched_for
      find_report_type(data_hash)
    end

    def cancelled_transactions_advance_search(params)
      data_hash ||= Hash.new
      searched_for = ""
      if (params[:search] or params[:date])
        all_fee_types="'HostelFee', 'TransportFee', 'FinanceFee', 'Refund', 'BookMovement', 'InstantFee'"
        salary = FinanceTransaction.get_transaction_category('Salary')
        if params['transaction']['type'].present? and params['transaction']['type']==t('others')
          searched_for =searched_for+ "<span> #{t('transaction_type')}</span>: #{t('others')}"
          conditions="AND (fa.id IS NULL OR fa.is_deleted = false) AND (cancelled_finance_transactions.collection_name IS NULL OR
                                     cancelled_finance_transactions.finance_type NOT IN (#{all_fee_types})) AND
                                    category_id <> #{salary}"
        elsif params['transaction']['type'].present? and params['transaction']['type']==t('payslips')
          searched_for =searched_for+ "<span> #{t('transaction_type')}</span>: #{t('payslips')}"
          conditions="AND (cancelled_finance_transactions.collection_name IS NULL OR
                                     cancelled_finance_transactions.finance_type NOT IN (#{all_fee_types})) AND
                                    category_id = #{salary}"
        else
          searched_for =searched_for+ "<span> #{t('transaction_type')}</span>: #{t('fees_text')}"
          conditions="AND (fa.id IS NULL OR fa.is_deleted = false) AND (cancelled_finance_transactions.collection_name IS NOT NULL OR
                                     cancelled_finance_transactions.finance_type IN (#{all_fee_types})) AND
                                    category_id <> #{salary}"
        end

        search_attr=params[:search].delete_if { |k, v| v=="" }
        condition_attr=""
        search_attr.keys.each do |k|
          if ["collection_name", "category_id"].include?(k)

            condition_attr=condition_attr+" AND cancelled_finance_transactions.#{k} LIKE ? "

          elsif ["first_name", "admission_no"].include?(k)
            condition_attr=condition_attr+" AND students.#{k} LIKE ?"
          elsif ["employee_number", "employee_name"].include?(k)

            k=="employee_number" ? condition_attr=condition_attr+" AND employees.#{k} LIKE ?" :
              condition_attr=condition_attr+" AND employees.first_name LIKE ?"
          else
            condition_attr=condition_attr+" AND instant_fees.#{k} LIKE ?" if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
          end

        end
        condition_attr=condition_attr+conditions
        #p condition_attr.split(' ')[1..-1].join(' ')
        unless condition_attr.empty?
          condition_attr=condition_attr.split(' ')[1..-1].join(' ')
          condition_attr="("+condition_attr+")"+" AND (cancelled_finance_transactions.created_at < ?
                                                                      AND cancelled_finance_transactions.created_at > ?)"
        else
          condition_attr= "(cancelled_finance_transactions.created_at < ? AND
                                    cancelled_finance_transactions.created_at > ?)"
        end
        condition_array=[]
        condition_array << condition_attr
        search_attr.values.each { |c| condition_array<< (c+"%") }
        #i=2
        condition_array<<"#{params[:date][:end_date].to_date+1.day}%"
        condition_array<<"#{params[:date][:start_date]}%"
        account_join = "LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
        #params[:date].values.each{|d| i=i-1;condition_array<< (d.to_date+i.day)}
        if params[:transaction][:type] == t('advance_fees_text')
          start_date = "#{params[:date][:start_date]}%"
          end_date = "#{params[:date][:end_date].to_date+1.day}%"
          if params[:report_format_type] == 'pdf'
            transactions = CancelledAdvanceFeeTransaction.all(:order => 'cancelled_advance_fee_transactions.created_at',
              :joins => [:student, :transaction_receipt], 
              :conditions => ['(cancelled_advance_fee_transactions.created_at BETWEEN ? AND ?) AND students.admission_no like ? AND students.first_name like ?', 
                start_date, end_date, params[:search][:admission_no], params[:search][:first_name]], 
              :select => "concat(students.first_name, ' ', students.middle_name, ' ', students.last_name) as payee_name, cancelled_advance_fee_transactions.fees_paid as amount, 
                cancelled_advance_fee_transactions.user_id as user_id, cancelled_advance_fee_transactions.reason_for_cancel as cancel_reason, 'Advance Fees' as finance_type, 
                cancelled_advance_fee_transactions.created_at, cancelled_advance_fee_transactions.transaction_data, transaction_receipts.ef_receipt_number as receipt_no")
          else
            transactions = CancelledAdvanceFeeTransaction.all(:order => "cancelled_advance_fee_transactions.created_at desc",
              :joins => [:student, :transaction_receipt], 
              :conditions => ['(cancelled_advance_fee_transactions.created_at BETWEEN ? AND ?) AND students.admission_no like ? AND students.first_name like ?', 
                start_date, end_date, params[:search][:admission_no], params[:search][:first_name]], 
              :select => "concat(students.first_name, ' ', students.middle_name, ' ', students.last_name) as payee_name_for_csv, transaction_receipts.ef_receipt_number as receipt_number, 'Advance Fees' as finance_type, 
              cancelled_advance_fee_transactions.fees_paid as amount, cancelled_advance_fee_transactions.user_id as user_id, cancelled_advance_fee_transactions.reason_for_cancel as cancel_reason, cancelled_advance_fee_transactions.created_at")      
          end
        else
          if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
            transactions = CancelledFinanceTransaction.all(:order => 'cancelled_finance_transactions.created_at desc', :include => [:user],
              :select => "cancelled_finance_transactions.*,
                                IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no,
                                IFNULL(IF(cancelled_finance_transactions.payee_type = 'Student',
                                    IF(students.id IS NOT NULL,
                                        CONCAT(students.first_name, ' ', students.middle_name, ' ', students.last_name),
                                        CONCAT(archived_students.first_name, ' ', archived_students.middle_name, ' ', archived_students.last_name)),
                                    IF(employees.id IS NOT NULL,
                                        CONCAT(employees.first_name, ' ', employees.middle_name, ' ', employees.last_name),
                                        CONCAT(archived_employees.first_name, ' ', archived_employees.middle_name, ' ', archived_employees.last_name))
                                ), '-') AS payee_name",
              :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                              LEFT OUTER JOIN archived_students ON archived_students.former_id = payee_id
                              LEFT OUTER JOIN employees ON employees.id = payee_id
                              LEFT OUTER JOIN archived_employees ON archived_employees.former_id = payee_id
                              LEFT OUTER JOIN instant_fees ON instant_fees.id = finance_id
                                  INNER JOIN finance_transaction_receipt_records ftrr
                                          ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                                  INNER JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id #{account_join}",
              :conditions => condition_array) unless params[:query] == ''
          else
            transactions = CancelledFinanceTransaction.all(:order => 'cancelled_finance_transactions.created_at desc', :include => [:user],
              :select => "cancelled_finance_transactions.*,
                                IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no,
                                IFNULL(IF(cancelled_finance_transactions.payee_type = 'Student',
                                    IF(students.id IS NOT NULL,
                                        CONCAT(students.first_name, ' ', students.middle_name, ' ', students.last_name),
                                        CONCAT(archived_students.first_name, ' ', archived_students.middle_name, ' ', archived_students.last_name)),
                                    IF(employees.id IS NOT NULL,
                                        CONCAT(employees.first_name, ' ', employees.middle_name, ' ', employees.last_name),
                                        CONCAT(archived_employees.first_name, ' ', archived_employees.middle_name, ' ', archived_employees.last_name))
                                ), '-') AS payee_name",
              :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                        LEFT OUTER JOIN employees ON employees.id = payee_id
                              INNER JOIN finance_transaction_receipt_records ftrr
                                      ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                              INNER JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id #{account_join}",
              :conditions => condition_array) unless params[:query] == ''
          end
        end
        data_hash[:transactions] = transactions

        search_attr.each do |k, v|
          searched_for=searched_for+ "<span> #{k.humanize}</span>"
          searched_for=searched_for+ ": " +v.humanize+" "
        end
        params[:date].each do |k, v|
          searched_for=searched_for+ "<span> #{k.humanize}</span>"
          searched_for=searched_for+ ": " +format_date(v.humanize)+" "
        end
      end
      data_hash[:parameters] = params
      data_hash[:method] = "generate_advance_cancelled_transactions"
      data_hash[:transaction_type] = params[:transaction][:type]
      data_hash[:searched_for] = searched_for
      find_report_type(data_hash)
    end

    def discipline_complaint_data(params)
      data=[]
      s_no = 1
      complaints = params[:complaints]
      data<< "Complaints"
      data << ""
      row = []
      row << t('s_no')
      row << t('title')
      row << t('complaint_no')
      row << t('description')
      row << t('trial_date')
      row << t('comp_by')
      row << t('comp_against')
      row << t('jury')
      row << t('officials')
      row << t('status')
      row << t('verdict')
      row << t('convicted')
      data << row
      complaints.each do |index|
        i=DisciplineComplaint.find(index.to_i)
        complainees = ""
        accused=""
        juries = ""
        members=""
        verdict=""
        convicted=""
        row =[]
        row << s_no
        row << i.subject.gsub("&#x200E;", '')
        row << i.complaint_no
        row << i.body
        row << format_date(i.trial_date)
        i.discipline_complainees.each do |s|
          complainees+= "#{s.user.first_name} #{s.user.last_name}-#{s.user.username}\n" unless s.user.nil?
          complainees+= "#{t('deleted_user')}\n" if s.user.nil?
        end
        i.discipline_accusations.each do |s|
          accused+= "#{s.user.first_name} #{s.user.last_name}-#{s.user.username}\n" unless s.user.nil?
          accused+= "#{t('deleted_user')}\n" if s.user.nil?
        end
        i.discipline_juries.each do |s|
          juries+= "#{s.user.first_name} #{s.user.last_name}-#{s.user.username}\n" unless s.user.nil?
          juries+= "#{t('deleted_user')}\n" if s.user.nil?
        end
        i.discipline_members.each do |s|
          members+= "#{s.user.first_name} #{s.user.last_name}-#{s.user.username}\n" unless s.user.nil?
          members+= "#{t('deleted_user')}\n" if s.user.nil?
        end
        i.discipline_actions.each do |s|
          action= s.discipline_student_actions.first
          unless action.nil?
            convicted+= "#{action.discipline_participation.user.first_name} #{action.discipline_participation.user.last_name}-#{action.discipline_participation.user.username}\n" unless action.discipline_participation.user.nil?
            convicted+= "#{t('deleted_user')}\n" if action.discipline_participation.user.nil?
          else
            convicted+= "#{t('deleted_user')}\n"
          end
        end
        i.discipline_actions.each do |s|
          verdict+= "#{s.remarks}\n"
        end
        if i.action_taken == true
          status = t('solved')
        else
          status = t('pending')
        end

        row << complainees.chop
        row << accused.chop
        row << juries.chop
        row << members.chop
        row << status
        row << verdict.chop
        row << convicted.chop
        data << row
        s_no = s_no+1
      end
      data << ""
      return data
    end

    def reminder_data(params)
      data = []
      s_no = 1
      user = User.find(params[:user_id])
      reminders = user.fetch_all_reminders
      data << t('messages_export')
      data << ""
      row = []
      row << t('s_no')
      row << t('from')
      row << t('subject_messages')
      row << t('message')
      row << t('attachments')
      row << t('date_text')
      data << row
      if reminders.present?
        reminders.each do |r|
          #r = Reminder.find(reminder.to_i)
          row = []
          row << s_no
          if r.user.present?
            row << r.user.full_name
          else
            row << t('deleted_user')
          end
          row << r.subject.gsub("&#x200E;", '')
          body = r.body.gsub(/<br\s*\/?>/, "\n").to_s
          row << ActionView::Base.full_sanitizer.sanitize(body)
          if r.reminder_attachments.present?
            #          row << "#{link_to "attachments", r.reminder_attachments.first.attachment.url(:original,false)}"
            #         row << link_to('attachments', r.reminder_attachments.first.attachment.url(:original,false))
            row << "#{FedenaSetting.s3_enabled? ? '' : Fedena.hostname}#{r.reminder_attachments.first.attachment.url(:original,false)}"
          else
            row << ""
          end
          row << format_date(r.created_at.to_date)
          data << row
          s_no = s_no+1
        end
      end
      data << ""
      return data
    end

    def employee_timetable_data_csv(data_hash)
      data ||=Array.new
      tt=Timetable.find(data_hash[:parameters][:tt_id])
      employee = Employee.find(data_hash[:parameters][:employee_id])
      data << "#{t('timetable_text')} #{format_date(tt.start_date)} - #{format_date(tt.end_date)} #{t('for').downcase} #{employee.full_name}"
      data << ""

      electives_list = employee.subjects.group_by(&:elective_group_id)
      timetable_entries = Hash.new { |l, k| l[k] = Hash.new(&l.default_proc) }
      #      employee_subjects = employee.subjects
      #      subjects = employee_subjects.select { |sub| sub.elective_group_id.nil? }
      #      electives = employee_subjects.select { |sub| sub.elective_group_id.present? }
      #      employee_timetable_subjects = employee_subjects.map { |sub| sub.elective_group_id.nil? ? sub : sub.elective_group.subjects.first }
      entries = employee.timetable_entries.all(:include => [:batch, :employees], :conditions => {:timetable_id => tt.id})
      entries = entries.reject { |t| t.entry_type=="ElectiveGroup" and (employee.subjects.collect(&:id) & t.entry.subjects.collect(&:id)).empty? }
      all_timetable_entries = entries.select { |t| t.batch.is_active }.select { |s| s.class_timing.is_deleted==false }
      all_batches = all_timetable_entries.collect(&:batch).uniq
      all_weekdays = all_timetable_entries.collect(&:weekday_id).uniq.sort
      all_classtimings = all_timetable_entries.collect(&:class_timing).uniq.sort! { |a, b| a.start_time <=> b.start_time }

      weekday = weekday_arrangers(all_weekdays)

      all_teachers = all_timetable_entries.collect(&:employees).flatten.uniq
      all_timetable_entries.each_with_index do |tte, i|
        timetable_entries[tte.weekday_id][tte.class_timing_id][i] = tte
      end
      unless weekday.blank?
        weekday.each do |week|
          col1=[""]
          col3=[""]
          col2 = ["#{WeekdaySet.weekday_name(week.to_s).titleize}"]
          all_classtimings.each do |ct|
            unless timetable_entries[week][ct.id].blank?
              timetable_entries[week][ct.id].each_pair do |k, tte|
                col1 << "#{format_date(ct.start_time, :format => :time)} - #{format_date(ct.end_time, :format => :time)}"
                if tte.entry_type == "Subject"
                  col2 << "#{tte.assigned_name}"
                else
                  if tte.is_a? Array
                    col2 << "#{(electives_list[tte.last.entry_id].is_a? Array) ? electives_list[tte.last.entry_id].collect(&:name).join(", ") : electives_list[tte.last.entry_id].name} (#{t('elective')})"
                  else
                    col2 << "#{(electives_list[tte.entry_id].is_a? Array) ? electives_list[tte.entry_id].collect(&:name).join(", ") : electives_list[tte.entry_id].name} (#{t('elective')})"
                  end
                end
                col3 << "#{tte.batch.full_name}"
              end
            end
          end

          data << col1
          data << col2
          data << col3
        end
      end
      return data
    end

    def timetable_data_csv(data_hash)
      data ||= Array.new
      tt=Timetable.find(data_hash[:parameters][:tt_id])
      batch = Batch.find(data_hash[:parameters][:batch_id])
      data << "#{t('timetable_text')} #{format_date(tt.start_date)} - #{format_date(tt.end_date)} #{t('for').downcase} #{batch.full_name}"
      data << ""
      time_table_class_timings = TimeTableClassTiming.find_by_timetable_id_and_batch_id(tt.id, batch.id)
      class_timing_sets = time_table_class_timings.nil? ? batch.batch_class_timing_sets(:joins => {:class_timing_set => :class_timing}) : time_table_class_timings.time_table_class_timing_sets(:joins => {:class_timing_set => :class_timings})
      if tt.duration >= 7
        weekday = weekday_arrangers(time_table_class_timings.time_table_class_timing_sets.collect(&:weekday_id))
      else
        weekdays=[]
        (tt.start_date..tt.end_date).each { |day| weekdays << day.wday if time_table_class_timings.time_table_class_timing_sets.collect(&:weekday_id).include?(day.wday) }
        weekday = weekday_arrangers(weekdays)
      end
      timetable_entries=TimetableEntry.find(:all, :conditions => {:batch_id => batch.id, :timetable_id => tt.id}, :include => [{:subject => :subject_leaves}, :employee, :timetable_swaps])
      timetable= Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      timetable_entries.each do |tte|
        timetable[tte.weekday_id][tte.class_timing_id]=tte
      end
      unless weekday.blank?
        weekday.each do |week|
          col1=[""]
          col3=[""]
          col2 = ["#{WeekdaySet.weekday_name(week.to_s).titleize}"]
          class_timings=class_timing_sets.find_by_weekday_id(week).class_timing_set.class_timings.timetable_timings
          if class_timings.present?
            class_timings.each do |ct|
              tte = timetable[week][ct.id]
              if (tte.is_a? TimetableEntry and !ct.is_break?)
                col1 << "#{format_date(ct.start_time, :format => :time)}-#{format_date(ct.end_time, :format => :time)}"
                if tte.entry.present?
                  col2<< tte.assigned_name.to_s
                  unless tte.entry_type == "Subject"
                    col3<< "(#{t('elective')})"
                  else
                    if tte.employees.present?
                      col3<< tte.employees.map(&:first_name).join(',')
                    else
                      col3<< t('no_teacher')
                    end
                  end
                end
              else
                col1 << "#{format_date(ct.start_time, :format => :time)}-#{format_date(ct.end_time, :format => :time)}"
                col2 << ""
                col3 << ""
              end
            end
          else
            col1 << "#{format_date(ct.start_time, :format => :time)}-#{format_date(ct.end_time, :format => :time)}"
            col2 << ""
            col3 << ""
          end
          data << col1
          data << col2
          data << col3
        end
      end

      return data
    end

    def consolidated_attendance_report(params)
      batch =Batch.find params[:batch]
      start_date = params[:start_date].to_date
      end_date = params[:end_date].to_date
      sub=batch.subjects
      students = batch.students.by_first_name
      subject_wise_leave = Attendance.leave_calculation(start_date,end_date,students,batch,sub)
      data_hash = {:students => students, :parameters => params, :method => "consolidated_attendance_report",:sub=>batch.subjects,:total_students=> batch.students.count,:course => batch.course.full_name, :batch =>batch.full_name,:subject_wise_leave=>subject_wise_leave}
      find_report_type(data_hash)
    end

    def student_attendance_report(params)
      config = Attendance.attendance_type_check
      attendance_lock = AttendanceSetting.is_attendance_lock
      config_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
      batch = Batch.find(params[:batch])
      students = batch.students.by_first_name
      start_date = params[:start_date].to_date
      selected_columns = params[:selected_columns]
      end_date = params[:end_date].to_date
      params.has_key?("range") ? range = params[:range] : range = ""
      params.has_key?("value") ? value = params[:value] : value = ""
      leaves=ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      absent=ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      present=ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      mode=params[:report_type]
      if mode=='custom'
        working_days=batch.date_range_working_days(start_date, end_date)
      else
        working_days=batch.working_days(start_date.to_date)
      end
      unless config == 'Daily'
        if mode == 'Overall'
          unless params[:subject] == '0'
            subject = Subject.find params[:subject]
            students = subject.students.by_first_name  unless subject.elective_group_id.nil?
            if attendance_lock
              academic_days = MarkedAttendanceRecord.subject_wise_working_days(batch,subject.id).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
              report = []
              academic_days.each do |a|
                report << batch.subject_leaves.find(:all,:conditions =>["batch_id= ? and month_date = ? and subject_id =? and class_timing_id=?",batch.id,a.month_date, a.subject_id,a.class_timing_id])
              end
              report = report.flatten
            else
              report = subject.subject_leaves.find(:all, :conditions => {:month_date => start_date..end_date})
            end
            academic_days=batch.subject_hours(start_date, end_date, params[:subject].to_i)
            academic_days_count = academic_days.values.flatten.compact.count.to_i
            late = report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
            grouped = report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
            students.each do |s|
              student_admission_date = s.admission_date
              s_academic_days = Hash.new
              student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,academic_days,academic_days_count,s_academic_days)
              if grouped[s.id].nil?
                leave=0
                absent[s.id]['absent']=0
              else
                leave=grouped[s.id].count
                absent[s.id]['absent']=grouped[s.id].count
              end
              total = (student_academic_days - leave)
              percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
              if range == "" or (student_academic_days > 0 and (range == "Below" and percent < value.to_f) || (range == "Above" and percent > value.to_f) || (range == "Equals" and percent == value.to_f))
                leaves[s.id]['leave'] = leave
                leaves[s.id]['total_academic_days'] = student_academic_days.to_f
                leaves[s.id]['total'] = total
                leaves[s.id]['percent'] = percent
                if late[s.id].present?
                  present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[s.id]['leave'])-  late[s.id].count.to_i
                else
                  present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[s.id]['leave'])
                end
              end
            end
          else
            cancelled_entries = TimetableSwap.find(:all, :select => ["timetable_swaps.*,subjects.id as ssubject_id"],:joins => ["inner join timetable_entries tte on tte.id = timetable_swaps.timetable_entry_id inner join subjects on subjects.id = tte.entry_id and tte.entry_type = 'Subject'"], :conditions => ["subjects.batch_id = ? and is_cancelled = ? and date BETWEEN ? AND ?", batch.id, true, start_date, end_date])
            report = batch.subject_leaves.find(:all, :conditions => {:month_date => start_date..end_date})
            if attendance_lock
              normal_academic_days = MarkedAttendanceRecord.overall_subject_wise_working_days(batch).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
              elective_academic_days = MarkedAttendanceRecord.elective_subject_working_days(batch).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
              total_academic_days = normal_academic_days + elective_academic_days
              report = report.to_a.select{|a| a if total_academic_days.uniq.detect{|x| x.month_date == a.month_date && x.class_timing_id == a.class_timing_id && x.subject_id == a.subject_id} }
            else
              normal_academic_days=batch.subject_hours(start_date, end_date, 0, nil, "normal")
            end
            cancelled_entries = cancelled_entries.count
            academic_days = attendance_lock ? normal_academic_days.collect(&:month_date) : normal_academic_days 
            academic_days_count = attendance_lock ? academic_days.count.to_i : academic_days.values.flatten.compact.count.to_i
            elective_groups = batch.elective_groups.active
            elect_days = {}
            elective_groups.each do |es|
              unless attendance_lock
                elect_days[es.id] = batch.subject_hours(start_date, end_date, es.id, nil, "elective")
              else
                elect_days[es.id] = MarkedAttendanceRecord.subject_wise_elective_working_days(batch.id,es).select{|v| v <= end_date and  v >= start_date}
              end
            end
            late = report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
            grouped = report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
            students.each do |s|
              student_admission_date = s.admission_date
              s_academic_days = attendance_lock ? nil : Hash.new
              elective_academic_days = Hash.new
              student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,academic_days,academic_days_count,s_academic_days)
              student_academic_days -= cancelled_entries.to_i unless attendance_lock
              if grouped[s.id].nil?
                leave=0
                absent[s.id]['absent']=0
              else
                leave=grouped[s.id].count
                absent[s.id]['absent']=grouped[s.id].count
              end
              elec_academic_days = MarkedAttendanceRecord.elective_subject_working_days(batch, s.subjects).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
              student_electives = s.current_subjects.collect(&:elective_group_id).uniq
              batch_elective = batch.elective_groups.collect(&:id).uniq
              student_electives = student_electives.select{|x|  batch_elective.include?(x)}
              student_electives.each do |se|
                elective_days = {} if attendance_lock
                elective_days[se] = elect_days[se].select{|x| elec_academic_days.collect(&:month_date).include?(x)} if attendance_lock
                elec_day = attendance_lock ? elective_days : elect_days
                student_academic_days += Attendance.calculate_student_working_days_elective(student_admission_date,end_date,start_date,elec_day,elective_academic_days,se)
              end
              total = (student_academic_days - leave)
              percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
              if range == "" or (student_academic_days > 0 and (range == "Below" and percent < value.to_f) || (range == "Above" and percent > value.to_f) || (range == "Equals" and percent == value.to_f))
                leaves[s.id]['leave']=leave
                leaves[s.id]['total_academic_days'] = student_academic_days.to_f
                leaves[s.id]['total'] = total
                leaves[s.id]['percent'] = percent
                if late[s.id].present?
                  present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[s.id]['leave'])-  late[s.id].count.to_i
                else
                  present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[s.id]['leave'])
                end
              end
            end
          end
        else
          unless params[:subject] == '0'
            subject = Subject.find params[:subject]
            students = subject.students.by_first_name unless subject.elective_group_id.nil?
            if attendance_lock
              report = []
              academic_days = MarkedAttendanceRecord.subject_wise_working_days(batch,subject.id).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
              academic_days.each do |a|
                report << batch.subject_leaves.find(:all,:conditions =>["batch_id= ? and month_date = ? and subject_id =? and class_timing_id=?",batch.id,a.month_date, a.subject_id,a.class_timing_id])
              end
              report = report.flatten
            else
              report = SubjectLeave.find_all_by_subject_id(subject.id, :conditions => {:batch_id => batch.id, :month_date => start_date..end_date})
            end
            academic_days=batch.subject_hours(start_date, end_date, params[:subject].to_i)
            academic_days_count = academic_days.values.flatten.compact.count.to_i
            late = report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
            grouped = report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
            batch.students.by_first_name.each do |s|
              s_academic_days = attendance_lock ? nil : Hash.new
              student_admission_date = s.admission_date
              student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,academic_days,academic_days_count,s_academic_days)
              #              student_academic_days = (student_admission_date <= end_date && student_admission_date >= start_date) ? (academic_days.each_pair {|x,y| s_academic_days[x] = y if x >= student_admission_date }; s_academic_days.values.flatten.compact.count.to_i) : (start_date >= student_admission_date ? academic_days.values.flatten.compact.count.to_i : 0)
              if grouped[s.id].nil?
                leave=0
                absent[s.id]['absent']=0
              else
                leave=grouped[s.id].count
                absent[s.id]['absent']=grouped[s.id].count
              end
              total = student_academic_days - leave
              percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
              if range == "" or (student_academic_days > 0 and (range == "Below" and percent < value.to_f) || (range == "Above" and percent > value.to_f) || (range == "Equals" and percent == value.to_f))
                leaves[s.id]['leave']=leave
                leaves[s.id]['total'] = total
                leaves[s.id]['total_academic_days'] = student_academic_days.to_f
                leaves[s.id]['percent'] = percent
                if late[s.id].present?
                  present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[s.id]['leave'])-  late[s.id].count.to_i
                else
                  present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[s.id]['leave'])
                end
              end
            end
          else
            #academic_days=batch.subject_hours(start_date, end_date, 0).values.flatten.compact.count
            report = batch.subject_leaves.find(:all, :conditions => {:month_date => start_date..end_date})
            cancelled_entries = TimetableSwap.find(:all, :select => ["timetable_swaps.*,subjects.id as ssubject_id"],:joins => ["inner join timetable_entries tte on tte.id = timetable_swaps.timetable_entry_id inner join subjects on subjects.id = tte.entry_id and tte.entry_type = 'Subject'"], :conditions => ["subjects.batch_id = ? and is_cancelled = ? and date BETWEEN ? AND ?", batch.id, true, start_date, end_date])
            if attendance_lock
              normal_academic_days = MarkedAttendanceRecord.overall_subject_wise_working_days(batch).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
              elective_academic_days = MarkedAttendanceRecord.elective_subject_working_days(batch).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
              total_academic_days = normal_academic_days + elective_academic_days
              report = report.to_a.select{|a| a if total_academic_days.uniq.detect{|x| x.month_date == a.month_date && x.class_timing_id == a.class_timing_id && x.subject_id == a.subject_id} }
            else
              normal_academic_days=batch.subject_hours(start_date, end_date, 0, nil, "normal")
            end
            cancelled_entries = cancelled_entries.count
            academic_days = attendance_lock ? normal_academic_days.collect(&:month_date) : normal_academic_days 
            elective_groups = batch.elective_groups.active
            elect_days = {}
            elective_groups.each do |es|
              unless attendance_lock
                elect_days[es.id] = batch.subject_hours(start_date, end_date, es.id, nil, "elective")
              else
                elect_days[es.id] = MarkedAttendanceRecord.subject_wise_elective_working_days(batch.id,es).select{|v| v <= end_date and  v >= start_date}
              end
            end
            late = report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
            grouped = report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
            if attendance_lock
              academic_days_count = academic_days.count.to_i
            else
              academic_days_count = academic_days.values.flatten.compact.count.to_i
            end
            batch.students.by_first_name.each do |s|
              student_admission_date = s.admission_date
              s_academic_days = attendance_lock ? nil : Hash.new
              elective_academic_days = Hash.new
              student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,academic_days,academic_days_count,s_academic_days)
              student_academic_days -= cancelled_entries.to_i unless attendance_lock
              if grouped[s.id].nil?
                leave=0
                absent[s.id]['absent']=0
              else
                leave=grouped[s.id].count
                absent[s.id]['absent']=grouped[s.id].count
              end
              elect_academic_days = MarkedAttendanceRecord.elective_subject_working_days(batch, s.subjects).select{|v| v.month_date <= end_date and  v.month_date >= start_date}
              student_electives = s.current_subjects.collect(&:elective_group_id).uniq
              batch_elective = batch.elective_groups.collect(&:id).uniq
              student_electives = student_electives.select{|x|  batch_elective.include?(x)}
              student_electives.each do |se|
                elective_days = {} if attendance_lock
                elective_days[se] = elect_days[se].select{|x| elect_academic_days.collect(&:month_date).include?(x)} if attendance_lock
                elec_day = attendance_lock ? elective_days : elect_days
                student_academic_days += Attendance.calculate_student_working_days_elective(student_admission_date,end_date,start_date,elec_day,elective_academic_days,se)
              end
              total = (student_academic_days - leave)
              percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
              if range == "" or (student_academic_days > 0 and (range == "Below" and percent < value.to_f) || (range == "Above" and percent > value.to_f) || (range == "Equals" and percent == value.to_f))
                leaves[s.id]['leave'] = leave
                leaves[s.id]['total_academic_days'] = student_academic_days.to_f
                leaves[s.id]['total'] = total
                leaves[s.id]['percent'] = percent
                if late[s.id].present?
                  present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[s.id]['leave'])-  late[s.id].count.to_i
                else
                  present[s.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[s.id]['leave'])
                end
              end
            end
          end
        end
      else #daily wise
        if mode=='Overall'
          if attendance_lock
            academic_days = MarkedAttendanceRecord.dailywise_working_days(batch.id)
          else
            academic_days = batch.academic_days
          end
        elsif mode=='custom'
          if attendance_lock
            academic_days = MarkedAttendanceRecord.dailywise_working_days(batch.id).select { |v| v <= end_date and  v >= start_date }
            academic_days= academic_days.select { |v| v<=end_date }
          else
            working_days=batch.date_range_working_days(start_date, end_date)
            academic_days= working_days.select { |v| v<=end_date } #.count
          end
        else
          if attendance_lock
            academic_days=MarkedAttendanceRecord.dailywise_working_days(batch.id).select { |v| v <= end_date and  v >= start_date } #.count
          else
            working_days=batch.working_days(start_date.to_date)
            academic_days= working_days.select { |v| v<=end_date } #.count
          end
        end
        academic_days_count = academic_days.count.to_i
        students = batch.students.by_first_name
        report = Attendance.find_all_by_batch_id(batch.id,  :conditions =>{:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date})
        if attendance_lock
          leaves_forenoon = Attendance.count(:conditions=>["forenoon = ? and afternoon = ? and  month_date IN (?)",true,false,academic_days],:group=>:student_id)
          leaves_afternoon = Attendance.count(:conditions=>["forenoon = ? and afternoon = ? and  month_date IN (?)",false,true,academic_days],:group=>:student_id)
          report = report.to_a.select{|a| academic_days.include?(a.month_date) }
        else
          leaves_forenoon=Attendance.count(:all, :conditions => {:batch_id => batch.id, :forenoon => true, :afternoon => false, :month_date => start_date..end_date}, :group => :student_id)
          leaves_afternoon=Attendance.count(:all, :conditions => {:batch_id => batch.id, :forenoon => false, :afternoon => true, :month_date => start_date..end_date}, :group => :student_id)
        end
        late = report.to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
        grouped = report.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.group_by(&:student_id)
        students.each do |student|
          if grouped[student.id].nil?
            leave = 0
            absent[student.id]['absent']=0 + (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          else
            leave=grouped[student.id].count
            absent[student.id]['absent']=grouped[student.id].count
            absent[student.id]['absent']= absent[student.id]['absent'].to_f + (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          end
          student_admission_date = student.admission_date
          student_academic_days = Attendance.calculate_student_working_days(student_admission_date,end_date,start_date,academic_days,academic_days_count)
          total = student_academic_days-leave.to_f-(0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
          percent = student_academic_days == 0 ? '-' : ((total.to_f/student_academic_days)*100).round(2)
          if range == "" or (student_academic_days > 0 and (range == "Below" and percent < value.to_f) || (range == "Above" and percent > value.to_f) || (range == "Equals" and percent == value.to_f))
            leaves[student.id]['total_academic_days'] = student_academic_days.to_f
            leaves[student.id]['total'] = total
            leaves[student.id]['percent'] = percent
            leaves[student.id]['leave'] = leave
            if  late[student.id].present?
              present[student.id]['present'] =  student_academic_days == 0 ? 0 : ((student_academic_days - leaves[student.id]['leave']) - late[student.id].count.to_i)
              present[student.id]['present'] =  present[student.id]['present'].to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
            else
              present[student.id]['present'] =  student_academic_days == 0 ? 0 : (student_academic_days - leaves[student.id]['leave']).to_f - (0.5*(leaves_forenoon[student.id].to_f+leaves_afternoon[student.id].to_f))
            end

          end
        end
      end
      data_hash = {:leaves => leaves,:absent => absent, :present => present, :academic_days => academic_days_count,:late => late, :students => students, :selected_columns => selected_columns , :config_enable =>  config_enable,:batch_id => batch,  :parameters => params, :method => "student_attendance_report", :config => config, :course => batch.course.full_name, :batch => batch.full_name, :subject => subject, :range => range, :value => value}
      find_report_type(data_hash)

    end

    def attendance_register_data(params)
      attendance_lock =  AttendanceSetting.is_attendance_lock
      current_user = Authorization.current_user.first_name
      config  = Configuration.get_config_value('StudentAttendanceType')
      batch = Batch.find_by_id(params[:batch_id])
      date_time = (Date.parse(params[:next])) || FedenaTimeSet.current_time_to_local_time(Time.now)
      today = date_time
      config_enable = Configuration.get_config_value('CustomAttendanceType') || "0"
      total_absentees = Hash.new
      holidays = []
      absent = Hash.new()
      val_code = AttendanceLabel.find_by_attendance_type('Absent').code if config_enable == "1"
      subject = Subject.find(params[:subject_id]) if params[:subject_id].present?
      unless subject.nil?
        unless subject.elective_group_id.nil?
          elective_student_ids = StudentsSubject.find_all_by_subject_id(subject.id).map { |x| x.student_id }
          if Configuration.enabled_roll_number?
            students = batch.students.by_full_name.with_full_name_roll_number_and_batch.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
          else
            students = batch.students.by_full_name.with_full_name_admission_no_and_batch.all(:conditions=>"FIND_IN_SET(id,\"#{elective_student_ids.split.join(',')}\")")
          end
        else
          if Configuration.enabled_roll_number?
            if params[:sort_by]== '0'
              students = batch.students.by_full_name.with_full_name_roll_number_and_batch
            else
              no_roll_numbers = batch.students.by_full_name.select{|s| s.roll_number == "" or s.roll_number == nil}
              with_roll_numbers = batch.students.by_roll_number - no_roll_numbers
              students = with_roll_numbers + no_roll_numbers
            end

          else
            students = batch.students.by_full_name.with_full_name_admission_no_and_batch
          end
        end
      else
        if Configuration.enabled_roll_number?
          if params[:sort_by]== '0'
            students = batch.students.by_full_name.with_full_name_roll_number_and_batch
          else
            no_roll_numbers = batch.students.by_full_name.select{|s| s.roll_number == "" or s.roll_number == nil}
            with_roll_numbers = batch.students.by_roll_number - no_roll_numbers
            students = with_roll_numbers + no_roll_numbers
          end

        else
          students = batch.students.by_full_name.with_full_name_admission_no_and_batch
        end
      end

      student_count = students.count.to_i
      if config == "Daily"
        saved_dates = MarkedAttendanceRecord.fetch_saved_dates(batch.id)
        working_days  = batch.date_range_working_days(today.beginning_of_month, today.end_of_month).count.to_i
        attendances = Attendance.by_month_and_batch(today,params[:batch_id])
        attendances = attendances.students_in_batches(batch) if batch.batch_students.exists?
        dates = batch.total_days(today)
        attendance_status = Attendance.dailywise_attendance_status(batch.id,dates)
        working_dates = batch.working_days(today)
        b_attendances =  attendances.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late" or !ct.student.present?}.group_by(&:month_date)
        b_attendances.each do |date,absentees_count|
          total_absentees.merge!({"#{date}" => b_attendances[date].count})
        end
        holidays = dates.to_a - working_dates
      else
        saved_dates = MarkedAttendanceRecord.fetch_saved_dates(params[:batch_id], params[:subject_id])
        attendance_list = SubjectLeave.by_month_batch_subject(today,params[:batch_id],params[:subject_id])
        attendance_list = attendance_list.students_in_batches(batch) if batch.batch_students.exists?
        attendance_list = attendance_list.all(:conditions=>["student_id in (?)" , students.collect(&:id)])
        attendance_list = attendance_list.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late" or !ct.student.present?} if (config_enable == "0")
        absent = attendance_list.group_by(&:student_id)
        dates_key = Timetable.tte_for_range(batch,today,subject)
        working_days = dates_key.values.compact.flatten.count
        dates_key = dates_key.sort
        attendance_status = SubjectLeave.attendance_status(batch.id,params[:subject_id],dates_key)
        dates = []
        dates << today
        b_attendances = attendance_list.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late" or !ct.student.present?}.group_by(&:month_date)
        b_attendances.each do |date, absentees_count|
          att_count = Hash.new
          if absentees_count.present?
            absentees_count.group_by(&:class_timing_id).each do |class_timing, leave_count|
              att_count.merge!({class_timing => leave_count.count})
            end
            total_absentees.merge!({"#{date}" => att_count})
          end
        end
      end
      data_hash = {:students => students, :config => config,:enable => config_enable,
        :batch => batch,:today => today, :method => "attendance_register_data",:roll_number_enabled => Configuration.enabled_roll_number?,
        :attendance_config => Configuration.is_batch_date_attendance_config?, :parameters => params, :total_absentees => total_absentees,
        :val_code => val_code, :dates_key=> dates_key, :subject => subject, :dates => dates, :holidays => holidays, :academic_days => working_days,
        :student_count => student_count, :current_user => current_user, :absents => absent,:attendance_lock => attendance_lock, 
        :saved_dates => saved_dates, :attendance_status => attendance_status }
      find_report_type(data_hash)


    end

    def day_wise_report(params)
      cur_user = Authorization.current_user
      attendance_lock = AttendanceSetting.is_attendance_lock
      save_attendance = MarkedAttendanceRecord.daywise_total_save_days(params[:date]) if attendance_lock
      #    data_hash[:attendance_label] = AttendanceLabel.find(params[:attendance_label_id]) if params[:attendance_label_id].present?
      if cur_user.admin? or (cur_user.employee? and cur_user.privileges.map { |p| p.name }.include?('StudentAttendanceView'))
        if params[:course_id].present?
          @batches = Batch.all(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
            :order => "courses.course_name,batches.id",
            :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{params[:date]}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
            :include => :course, :conditions => ["'#{params[:date]}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batches.course_id = #{params[:course_id]}"],
            :group => "batches.id")
        else
          @batches = Batch.all(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
            :order => "courses.course_name,batches.id", :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{params[:date]}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id",
            :include => :course, :conditions => ["'#{params[:date]}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0"],
            :group => "batches.id")
        end
      else
        if params[:course_id].present?
          @batches = Batch.all(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
            :order => "courses.course_name,batches.id",
            :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{params[:date]}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
            :include => :course, :conditions => ["'#{params[:date]}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{cur_user.employee_record.id} AND batches.course_id = #{params[:course_id]}"],
            :group => "batches.id")
        else
          @batches = Batch.all(:select => "batches.*,courses.course_name AS course_name,count(DISTINCT IF(attendances.student_id = students.id,attendances.id,NULL)) AS attendance_count",
            :order => "courses.course_name,batches.id",
            :joins => " INNER JOIN courses ON courses.id = batches.course_id LEFT OUTER JOIN attendances ON attendances.batch_id = batches.id AND attendances.month_date = '#{params[:date]}' LEFT OUTER JOIN students ON students.id = attendances.student_id AND students.batch_id = batches.id LEFT OUTER JOIN batch_tutors ON batches.id = batch_tutors.batch_id",
            :include => :course, :conditions => ["'#{params[:date]}' BETWEEN batches.start_date AND batches.end_date AND batches.is_active = 1 AND batches.is_deleted = 0 AND courses.is_deleted = 0 AND batch_tutors.employee_id = #{cur_user.employee_record.id}"],
            :group => "batches.id")
        end
      end
      data_hash = {:date => params[:date], :method => "day_wise_report", :parameters => params}
      leave_count = Attendance.all(:select => "attendances.*,CONCAT(students.first_name, students.last_name )as student_name,  students.roll_number as roll_no" ,:joins => ["INNER JOIN batches ON batches.id = attendances.batch_id INNER JOIN students ON attendances.student_id = students.id AND students.batch_id = batches.id"],
        :conditions => {:month_date => "#{params[:date]}", :'batches.is_deleted' => false, :'batches.is_active' => true})
      leave_count = leave_count.to_a.select{|leave| save_attendance.collect(&:batch_id).include?(leave.batch_id)} if attendance_lock
      leave_count = leave_count.to_a.select{|leave| save_attendance.collect(&:month_date).include?(leave.month_date)} if attendance_lock
      data_hash[:leave_count] = leave_count
      data_hash[:late] = data_hash[:leave_count].to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      data_hash[:late] =  data_hash[:late].group_by(&:batch_id)
      data_hash[:absent] = data_hash[:leave_count].to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}
      data_hash[:absent] =  data_hash[:absent].group_by(&:batch_id)
      data_hash[:leave_count] = data_hash[:leave_count].count
      data_hash[:attendance_lock] = attendance_lock if attendance_lock
      # data_hash[:]
      data_hash[:report] = @batches.to_a.group_by { |b| b.course_name }
      find_report_type(data_hash)
    end

    def student_ranking_per_subject(params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_ranking_per_subject"
      data_hash[:parameters] = params
      subject = Subject.find(params[:subject_id])
      data_hash[:subject] = subject
      batch = subject.batch
      data_hash[:batch_name] = batch.name
      data_hash[:course] = batch.course.full_name
      students = batch.students.by_first_name
      data_hash[:students] = students
      unless subject.elective_group_id.nil?
        students.reject! { |s| !StudentsSubject.exists?(:student_id => s.id, :subject_id => subject.id) }
      end
      exam_groups = ExamGroup.find(:all, :conditions => {:batch_id => batch.id}, :include => [:exams => :exam_scores])
      data_hash[:exam_groups] = exam_groups
      exam_groups.reject! { |e| e.exam_type=="Grades" }
      ranks = []
      exam_groups.each do |exam_group|
        rank_exam = exam_group.exams.select { |x| x.subject_id == subject.id and x.exam_group_id == exam_group.id }
        unless rank_exam.empty?
          exam_scores = rank_exam[0].exam_scores.select { |x| x.exam_id == rank_exam[0].id }
          ordered_marks = exam_scores.map { |m| m.marks }.compact.uniq.sort.reverse
          ranks << [exam_group.id, ordered_marks]
        end
      end
      data_hash[:ranks] = ranks
      find_report_type(data_hash)
    end

    def timetable_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "timetable_data"
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def employee_timetable_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "employee_timetable_data"
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def student_ranking_per_batch(params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_ranking_per_batch"
      batch = Batch.find(params[:batch_id], :include => [:students])
      data_hash[:batch] = batch.name
      data_hash[:course] = batch.course.full_name
      students = batch.students
      grouped_exams = GroupedExam.find_all_by_batch_id(batch.id)
      ranked_students = batch.find_batch_rank
      data_hash[:parameters] = params
      data_hash[:ranked_students] = ranked_students
      find_report_type(data_hash)
    end

    def student_ranking_per_course(params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_ranking_per_course"
      course = Course.find(params[:course_id])
      data_hash[:course] = course
      if course.has_batch_groups_with_active_batches
        batch_group = BatchGroup.find(params[:batch_group_id])
        data_hash[:batch_group] = batch_group
        batches = batch_group.batches
      else
        batches = course.active_batches
      end
      students = Student.find_all_by_batch_id(batches)
      grouped_exams = GroupedExam.find_all_by_batch_id(batches)
      sort_order=""
      unless !params[:sort_order].present?
        sort_order=params[:sort_order]
      end
      ranked_students = course.find_course_rank(batches.collect(&:id), sort_order)
      data_hash[:ranked_students] =ranked_students
      data_hash[:parameters] = params
      data_hash[:sort_order] = sort_order
      find_report_type(data_hash)
    end

    def student_ranking_per_school(params)
      params = params[:params] if params.key?(:params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_ranking_per_school"
      courses = Course.all(:conditions => {:is_deleted => false})
      batches = Batch.all(:conditions => {:course_id => courses, :is_deleted => false, :is_active => true})
      students = Student.find_all_by_batch_id(batches)
      grouped_exams = GroupedExam.find_all_by_batch_id(batches)
      sort_order = ""
      unless !params[:sort_order].present?
        sort_order=params[:sort_order]
      end
      data_hash[:sort_order] = sort_order
      unless courses.empty?
        ranked_students = courses.first.find_course_rank(batches.collect(&:id), sort_order)
      else
        ranked_students = []
      end
      data_hash[:ranked_students] = ranked_students
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def student_ranking_per_attendance(params)
      batch = Batch.find(params[:batch_id])
      students = Student.find_all_by_batch_id(batch.id)
      start_date = params[:start_date].to_date
      end_date = params[:end_date].to_date
      ranked_students = batch.find_attendance_rank(start_date, end_date)
      data_hash = {:method => "student_ranking_per_attendance", :batch => batch, :students => students, :start_date => start_date, :end_date => end_date, :ranked_students => ranked_students, :parameters => params}
      find_report_type(data_hash)
    end

    def employee_advance_search(params)
      params = params[:params] if params.key?(:params)
      employee_ids = params[:result]
      searched_for = params[:for]
      status = params[:status]
      employees = []
      if params[:status] == 'true'
        search = Employee.ascend_by_first_name.search(params[:search])
        employees += search.all
      elsif params[:status] == 'false'
        search = ArchivedEmployee.ascend_by_first_name.search(params[:search])
        employees += search.all
      else
        search1 = Employee.ascend_by_first_name.search(params[:search]).all
        search2 = ArchivedEmployee.ascend_by_first_name.search(params[:search]).all
        employees+=search1+search2
      end
      data_hash = {:method => "employee_advance_search", :parameters => params, :searched_for => searched_for, :employees => employees}
      find_report_type(data_hash)
    end

    def reportees_attendance_data(params)
      params = params[:params] if params.key?(:params)
      employee = Employee.find(params[:id])
      leave_types = EmployeeLeaveType.all
      if params[:filter] == "true"
        if params[:start_date].present?
          start_date = params[:start_date].to_date
          end_date = params[:end_date].to_date
          employee_attendance = Employee.all(:joins => "inner join employee_departments ed on ed.id = employees.employee_department_id inner join employee_attendances ea on ea.attendance_date between '#{params[:start_date]}' and '#{params[:end_date]}'", :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken", :include => [:employee_attendances, :employee_additional_leaves], :conditions => ["employees.reporting_manager_id = ?", employee.user.id], :group => "employees.employee_department_id, employees.id", :order => 'ed.name, employees.first_name')
          employees = employee_attendance.group_by(&:name)
        else
          employee_attendance = Employee.all(:joins => "inner join employee_departments ed on ed.id = employees.employee_department_id inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= el.reset_date", :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", :include => [:employee_attendances, :employee_additional_leaves], :conditions => ["employees.reporting_manager_id = ?", employee.user.id], :group => "employees.employee_department_id, employees.id", :order => 'ed.name, employees.first_name')
          employees = employee_attendance.group_by(&:name)
        end
      else
        employee_attendance = Employee.all(:joins => "inner join employee_departments ed on ed.id = employees.employee_department_id inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= el.reset_date", :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", :include => [:employee_attendances, :employee_additional_leaves], :conditions => ["employees.reporting_manager_id = ?", employee.user.id], :group => "employees.employee_department_id, employees.id", :order => 'ed.name, employees.first_name')
        employees = employee_attendance.group_by(&:name)
      end
      data_hash = {:method => "employee_attendance_data", :from => params[:from], :parameters => params, :employees => employees, :leave_types => leave_types, :start_date => start_date, :end_date => end_date}
      find_report_type(data_hash)
    end

    def employee_attendance_data(params)
      params = params[:params] if params.key?(:params)
      leave_types = EmployeeLeaveType.all

      if params[:filter] == "true"
        join = "left outer join employee_attendances ea on ea.employee_id = employees.id and"
        if params[:leave_criteria].present?
          case params[:leave_criteria]
          when "All"
            join = "left outer join employee_attendances ea on ea.employee_id = employees.id and"
          when "additional_leaves"
            join = "inner join employee_additional_leaves ea on ea.employee_id = employees.id and"
          when "lop_deducted"
            join = "inner join employee_additional_leaves ea on ea.employee_id = employees.id and ea.is_deductable = true and ea.is_deducted = true and"
          when "lop_not_deducted"
            join = "inner join employee_additional_leaves ea on ea.employee_id = employees.id and ea.is_deductable = true and ea.is_deducted = false and"
          end
        end
        if params[:start_date].present?
          start_date = params[:start_date].to_date
          end_date = params[:end_date].to_date
          if params[:department_id] == "All Departments"
            employee_attendance = Employee.all(:joins => "inner join employee_departments ed on ed.id = employees.employee_department_id #{join} ea.attendance_date between '#{start_date}' and '#{end_date}'", :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken", :include => [:employee_attendances, :employee_additional_leaves], :group => "employees.employee_department_id, employees.id", :order => 'ed.name, employees.first_name')
            employees = employee_attendance.group_by(&:name)
          else
            employee_attendance = Employee.all(:joins => "inner join employee_departments ed on ed.id = employees.employee_department_id  and employees.employee_department_id = #{params[:department_id]} #{join} ea.attendance_date between '#{start_date}' and '#{end_date}'", :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken", :include => [:employee_attendances, :employee_additional_leaves], :group => "employees.employee_department_id, employees.id", :order => 'ed.name, employees.first_name')
            employees = employee_attendance.group_by(&:name)
          end
        else
          if params[:department_id] == "All Departments"
            employee_attendance = Employee.all(:joins => "inner join employee_departments ed on ed.id = employees.employee_department_id inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id #{join} ea.attendance_date >= employees.last_reset_date", :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", :include => [:employee_attendances, :employee_additional_leaves], :group => "employees.employee_department_id, employees.id", :order => 'ed.name, employees.first_name')
            employees = employee_attendance.group_by(&:name)
          else
            employee_attendance = Employee.all(:joins => "inner join employee_departments ed on ed.id = employees.employee_department_id and employees.employee_department_id = #{params[:department_id]} inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id #{join} ea.attendance_date >= employees.last_reset_date", :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", :include => [:employee_attendances, :employee_additional_leaves], :group => "employees.employee_department_id, employees.id", :order => 'ed.name, employees.first_name')
            employees = employee_attendance.group_by(&:name)
          end
        end
        if params[:leave_category] == "active"
          leave_types = leave_types.select{|lt| lt.is_active == true} if leave_types.present?
        end
      else
        leave_types = leave_types.select{|lt| lt.is_active == true} if leave_types.present?
        employee_attendance = Employee.all(:joins => "inner join employee_departments ed on ed.id = employees.employee_department_id inner join (select * from employee_leaves group by employee_id) el on el.employee_id = employees.id left outer join employee_attendances ea on ea.employee_id = employees.id and ea.attendance_date >= employees.last_reset_date", :select => "employees.last_reset_date,employees.id,employees.first_name,employees.middle_name,employees.last_name, employees.employee_number,ed.name, SUM(case(ea.is_half_day) when true then 0.5 when false then 1 else 0 end) as leaves_taken, el.reset_date", :include => [:employee_attendances, :employee_additional_leaves], :group => "employees.employee_department_id, employees.id", :order => 'ed.name, employees.first_name')
        employees = employee_attendance.group_by(&:name)
      end

      data_hash = {:method => "employee_attendance_data", :from => params[:from], :parameters => params, :employees => employees, :leave_types => leave_types, :start_date => start_date, :end_date => end_date}
      find_report_type(data_hash)
    end

    def subject_wise_data(params)
      subject = Subject.find(params[:subject_id])
      batch = subject.batch
      #students = batch.students
      #if Configuration.enabled_roll_number?  Configuration.enabled_roll_number?
      if Configuration.enabled_roll_number? && batch.roll_number_generated?
        students = batch.students.find(:all, :order => "#{Student.sort_order}")
      else
        students = batch.students.find(:all, :order => "#{Student.sort_order}")
      end

      exam_groups = ExamGroup.find(:all, :conditions => {:batch_id => batch.id})
      data_hash = {:method => "subject_wise_data", :parameters => params, :subject => subject, :batch => batch, :exam_groups => exam_groups, :students => students}
      find_report_type(data_hash)
    end

    def consolidated_exam_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "consolidated_exam_data"
      exam_group = ExamGroup.find(params[:exam_group], :include => :exams)
      data_hash[:exam_group] = exam_group
      data_hash[:exams] = exam_group.exams
      batch = exam_group.batch
      data_hash[:batch] = batch
      if batch.gpa_enabled?
        data_hash[:grade_type] = "GPA"
      elsif batch.cwa_enabled?
        data_hash[:grade_type] = "CWA"
      else
        data_hash[:grade_type] = "normal"
      end
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def ranking_level(params)
      data_hash ||= Hash.new
      data_hash[:method] = "ranking_level"
      data_hash[:parameters] = params
      ranking_level = RankingLevel.find(params[:ranking_level_id])
      mode = params[:mode]
      if mode=="batch"
        batch = Batch.find(params[:batch_id])
        report_type = params[:report_type]
        if report_type=="subject"
          students = batch.students.find(:all, :order => "#{Student.sort_order}")
          subject = Subject.find(params[:subject_id])
          scores = GroupedExamReport.find(:all, :conditions => {:student_id => students.collect(&:id), :batch_id => batch.id, :subject_id => subject.id, :score_type => "s"})
          if batch.gpa_enabled?
            scores.reject! { |s| !((s.marks < ranking_level.gpa if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.gpa if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.gpa if ranking_level.marks_limit_type=="exact")) }
          else
            scores.reject! { |s| !((s.marks < ranking_level.marks if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.marks if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.marks if ranking_level.marks_limit_type=="exact")) }
          end
        else
          students = batch.students.find(:all, :order => "#{Student.sort_order}")
          unless ranking_level.subject_count.nil?
            unless ranking_level.full_course==true
              subjects = batch.subjects
              scores = GroupedExamReport.find(:all, :conditions => {:student_id => students.collect(&:id), :batch_id => batch.id, :subject_id => subjects.collect(&:id), :score_type => "s"})
            else
              scores = GroupedExamReport.find(:all, :conditions => {:student_id => students.collect(&:id), :score_type => "s"})
            end
            if batch.gpa_enabled?
              scores.reject! { |s| !((s.marks < ranking_level.gpa if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.gpa if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.gpa if ranking_level.marks_limit_type=="exact")) }
            else
              scores.reject! { |s| !((s.marks < ranking_level.marks if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.marks if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.marks if ranking_level.marks_limit_type=="exact")) }
            end
          else
            unless ranking_level.full_course==true
              scores = GroupedExamReport.find(:all, :conditions => {:student_id => students.collect(&:id), :batch_id => batch.id, :score_type => "c"})
            else
              scores = []
              students.each do |student|
                total_student_score = 0
                avg_student_score = 0
                marks = GroupedExamReport.find_all_by_student_id_and_score_type(student.id, "c")
                unless marks.empty?
                  marks.map { |m| total_student_score+=m.marks }
                  avg_student_score = total_student_score.to_f/marks.count.to_f
                  marks.first.marks = avg_student_score
                  scores.push marks.first
                end
              end
            end
            if batch.gpa_enabled?
              scores.reject! { |s| !((s.marks < ranking_level.gpa if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.gpa if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.gpa if ranking_level.marks_limit_type=="exact")) }
            else
              scores.reject! { |s| !((s.marks < ranking_level.marks if ranking_level.marks_limit_type=="upper") or (s.marks >= ranking_level.marks if ranking_level.marks_limit_type=="lower") or (s.marks == ranking_level.marks if ranking_level.marks_limit_type=="exact")) }
            end
          end
        end
      else
        course = Course.find(params[:course_id])
        if course.has_batch_groups_with_active_batches
          batch_group = BatchGroup.find(params[:batch_group_id])
          batches = batch_group.batches
        else
          batches = course.active_batches
        end
        students = Student.find_all_by_batch_id(batches.collect(&:id), :order => "#{Student.sort_order}")
        unless ranking_level.subject_count.nil?
          scores = GroupedExamReport.find(:all, :conditions => {:student_id => students.collect(&:id), :batch_id => batches.collect(&:id), :score_type => "s"})
        else
          unless ranking_level.full_course==true
            scores = GroupedExamReport.find(:all, :conditions => {:student_id => students.collect(&:id), :batch_id => batches.collect(&:id), :score_type => "c"})
          else
            scores = []
            students.each do |student|
              total_student_score = 0
              avg_student_score = 0
              marks = GroupedExamReport.find_all_by_student_id_and_score_type(student.id, "c")
              unless marks.empty?
                marks.map { |m| total_student_score+=m.marks }
                avg_student_score = total_student_score.to_f/marks.count.to_f
                marks.first.marks = avg_student_score
                scores.push marks.first
              end
            end
          end
        end
        if ranking_level.marks_limit_type=="upper"
          scores.reject! { |s| !(((s.marks < ranking_level.gpa unless ranking_level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks < ranking_level.marks unless ranking_level.marks.nil?)) }
        elsif ranking_level.marks_limit_type=="exact"
          scores.reject! { |s| !(((s.marks == ranking_level.gpa unless ranking_level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks == ranking_level.marks unless ranking_level.marks.nil?)) }
        else
          scores.reject! { |s| !(((s.marks >= ranking_level.gpa unless ranking_level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks >= ranking_level.marks unless ranking_level.marks.nil?)) }
        end
      end
      if mode=="batch"
        unless scores.empty?
          if report_type=="subject"
            ranked_students = Student.find_all_by_id(scores.collect(&:student_id), :order => "#{Student.sort_order}")
            ranked_students = ranked_students.reject { |st| st.has_higher_priority_ranking_level(ranking_level.id, "subject", subject.id)==true }
          else
            unless ranking_level.subject_count.nil?
              sub_count = ranking_level.subject_count
              ranked_students = []
              students.each do |student|
                student_scores = scores.dup
                student_scores.reject! { |s| !(s.student_id==student.id) }
                if ranking_level.subject_limit_type=="upper"
                  if student_scores.count < sub_count
                    ranked_students << student
                  end
                elsif ranking_level.subject_limit_type=="exact"
                  if student_scores.count == sub_count
                    ranked_students << student
                  end
                else
                  if student_scores.count >= sub_count
                    ranked_students << student
                  end
                end
              end
            else
              ranked_students = Student.find_all_by_id(scores.collect(&:student_id), :order => "#{Student.sort_order}")
            end
            ranked_students = ranked_students.reject { |st| st.has_higher_priority_ranking_level(ranking_level.id, "overall", "")==true }
          end
          data_hash[:ranked_students] = ranked_students
          data_hash[:ranking_level] = ranking_level
          find_report_type(data_hash)
        end
      else
        unless scores.empty?
          unless ranking_level.subject_count.nil?
            sub_count = ranking_level.subject_count
            ranked_students = []
            unless ranking_level.full_course==true
              students.each do |student|
                student_scores = scores.dup
                student_scores.reject! { |s| !(s.student_id==student.id) }
                batch_ids = student_scores.collect(&:batch_id)
                batch_ids.each do |batch_id|
                  unless batch_ids.empty?
                    count = batch_ids.count(batch_id)
                    if ranking_level.subject_limit_type=="upper"
                      if count < sub_count
                        unless student.has_higher_priority_ranking_level(ranking_level.id, "course", "")
                          ranked_students << [student.id, batch_id]
                        end
                      end
                    elsif ranking_level.subject_limit_type=="exact"
                      if count == sub_count
                        unless student.has_higher_priority_ranking_level(ranking_level.id, "course", "")
                          ranked_students << [student.id, batch_id]
                        end
                      end
                    else
                      if count >= sub_count
                        unless student.has_higher_priority_ranking_level(ranking_level.id, "course", "")
                          ranked_students << [student.id, batch_id]
                        end
                      end
                    end
                    batch_ids.delete(batch_id)
                  end
                end
              end
            else
              students.each do |student|
                student_scores = scores.dup
                student_scores.reject! { |s| !(s.student_id==student.id) }
                if ranking_level.subject_limit_type=="upper"
                  if student_scores.count < sub_count
                    unless student.has_higher_priority_ranking_level(ranking_level.id, "course", "")
                      ranked_students << [student.id, student.batch.id]
                    end
                  end
                elsif ranking_level.subject_limit_type=="exact"
                  if student_scores.count == sub_count
                    unless student.has_higher_priority_ranking_level(ranking_level.id, "course", "")
                      ranked_students << [student.id, student.batch.id]
                    end
                  end
                else
                  if student_scores.count >= sub_count
                    unless student.has_higher_priority_ranking_level(ranking_level.id, "course", "")
                      ranked_students << [student.id, student.batch.id]
                    end
                  end
                end
              end
            end
          else
            ranked_students = []
            scores.each do |score|
              unless score.student.has_higher_priority_ranking_level(ranking_level.id, "course", "")
                ranked_students << [score.student_id, score.batch_id]
              end
            end
          end
          data_hash[:ranked_students] = ranked_students
          data_hash[:ranking_level] = ranking_level
          find_report_type(data_hash)
        end
      end
    end

    def finance_payslip_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "finance_payslip_data"
      data_hash[:parameters] = params.except("payslip")
      data_hash[:search_parameters] = params[:payslip]
      grouping = data_hash[:search_parameters][:department_id] == "All" ? "dept_name" : "payment_period"
      data_hash[:department_name] = data_hash[:search_parameters][:department_id] == "All" ? t('all_departments') : EmployeeDepartment.find(data_hash[:search_parameters][:department_id]).name
      conditions = EmployeePayslip.fetch_conditions(data_hash[:search_parameters])
      where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
      payslips_list = EmployeePayslip.all(:select => "employee_payslips.id, emp.first_name, emp.middle_name, emp.last_name, emp.employee_number, employee_departments.name AS dept_name, emp.emp_type, payroll_groups.payment_period, payslips_date_ranges.start_date, payslips_date_ranges.end_date, employee_payslips.net_pay, employee_payslips.is_approved, employee_payslips.is_rejected, employee_payslips.payslips_date_range_id, employee_payslips.employee_id", :joins => "INNER JOIN ((SELECT id AS emp_id, first_name, last_name, middle_name, employee_number, employee_department_id, 'Employee' AS emp_type from employees #{where_condition}) UNION ALL (SELECT id AS emp_id,first_name, last_name, middle_name, employee_number, employee_department_id, 'ArchivedEmployee' AS emp_type from archived_employees #{where_condition})) emp ON emp.emp_id=employee_payslips.employee_id AND employee_payslips.employee_type = emp.emp_type  INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id INNER JOIN employee_departments ON emp.employee_department_id = employee_departments.id", :conditions => conditions, :order => "#{grouping}, first_name", :include => {:payslips_date_range => :payroll_group})
      data_hash[:payslips] = payslips_list.group_by(&grouping.to_sym)
      data_hash[:currency_type] = Configuration.find_by_config_key("CurrencyType").config_value
      find_report_type(data_hash)
    end


    def exam_timings_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "exam_timings_data"
      data_hash[:parameters] = params
      data_hash[:course] = Course.find params[:course_id]
      data_hash[:assessment_group] = AssessmentGroup.find params[:group_id]
      data_hash[:term] = data_hash[:assessment_group].parent
      assessments = AssessmentGroupBatch.course_assessments(data_hash[:assessment_group].id, data_hash[:course].id)
      if params[:batch_id].present? and params[:batch_id] != "All"
        assessments = assessments.batch_equals(params[:batch_id])
        data_hash[:batch] = Batch.find(params[:batch_id])
      end
      data_hash[:assessments] = assessments.group_by(&:batch)
      find_report_type(data_hash)
    end

    def finance_tax_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "finance_tax_data"
      data_hash[:parameters] = params

      start_date = (params[:start_date]).to_date
      data_hash[:start_date] = start_date
      end_date = (params[:end_date]).to_date
      data_hash[:end_date] = end_date
      # finance fee tax payments
      all_tax_payments = TaxPayment.finance_fee_tax_payments(start_date, end_date)
      # hostel tax payments if plugin is enabled
      all_tax_payments += TaxPayment.hostel_fee_tax_payments(start_date, end_date) if FedenaPlugin.can_access_plugin?("fedena_hostel")
      # transport tax payments if plugin is enabled
      all_tax_payments += TaxPayment.transport_fee_tax_payments(start_date, end_date) if FedenaPlugin.can_access_plugin?("fedena_transport")
      # instant fee tax payments if plugin is enabled
      all_tax_payments += TaxPayment.instant_fee_tax_payments(start_date, end_date) if FedenaPlugin.can_access_plugin?("fedena_instant_fee")

      data_hash[:tax_payments] = all_tax_payments

      #      tax_payments = all_tax_payments.group_by { |tax|  "#{tax.slab_name} - &rlm;(#{precision_label(tax.slab_rate)}%)&rlm;" }
      #      total_tax = all_tax_payments.map(&:tax_amount).sum.to_f
      find_report_type(data_hash)
    end

    def fee_structure_overview_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "fee_structure_overview_data"
      data_hash[:parameters] = params

      find_report_type(data_hash)
    end

    def student_fees_structure_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "student_fees_structure_overview_data"
      data_hash[:parameters] = params

      data_hash[:batch] = batch = Batch.find(data_hash[:parameters][:batch_id])
      data_hash[:student] = student = Student.find(data_hash[:parameters][:student_id])
      data_hash[:student_fees] = ActiveSupport::OrderedHash.new
      # finance fees
      data_hash[:student_fees]["finance_fees"] = student.fetch_fees 'FinanceFee', batch.id
      # hostel fees
      data_hash[:student_fees]["hostel_fees"] = student.fetch_fees 'HostelFee', batch.id if FedenaPlugin.
        can_access_plugin?("fedena_hostel")
      # transport fees
      data_hash[:student_fees]["transport_fees"] = student.fetch_fees 'TransportFee', batch.id if FedenaPlugin.
        can_access_plugin?("fedena_transport")
      find_report_type(data_hash)
    end

    def finance_transaction_data(params)
      data_hash ||= Hash.new
      accounts_enabled, filter_by_account, account_id = account_filter params
      joins = "INNER JOIN finance_transactions
                       ON finance_transactions.category_id = finance_transaction_categories.id "
      ft_joins = "INNER JOIN finance_transaction_receipt_records ftrr
                          ON ftrr.finance_transaction_id=finance_transactions.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      ft_joins_2 = "LEFT JOIN finance_transaction_receipt_records ftrr
                           ON ftrr.finance_transaction_id=finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"

      if filter_by_account
        joins += "INNER JOIN finance_transaction_receipt_records ftrr
                          ON ftrr.finance_transaction_id = finance_transactions.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
        # ft_joins = {:finance_transactions => :finance_transaction_receipt_record}
        # joins = [:finance_transaction_receipt_record]
        # filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_conditions += " AND fa.is_deleted = false" #if account_id.present?
        filter_values = [account_id]
        filter_select = ", ftrr.fee_account_id AS account_id"
      else
        # ft_joins = :finance_transactions
        # joins = []
        joins += "LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
        filter_conditions = " AND (fa.id IS NULL or fa.is_deleted = false) "
        filter_select = ""
        filter_values = []
      end

      data_hash[:accounts_enabled] = accounts_enabled
      data_hash[:account_name] = @account_name if accounts_enabled
      data_hash[:method] = "finance_transaction_data"
      data_hash[:parameters] = params
      cat_names = ['Fee', 'Salary', 'Donation']
      plugin_cat = []
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        cat_names << "#{category[:category_name]}"
        plugin_cat << "#{category[:category_name]}"
      end
      fixed_cat_ids = FinanceTransactionCategory.find(:all, :conditions => {:name => cat_names}).collect(&:id)
      hr = Configuration.find_by_config_value("HR")
      data_hash[:hr] = hr
      start_date = (params[:start_date]).to_date
      data_hash[:start_date] = start_date
      end_date = (params[:end_date]).to_date
      data_hash[:end_date] = end_date
      refund_category = FinanceTransactionCategory.find_by_name 'Refund'
      fixed_cat_ids << refund_category.id if refund_category.present?
      other_cat_ids = fixed_cat_ids.join(',')
      other_transaction_categories = FinanceTransactionCategory.find(:all,
        :conditions => ["finance_transactions.transaction_date BETWEEN ? AND ?
          and finance_transaction_categories.id NOT IN (#{fixed_cat_ids.join(',')}) #{filter_conditions}",
          start_date, end_date] + filter_values, :joins => joins).uniq
      data_hash[:other_transaction_categories] = other_transaction_categories
      fees_id = FinanceTransaction.get_transaction_category("Fee")
      transactions_fees = FinanceTransaction.all(:select => "amount", :joins => ft_joins,
        :conditions => ["transaction_date BETWEEN ? AND ? AND category_id = ? #{filter_conditions}",
          start_date, end_date, fees_id] + filter_values).map {|x| x.amount.to_f }.sum
      data_hash[:transactions_fees] = transactions_fees
      salary = FinanceTransaction.all(:select => "amount", #:joins => joins,
        :conditions => ["title = 'Monthly Salary' AND transaction_date BETWEEN ? AND ?",
          start_date, end_date]).map {|x| x.amount.to_f }.sum
      data_hash[:salary] = salary
      refund = FinanceTransaction.get_refund_total_amount(refund_category, start_date, end_date)
      data_hash[:refund] = refund
      data_hash[:refund_cat_name] = refund_category.name
      donations_total = FinanceTransaction.donations_triggers(start_date, end_date,
        {:conditions => filter_conditions, :values => filter_values, :joins => ft_joins, :select => filter_select})
      data_hash[:donations_total] = donations_total
      category_transaction_totals = {}

      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        category_transaction_totals["#{category[:category_name]}"] = FinanceTransaction.
          total_transaction_amount(category[:category_name], start_date, end_date, {
            :conditions => filter_conditions, :values => filter_values,
            :joins => "INNER JOIN finance_transaction_categories ftc
                             ON ftc.id = finance_transactions.category_id #{ft_joins_2}"})
      end
      # advance fee transaction report
      dy_condition_c = 'AND advance_fee_transaction_receipt_records.fee_account_id is null' if account_id.nil?
      dy_condition_c = "AND advance_fee_transaction_receipt_records.fee_account_id = #{account_id}" if (!account_id.nil? and account_id != false)
      dy_condition_c =  nil if account_id == false
      wallet_collections = AdvanceFeeCollection.find(:all, :joins => [:advance_fee_transaction_receipt_record],
        :conditions => ["date_of_advance_fee_payment between ? AND ? #{(dy_condition_c unless dy_condition_c.nil?)}", start_date, end_date+1.day ])
      
      wallet_collection_amount = 0
      wallet_collections.each do |collection|
        wallet_collection_amount += collection.fees_paid
      end
      
      wallet_deductions = AdvanceFeeDeduction.find(:all, :joins => [:finance_transaction], 
        :conditions => ["deduction_date between ? and ?", start_date, end_date+1.day ])
      wallet_deduction_amount = 0
      wallet_deductions.each do |deduction|
        wallet_deduction_amount += deduction.amount
      end
      data_hash[:wallet_income] = wallet_collection_amount if wallet_collections.present?
      data_hash[:wallet_expense] = wallet_deduction_amount
      data_hash[:category_transaction_totals] = category_transaction_totals
      find_report_type(data_hash)
    end

    #########################################
    #     fetch students wallet details     #
    #########################################
    def fetch_students_wallet_details(params)
      data_hash ||= Hash.new
      if params[:batch_wise] && params[:batch_id]
        data_hash[:method] = "batch_wise_monthly_report"
      elsif params[:id] && params[:category_id]
        data_hash[:method] = "students_wallet_details_by_category"
      elsif params[:id]
        data_hash[:method] = "students_wallet"
      elsif params[:collection_wise] && params[:category_id] && params[:student_id]
        data_hash[:method] = "collection_wise_student_report"
      elsif params[:collection_wise] && params[:category_id]
        data_hash[:method] = "collection_wise_monthly_report"
      elsif params[:wallet_expense_course]
        data_hash[:method] = "wallet_expense_monthly_course"
      elsif params[:wallet_credit_transactions]
        data_hash[:method] = "wallet_credit_transactions"
      elsif params[:batch_wise_expense]
        data_hash[:method] = "wallet_expense_transactions_batch_wise"
      elsif params[:transaction_id]
        data_hash[:method] = "wallet_deduction_transaction"
      elsif params[:course_id] || params[:batch_id]
        data_hash[:method] = "students_wallet_details"
      end
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    ############################################
    # batch or course wise wallet report (csv) #
    ############################################
    def students_wallet_details_csv(data_hash)
      data = Array.new
      course = Course.find_by_id(data_hash[:parameters][:course_id]) if data_hash[:parameters][:course_id].present?
      batch = Batch.find_by_id(data_hash[:parameters][:batch_id]) if data_hash[:parameters][:batch_id].present?
      students  = course.students if course.present?
      students  = batch.students if batch.present?
      data << ["#{t('students_wallet_report')}"]
      data << ""
      if batch.present?
        data << ["#{t('batch_name')}"]
        data << ["#{batch.full_name}"]
      else
        data << ["#{t('course_name')}"]
        data << ["#{course.full_name}"]
      end
      data << ""
      data << ["#{t('sl_no')}", "#{t('student_name')}", "#{t('wallet_amount')}"]
      students.each_with_index do |student, i|
        data << ["#{i+1}","#{student.full_name}","#{student.advance_fee_wallet.present? ? student.advance_fee_wallet.amount : "0.00"}"]
      end
      return data
    end

    def students_wallet_csv(data_hash)
      data = Array.new
      student = Student.find_by_id(data_hash[:parameters][:id])
      data << ["#{t('students_wallet_report')}"]
      data << ""
      data << ["#{t('student_name')}", "#{student.full_name}"]
      data << ["#{t('admission_no')}",  "#{student.admission_no}"]
      data << ["#{t('batch_name')}", "#{student.batch.full_name}"]
      data << ["#{t('sl_no')}", "#{t('advance_fees_credit_category_text')}", "#{t('amount')}"]
      data << " "
      transactions = AdvanceFeeCategoryCollection.all(:joins => [:advance_fee_category, :advance_fee_collection], 
        :conditions => {:advance_fee_collections => {:student_id => student.id}}, 
        :select => "sum(advance_fee_category_collections.fees_paid) as amount, advance_fee_categories.name as category_name, advance_fee_collections.student_id as student, advance_fee_categories.id as advance_fee_category_id", 
        :group => "advance_fee_categories.id")
      wallet_credit_transactions = Hash.new
      wallet_credit_transactions = transactions
      wallet_debit_transactions = student.advance_fee_deductions
      i = 0
      wallet_credit_transactions.each do |category|
        data << ["#{ i += 1}", "#{category["category_name"]}", "#{category["amount"]}"]
      end
      i = 0
      data << " "
      data << " "
      data << ["#{t('sl_no')}", "#{t('advance_fees_debit_reciept_text')}", "#{t('amount')}"]
      data << " "
      wallet_debit_transactions.each do |transaction|
        data << ["#{ i += 1}", "#{transaction.finance_transaction.transaction_receipt.ef_receipt_number}", "#{transaction.amount}"]
      end
      return data
    end

    def students_wallet_details_by_category_csv(data_hash)
      data = Array.new
      student = Student.find_by_id(data_hash[:parameters][:id])
      advance_fee_category = AdvanceFeeCategory.find_by_id(data_hash[:parameters][:category_id])
      advance_fee_collections = advance_fee_category.advance_fee_category_collections.all(:joins => [:advance_fee_collection], 
        :conditions => {:advance_fee_collections => {:student_id => student.id}})
      collections_total_amount = 0
      advance_fee_collections.each do |collection|
        collections_total_amount += collection.fees_paid
      end
      data << ["#{t('students_wallet_report')}"]
      data << ""
      data << ["#{t('student_name')}", "#{student.full_name}"]
      data << ["#{t('admission_no')}",  "#{student.admission_no}"]
      data << ["#{t('batch_name')}", "#{student.batch.full_name}"]
      data << ["#{t('category_name')}", "#{t('amount')}"]
      data << ["#{advance_fee_category.name}", "#{collections_total_amount}"]
      data << " "
      data << ["#{t('sl_no')}", "#{t('receipt_no')}", "#{t('transaction_date')}", "#{t('payment_mode')}", "#{t('amount')}"]
      advance_fee_collections.each_with_index do |collection, i|
        data << ["#{i + 1 }", "#{collection.advance_fee_collection.receipt_data.receipt_no}", "#{format_date(collection.advance_fee_collection.date_of_advance_fee_payment)}", "#{collection.advance_fee_collection.payment_mode}", "#{collection.fees_paid}"]
      end
      return data
    end

    def collection_wise_monthly_report_csv(data_hash)
      data = Array.new
      advance_fee_category = AdvanceFeeCategory.find_by_id(data_hash[:parameters][:category_id])
      batch_details = Hash.new
      batch_details = advance_fee_category.fetch_batches_by_collection(data_hash[:parameters][:start_date],
        data_hash[:parameters][:end_date], advance_fee_category.id, data_hash[:parameters][:fee_account_id])
      a = []
      batch_details.each do |x|
        a << x["course_id"]
      end
      a.uniq
      data << ["#{t('course_wise_wallet_report')}"]
      data << " "
      data << ["#{t('from')}", "#{format_date(data_hash[:parameters][:start_date])}", "#{t('to')}", "#{format_date(data_hash[:parameters][:end_date])}"]
      total_amount = 0.00
      a.uniq.each do |course|
        data << ["#{t('course_name')}", "#{Course.find_by_id(course).course_name}"]
        data << ["#{t('sl_no')}", "#{t('batch_name')}", "#{t('amount')}"]
        i = 0
        batch_details.each do |batch|
          if batch["course_id"] == course
            data << ["#{i += 1}", "#{batch["batch_name"]}", "#{batch["amount"]}"]
          end
          total_amount += batch["amount"].to_f
        end
        data << []
      end
      data << [" ", "#{t('net_income')}", "#{total_amount}"]
      return data
    end

    def batch_wise_monthly_report_csv(data_hash)
      data = Array.new
      advance_fee_category = AdvanceFeeCategory.find_by_id(data_hash[:parameters][:category_id])
      batch = Batch.find_by_id(data_hash[:parameters][:batch_id])
      batch_details = Hash.new
      student_fee_collections_by_batch = AdvanceFeeCollection.batch_wise_monthly_income_report(data_hash[:parameters][:start_date], data_hash[:parameters][:end_date], advance_fee_category.id, batch.id, data_hash[:parameters][:fee_account_id])
      data << ["#{t('batch_wise_wallet_report_descr')}"]
      data << " "
      data << ["#{t('from')}", "#{format_date(data_hash[:parameters][:start_date])}", "#{t('to')}", "#{format_date(data_hash[:parameters][:end_date])}"]
      data << ["#{t('batch_name')}", "#{batch.name}"]
      data << ["#{t('advance_fee_category_name')}", "#{advance_fee_category.name}"]
      data << ["#{t('course_name')}", "#{batch.course.course_name}"]
      data << " "
      data << ["#{t('sl_no')}", "#{t('student_name')}", "#{t('amount')}"]
      total_amount = 0
      i = 0
      student_fee_collections_by_batch.each do |collection|
        data << ["#{i += 1}", "#{Student.find_by_id(collection.student_id).full_name}", "#{collection.amount.to_f}"]
        total_amount += collection.amount.to_f
      end
      data << " "
      data << [" ", "#{t('net_income')}", "#{total_amount}"]
      return data
    end

    def collection_wise_student_report_csv(data_hash)
      data = Array.new
      advance_fee_category = AdvanceFeeCategory.find_by_id(data_hash[:parameters][:category_id])
      student = Student.find(data_hash[:parameters][:student_id])
      batch_details = Hash.new
      advance_fee_collections =AdvanceFeeCollection.category_wise_collection_report(data_hash[:parameters][:start_date], data_hash[:parameters][:end_date], advance_fee_category.id, student.id, student.batch.id, data_hash[:parameters][:fee_account_id])
      data << ["#{t('category_collection_report_desc')}"]
      data << " "
      data << ["#{t('from')}", "#{format_date(data_hash[:parameters][:start_date])}", "#{t('to')}", "#{format_date(data_hash[:parameters][:end_date])}"]
      data << ["#{t('student_name')}", "#{student.full_name}"]
      data << ["#{t('advance_fee_category_name')}", "#{advance_fee_category.name}"]
      data << ["#{t('course_name')}", "#{student.batch.course.course_name}"]
      data << " "
      data << ["#{t('fees_receipt_no')}", "#{t('amount')}", "#{t('transaction_date')}", "#{t('payment_mode')}", "#{t('payment_notes')}"]
      total_amount = 0
      advance_fee_collections.each do |collection|
        data << ["#{collection.receipt_no}", "#{collection.amount.to_f}", "#{format_date(collection.transaction_date)}", "#{collection.payment_mode}", "#{collection.payment_note}"]
        total_amount += collection.amount.to_f
      end
      data << " "
      data << ["#{t('net_income')}", "#{total_amount}"]
      return data
    end

    def wallet_expense_monthly_course_csv(data_hash)
      data = Array.new
      batch_details = AdvanceFeeCollection.fetch_wallet_expense_transaction_course_wise(data_hash[:parameters][:start_date], data_hash[:parameters][:end_date])
      a = []
      batch_details.each do |x|
        a << x["course_id"]
      end
      a.uniq
      data << ["#{t('monthly_wallet_exepese_report_course_wise')}"]
      data << " "
      a.uniq.each do |course|
        data << ["#{t('course_name')}", "#{Course.find_by_id(course).course_name}"]
        data << ["#{t('sl_no')}", "#{t('batch_name')}", "#{t('amount')}"]
        i = 0
        batch_details.each do |batch|
          if batch["course_id"] == course
            data << ["#{i += 1}", "#{batch["batch_name"]}", "#{batch["amount"]}"]
          end
        end
      end
      return data
    end

    def wallet_credit_transactions_csv(data_hash)
      data = Array.new
      advance_fee_categories = AdvanceFeeCollection.fetch_wallet_credit_transaction_details(data_hash[:parameters][:start_date], data_hash[:parameters][:end_date], data_hash[:parameters][:fee_account_id])
      data << ["#{t('students_wallet_details_by_category')}"]
      data << " "
      data << ["#{t('from')}", "#{format_date(data_hash[:parameters][:start_date])}", "#{t('to')}", "#{format_date(data_hash[:parameters][:end_date])}"]
      data << " "
      data << ["#{t('sl_no')}", "#{t('advance_fee_categories_text')}", "#{t('amount')}"]
      i = 0
      total_amount = 0
      advance_fee_categories.each do |category|
        amount = category.amount.to_f
        total_amount += amount
        data << ["#{i += 1}","#{category.category_name}", "#{amount}"]
      end

      data << [" ", "#{t('net_income')}", "#{total_amount}"]
      return data
    end

    def wallet_expense_transactions_batch_wise_csv(data_hash)
      data = Array.new
      batch = Batch.find_by_id(data_hash[:parameters][:batch_id])
      student_fee_collections_by_batch = FinanceTransaction.fetch_batch_wise_expense_report_wallet(data_hash[:parameters][:batch_id], data_hash[:parameters][:start_date], data_hash[:parameters][:end_date], data_hash[:parameters][:page])
      data << ["#{t('monthly_wallet_exepese_report_batch_wise')}"]
      data << " "
      data << ["#{t('from')}", "#{format_date(data_hash[:parameters][:start_date])}", "#{t('to')}", "#{format_date(data_hash[:parameters][:end_date])}"]
      data << " "
      data << ["#{t('batch_name')}", "#{batch.name}"]
      data << " "
      i = 0
      data << ["#{t('sl_no')}", "#{t('student_name')}", "#{t('amount')}", "#{t('receipt_no')}", "#{t('transaction_date')}", "#{t('payment_mode')}", "#{t('payment_notes')}"]
      student_fee_collections_by_batch.each do |transaction|
        data << ["#{ i += 1 }", "#{AdvanceFeeCollection.fetch_student_name(transaction.student_id)}", "#{transaction.amount.to_f}", "#{transaction.receipt_no}", "#{format_date(transaction.transaction_date)}", "#{transaction.payment_mode}", "#{transaction.payment_note}"]
      end
      return data
    end

    def wallet_deduction_transaction_csv(data_hash)
      data = Array.new
      finance_transaction = FinanceTransaction.find_by_id(data_hash[:parameters][:transaction_id])
      student = Student.find_by_id(data_hash[:parameters][:student_id])
      data << ["#{t('wallet_expense_report')}"]
      data << " "
      data << ["#{t('student_details')}"]
      data << " "
      data << ["#{t('student_name')}", "#{student.full_name}"]
      data << ["#{t('addmission_no')}", "#{student.admission_no}"]
      data << ["#{t('batch_name')}", "#{student.batch.name}"]
      data << " "
      data << ["#{t('transaction_details')}"]
      data << " "
      data << ["#{t('receipt_no')}", "#{t('transaction_date')}", "#{t('payment_mode')}", "#{t('payment_notes')}", "#{t('amount')}"]
      data << ["#{finance_transaction.finance_transaction_receipt_record.transaction_receipt.ef_receipt_number}",
        "#{format_date(finance_transaction.transaction_date)}", "#{finance_transaction.payment_mode}", "#{finance_transaction.payment_note}", "#{finance_transaction.wallet_amount}"]
      return data
    end

    def employee_payslip_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "employee_payslip_data"
      data_hash[:parameters] = params
      if params[:department_id] == "All"
        department = EmployeeDepartment.ordered
        employees = Employee.find(:all)
        data_hash[:department_name] = t('all_departments')
      else
        department = EmployeeDepartment.find(params[:department_id])
        employees = Employee.find_all_by_employee_department_id(department.id)
        data_hash[:department_name] = department.name
      end
      data_hash[:salary_month] = Date.parse(params[:salary_date]).strftime("%B %Y")
      if params[:salary_date].present? and params[:department_id].present?
        payslips = MonthlyPayslip.find_and_filter_by_department(params[:salary_date], params[:department_id])
      end
      currency_type = Configuration.find_by_config_key("CurrencyType").config_value
      salary_date = params[:salary_date] if params[:salary_date]
      if payslips[:monthly_payslips].present? or payslips[:individual_payslip_category].present?
        grouped_monthly_payslips = payslips[:monthly_payslips] unless payslips[:monthly_payslips].blank?
        data_hash[:grouped_monthly_payslips] = grouped_monthly_payslips
        grouped_individual_payslip_categories = payslips[:individual_payslip_category] unless payslips[:individual_payslip_category].blank?
        data_hash[:grouped_individual_payslip_categories] = grouped_individual_payslip_categories
        find_report_type(data_hash)
      end
    end

    def student_wise_report(params)
      if params[:cat_id].to_i==0
        params.delete("cat_id")
      end
      data_hash ||= Hash.new
      if params[:cat_id].to_i==0
        params.delete("cat_id")
      end
      data_hash[:method] = "student_wise_report"
      student= (params[:type]=="former" ? ArchivedStudent.find_by_former_id(params[:id]) : Student.find(params[:id]))
      data_hash[:student] = student
      type= params[:type] || "regular"
      if params[:batch_id].present?
        @batch=Batch.find(params[:batch_id])
        student.batch_in_context_id = @batch.id
      else
        @batch=student.batch
      end
      data_hash[:batch] = @batch
      report=student.individual_cce_report_cached
      data_hash[:report] = report
      subjects=student.all_subjects
      data_hash[:subjects] = subjects
      #      exam_groups=ExamGroup.find_all_by_id(report.exam_group_ids, :include=>:cce_exam_category)
      exam_groups=@batch.exam_groups.all(:include => :cce_exam_category)
      data_hash[:exam_groups] = exam_groups
      coscholastic=report.coscholastic
      observation_group_ids=coscholastic.collect(&:observation_group_id)
      observation_groups=ObservationGroup.find_all_by_id(observation_group_ids).collect(&:name)
      co_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      obs_groups=@batch.observation_groups.to_a
      data_hash[:obs_groups] = obs_groups
      og=obs_groups.group_by(&:observation_kind)
      co_hashi = {}
      og.each do |kind, ogs|
        co_hashi[kind]=[]
        coscholastic.each { |cs| co_hashi[kind] << cs if ogs.collect(&:id).include? cs.observation_group_id }
      end
      data_hash[:co_hashi] = co_hashi
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def grouped_exam(params)
      params = params[:params] if params.key?(:params)
      data_hash ||= Hash.new
      data_hash[:parameters] = params
      data_hash[:method] = "grouped_exam"
      type = params[:type]
      data_hash[:type] = type
      batch = Batch.find(params[:batch])
      data_hash[:batch] = batch
      students = batch.students.find(:all, :order => "#{Student.sort_order}")
      data_hash[:students] = students
      if type == 'grouped'
        grouped_exams = GroupedExam.find_all_by_batch_id(batch.id)
        exam_groups = []
        grouped_exams.each do |x|
          exam_groups.push ExamGroup.find(x.exam_group_id, :include => :exams)
        end
      else
        exam_groups = ExamGroup.find_all_by_batch_id(batch.id)
        #exam_groups.reject! { |e| e.result_published==false }
      end
      data_hash[:exam_groups] = exam_groups
      if batch.gpa_enabled?
        data_hash[:grade_type] = "GPA"
      elsif batch.cwa_enabled?
        data_hash[:grade_type] = "CWA"
      else
        data_hash[:grade_type] = "normal"
      end
      find_report_type(data_hash)
    end

    def group_wise_employee_payslips_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "group_wise_employee_payslips"
      data_hash[:parameters] = params
      payslips_date_range = PayslipsDateRange.find_by_start_date_and_end_date_and_payroll_group_id(params[:start_date], params[:end_date], params[:id])
      payroll_group = PayrollGroup.find(params[:id])
      data_hash[:payslips_date_range] = payslips_date_range
      data_hash[:payroll_group] = payroll_group
      if payroll_group.current_revision == payslips_date_range.revision_number
        categories = payroll_group.payroll_categories
      else
        revision = payroll_group.payroll_group_revisions.find_by_revision_number(payslips_date_range.revision_number)
        categories = PayrollCategory.find(revision.categories)
      end
      data_hash[:earnings] = categories.select { |c| c.is_deduction == false }
      data_hash[:deductions] = categories.select { |c| c.is_deduction == true }
      where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
      payslips = EmployeePayslip.group_wise_payslips(params[:start_date], params[:end_date], params[:id], where_condition)
      data_hash[:approved] = payslips.select { |p| p.is_approved }.count
      data_hash[:pending] = payslips.select { |p| !p.is_approved and !p.is_rejected }.count
      data_hash[:rejected] = payslips.select { |p| p.is_rejected }.count
      data_hash[:payslips] = payslips
      data_hash[:total_cost] = payslips.select { |p| !p.is_rejected }.map { |p| p.net_pay.to_f }.sum
      data_hash[:is_lop] = payslips.collect(&:lop).compact.present?
      if params[:employees].nil? or params[:employees] == 'all'
        data_hash[:payslips_list] = payslips.send((params[:status]||"approved_and_pending")+"_payslips").updated_structure_payslips.load_payslips_categories
      else
        data_hash[:payslips_list] = payslips.send((params[:status]||"approved_and_pending")+"_payslips").updated_structure_payslips.send(params[:employees]).load_payslips_categories
      end
      find_report_type(data_hash)
    end

    private

    def find_report_type(h)
      case h[:parameters][:report_format_type]
      when "csv"
        send("#{h[:method]}_csv", h)
      when "pdf"
        return h
      end
    end

    def generate_advance_cancelled_transactions_csv(data_hash)
      csv_string=FasterCSV.generate do |csv|
        cols=[]
        cols << "Cancelled Transactions"
        csv << cols
        cols = []
        cols << t('sl_no')
        unless data_hash[:transaction_type] == t('payslips')
          cols << t('payee_name')
          cols << t('receipt_no')
        else
          cols << t('employee_name')
        end
        cols << t('amount')
        cols << t('cancelled_by')
        cols << t('reason')
        cols << t('date_text')
        if (data_hash[:transaction_type].nil? or data_hash[:transaction_type] == "" or
              data_hash[:transaction_type]==t('fees_text'))
          cols << t('fee_collection_name')
        end
        unless data_hash[:transaction_type] == t('payslips')
          cols << t('finance_type')
        end
        csv << cols
        cols = []
        i=0
        data_hash[:transactions].each do |f|
          cols << (i +=1)
          cols << f.payee_name_for_csv
          unless data_hash[:transaction_type] == t('payslips')
            cols << f.receipt_number
          end
          cols << (precision_label(f.amount))
          cols << (f.user.present? ? f.user.full_name : t('user_deleted'))
          cols << (f.cancel_reason.present? ? f.cancel_reason : "-")
          cols << (format_date(f.created_at, :format => :short_date))
          if (data_hash[:transaction_type].nil? or data_hash[:transaction_type] == "" or
                data_hash[:transaction_type]==t('fees_text'))
            cols << f.collection_name
          end
          unless data_hash[:transaction_type] == t('payslips')
            cols << f.finance_type.underscore.humanize()
          end
          csv << cols
          cols =[]
        end
      end
      return csv_string
    end

    def student_advanced_search_csv(data_hash)
      data ||= Array.new
      data << ["#{t('students')} #{t('listed_by')} "+"#{ }"+data_hash[:searched_for].downcase]
      temp = ["#{t('name')}", "#{t('batch')}", "#{t('adm_no')}"]
      temp.push("#{t('roll_no')}") if Configuration.enabled_roll_number?
      if (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:dob_option].present?)))
        temp.push("#{t('admission_date')}")
      elsif (((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
        temp.push("#{t('date_of_birth')}")
      elsif (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
        temp.push("#{t('admission_date')}")
        temp.push("#{t('date_of_birth')}")
      end
      temp.push("#{t('leaving_date')}") if data_hash[:parameters][:search][:is_active_equals]=="false"
      data << temp
      data_hash[:students].each do |row|
        temp = [row.full_name.to_s, row.batch.full_name.to_s, row.admission_no.to_s]
        temp.push(row.roll_number) if Configuration.enabled_roll_number?
        if (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push(format_date(row.admission_date))
        elsif (((!data_hash[:parameters].present?) or (!data_hash[:parameters][:advv_search].present?) or (!data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push(format_date(row.date_of_birth))
        elsif (((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:doa_option].present?)) and ((data_hash[:parameters].present?) and (data_hash[:parameters][:advv_search].present?) and (data_hash[:parameters][:advv_search][:dob_option].present?)))
          temp.push(format_date(row.admission_date))
          temp.push(format_date(row.date_of_birth))
        end
        temp.push(format_date(row.date_of_leaving, :format => :short)) if data_hash[:parameters][:search][:is_active_equals]=="false"
        data << temp
      end
      return data
    end

    def consolidated_attendance_report_csv(data_hash)
      data ||= Array.new
      data << ["#{Configuration.get_config_value("InstitutionName")}"]
      data << ["#{t('course_name')}:  #{data_hash[:course]}"]
      data << ["#{t('batch_name')}: #{data_hash[:batch]}"]
      data << ["#{t('start_date')}: #{data_hash[:parameters][:start_date]}"]
      data << ["#{t('end_date')}: #{data_hash[:parameters][:end_date]}"]
      data << ["#{t('total_students')}: #{data_hash[:total_students]}"]
      row=[]
      row << t('sl_no')
      row << t('admission_no')
      row <<  t('student_name')
      data_hash[:sub].each do |s|
        if data_hash[:parameters][:type]==("Both")
          row << s.code + "(" + t('classes') + "-" + (data_hash[:subject_wise_leave][s.id]['academic_days']).to_s  + ")"
          row << s.code + "(" + "%" + ")"
        elsif data_hash[:parameters][:type]==("Classes")
          row << s.code + "(" +t('classes') + "-" + (data_hash[:subject_wise_leave][s.id]['academic_days']).to_s + ")"
        else
          row << s.code
        end
      end
      data << row
      data_hash[:students].each_with_index do |stu,index|
        temp = [index+1,stu.admission_no,stu.full_name]
        data_hash[:sub].each do |s|
          if data_hash[:parameters][:type]=="Both"
            temp << data_hash[:subject_wise_leave][s.id][stu.id]['total'].to_s
            if data_hash[:subject_wise_leave][s.id][stu.id]['percent']==nil
              temp<< "0.00"
            elsif data_hash[:subject_wise_leave][s.id][stu.id]['percent']=='-'
              temp<< "-"
            else
              temp << data_hash[:subject_wise_leave][s.id][stu.id]['percent'].round(2).to_s
            end
          elsif data_hash[:parameters][:type]=="Percentage"
            if data_hash[:subject_wise_leave][s.id][stu.id]['percent']==nil
              temp<< "0.00"
            elsif data_hash[:subject_wise_leave][s.id][stu.id]['percent']=='-'
              temp<< "-"
            else
              temp << data_hash[:subject_wise_leave][s.id][stu.id]['percent'].round(2).to_s
            end
          else
            temp << data_hash[:subject_wise_leave][s.id][stu.id]['total'].to_s
          end
        end
        data << temp
      end
      return data
    end

    def attendance_register_data_csv(data_hash)
      data ||=Array.new
      school_name =  Configuration.get_config_value('InstitutionName')
      school_address =  Configuration.get_config_value('InstitutionAddress')
      data << ["#{school_name}"]
      data << ["#{school_address}"]
      data << []
      data << ["#{t('attendance_register')} : #{format_date(data_hash[:dates].first.to_date,:format=>:month_year)}"]
      data << ["#{t('batch')} : #{data_hash[:batch].full_name}"]
      data << ["#{t('student_count')} : #{data_hash[:batch].students.active.count}"]
      if data_hash[:config] == 'Daily'
        data_hash[:attendance_status] = data_hash[:attendance_status]['marked'].to_a.reject{|date|  data_hash[:saved_dates].include?(date) } if data_hash[:attendance_lock]
        data << ["#{t('attendance_type')} : " + data_hash[:config]]
        data << ["#{t('total_no_of_wrkng_days')} = " + data_hash[:academic_days].to_s ]
      else
        if data_hash[:subject].nil?
          data << [ "#{t('subject')} : " + "#{t('all_subjects')}" ]
        else
          data << ["#{t('subject')} : " + data_hash[:subject].name ]
        end
        data << ["#{t('total_no_of_wrkng_hours')} = " + data_hash[:academic_days].to_s ]
      end
      temp = []
      temp << ' '
      current_day = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
      if data_hash[:config] =='Daily'
        data_hash[:dates].each do |date|
          temp << "#{format_date(date,:format=>:short_day)}"
        end
      else
        data_hash[:dates_key].each do |attendance_entry|
          if attendance_entry[1].present?
            attendance_entry[1].each do |entry|
              temp << format_date(attendance_entry[0],:format=>:short_day)
            end
          end
        end
      end
      data << temp
      temp = []
      temp << t('name')
      if data_hash[:config] =='Daily'
        data_hash[:dates].each do |date|
          temp <<   format_date(date,:format=>:day)
        end
      else
        data_hash[:dates_key].each do |attendance_entry|
          if attendance_entry[1].present?
            attendance_entry[1].each do |entry|
              temp <<   format_date(attendance_entry[0],:format=>:day)
            end
          end
        end
      end
      data << temp
      data_hash[:students].each do |student|
        temp = []
        temp << student.name_with_roll_number
        if data_hash[:config] == 'Daily'
          data_hash[:dates].each do |date|
            data_hash[:absent] = Attendance.get_absent(student.id, date, student.batch_id)
            unless data_hash[:absent].nil?
              if data_hash[:enable] == '1'
                if data_hash[:absent].attendance_label.nil?
                  temp << data_hash[:val_code]
                else
                  temp << data_hash[:absent].attendance_label.code
                end
              else
                if data_hash[:absent].to_a.select{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.present?
                  if data_hash[:attendance_lock] and data_hash[:saved_dates].include?(date)
                    if student.admission_date <= date
                      temp << 'P'
                    else
                      temp << ' '
                    end
                  else
                    temp << ' '
                  end
                else
                  temp << 'X'
                end
              end
            else
              if data_hash[:holidays].include?(date)
                temp << t('holiday_off')
              else
                if data_hash[:attendance_lock] and data_hash[:saved_dates].include?(date)
                  if student.admission_date <= date
                    temp << 'P'
                  else
                    temp << ' '
                  end
                else
                  temp << ' '
                end
              end
            end
            if data_hash[:attendance_lock] && (data_hash[:attendance_status].include?(date))
              temp.pop 
              temp << ' ' 
            end
          end
        else
          data_hash[:dates_key].each do |attendance_entry|
            if attendance_entry[1].present?
              attendance_entry[1].each do |entry|
                if data_hash[:absents][student.id].present?
                  att_entry = data_hash[:absents][student.id].select{|s| s.month_date.to_date == attendance_entry[0]  and s.class_timing_id == entry.class_timing_id}
                  if att_entry.present?
                    if data_hash[:enable] == '1'
                      if att_entry.first.attendance_label.nil?
                        temp << data_hash[:val_code]
                      else
                        temp << att_entry.first.attendance_label.code
                      end
                    else
                      temp << 'X'
                    end
                  else
                    if data_hash[:attendance_lock] and data_hash[:saved_dates][entry.class_timing_id].present? and data_hash[:saved_dates][entry.class_timing_id].include?(attendance_entry[0])
                      if student.admission_date <= attendance_entry[0]
                        temp << 'P'
                      else
                        temp << ' '
                      end
                    else
                      temp << ' '
                    end
                  end
                else
                  if data_hash[:attendance_lock] and data_hash[:saved_dates][entry.class_timing_id].present? and data_hash[:saved_dates][entry.class_timing_id].include?(attendance_entry[0])
                    if student.admission_date <= attendance_entry[0]
                      temp << 'P'
                    else
                      temp << ' '
                    end
                  else
                    temp << ' '
                  end
                end
                if data_hash[:attendance_lock] && (data_hash[:attendance_status][attendance_entry[0]].include?(entry.class_timing_id)) && (!data_hash[:saved_dates][entry.class_timing_id].present? || (data_hash[:saved_dates][entry.class_timing_id].present? && !data_hash[:saved_dates][entry.class_timing_id].include?(attendance_entry[0])))
                  temp.pop
                  temp << ' '
                end
              end
            end
          end
        end
        data << temp
      end
      data << ' '
      temp = []
      temp << ["#{t('absentee_no')} : "]
      if data_hash[:total_absentees].present?
        if data_hash[:config] == 'Daily'
          data_hash[:dates].each do |date|
            if data_hash[:total_absentees].keys.select{|k| k.to_date == date}.present?
              val_count = data_hash[:total_absentees].keys.select{|k| k.to_date == date}
              temp << data_hash[:total_absentees]["#{val_count}"]
            else
              temp << ' '
            end
            if data_hash[:attendance_lock] && (data_hash[:attendance_status].include?(date))
              temp.pop
              temp << ' '
            end
          end
        else
          data_hash[:dates_key].each do |attendance_entry|
            val_count = data_hash[:total_absentees].keys.select{|k| k.to_date == attendance_entry[0]}
            if val_count.present?
              if attendance_entry[1].present?
                attendance_entry[1].each do |entry|
                  count_hash = data_hash[:total_absentees]["#{attendance_entry[0]}"]
                  lc = count_hash.keys.select{|key| key == entry.class_timing_id}
                  if lc.present?
                    temp << count_hash["#{lc}".to_i]
                    if data_hash[:attendance_lock] && (data_hash[:attendance_status][attendance_entry[0]].include?(entry.class_timing_id)) && (!data_hash[:saved_dates][entry.class_timing_id].present? || (data_hash[:saved_dates][entry.class_timing_id].present? && !data_hash[:saved_dates][entry.class_timing_id].include?(attendance_entry[0])))
                      temp.pop
                      temp << ' '
                    end
                  else
                    temp << ' '
                  end
                end
              end
            else
              if attendance_entry[1].present?
                attendance_entry[1].each do |entry|
                  temp << ' '
                end
              end
            end
           
          end
        end
        data << temp
      end

      data << []
      data << []
      data << ["#{t('generated_by')} #{data_hash[:current_user]} on #{format_date(Date.today)} at #{Time.now.strftime("%I:%M%p")} "]
      return data

    end

    def student_attendance_report_csv(data_hash)
      data ||= Array.new
      data << ["#{t('course_text')} : #{data_hash[:course]}"]
      data << ["#{t('batch')} : #{data_hash[:batch]}"]
      if data_hash[:parameters][:report_type] == 'Monthly'
        data << ["#{t('date_range')} : #{data_hash[:parameters][:start_date].to_date.strftime('%B %Y')}"]
      elsif data_hash[:parameters][:report_type] == 'Overall'
        data << ["#{t('date_range')} : #{data_hash[:parameters][:report_type]}"]
      elsif data_hash[:parameters][:report_type] == 'custom'
        data << ["#{t('date_range')} : #{format_date(data_hash[:parameters][:start_date].to_date,:format=>:month_year)} - #{format_date(data_hash[:parameters][:end_date].to_date,:format=>:month_year)}"]
      end
      if data_hash[:config] == 'Daily'
        data << "#{t('total_no_of_wrkng_days')} = " + data_hash[:academic_days].to_s
      else
        if data_hash[:subject].nil?
          data << "#{t('subject')} : " + "#{t('all_subjects')}"
        else
          data << "#{t('total_no_of_wrkng_hours')} = " + data_hash[:academic_days].to_s
          data << "#{t('subject')} : " + data_hash[:subject].name
        end
      end
      if data_hash[:range].present? and data_hash[:value].present?
        data << "#{t('filtered')}: "+ "#{t(data_hash[:range].to_s.downcase)}" + " " + data_hash[:value].to_s + "%"
      end

      temp = [t('name'), t('adm_no'), t('total'), t('percentage')+"(%)"]
      if data_hash[:selected_columns].present?
        data_hash[:selected_columns].each_with_index do | column, i|
          temp.insert(2+i, t(column))
        end
        count_column_no = data_hash[:selected_columns].count
      end
      if  data_hash[:config_enable] == '1'
        if count_column_no.present?
          temp.insert(count_column_no+2, t('present'))
          temp.insert(count_column_no+3, t('late'))
          temp.insert(count_column_no+4, t('absent'))
        else
          temp.insert(2, t('present'))
          temp.insert(3, t('late'))
          temp.insert(4, t('absent'))
        end
      end
      data << temp
      data_hash[:leaves].each_pair do |student_id, attendance_data|
        student = data_hash[:students].select {|x| x.id == student_id }.last
        total_academic_days_count = attendance_data['total_academic_days']
        if total_academic_days_count.present?
          count_academic_days = total_academic_days_count > 0 ? total_academic_days_count == 0 ? '-' : "#{attendance_data['total']} / #{attendance_data['total_academic_days']}" : "-"
          percentage_academic_days = total_academic_days_count > 0 ? attendance_data['percent'] : "-"
        end
        temp = [student.full_name, student.admission_no, count_academic_days, percentage_academic_days]
        if data_hash[:selected_columns].present?
          data_hash[:selected_columns].each_with_index do | column, i|
            temp.insert(2+i, student.send(column.to_sym))
          end
          count_column_no = data_hash[:selected_columns].count
        end

        if  data_hash[:config_enable] == '1'
          if count_column_no.present?
            temp.insert(count_column_no+2, data_hash[:present][student.id]['present'])
            if data_hash[:late][student.id].present?
              temp.insert((count_column_no)+3, data_hash[:late][student.id].count)
            else
              temp.insert(count_column_no+3, '0')
            end
            temp.insert(count_column_no+4, data_hash[:absent][student.id]['absent'])
          else
            temp.insert(2, data_hash[:present][student.id]['present'])
            if data_hash[:late][student.id].present?
              temp.insert(3, data_hash[:late][student.id].count)
            else
              temp.insert(3, '0')
            end
            if data_hash[:absent][student.id]['absent'].present?
              temp.insert(4, data_hash[:absent][student.id]['absent'])
            else

              temp.insert(4, '0')
            end
          end
        end
        data << temp
      end
      return data
    end

    def day_wise_report_csv(data_hash)
      custom_attendance = Configuration.get_config_value('CustomAttendanceType') || "0"
      attendance_label = AttendanceLabel.find(data_hash[:parameters][:attendance_label_id].to_i) if data_hash[:parameters][:attendance_label_id].present?
      enabled_roll_number = Configuration.enabled_roll_number?
      data ||= Array.new
      summary_temp = [t('summary')]
      @total_students = 0
      @present_students = 0
      @total_late_students = 0
      @total_absent_students = 0
      data << ["#{t('date_text')} : #{format_date(data_hash[:date])}"]
      if attendance_label.present? and attendance_label.attendance_type == 'Late'
        data << [t('courses_text'), t('batches_text'), t('total'),t('late'), t('late_students')]
        data_hash[:report].each do |course, batches|
          batches.each do |batch|
            @total_students += batch.students.count
            if data_hash[:late][batch.id].present?
              late= data_hash[:late][batch.id].count
              late_students = Array.new
              data_hash[:late][batch.id].each do |att|
                student = att.student_name
                student = "#{student}" + "-" +"#{att.roll_no}" if  att.roll_no.present? and enabled_roll_number
                late_students << student
              end
            else
              late =0
              late_students = ['-']
            end
            if data_hash[:absent][batch.id].present?
              @total_absent_students += data_hash[:absent][batch.id].count
            end
            @total_late_students += late_students.reject{|a| a == '-'}.count
            if batch.working_days(data_hash[:date].to_date).include?(data_hash[:date].to_date)
              saved_attendance = MarkedAttendanceRecord.day_wise_working_days(batch,data_hash[:date].to_date)
              if data_hash[:attendance_lock]
                if saved_attendance.present?
                  student_count = batch.students.count
                else
                  @total_students -= batch.students.count
                  student_count = t('not_marked')
                end
              else
                student_count = batch.students.count
              end
            else
              student_count = t('holiday')
            end
            data << [course, batch.name, student_count,  late, late_students.reject{|a| a == '-'}.join(",")]
          end
        end
        all_summary_temp = [t('total'), t('present'), t('late')]
        data << summary_temp
        data <<  all_summary_temp
        data << [@total_students,(@total_students - @total_late_students) - @total_absent_students , @total_late_students]
      elsif attendance_label.present? and attendance_label.attendance_type == 'Absent'
        data << [t('courses_text'), t('batches_text'), t('total'),t('absent'), t('absent_students')]
        data_hash[:report].each do |course, batches|
          batches.each do |batch|
            @total_students += batch.students.count
            if data_hash[:absent][batch.id].present?
              absent = data_hash[:absent][batch.id].count
              absent_students = Array.new
              data_hash[:absent][batch.id].each do |att|
                student = att.student_name
                student = "#{student}" + "-" +"#{att.roll_no}" if att.roll_no.present? and  enabled_roll_number
                absent_students << student
              end
            else
              absent= 0
              absent_students = ['-']
            end
            if data_hash[:late][batch.id].present?
              @total_late_students += data_hash[:late][batch.id].count
            end
            @total_absent_students += absent_students.reject{|a| a == '-'}.count
            if batch.working_days(data_hash[:date].to_date).include?(data_hash[:date].to_date)
              saved_attendance = MarkedAttendanceRecord.day_wise_working_days(batch,data_hash[:date].to_date)
              if data_hash[:attendance_lock]
                if saved_attendance.present?
                  student_count = batch.students.count
                else
                  @total_students -= batch.students.count
                  student_count = t('not_marked')
                end
              else
                student_count = batch.students.count
              end
            else
              student_count = t('holiday')
            end
            
            data << [course, batch.name,student_count, absent, absent_students.reject{|a| a == '-'}.join(",")]
          end
        end
        all_summary_temp = [t('total'), t('present'),t('absent')]
        data << summary_temp
        data <<  all_summary_temp
        data << [@total_students,(@total_students - @total_late_students) - @total_absent_students , @total_absent_students]
      else
        temp = [t('courses_text'), t('batches_text'), t('total'),t('absent'), t('absent_students')]
        if custom_attendance == '1'
          temp.insert(3, t('late'))
          temp.insert(4, t('late_students'))
        end
        summary_temp = [t('summary')]
        all_summary_temp = [t('total'), t('present'),t('absent')]
        all_summary_temp.insert(2, t('late'))  if custom_attendance == '1'
        data << temp
        data_hash[:report].each do |course, batches|
          batches.each do |batch|
            @total_students += batch.students.count
            if data_hash[:late][batch.id].present?
              late= data_hash[:late][batch.id].count
              late_students = Array.new
              data_hash[:late][batch.id].each do |att|
                student = att.student_name
                student = "#{student}" + "-" +"#{att.roll_no}" if att.roll_no.present? and  enabled_roll_number
                late_students << student
              end
            else
              late =0
              late_students = ['-']
            end
            @total_late_students += late_students.reject{|a| a == '-'}.count
            if data_hash[:absent][batch.id].present?
              absent = data_hash[:absent][batch.id].count
              absent_students = Array.new
              data_hash[:absent][batch.id].each do |att|
                student = att.student_name
                student = "#{student}" + "-" +"#{att.roll_no}" if att.roll_no.present? and enabled_roll_number
                absent_students << student
              end
            else
              absent= 0
              absent_students = ['-']
            end
            @total_absent_students += absent_students.reject{|a| a == '-'}.count
            if batch.working_days(data_hash[:date].to_date).include?(data_hash[:date].to_date)
              saved_attendance = MarkedAttendanceRecord.day_wise_working_days(batch,data_hash[:date].to_date)
              if data_hash[:attendance_lock]
                if saved_attendance.present?
                  student_count = batch.students.count
                else
                  @total_students -= batch.students.count
                  student_count = t('not_marked')
                end
              else
                student_count = batch.students.count
              end
            else
              student_count = t('holiday')
            end
            temp = [course, batch.name, student_count,  absent, absent_students.reject{|a| a == '-'}.join(",")]
            if custom_attendance == '1'
              temp.insert(3, late)
              temp.insert(4, late_students.reject{|a| a == '-'}.join(","))
            end
            data << temp
          end
        end
        data << summary_temp
        data <<  all_summary_temp
        if custom_attendance == '1'
          data << [@total_students, (@total_students-@total_late_students)-@total_absent_students , @total_late_students, @total_absent_students]
        else
          data << [@total_students, (@total_students-@total_absent_students) , @total_absent_students]
        end
      end

      return data
    end

    def student_ranking_per_subject_csv(data_hash)
      data ||= Array.new
      data << ["#{t('subjects_rankings')} - #{data_hash[:subject].name}"]
      data << ["#{data_hash[:batch_name]} - #{data_hash[:course]}"]
      header = ["#{t('name')}", "#{t('adm_no')}"]
      header.insert(2, "#{t('roll_no')}") if Configuration.enabled_roll_number?
      data_hash[:exam_groups].each do |exam_group|
        header << exam_group.name
      end
      data << header
      data_hash[:students].each_with_index do |student, i|
        row = [student.full_name]
        student.admission_no.present? ? row << student.admission_no : row << "-"
        (student.roll_number.present? ? row << student.roll_number : row << "--") if Configuration.enabled_roll_number?
        data_hash[:exam_groups].each do |exam_group|
          mark_list = []
          data_hash[:ranks].each do |rank|
            if rank[0]==exam_group.id
              mark_list = rank[1]
            end
          end
          exam = Exam.find_by_subject_id(data_hash[:subject].id, :conditions => {:exam_group_id => exam_group.id}, :include => :exam_scores)
          exam_score = exam.exam_scores.select { |x| x.student_id == student.id and x.exam_id == exam.id } unless exam.nil?
          unless exam.nil?
            exam_score.empty? ? row << '-' : row << (exam_score[0].marks.nil? ? '-' : (mark_list.index(exam_score[0].marks) + 1))
          else
            row << "#{t('n_a')}"
          end
        end
        data << row
      end
      return data
    end

    def student_ranking_per_batch_csv(data_hash)
      data = Array.new
      data << ["#{t('overall_batch_rankings')} : #{data_hash[:batch]} - #{data_hash[:course]}"]
      temp = ["#{t('name')}", "#{t('adm_no')}", "#{t('marks')}", "#{t('rank')}"]
      temp.insert(2, "#{t('roll_no')}") if Configuration.enabled_roll_number?
      data << temp
      data_hash[:ranked_students].each_with_index do |student, ind|
        row = ["#{student[3].full_name}"]
        student[3].admission_no.present? ? row << student[3].admission_no : row << "--"
        (student[3].roll_number.present? ? row << student[3].roll_number : row << "--") if Configuration.enabled_roll_number?
        row << student[1]
        row << student[0]
        data << row
      end
      return data
    end

    def student_ranking_per_course_csv(data_hash)
      data = Array.new
      data << "#{t('overall_rankings')}" + ":" + (data_hash[:batch_group].present? ? "#{data_hash[:batch_group].name}" : "#{data_hash[:course].full_name}")
      temp = ["#{t('name')}", "#{t('batch')}", "#{t('adm_no')}", "#{t('marks')}", "#{t('rank')}"]
      temp.insert(3, t('roll_no')) if Configuration.enabled_roll_number?
      data << temp
      data_hash[:ranked_students].each_with_index do |student, i|
        row = []
        if data_hash[:sort_order]=="" or data_hash[:sort_order]=="rank-ascend" or data_hash[:sort_order]=="rank-descend"
          row << student[3].full_name
          row << student[3].batch.full_name
          student[3].admission_no.present? ? row << student[3].admission_no : row << "--"
          (student[3].roll_number.present? ? row << student[3].roll_number : row << "--") if Configuration.enabled_roll_number?
          row << student[1]
          row << student[0]
        else
          row << student[4].full_name
          row << student[4].batch.full_name
          student[4].admission_no.present? ? row << student[4].admission_no : row << "--"
          (student[4].roll_number.present? ? row << student[4].roll_number : row << "--") if Configuration.enabled_roll_number?
          row << student[2]
          row << student[1]
        end
        data << row
      end
      return data
    end

    def student_ranking_per_school_csv(data_hash)
      data = Array.new
      data << ["#{t('overall_school_rankings')} : #{Configuration.find_by_config_key("InstitutionName").config_value.present? ? Configuration.find_by_config_key("InstitutionName").config_value : "-"}"]
      temp = ["#{t('name')}", "#{t('batch')}", "#{t('adm_no')}", "#{t('marks')}", "#{t('rank')}"]
      temp.insert(3, t('roll_no')) if Configuration.enabled_roll_number?
      data << temp
      index = 0; total = 0; i = 0
      data_hash[:ranked_students].each_with_index do |student, i|
        row = []
        if data_hash[:sort_order] =="" or data_hash[:sort_order] =="rank-ascend" or data_hash[:sort_order]=="rank-descend"
          row << student[3].full_name
          row << student[3].batch.full_name
          student[3].admission_no.present? ? row << student[3].admission_no : row << "--"
          (student[3].roll_number.present? ? row << student[3].roll_number : row << "--") if Configuration.enabled_roll_number?
          row << student[1]
          row << student[0]
        else
          row << student[4].full_name
          row << student[4].batch.full_name
          student[4].admission_no.present? ? row << student[4].admission_no : row << "--"
          (student[4].roll_number.present? ? row << student[4].roll_number : row << "--") if Configuration.enabled_roll_number?
          row << student[2]
          row << student[1]
        end
        data << row
      end
      return data
    end

    def student_ranking_per_attendance_csv(data_hash)
      data = Array.new
      data << ["#{t('overall_ranking_per_attendance')} : #{data_hash[:batch].name} - #{data_hash[:batch].course.full_name} | #{format_date(data_hash[:start_date])} - #{format_date(data_hash[:end_date])}"]
      temp = ["#{t('name')}", "#{t('adm_no')}", "#{t('working_days')}", "#{t('attended')}", "#{t('percentage')}", "#{t('rank')}"]
      temp.insert(2, t('roll_no')) if Configuration.enabled_roll_number?
      data << temp
      unless data_hash[:students].empty?
        working_days = data_hash[:batch].find_working_days(data_hash[:start_date], data_hash[:end_date]).count
        unless working_days == 0
          data_hash[:ranked_students].each_with_index do |student, ind|
            row = ["#{student[5].full_name}"]
            student[5].admission_no.present? ? row << student[5].admission_no : row << "--"
            (student[5].roll_number.present? ? row << student[5].roll_number : row << "--") if Configuration.enabled_roll_number?
            row << student[3]
            if student[6] == 0
              row << "-"
              row << "-"
              row << "-"
            else
              row << "#{student[4]} / #{student[6]}"
              row << student[1]
              row << student[0]
            end
            data << row
          end
        end
      end
      return data
    end

    def employee_advance_search_csv(data_hash)
      data = Array.new
      data << ["#{t('employee_search_report')}"]
      data << ["#{t('employee_text')} "+ (data_hash[:searched_for].camelcase unless data_hash[:searched_for].nil?)]
      data << ["#{t('name')}", "#{t('department')}", "#{t('employee_number')}", "#{t('joining_date')}", (("#{t('leaving_date')}") if data_hash[:parameters][:status]=='false')]
      data_hash[:employees].each_with_index do |employee1, i|
        row = [employee1.full_name, employee1.employee_department.name, employee1.employee_number, format_date(employee1.joining_date)]
        row << format_date(employee1.updated_at, :format => :short_date) if data_hash[:parameters][:status]=='false'
        data << row
      end
      return data
    end

    def employee_attendance_data_csv(data_hash)
      data = Array.new

      start_date = data_hash[:start_date]
      end_date = data_hash[:end_date]

      if start_date && end_date
        data << [t('from'), start_date.to_date]
        data << [t('to'), end_date.to_date]
      end

      row = ["", t('leave_summary'), "", ""]
      data_hash[:leave_types].each do |lt|
        row << "#{lt.name} ( #{lt.code} )"
        row << ""
        row << ""
      end
      data << row
      data << []
      row = [t('name'), t('total_leaves'), t('additional_leaves'), t('lop')]
      row.insert(1, t('recent_leave_reset')) if data_hash[:from] == "reportees_leaves"
      data_hash[:leave_types].each do |lt|
        row << t('total_leaves')
        row << t('additional_leaves')
        row << t('lop')
      end
      data << row

      data_hash[:employees].each do |dpt, emp|
        data << dpt
        emp.each do |e|
          row = ["#{e.full_name} ( #{e.employee_number} )"]
          row << "#{format_date(e.last_reset_date, :format => :short)}" if data_hash[:from] == "reportees_leaves"

          conditions = ""
          if start_date && end_date
            conditions += (" && " if conditions.present?).to_s + "ea.attendance_date.to_date <= end_date.to_date && ea.attendance_date.to_date >= start_date.to_date"
          else
            conditions += (" && " if conditions.present?).to_s + "ea.attendance_date.to_date >= e.last_reset_date.to_date"
          end

          row << e.employee_attendances.collect { |ea| (ea.is_half_day ? 0.5 : 1) if eval(conditions) }.compact.sum


          conditions = ""
          if data_hash[:start_date] && data_hash[:end_date]
            conditions += ((" && " if conditions.present?).to_s + "al.attendance_date.to_date <= end_date.to_date && al.attendance_date.to_date >= start_date.to_date")
          else
            conditions += ((" && " if conditions.present?).to_s + "al.attendance_date.to_date >= e.last_reset_date.to_date")
          end

          row << e.employee_additional_leaves.collect { |al| (al.is_half_day ? 0.5 : 1) if eval(conditions) }.compact.sum
          conditions = "al.is_deductable"
          if data_hash[:start_date] && data_hash[:end_date]
            conditions += " && " + "al.attendance_date.to_date <= end_date.to_date && al.attendance_date.to_date >= start_date.to_date"
          else
            conditions += " && " + "al.attendance_date.to_date >= e.last_reset_date.to_date"
          end


          row << e.employee_additional_leaves.collect { |al| (al.is_half_day ? 0.5 : 1) if eval(conditions) }.compact.sum
          data_hash[:leave_types].each do |lt|

            conditions = "ea.employee_leave_type_id == lt.id"
            if data_hash[:start_date] && data_hash[:end_date]
              conditions += (" && " if conditions.present?).to_s + "ea.attendance_date.to_date <= end_date.to_date && ea.attendance_date.to_date >= start_date.to_date"
            else
              conditions += (" && " if conditions.present?).to_s + "ea.attendance_date.to_date >= e.last_reset_date.to_date"
            end

            row << e.employee_attendances.collect { |ea| (ea.is_half_day ? 0.5 : 1) if eval(conditions) }.compact.sum

            conditions = "al.employee_leave_type_id == lt.id"
            if data_hash[:start_date] && data_hash[:end_date]
              conditions += ((" && " if conditions.present?).to_s + "al.attendance_date.to_date <= end_date.to_date && al.attendance_date.to_date >= start_date.to_date")
            else
              conditions += ((" && " if conditions.present?).to_s + "al.attendance_date.to_date >= e.last_reset_date.to_date")
            end
            row << e.employee_additional_leaves.collect { |al| (al.is_half_day ? 0.5 : 1) if eval(conditions) }.compact.sum

            conditions = "al.is_deductable && al.employee_leave_type_id == lt.id"
            if data_hash[:start_date] && data_hash[:end_date]
              conditions += " && " + "al.attendance_date.to_date <= end_date.to_date && al.attendance_date.to_date >= start_date.to_date"
            else
              conditions += " && " + "al.attendance_date.to_date >= e.last_reset_date.to_date"
            end

            row << e.employee_additional_leaves.collect { |al| (al.is_half_day ? 0.5 : 1) if eval(conditions) }.compact.sum


          end
          data << row
        end
      end
      return data
    end

    def subject_wise_data_csv(data_hash)
      data ||= Array.new
      data << [data_hash[:subject].name]
      data << ["#{data_hash[:batch].name} -  #{data_hash[:batch].course.full_name}"]
      row = ["#{t('name')}", "#{t('admission_no')}"]
      row << "#{t('roll_no')}" if Configuration.enabled_roll_number?
      i = 0
      data_hash[:exam_groups].each do |exam_group|
        row << exam_group.name
      end
      data << row
      data_hash[:students].each do |student|
        is_valid_subject = 1
        unless data_hash[:subject].elective_group_id.nil?
          is_student_elective = StudentsSubject.find_by_student_id_and_subject_id(student.id, data_hash[:subject].id)
          is_valid_subject = 0 if is_student_elective.nil?
        end
        unless is_valid_subject == 0
          row = [student.full_name, student.admission_no]
          row << (student.roll_number.present? ? student.roll_number : '--') if Configuration.enabled_roll_number?
          data_hash[:exam_groups].each do |exam_group|
            exam = Exam.find_by_subject_id(data_hash[:subject].id, :conditions => {:exam_group_id => exam_group.id})
            exam_score = ExamScore.find_by_student_id(student.id, :conditions => {:exam_id => exam.id}) unless exam.nil?
            unless exam.nil?
              if exam_group.exam_type == 'Marks'
                exam_score.nil? ? row << "--" : row << "#{exam_score.marks || "-"}/"+exam.maximum_marks.to_s
              elsif exam_group.exam_type == 'Grades'
                exam_score.nil? ? row << "--" : row << (exam_score.grading_level || '-')
              else
                exam_score.nil? ? row << "--" : row << "#{(exam_score.marks || "-")}" +"/"+exam.maximum_marks.to_s+"[#{(exam_score.grading_level || "-")}]"
              end
            else
              row << "N.A"
            end
          end
          i+=1
          data << row
        end
      end
      row = ["#{t('class_average')}", ""]
      data_hash[:exam_groups].each do |exam_group|
        if exam_group.exam_type == 'Marks' or exam_group.exam_type == 'MarksAndGrades'
          exam = Exam.find_by_subject_id(data_hash[:subject].id, :conditions => {:exam_group_id => exam_group.id})
          if exam.nil?
            row << "--"
          else
            row << ("%.2f"%exam_group.subject_wise_batch_average_marks(data_hash[:subject].id)).to_s unless exam.nil?
          end
        else
          row << "--"
        end
      end
      data << row
      return data
    end

    def consolidated_exam_data_csv(data_hash)
      data ||= Array.new
      data << [data_hash[:batch].course.full_name + data_hash[:batch].name + "|" + data_hash[:exam_group].name]
      row = ["#{t('name')}", "#{t('admission_no')}"]
      row << "#{t('roll_no')}" if Configuration.enabled_roll_number?
      grade_type = data_hash[:grade_type]
      if grade_type=="GPA" or grade_type=="CWA"
        data_hash[:exams].each do |exam|
          row << exam.subject.code + ("(" + exam.subject.credit_hours.to_s + ")" unless exam.subject.credit_hours.nil?)
        end
        if grade_type=="CWA"
          row << t('weighted_average')
        else
          row << t('gpa')
        end
      else
        data_hash[:exams].each do |exam|
          #         row << exam.subject.code + (("(&#x200E;" + exam.maximum_marks.to_s + ")&#x200E;")  unless (exam.maximum_marks.nil? or exam_group.exam_type == "Grades" ))
          row << exam.subject.code #+ (("("+ exam.maximum_marks.to_s + ")")  unless (exam.maximum_marks.nil? or h[:exam_group].exam_type == "Grades" ))
        end
        unless data_hash[:exam_group].exam_type == "Grades"
          row << t('percentage') + "(%)"
        end
      end
      data << row
      data_hash[:exam_group].batch.students.find(:all, :order => "#{Student.sort_order}").each do |student|
        row = [student.full_name, student.admission_no]
        row << (student.roll_number.present? ? student.roll_number : '--') if Configuration.enabled_roll_number?
        if grade_type=="GPA"
          total_credits = 0
          total_credit_points=0
          data_hash[:exams].each do |exam|
            exam_score = ExamScore.find_by_student_id_and_exam_id(student.id, exam.id)
            unless exam_score.nil?
              exam_score.grading_level.present? ? row << exam_score.grading_level : row << "--"
              total_credits = total_credits + exam.subject.credit_hours.to_f unless exam.subject.credit_hours.nil?
              total_credit_points = total_credit_points + (exam_score.grading_level.credit_points.to_f * exam.subject.credit_hours.to_f) unless exam_score.grading_level.nil?
            else
              row << "--"
            end
          end
          if (total_credit_points.to_f/total_credits.to_f).nan?
            row << "--"
          else
            row << "%.2f" %(total_credit_points.to_f/total_credits.to_f)
          end
        elsif grade_type=="CWA"
          total_credits = 0
          total_weighted_marks=0
          data_hash[:exams].each do |exam|
            exam_score = ExamScore.find_by_student_id_and_exam_id(student.id, exam.id)
            unless exam_score.nil?
              exam_score.marks.present? ? row << "%.2f" %((exam_score.marks.to_f/exam.maximum_marks.to_f)*100) : row << "--"
              total_credits = total_credits + exam.subject.credit_hours.to_f unless exam.subject.credit_hours.nil?
              total_weighted_marks = total_weighted_marks + ((exam_score.marks.to_f/exam.maximum_marks.to_f)*(exam.subject.credit_hours.to_f)) unless exam_score.marks.nil?
            else
              row << "--"
            end
          end
          if (total_weighted_marks.to_f/total_credits.to_f).nan?
            row << "--"
          else
            row << "%.2f" %((total_weighted_marks.to_f.result_round(4)/total_credits.to_f).result_round)
          end

        else
          total_marks = 0
          total_max_marks = 0
          data_hash[:exams].each do |exam|
            exam_score = ExamScore.find_by_student_id_and_exam_id(student.id, exam.id)
            unless data_hash[:exam_group].exam_type == "Grades"
              if data_hash[:exam_group].exam_type == "MarksAndGrades"
                exam_score.nil? ? row << '--' : row << "#{(exam_score.marks || "-")}" + "(#{(exam_score.grading_level || "-")})"
              else
                exam_score.nil? ? row << '--' : row << exam_score.marks || "-"
              end
              total_marks = total_marks+(exam_score.marks || 0) unless exam_score.nil?
              total_max_marks = total_max_marks+exam.maximum_marks unless exam_score.nil?
            else
              exam_score.nil? ? row << '--' : row << exam_score.grading_level || "-"
            end
          end
          unless data_hash[:exam_group].exam_type == "Grades"
            percentage = total_marks*100/total_max_marks.to_f unless total_max_marks == 0
            unless total_max_marks == 0
              row << "%.2f" %percentage
            else
              row << "-"
            end
          end
        end
        data << row
      end
      return data
    end

    def ranking_level_csv(data_hash)
      data = Array.new
      if data_hash[:parameters][:mode] == "batch"
        subject = Subject.find(data_hash[:parameters][:subject_id]) if data_hash[:parameters][:subject_id].present?
        batch = Batch.find(data_hash[:parameters][:batch_id]) if data_hash[:parameters][:batch_id].present?
        data << ["#{data_hash[:ranking_level].name} #{t('students')}"]
        data << ["#{batch.full_name}"] #+  (" | #{t('subject')} : "+ subject.name if subject.present?) ]
        temp = ["#{t('adm_no')}", "#{t('name')}"]
        temp.insert(0, "#{t('roll_no')}") if Configuration.enabled_roll_number?
        data << temp
        data_hash[:ranked_students].each_with_index do |s, ind|
          row_data = []
          (s.roll_number.present? ? row_data << s.roll_number : row_data << "--") if Configuration.enabled_roll_number?
          s.admission_no.present? ? row_data << s.admission_no : row_data << "--"
          row_data << s.full_name
          data << row_data
        end
      else
        course = Course.find(data_hash[:parameters][:course_id])
        data << ["#{data_hash[:ranking_level].name} #{t('students')}"]
        data << ["#{course.full_name}"]
        temp = ["#{t('adm_no')}", "#{t('name')}", "#{t('batch')}", ("#{data_hash[:ranking_level].name} #{t('batch')}" unless data_hash[:ranking_level].full_course==true)]
        temp.insert(0, "#{t('roll_no')}") if Configuration.enabled_roll_number?
        data << temp
        data_hash[:ranked_students].each_with_index do |s, i|
          stu = Student.find(s[0])
          batch = Batch.find(s[1])
          row = [(stu.admission_no.present? ? stu.admission_no : "-"), stu.full_name, stu.batch.full_name, (batch.full_name unless data_hash[:ranking_level].full_course==true)]
          row.insert(0, (stu.roll_number.present? ? stu.roll_number : "--")) if Configuration.enabled_roll_number?
          data << row
        end
      end
      return data
    end

    def finance_transaction_data_csv(data_hash)
      data = Array.new
      data << ["#{t('finance_transaction_report')}"]
      data << ["#{t('from')} ( #{format_date(data_hash[:start_date])}) #{t('to')} ( #{format_date(data_hash[:end_date])})"]
      data << [t('fee_account_text'), "#{@account_name}"] if data_hash[:accounts_enabled]
      data << ""
      data << "#{t('income')}"
      data << ["#{t('finance_categories')}", "#{t('amount')}"]
      index = 0; income_total = 0; expenses_total = 0
      data << ["#{t('donations')}", precision_label(data_hash[:donations_total])]
      data << ["#{t('student_fees')}", precision_label(data_hash[:transactions_fees])]

      data << ["#{t('advance_fees_credit_text')}", precision_label(data_hash[:wallet_income])] if data_hash[:wallet_income].present?
      income_total +=precision_label(data_hash[:transactions_fees]).to_f
      income_total +=precision_label(data_hash[:donations_total]).to_f
      income_total +=precision_label(data_hash[:wallet_income]).to_f if data_hash[:wallet_income].present?
      grand_total = 0

      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        plugin_present="#{category[:plugin_name]}".present? ? FedenaPlugin.can_access_plugin?("#{category[:plugin_name]}") : true
        if plugin_present == true
          row=Array.new
          if data_hash[:category_transaction_totals]["#{category[:category_name]}"][:category_type] == "income"
            if precision_label(data_hash[:category_transaction_totals]["#{category[:category_name]}"][:amount]).to_f>0
              row << ["#{t(category[:category_name].underscore.gsub(/\s+/, '_')+'_fees')}"]
              row << precision_label(data_hash[:category_transaction_totals]["#{category[:category_name]}"][:amount])
              income_total +=precision_label(data_hash[:category_transaction_totals]["#{category[:category_name]}"][:amount]).to_f
              data << row
            end
          end
        end
      end
      data_hash[:other_transaction_categories].each_with_index do |t, i|
        income = t.total_income(data_hash[:start_date], data_hash[:end_date]).to_f
        if income >0
          if t.is_income
            data << [t.name, precision_label(income)]
            income_total +=income
          end
        end
      end
      data <<["#{t('total_income')}", precision_label(income_total)]
      data << ''


      ############ Expenses ######

      data << "#{t('expense')}"
      data << ["#{t('finance_categories')}", "#{t('amount')}"]
      index = 0; expenses_total = 0
      unless data_hash[:hr].nil?
        data << ["#{t('employee_salary')}", precision_label(data_hash[:salary]), ""]
        expenses_total+=precision_label(data_hash[:salary]).to_f
      end
      if data_hash[:refund].present? and data_hash[:refund].to_f > 0
        data << ["Refund", precision_label(data_hash[:refund]), ""]
        expenses_total+=precision_label(data_hash[:refund]).to_f
      end
      data << ["#{t('advance_fees_debit_text')}", precision_label(data_hash[:wallet_expense])]
      expenses_total +=precision_label(data_hash[:wallet_expense]).to_f
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        row=Array.new
        plugin_present="#{category[:plugin_name]}".present? ? FedenaPlugin.can_access_plugin?("#{category[:plugin_name]}") : true
        if plugin_present == true
          unless data_hash[:category_transaction_totals]["#{category[:category_name]}"][:category_type] == "income"
            if precision_label(data_hash[:category_transaction_totals]["#{category[:category_name]}"][:amount]).to_f>0
              row << ["#{t(category[:category_name].underscore.gsub(/\s+/, '_')+'_fees')}"]
              row << precision_label(data_hash[:category_transaction_totals]["#{category[:category_name]}"][:amount])
              expenses_total +=precision_label(data_hash[:category_transaction_totals]["#{category[:category_name]}"][:amount]).to_f
              data << row
            end
          end
        end
      end

      data_hash[:other_transaction_categories].each_with_index do |t, i|
        expense = t.total_expense(data_hash[:start_date], data_hash[:end_date])
        if expense>0
          unless t.is_income
            data<<[t.name, precision_label(expense)]
            expenses_total+=expense
          end
        end
      end
      grand_total=income_total-expenses_total
      data <<["#{t('total_expenses')}", precision_label(expenses_total)]
      data << ''
      data << ["#{t('grand_total')}", precision_label(grand_total).to_s]
      return data
    end

    def student_fees_structure_overview_data_csv(data_hash)
      data = Array.new
      data << ["#{t('fee_structure')}"]
      student = data_hash[:student]
      batch = data_hash[:batch]
      student_fees = data_hash[:student_fees]
      data << ["#{t('students_name')}","#{student.full_name}"]
      data << ["#{t('course_and_batch')}","#{batch.course_name} - #{batch.name}"]
      data << ["#{t('adm_no')}","#{student.admission_no}"]
      data << ["#{t('roll_no')}","#{student.roll_number.present? ? student.roll_number : '-'}"] if Configuration.
        get_config_value('EnableRollNumber') == "1"
      data << [] # line break
      data << ["#{t('finance_type')}","#{t('fees_name')}","#{t('balance')}", "#{t('total_amount')}","#{t('due_date')}","#{t('status')}","#{t('paid_on')}"]
      g_total = 0
      g_balance = 0
      student_fees.each_pair do |fee_type, fees|
        fee_type_name = fee_type.singularize
        fees.each do |fee|
          collection = fee.send("#{fee_type_name}_collection")
          data_row = []
          data_row << t("#{fee_type == 'finance_fees' ? 'general_fees' : fee_type}")
          data_row << fee.name

          amount_to_pay = fee.balance.to_f

          if fee_type == 'finance_fees'
            amount_to_pay += collection.fine_to_pay(student).to_f
            paid = (fee.is_paid? || ((precision_label(fee.balance.to_f + fee.finance_fee_collection.fine_to_pay(student).to_f))==precision_label(0)))
          elsif fee_type == 'transport_fees'
            discount = precision_label(fee.total_discount_amount).to_f
            amount_to_pay += fee.auto_fine_amount(collection,discount,fee).to_f
            paid = fee.is_paid? #|| ((precision_label(fee.balance.to_f + fee.finance_fee_collection.fine_to_pay(student).to_f))==precision_label(0)))
          else
            paid = ((precision_label(fee.balance.to_f))==precision_label(0))
          end

          total_amount = fee.try(:paid_amount).to_f + amount_to_pay
          g_balance += amount_to_pay
          g_total += total_amount

          data_row << "#{precision_label(amount_to_pay)}"
          data_row << "#{precision_label(total_amount)}"
          data_row << "#{format_date(collection.due_date.to_date, :format => :short)}"
          if paid
            transaction_date = fee.try(:last_transaction_date).try(:to_date)
            data_row << "#{t('paid')}"
            data_row << (transaction_date.present? ? "#{format_date(transaction_date, :format => :short)}" : "")
          else
            data_row << "#{t('unpaid')}"
            data_row << ""
          end

          data << data_row
        end
      end
      data << [] # line break
      data << ["#{t('grand_total')}","","#{precision_label(g_balance)}","#{precision_label(g_total)}"]
      return data
    end

    def fee_structure_overview_data_csv(data_hash)
      data = Array.new

      students = data_hash[:parameters][:students]
      query = data_hash[:parameters][:query]
      batch_id = data_hash[:parameters][:batch_id]
      batch = Batch.find(batch_id) if batch_id.present?
      roll_no_enabled = Configuration.get_config_value('EnableRollNumber') == "1" ? true : false
      # add code
      data << ["#{t('fee_structure')}"]
      data << ["#{t('searched_for')}#{query}"] if query.present?
      data << ["#{t('searched_for')}#{batch.full_name}"] if batch_id.present?
      data << ""
      # heading row data
      if students.present?
        row_heading = ["#{t('first_name')}", "#{t('batch')}", "#{t('adm_no')}"]
        if roll_no_enabled
          row_heading << "#{t('roll_no')}"
        end
        row_heading << "#{t('fees_text')}"
        data << row_heading
        # data rows
        students.each do |student|
          data_row = []
          data_row = ["#{student.fullname}", "#{student.batch_full_name}", "#{student.admission_no}"]
          if roll_no_enabled
            data_row << "#{student.roll_number.present? ? student.roll_number : '-'}"
          end
          fee_cnt = student.fee_count.to_i
          #          all_fee_count = fee_cnt + student.hostel_count.to_i + student.transport_count.to_i
          student_fee = student.fee_due.to_f
          total_fee = student_fee + student.transport_due.to_f + student.hostel_due.to_f
          if fee_cnt > 0 and  precision_label(student_fee).to_f > 0
            batch_id = student.batch_id
            total_fee += student.total_automatic_finance_fee_fine(batch_id) if batch_id.present?
          end
          data_row << precision_label(total_fee)

          data << data_row
        end
      end
      return data
    end

    def finance_tax_data_csv(data_hash)
      data = Array.new
      data << ["#{t('tax_report')}"]
      data << ["#{t('from')} ( #{format_date(data_hash[:start_date])}) #{t('to')} ( #{format_date(data_hash[:end_date])})"]

      grand_total= 0
      if data_hash[:tax_payments].present?
        data << ""
        data << ["#{t('tax_slabs_text')}", "#{t('amount')}"]
        data_hash[:tax_payments].group_by do |tax|
          "#{tax.slab_name} - (#{precision_label(tax.slab_rate)}%)"
        end.each_pair do |slab, slab_data|
          data << ["#{slab}", precision_label(slab_data.map {|x| x.tax_amount.to_f }.sum)]
        end
        grand_total = data_hash[:tax_payments].map(&:tax_amount).sum.to_f
      end
      data << ""
      data << ["#{t('grand_total')}", precision_label(grand_total).to_s]
      return data
    end

    def finance_payslip_data_csv(data_hash)
      return payslip_data(data_hash)
    end

    def employee_payslip_data_csv(data_hash)
      return payslip_data(data_hash)
    end

    def payslip_data(data_hash)
      data ||= Array.new
      data << ["#{t('department')} : #{data_hash[:department_name]}"] if data_hash[:department_name].present?
      data << ["#{t('start_date')} : #{format_date(data_hash[:search_parameters][:start_date], :short)}"] if data_hash[:search_parameters][:start_date].present?
      data << ["#{t('end_date')} : #{format_date(data_hash[:search_parameters][:end_date], :short)}"] if data_hash[:search_parameters][:end_date].present?
      data << ["#{t('payslip_period')} : #{data_hash[:search_parameters][:payslip_period] == "All" ? t('all') : t(PayrollGroup::PAYMENT_PERIOD[data_hash[:search_parameters][:payslip_period].to_i])}"] if data_hash[:search_parameters][:payslip_period].present?
      data << ["#{t('payslip_status')} : #{data_hash[:search_parameters][:payslip_status] == "All" ? t('all') : t(EmployeePayslip::PAYSLIP_STATUS[data_hash[:search_parameters][:payslip_status].to_i])}"] if data_hash[:search_parameters][:payslip_status].present?
      data << ["#{t('employee_name')} : #{data_hash[:search_parameters][:employee_name]}"] if data_hash[:search_parameters][:employee_name].present?
      data << ["#{t('employee_number')} : #{data_hash[:search_parameters][:employee_no]}"] if data_hash[:search_parameters][:employee_no].present?
      if data_hash[:search_parameters][:department_id] == "All"
        data << ["#{t('employee_text')}", "#{t('payment_frequency')}", "#{t('payslip_period')}", "#{t('amount')} (#{data_hash[:currency_type]})", "#{t('payslip_status')}"]
      else
        data << ["#{t('employee_text')}", "#{t('payslip_period')}", "#{t('amount')} (#{data_hash[:currency_type]})", "#{t('payslip_status')}"]
      end
      total_salary = 0; total_approved_salary = 0; total_employees = []; i=0
      unless data_hash[:payslips].blank?
        data_hash[:payslips].each do |group_name, payslips|
          if data_hash[:search_parameters][:department_id] == "All"
            data << [group_name]
          else
            data << PayrollGroup.payment_period_translation(group_name)
          end
          payslips.each do |p|
            if p.emp_type == 'Employee'
              row = ["#{i+=1}. #{p.full_name}(#{p.employee_number})"]
            else
              row = ["#{i+=1}. #{p.full_name}(#{p.employee_number}) #{t('archived')}"]
            end
            if data_hash[:search_parameters][:department_id] == "All"
              row << PayrollGroup.payment_period_translation(p.payment_period)
            end
            row << p.date_range
            row << p.net_pay
            row << (p.is_rejected == true ? t('rejected') : p.is_approved == true ? t('approved') : t('pending'))
            total_salary += p.net_pay.to_f
            total_approved_salary += p.net_pay.to_f if p.is_approved
            total_employees << p.employee_id
            data << row
          end
        end
        data << [] << ["#{t('total_payslips')}", total_employees.count]
        data << ["#{t('total_employees')}", total_employees.uniq.count]
        data << ["#{t('total_salary_text')}", precision_label(total_salary)]
        data << ["#{t('approved_salary')}", precision_label(total_approved_salary)]
      end
      return data
    end

    def exam_timings_data_csv(data_hash)
      return exam_schedule_data(data_hash)
    end

    def exam_schedule_data(data_hash)
      data ||= Array.new
      data << [t('exam_timetable')]
      data << ["#{t('course')}", data_hash[:course].course_name]
      unless data_hash[:batch].present?
        data << ["#{t('batches_text')}", data_hash[:course].batches_in_academic_year(data_hash[:assessment_group].academic_year_id).count]
        data << ["#{t('students')}", data_hash[:course].active_students_in_academic_year(data_hash[:assessment_group].academic_year_id).count]
      else
        data << ["#{t('batches_text')}", data_hash[:batch].name]
        data << ["#{t('students')}", data_hash[:batch].students.count]
      end
      data << ["#{t('exam_group')}", data_hash[:assessment_group].name]
      data << ["#{t('term_text')}", data_hash[:term].name]
      data << ["#{t('maximum_marks')}", data_hash[:assessment_group].maximum_marks_text.gsub("&#x200E;", "")]
      data << []
      data << [t('date_text'), t('time_text'), "#{t('subject')} #{(data_hash[:batch].present? ? ("- " + data_hash[:batch].name) : '')}"]
      unless data_hash[:assessments].blank?
        data_hash[:assessments].each do |batch,timetables|
          unless data_hash[:batch].present?
            data << [batch.name]
          end
          timetables.each do |exam|
            row = []
            row << format_date(exam.exam_date, :format => :long_date_and_date)
            row << "#{format_date(Time.parse(exam.start_time), :format => :time )} #{t('to')} #{format_date(Time.parse(exam.end_time), :format => :time )}"
            row << "#{exam.subject_name} #{exam.elective_group_id.present? ? t('elective_sub') : ''}"
            data << row
          end
        end
      end
      return data
    end

    def student_wise_report_csv(data_hash)
      data = Array.new
      scholastic = data_hash[:report].scholastic
      cgpa=0.0; count=0
      data << ["STUDENT REPORT"]
      data << ["Name : #{data_hash[:student].full_name}"]
      data << ["#{t('course')} : #{data_hash[:batch].course.full_name}"]
      data << ["Adm No. : #{(data_hash[:student].admission_no.present? ? data_hash[:student].admission_no : "--")}"]
      data << ["Roll No. : #{(data_hash[:student].roll_number.present? ? data_hash[:student].roll_number : "--")}"] if Configuration.enabled_roll_number?
      data << ["Batch : #{data_hash[:batch].name}"]
      data << ["Scholastic Areas"]

      if data_hash[:parameters][:cat_id].present?
        data_hash[:exam_groups].reject! { |k| k.cce_exam_category_id!=data_hash[:parameters][:cat_id].to_i }
      end

      if data_hash[:exam_groups].empty?
        data << ["No reports to show"]
      else
        row = ["Sl no", "Subjects"]
        data_hash[:exam_groups].each do |eg|
          row << eg.cce_exam_category.name
          row <<['', '', '', '']
        end
        if data_hash[:exam_groups].count==2
          row << ["Overall"]
        end
        row.flatten!
        data << row
        row=[]
        row<<["  ", " "]
        data_hash[:exam_groups].each_with_index do |eg, i|
          if data_hash[:parameters][:check_term]=="second_term"
            i=1
          end
          row << ["FA#{2*i+1}", "FA#{2*i+2}", "SA#{i+1}", "Total"]

        end
        if data_hash[:exam_groups].count==2
          row << "FA Total"
          row << "SA Total"
          row << "Overall"
          row << "Grade Point"
        end
        row.flatten!
        data << row
        data_hash[:subjects].each_with_index do |s, i|
          row = [i+1, s.name]
          sub=scholastic.find { |c| c.subject_id==s.id }
          data_hash[:exam_groups].each_with_index do |eg, j|
            se=sub.exams.find { |g| g.exam_group_id==eg.id } if sub
            if se
              if data_hash[:parameters][:check_term]=="second_term"
                j=1
              end
              set1 = se.fa_names["FA#{2*j+1}"].nil? ? " " : se.fa[se.fa_names["FA#{2*j+1}"]]["grade"]
              row << set1
              set2 = se.fa_names["FA#{2*j+2}"].nil? ? " " : se.fa[se.fa_names["FA#{2*j+2}"]]["grade"]
              row << set2
              set3 = se.sa.nil? ? " " : se.sa["grade"]
              row << set3
              row << se.overall
            else
              row << "-"
              row << "-"
              row << "-"
              row << "-"
            end
          end
          if data_hash[:exam_groups].count==2
            if sub
              row << sub.fa
              row << sub.sa
              row << (sub.upscaled == 'true' ? "#{sub.overall}**" : sub.overall)
              row << sub.grade_point
              if s.elective_group_id.nil? and !s.is_sixth_subject
                cgpa += sub.grade_point.to_f
                count += 1
              elsif !s.elective_group_id.nil? and !s.elective_group.is_sixth_subject
                cgpa += sub.grade_point.to_f
                count += 1
              end
            else
              row << "-"
              row << "-"
              row << "-"
              row << "-"
            end
          end
          data << row
        end
      end
      if data_hash[:exam_groups].count==2
        row =[]
        data << ""
        if @batch.asl_subject.present?
          row << "Grade in Assessment of Speaking and Listening Skills in #{@batch.asl_subject.name} (ASL)"
          row << " #{data_hash[:report][:asl]}"
          row << " "
        end
        row << "Cumulative Grade Point Average(CGPA)"
        row << "%.2f" % (cgpa.to_f/count.to_f) unless count==0
        data << row
        data << ""
      end

      if data_hash[:parameters][:check_term]=="all"
        data_hash[:co_hashi].keys.sort.each do |kind|
          unless data_hash[:co_hashi][kind].blank?
            data << [ObservationGroup::OBSERVATION_KINDS[kind]]
          end
          i = 0; data_hash[:co_hashi][kind].each { |el| i+=1; el.sort_order ||= i }
          data_hash[:co_hashi][kind].sort_by(&:sort_order).each do |ob_grp|
            data << [data_hash[:obs_groups].find { |o| o.id == ob_grp.observation_group_id }.try(:name)]
            data << ["Observation", "Descriptive Indicators", "Grade"]
            ob_grp.observations.sort_by(&:sort_order).each do |o|
              data << [o.observation_name, data_hash[:student].get_descriptive_indicators(o.observation_id), o.grade]
            end
          end
        end
        j=1
      end
      return data
    end

    def grouped_exam_csv(data_hash)
      data = Array.new
      type = data_hash[:type]
      batch = data_hash[:batch]
      data << "Grouped Exam Report for Batch : "+ batch.full_name
      grade_type = data_hash[:grade_type]
      students = data_hash[:students]
      general_subjects = Subject.find_all_by_batch_id(batch.id, :conditions => "elective_group_id IS NULL and is_deleted=false")
      exams = Exam.find_all_by_exam_group_id(data_hash[:exam_groups].collect(&:id))
      students.each_with_index do |student, i|
        student_electives = StudentsSubject.find_all_by_student_id(student.id, :conditions => "batch_id = #{batch.id}")
        elective_subjects = []
        student_electives.each do |elect|
          elective_subjects.push Subject.find_by_id(elect.subject_id, :conditions => {:is_deleted => false})
        end
        subjects = general_subjects + elective_subjects
        subjects = subjects.compact.flatten
        subjects.reject! { |s| s.no_exams==true }
        subject_ids = exams.collect(&:subject_id)
        subjects.reject! { |sub| !(subject_ids.include?(sub.id)) }
        row_data = ["#{student.full_name} - #{student.admission_no}"]
        data << row_data
        data << ["#{t('roll_no')} - #{student.roll_number.present? ? student.roll_number : '--'}"] if Configuration.enabled_roll_number?
        if type=="grouped"
          row_data = []
          row_data << t('subject')
          if grade_type=="GPA" or grade_type=="CWA"
            row_data << t('credit')
          end
          data_hash[:exam_groups].each do |exam_group|
            row_data << exam_group.name
          end
          row_data << t('combined')
          data << row_data
          subjects.each do |subject|
            row_data = ["#{subject.name}"]
            if grade_type=="GPA" or grade_type=="CWA"
              subject.credit_hours.present? ? row_data << subject.credit_hours : row_data << "-"
            end
            data_hash[:exam_groups].each do |exam_group|
              exam = Exam.find_by_subject_id_and_exam_group_id(subject.id, exam_group.id)
              exam_score = ExamScore.find_by_student_id(student.id, :conditions => {:exam_id => exam.id}) unless exam.nil?
              if grade_type=="GPA"
                exam_score.present? ? row_data << "#{exam_score.grading_level || "-"}"+" ["+"#{exam_score.grading_level.present? ? (exam_score.grading_level.credit_points || "-") : "-"}"+"]" : row_data << "-"
              elsif grade_type=="CWA"
                exam_score.present? ? row_data << "#{exam_score.marks.present? ? ("%.2f" %((exam_score.marks.to_f/exam.maximum_marks.to_f)*100)) : "-"}"+" ["+"#{exam_score.grading_level.present? ? exam_score.grading_level : "-"}"+"]" : row_data << "-"
              else
                if exam_group.exam_type == "MarksAndGrades"
                  exam_score.nil? ? row_data << '-' : row_data << "#{(exam_score.marks || "-")}" +"/"+exam.maximum_marks.to_s+"[#{(exam_score.grading_level || "-")}]"
                elsif exam_group.exam_type == "Marks"
                  exam_score.nil? ? row_data << '-' : row_data << "#{exam_score.marks || "-"}/"+exam.maximum_marks.to_s
                else
                  exam_score.nil? ? row_data << '-' : row_data << (exam_score.grading_level || '-')
                end
              end
            end
            subject_average = GroupedExamReport.find_by_student_id_and_subject_id_and_score_type(student.id, subject.id, "s")
            if grade_type=="GPA"
              subject_average.present? ? row_data << "#{subject_average.marks}" : "-"
            else
              subject_average.present? ? row_data << "#{subject_average.marks}[#{GradingLevel.percentage_to_grade(subject_average.marks, batch.id).present? ? GradingLevel.percentage_to_grade(subject_average.marks, batch.id) : '-'}]" : "-[-]"
            end
            data << row_data
          end
          row_data = []
          if grade_type=="GPA"
            row_data << t('gpa') << ""
          elsif grade_type=="CWA"
            row_data << t('weighted_average')
          else
            row_data << t('percentage')
          end
          data_hash[:exam_groups].each do |exam_group|
            exam_total = GroupedExamReport.find_by_student_id_and_exam_group_id_and_score_type(student.id, exam_group.id, "e")
            exam_total.present? ? row_data << exam_total.marks : row_data << "-"
          end
          total_avg = GroupedExamReport.find_by_student_id_and_batch_id_and_score_type(student.id, student.batch.id, "c")
          total_avg.present? ? row_data << total_avg.marks : row_data << "-"
          data << row_data
          row_data = []
          row_data << "#{t('aggregate')} #{t('grade')}"
          unless total_avg.nil?
            if grade_type=="GPA"
              row_data << GradingLevel.percentage_to_grade(total_avg.marks, data_hash[:batch].id, 'gpa') unless total_avg.marks.nil?
            else
              row_data << GradingLevel.percentage_to_grade(total_avg.marks, data_hash[:batch].id) unless total_avg.marks.nil?
            end
          else
            row_data << '-'
          end
          data << row_data
        else
          row_data = []
          all_exams = data_hash[:exam_groups].reject { |ex| ex.exam_type == "Grades" }
          row_data << t('subject')
          data_hash[:exam_groups].each do |exam_group|
            row_data << exam_group.name
          end
          unless all_exams.empty?
            row_data << t('total')
          end
          data << row_data
          subjects.each do |subject|
            row_data = ["#{subject.name}"]
            mmg = 1; g = 1
            data_hash[:exam_groups].each do |exam_group|
              exam = Exam.find_by_subject_id_and_exam_group_id(subject.id, exam_group.id)
              exam_score = ExamScore.find_by_student_id(student.id, :conditions => {:exam_id => exam.id}) unless exam.nil?
              unless exam.nil?
                if exam_group.exam_type == "MarksAndGrades"
                  exam_score.nil? ? row_data << '-' : row_data << "#{(exam_score.marks || "-")}" +"/"+exam.maximum_marks.to_s+"[#{(exam_score.grading_level || "-")}]"
                elsif exam_group.exam_type == "Marks"
                  exam_score.nil? ? row_data << '-' : row_data << "#{exam_score.marks || "-"}/"+exam.maximum_marks.to_s
                else
                  exam_score.nil? ? row_data << '-' : row_data << (exam_score.grading_level || '-')
                  g = 0
                end
              else
                row_data << "#{t('n_a')}"
              end
            end
            total_score = ExamScore.new()
            unless all_exams.empty?
              if mmg == g
                row_data << total_score.grouped_exam_subject_total(subject, student, type,"",1)
              else
                row_data << "-"
              end
            end
            data << row_data
          end
          row_data = [t('total')]
          max_total = 0; marks_total = 0
          data_hash[:exam_groups].each do |exam_group|
            if exam_group.exam_type == "MarksAndGrades"
              row_data << exam_group.total_marks(student)[0]
            elsif exam_group.exam_type == "Marks"
              row_data << exam_group.total_marks(student)[0]
            else
              row_data << "-"
            end
            unless exam_group.exam_type == "Grades"
              max_total = max_total + exam_group.total_marks(student)[1]
              marks_total = marks_total + exam_group.total_marks(student)[0]
            end
          end
          unless all_exams.empty?
            row_data << ""
          end
          data << row_data

          percentage = (marks_total*100/max_total.to_f)  unless max_total==0
          row_data = []
          row_data << t('total_marks')
          row_data << "#{marks_total}/#{max_total}"
          row_data << t('aggregate')
          percentage.nil? ? row_data << "-" : row_data << "%.2f" %percentage
          row_data << "#{t('aggregate')} #{t('grade')}"
          if grade_type=="GPA"
            percentage.nil? ? row_data << "-" : row_data << GradingLevel.percentage_to_grade(percentage, data_hash[:batch].id, 'gpa')
          else
            percentage.nil? ? row_data << "-" : row_data << GradingLevel.percentage_to_grade(percentage, data_hash[:batch].id)
          end
          data << row_data
        end
        row_data = []
        data << row_data

        row_data = []
        data << row_data
        remarks=RemarkMod.generate_common_remark_form("grouped_exam_general", student.id, nil, 1, {:batch_id => student.batch_id, :student_id => student.id})
        if remarks.present?
          row_data << "#{t('remarks')}"
          row_data = []
          data << row_data
          remarks.each do |remark|
            remark_user=remark.user.present? ? remark.user.first_name : 'deleted user'
            row_data=[remark.remarked_by, remark.remark_body, "#{remark_user} on #{format_date(remark.updated_at, :format => :long)}"]
            data<<row_data
          end
        end
        row_data=[]
        data << row_data
      end
      return data
    end

    def student_fees_data(params)
      data=[]
      student=Student.find(params[:student_id])
      batches=student.all_batches.reverse
      @@total_paid=0;
      @@total_unpaid=0;
      data << "#{t('student_name')} : "+ student.full_name
      data << "#{t('batch_name')} : "+ student.batch.complete_name
      data << "#{t('admission_no')} : "+ student.admission_no
      data << "#{t('roll_no')} : "+ student.roll_number if student.roll_number.present? && roll_number_enabled?
      data << "#{t('total_paid')} : "+ precision_label(@@total_paid).to_s #place holder
      data << "#{t('total_unpaid')} : "+ precision_label(@@total_unpaid).to_s #place holder
      data<< " "
      batches.each do |batch|
        data << batch.complete_name
        data <<[t('fees_name'), t('status'), t('amount'), t('date_text')]
        fees_list_by_batch=student.fees_list_by_batch(batch.id)
        unless fees_list_by_batch.empty?
          data << t('general_fees')
          fees_list_by_batch.each do |fee|
            if fee.is_fine_waiver == "1"
              fine_to_pay = 0.0
            elsif  Configuration.is_fine_settings_enabled? && fee.balance.to_f<=0 && !fee.is_paid? && fee.balance_fine.present?
              fine_to_pay = fee.balance_fine.to_f
            else
              fine_amount = fee.is_amount == "0" ? (fee.actual_amount.to_f*fee.fine_amount.to_f)/100 : fee.fine_amount if fee.is_amount.present?
              fine_to_pay = fine_amount.present? ? (fine_amount.to_f - fee.automatic_fine_paid.to_f) : 0
            end
            paid = (fee.is_paid or ((precision_label(fee.balance.to_f+fine_to_pay.to_f))==precision_label(0)))
            paid = paid.to_i if paid.class.to_s == "String"
            if paid == true || paid ==1
              name=fee.name
              status=t('paid')
              amount=precision_label(fee.paid_amount)
              date=t('paid_on')+' '+format_date(fee.last_transaction_date)
              @@total_paid+=amount.to_f
            else
              name=fee.name
              status=t('unpaid')
              amount_to_pay=precision_label(fee.balance.to_f+fine_to_pay.to_f)
              partialy_paid_amount=fee.try(:paid_amount) || 0
              total_amount=precision_label(amount_to_pay.to_f + partialy_paid_amount.to_f)
              amount= "#{amount_to_pay}/#{total_amount}"
              date=t('due_on')+' '+format_date(fee.due_date)
              @@total_unpaid+=amount.to_f
              @@total_paid+=partialy_paid_amount.to_f if partialy_paid_amount.present?
            end
            row=[name, status, amount, date]
            data << row
          end
        end
        plugin_data=load_data_from_plugins(student, batch)
        if plugin_data.present?
          data+=plugin_data
        end
        if fees_list_by_batch.empty? && plugin_data.empty?
          data<< t('no_fees_to_pay')
        end
        data << " "
      end
      # other fees ( transactions without batch id)
      other_data=load_data_from_plugins(student, nil)
      if other_data.present?
        data << ""
        data << t('others')
        data+=other_data
      end
      if student.roll_number.present? && roll_number_enabled?
        paid_row=4
        unpaid_row=5
      else
        paid_row=3
        unpaid_row=4
      end
      data[paid_row]= "#{t('total_paid')} : "+ precision_label(@@total_paid).to_s
      data[unpaid_row]= "#{t('total_unpaid')} : "+ precision_label(@@total_unpaid).to_s
      return data
    end

    def active_account_joins use_alias = false, alias_name = nil
      alias_name = use_alias ? alias_name : 'finance_fee_collections'
      " LEFT JOIN fee_accounts fa ON fa.id = #{alias_name}.fee_account_id"
    end

    def active_account_conditions
      "(fa.id IS NULL OR fa.is_deleted = false)"
    end

    def load_data_from_plugins(student, batch)
      # HostelFee
      data=[]
      if FedenaPlugin.can_access_plugin?("fedena_hostel")
        joins = "INNER JOIN hostel_fee_collections hfc ON hfc.id = hostel_fees.hostel_fee_collection_id
                      #{active_account_joins(true, 'hfc')}"

        hostel_fees_list = HostelFee.all(:joins => joins,
          :conditions => ["hostel_fees.batch_id = ? AND hostel_fees.student_id = ? AND
           #{active_account_conditions}", batch.try(:id), student.id])

        unless hostel_fees_list.empty?
          data << t('hostel_fees')
          hostel_fees_list.each do |fee|
            collection=fee.hostel_fee_collection
            balance = student.hostel_fee_balance(collection.id)
            paid = (balance == 0)
            if paid
              name=fee.name
              status=t('paid')
              amount=precision_label(fee.finance_transaction.amount)
              date=t('paid_on')+' '+format_date(fee.finance_transaction.transaction_date)
              @@total_paid+=amount.to_f
            else
              name=fee.name
              status=t('unpaid')
              amount=precision_label(fee.rent)
              date=t('due_on')+' '+format_date(collection.due_date)
              @@total_unpaid+=amount.to_f
            end
            row=[name, status, amount, date]
            data << row
          end
          data << " "
        end
      end
      #TransportFee
      if FedenaPlugin.can_access_plugin?("fedena_transport")
        joins = "INNER JOIN transport_fee_collections tfc ON tfc.id = transport_fees.transport_fee_collection_id
                      #{active_account_joins(true, 'tfc')}"
        cond = ["receiver_type = 'Student' AND receiver_id = ? AND groupable_type = 'Batch' AND groupable_id = ? AND
                 transport_fees.is_active = true AND #{active_account_conditions}", student.id, batch.try(:id)]
        transport_fees_list = TransportFee.all(:conditions => cond, :joins => joins, :order => "transaction_id")

        unless transport_fees_list.empty?
          data << t('transport_fees')
          transport_fees_list.each do |fee|
            collection=fee.transport_fee_collection
            balance = student.transport_fee_balance(collection.id)
            paid = (balance == 0)
            if paid
              name=collection.name
              status=t('paid')
              amount=precision_label(fee.finance_transactions.sum(:amount))
              date=t('paid_on')+' '+format_date(fee.finance_transaction.transaction_date)
              @@total_paid+=amount.to_f
            else
              if fee.finance_transactions.present?
                amount=precision_label(fee.finance_transactions.sum(:amount))
                @@total_paid+=amount.to_f
              end
              name=collection.name
              status=t('unpaid')
              discount = fee.total_discount_amount
              auto_fine_amount = fee.auto_fine_amount(collection,discount,fee)
              amount_to_pay = fee.balance.to_f+ auto_fine_amount .to_f
              total_amount = fee.bus_fare.to_f-discount.to_f+fee.fine_amount.to_f+auto_fine_amount.to_f
              if fee.tax_enabled?
                total_amount +=  fee.tax_amount.to_f
              end
              amount = precision_label(amount_to_pay)+"/"+precision_label(total_amount)
              date=t('due_on')+' '+format_date(collection.due_date)
              @@total_unpaid+=amount.to_f
            end
            row=[name, status, amount, date]
            data << row
          end
          data << " "
        end
      end
      #instant_fee
      if FedenaPlugin.can_access_plugin?("fedena_instant_fee")

        instant_fee_list=student.find_instance_fees_by_batch(batch.try(:id))
        # if batch.present?
        #   # instant_fee_list=InstantFee.get_instant_fees_by_batch_and_student(student.id,batch.id)
        #   instant_fee_list=student.find_instance_fees_by_batch(batch.id)
        # else
        #   # instant_fee_list=InstantFee.get_instant_fees_by_batch_and_student(student.id,nil)
        # end
        unless instant_fee_list.empty?
          data<< t('instant_fees_text')
          instant_fee_list.each do |instant_fee|
            name=instant_fee.category_name
            status=t('paid')
            amount=precision_label(instant_fee.amount)
            date=t('paid_on')+' '+format_date(instant_fee.transaction_date)
            @@total_paid+=amount.to_f
            row=[name, status, amount, date]
            data << row
          end
          data << " "
        end
      end
      #LibraryFine
      if FedenaPlugin.can_access_plugin?("fedena_library")
        if batch.present?
          fine_list= student.library_fines_by_batch_id(batch.id)
        else
          fine_list= student.library_fines_by_batch_id(nil)
        end
        unless fine_list.empty?
          data << t('library_text')
          fine_list.each do |fine|
            name=t('due_fine')
            status=t('paid')
            amount=precision_label(fine.amount.to_f)
            date=t('paid_on')+' '+format_date(fine.date.to_date)
            @@total_paid+=amount.to_f
            # row = [fine.title,t('paid'),precision_label(fine.amount.to_f),fine.date.to_date]
            row=[name, status, amount, date]
            data << row
          end
          data << " "
        end
      end
      return data
    end


    def finance_fee_collection_data(params)
      data=[]

      accounts_enabled, filter_by_account, account_id = account_filter params

      if filter_by_account
        ft_joins = [:finance_transaction_receipt_record]
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        ft_joins = []
        filter_conditions = ""
        filter_values = []
      end

      data << t('student_fee_report')
      data << [t('start_date'), format_date(params[:start_date])]
      data << [t('end_date'), format_date(params[:end_date])]
      data << [t('fee_account_text'), "#{@account_name}"] if accounts_enabled
      data << ""

      start_date = params[:start_date].to_date
      end_date = params[:end_date].to_date

      total = 0

      fee_id = FinanceTransactionCategory.find_by_name("Fee").id
      data << [t('fee_collections_and_particulars'), "","","", t('amount')]
      collections = FinanceFeeCollection.find(:all,
        :joins => {:finance_fees => {:finance_transactions => ft_joins}},
        :group => :fee_collection_id,
        :conditions => ["finance_transactions.finance_type = 'FinanceFee' AND finance_transactions.category_id = ? AND
                                 (finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          fee_id, start_date.to_s, end_date.to_s] + filter_values,
        :select => "finance_fee_collections.id AS collection_id,
                           finance_fee_collections.name AS collection_name,
                           finance_fee_collections.tax_enabled,
                           SUM(finance_transactions.amount) AS amount,
                           IF(finance_fee_collections.tax_enabled,
                              SUM(finance_transactions.tax_amount),0) AS total_tax,
                           SUM(finance_transactions.fine_amount) AS total_fine",
        :order => "finance_fee_collections.id DESC")
      conditions = ["((`particular_payments`.`transaction_date` BETWEEN '#{start_date}' AND
                            '#{end_date}') OR
                            particular_payments.id is null) AND
                            `ffc`.`id` IN (#{collections.collect(&:collection_id).join(',')}) #{filter_conditions}"] + filter_values
      joins="LEFT JOIN `particular_payments`
                          ON particular_payments.finance_fee_particular_id = finance_fee_particulars.id
                 LEFT JOIN `particular_discounts`
                          ON particular_discounts.particular_payment_id = particular_payments.id
              INNER JOIN finance_fees ff
                          ON ff.id=particular_payments.finance_fee_id
              INNER JOIN finance_fee_collections ffc
                          ON ffc.id=ff.fee_collection_id"

      joins += filter_by_account ?
        " LEFT JOIN finance_transactions ON finance_transactions.id = particular_payments.finance_transaction_id
          LEFT JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.id = finance_transactions.id" : ""

      tax_select = ",(SELECT SUM(tax_amount)
                                 FROM tax_payments
                               WHERE tax_payments.taxed_entity_id = particular_payments.finance_fee_particular_id AND
                                           tax_payments.taxed_entity_type = 'FinanceFeeParticular' AND
                                           tax_payments.taxed_fee_id = particular_payments.finance_fee_id AND
                                           tax_payments.taxed_fee_type = 'FinanceFee') AS tax_paid"
      collection_and_particulars = FinanceFeeParticular.find(:all, :joins => joins, :conditions => conditions,
        :select => "finance_fee_particulars.name,
                           (SUM(particular_payments.amount)) AS amount_paid,
                           IFNULL(SUM(particular_discounts.discount),0) AS discount_paid,
                           ffc.id AS collection_id #{tax_select}",
        :group => "finance_fee_particulars.name,ffc.id").group_by(&:collection_id)

      collections.each do |b|
        total+=b.amount.to_f
        data << [b.collection_name, "","","", b.amount]
        data << ["", "#{t('particulars')}","#{t('discount_applied')}","#{t('amount_received')}", "#{t('total_amount')}"]
        discount_paid=0
        if collection_and_particulars[b.collection_id.to_s].present?
          collection_and_particulars[b.collection_id.to_s].each do |c|
            discount_paid+=c.discount_paid.to_f
            data << ["", c.name, precision_label(c.discount_paid.to_f),precision_label(c.amount_paid.to_f-c.discount_paid.to_f),precision_label(c.amount_paid.to_f)]
          end
        end
        data << ["", t('total_discount'),"","", precision_label(discount_paid.to_f)]
        data << ["", t('total_tax'),"","", precision_label(b.total_tax.to_f)] if b.tax_enabled?
        data << ["", t('total_fine_amount'),"","", precision_label(b.total_fine.to_f)]
        data << ""
      end
      data << ""
      data << [t('net_income'), "","","", precision_label(total)]
      return data
    end


    def finance_fee_course_data(params)
      data = []
      accounts_enabled, filter_by_account, account_id = account_filter params

      @fee_collection = FinanceFeeCollection.find(params[:id])
      #      @batch = Batch.find(params[:batch_id])

      data << [t('fees_collection'), @fee_collection.name]
      data << [t('start_date'), format_date(params[:start_date].to_date)]
      data << [t('end_date'), format_date(params[:end_date].to_date)]

      if filter_by_account
        joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id"
        filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        filter_select = ", ftrr.fee_account_id AS account_id"
        data << [t('fee_account_text'), "#{@account_name}"]
      else
        joins = ""
        filter_conditions = ""
        filter_values = []
        filter_select = ""
        data << [t('fee_account_text'), "#{@account_name}"] if accounts_enabled
      end

      data << [t('batch'), "", t('amount')]

      total = 0

      @course_ids = FinanceFeeCollection.all(
        :joins => "INNER JOIN finance_fees ff ON ff.fee_collection_id = finance_fee_collections.id
                        INNER JOIN batches b ON b.id = ff.batch_id
                        INNER JOIN courses ON courses.id = b.course_id
                        INNER JOIN finance_transactions ft ON ft.finance_id = ff.id #{joins}",
        :group => "ff.batch_id",
        :conditions => ["ft.finance_type = 'FinanceFee' and (ft.transaction_date BETWEEN ? AND ?) AND
                                 finance_fee_collections.id = ? #{filter_conditions}",
          params[:start_date], params[:end_date], params[:id]] + filter_values,
        :select => "b.id as batch_id, b.name as batch_name, b.course_id as course_id,
                          SUM(ft.amount) AS amount, courses.course_name AS course_name #{filter_select}").
        group_by(&:course_name)

      @course_ids.each do |course_name, batches|
        data << ""
        data << [course_name]
        batches.each do |b|
          data << ["", b.batch_name, precision_label(b.amount)]
          total += b.amount.to_f
        end
      end

      data << ""
      data << [t('net_income'), "", precision_label(total)]

      return data
    end

    def account_filter params, filter = true
      return (accounts_enabled = false) unless filter
      accounts_enabled = (Configuration.get_config_value("MultiFeeAccountEnabled").to_i == 1)
      return [false, false, false] unless accounts_enabled
      #      @accounts = @accounts_enabled ? FeeAccount.all : []
      filter_by_account = params[:fee_account_id].present?
      @account_id = params[:fee_account_id]
      @account_name = @account_id.present? ? (@account_id.to_i.zero? ? t('default_account') :
          FeeAccount.find_by_id(@account_id.to_i).try(:name)) : t('all_accounts')
      [accounts_enabled, filter_by_account, filter_by_account ? (params[:fee_account_id].to_i == 0 ? nil : params[:fee_account_id]) : false]
    end

    def finance_batch_fees_transaction_data(params)
      data = []

      accounts_enabled, filter_by_account, account_id = account_filter params

      @fee_collection = FinanceFeeCollection.find(params[:id])
      @batch = Batch.find(params[:batch_id])
      data << [t('fees_collection'), @fee_collection.name]
      data << [t('batch'), @batch.full_name]
      data << [t('start_date'), format_date(params[:start_date].to_date)]
      data << [t('end_date'), format_date(params[:end_date].to_date)]

      if filter_by_account
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        filter_select = ", finance_transaction_receipt_records.fee_account_id AS account_id"
        data << [t('fee_account_text'), "#{@account_name}"]
      else
        filter_conditions = ""
        filter_values = []
        filter_select = ""
        data << [t('fee_account_text'), "#{@account_name}"] if accounts_enabled
      end

      data << [t('student_name'), t('amount'), t('receipt_no'), t('date_text'), t('payment_mode'), t('payment_notes')]
      total = 0

      @transactions = FinanceTransaction.all(
        :select => "finance_transactions.* #{filter_select},
                          CONCAT(IFNULL(transaction_receipts.receipt_sequence,''),
                                        transaction_receipts.receipt_number) AS receipt_no",
        :joins => "INNER JOIN finance_transaction_receipt_records
                                 ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id
                        INNER JOIN transaction_receipts ON transaction_receipts.id = finance_transaction_receipt_records.transaction_receipt_id
                        INNER JOIN fee_transactions ON finance_transactions.id = fee_transactions.finance_transaction_id
                        INNER JOIN finance_fees ON finance_fees.id = fee_transactions.finance_fee_id",
        :conditions => ["finance_fees.batch_id = ? and finance_fees.fee_collection_id = ? and
                                 (finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          params[:batch_id], params[:id], params[:start_date], params[:end_date]] + filter_values)

      total = 0

      @transactions.each do |f|
        row = []
        student = f.student_payee
        row << "#{student.full_name}(#{student.admission_no})"
        row << precision_label(f.amount)
        row << f.receipt_no
        row << f.transaction_date
        if f.reference_no.present?
          row << ["#{f.payment_mode}-#{f.reference_no}"]
        else
          row<< f.payment_mode
        end
        row<< f.payment_note
        total += f.amount.to_f
        data << row
      end
      data << ""
      data << [t('net_income'), precision_label(total)]
      return data
    end


    def salary_with_department_data(params)
      data=[]
      data << [t('employee_salary_report')]
      data << [t('start_date'), format_date(params[:start_date].to_date)]
      data << [t('end_date'), format_date(params[:end_date].to_date)]
      data << [t('department'), t('amount')]
      archived_employee_salary=FinanceTransaction.all(:select => "sum(finance_transactions.amount) as amount,employee_departments.id,employee_departments.name", :conditions => {:title => "Monthly Salary", :transaction_date => params[:start_date]..params[:end_date]}, :joins => "INNER JOIN archived_employees on archived_employees.former_id= finance_transactions.payee_id INNER JOIN employee_departments on employee_departments.id= archived_employees.employee_department_id", :group => "employee_departments.id", :order => "employee_departments.name").group_by(&:id)
      employee_salary=FinanceTransaction.all(:select => "sum(finance_transactions.amount) as amount,employee_departments.id,employee_departments.name", :conditions => {:title => "Monthly Salary", :transaction_date => params[:start_date]..params[:end_date]}, :joins => "INNER JOIN employees on employees.id= finance_transactions.payee_id LEFT OUTER JOIN employee_departments on employee_departments.id= employees.employee_department_id", :group => "employee_departments.id", :order => "employee_departments.name").group_by(&:id)
      @departments=EmployeeDepartment.ordered(:select => "id, name")
      @departments.each do |d|
        total=0.0
        total+=archived_employee_salary[d.id].nil? ? 0 : archived_employee_salary[d.id][0].amount.to_f
        total+=employee_salary[d.id].nil? ? 0 : employee_salary[d.id][0].amount.to_f
        d['amount']=total
      end
      total=0
      @departments.each_with_index do |d, i|
        data <<[d.name, precision_label(d.amount)]
        total+=d.amount
      end
      data << ""
      data << [t('net_expenses'), precision_label(total)]
      return data
    end


    def income_details_csv(params)
      data=[]
      income_category = FinanceTransactionCategory.find(params[:id])
      filter_by_account = income_category.present? ? income_category.is_income : true

      accounts_enabled, filter_by_account, account_id = account_filter params, filter_by_account

      ft_joins = "LEFT JOIN finance_transaction_receipt_records ftrr
                                  ON ftrr.finance_transaction_id = finance_transactions.id
                        LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id"
      if filter_by_account
        filter_conditions = "AND (ftrr.id IS NOT NULL AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ? )"
        filter_values = [account_id]
      else
        filter_conditions = ""
        filter_values = []
      end

      if income_category.present? and income_category.name == 'Refund'
        ft_joins = "INNER JOIN fee_refunds fr ON fr.finance_transaction_id = finance_transactions.id
                    INNER JOIN finance_fees ff ON ff.id = fr.finance_fee_id
                    INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
                     LEFT JOIN fee_accounts fa On fa.id = ffc.fee_account_id"
        cond = "(fa.id IS NULL OR fa.is_deleted = false) AND "
      else
        cond = ""
      end

      incomes = income_category.finance_transactions.find(:all, :joins => ft_joins,
        :select => "finance_transactions.*,
                    IF(#{income_category.is_income},
                       IFNULL(CONCAT(IFNULL(tr.receipt_sequence,''), tr.receipt_number),'-'), '') AS receipt_no",
        :conditions => ["#{cond} transaction_date BETWEEN ? AND ? #{filter_conditions}", params[:start_date],
          params[:end_date]] + filter_values)

      data << (income_category.is_income ? t('income') : t('expense'))
      data<< income_category.name
      data << [t('start_date'), format_date(params[:start_date].to_date)]
      data << [t('end_date'), format_date(params[:end_date].to_date)]
      # clarify if we need to show filter account name in csv ( since we dont show in view)
      #      data << [t('fee_account_text'), "#{@account_name}"] if accounts_enabled
      data << ""

      row = []
      row << t('name')
      row << t('description')
      row << t('amount')
      row << t('transaction_date')
      row << (income_category.is_income ? t('receipt_no') : t('voucher_no'))
      data << row

      total = 0
      incomes.each do |i|
        row = []
        row << i.title.gsub("&#x200E;", '')
        row << i.description
        row << precision_label(i.amount)
        total += i.amount.to_f
        row << format_date(i.transaction_date)
        if income_category.is_income
          row << i.receipt_no
        else
          row << i.voucher_no
        end
        data << row
      end

      data << ""

      if income_category.is_income
        data << [t('net_income'), "", precision_label(total)]
      else
        data << [t('net_expenses'), "", precision_label(total)]
      end
      return data
    end

    def compare_finance_transactions_date(params)
      fixed_category_name
      @hr = Configuration.find_by_config_value("HR")
      @start_date = (params[:start_date]).to_date
      @end_date = (params[:end_date]).to_date
      @start_date2 = (params[:start_date2]).to_date
      @end_date2 = (params[:end_date2]).to_date
      accounts_enabled, filter_by_account, account_id = account_filter params, true
      common_joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id
                   LEFT JOIN fee_accounts fa ON fa.id = finance_transaction_receipt_records.fee_account_id"
      ft_joins = "INNER JOIN finance_transactions ON finance_transactions.category_id = finance_transaction_categories.id
                  #{common_joins}"
      joins = "INNER JOIN finance_transaction_categories ON finance_transaction_categories.id = finance_transactions.category_id
                  #{common_joins}"

      common_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "

      if filter_by_account
        filter_conditions = " AND #{common_conditions} AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      other_category_ids = @fixed_cat_ids.join(",")
      @other_transaction_categories = FinanceTransactionCategory.all(:joins => ft_joins,
        :group => "finance_transactions.category_id",
        :select => "finance_transaction_categories.name, finance_transaction_categories.id AS cat_id, is_income,
                    IFNULL(SUM(CASE WHEN transaction_date >= '#{@start_date}' AND transaction_date <= '#{@end_date}'
                                    THEN finance_transactions.amount end),0) AS first,
                    IFNULL(SUM(CASE WHEN transaction_date >= '#{@start_date2}' AND transaction_date <= '#{@end_date2}'
                                    THEN finance_transactions.amount end),0) AS second",
        :conditions => ["#{common_conditions} AND category_id NOT IN (#{other_category_ids}) #{filter_conditions}"] + filter_values)
      @salary=FinanceTransaction.get_total_amount("Salary", [@start_date, @end_date], [@start_date2, @end_date2],
        {:joins => common_joins, :conditions => common_conditions})
      @donations_total=FinanceTransaction.get_total_amount("Donation", [@start_date, @end_date], [@start_date2, @end_date2],
        {:joins => common_joins, :conditions => common_conditions})
      @transactions_fees=FinanceTransaction.get_total_amount("Fee", [@start_date, @end_date], [@start_date2, @end_date2],
        {:joins => common_joins, :conditions => common_conditions})
      @category_transaction_totals = {}
      plugin_categories=FedenaPlugin::FINANCE_CATEGORY.collect { |p_c| p_c[:category_name] if FedenaPlugin.can_access_plugin?("#{p_c[:plugin_name]}") }
      @plugin_amount=FinanceTransaction.find(:all,
        :conditions => ["#{common_conditions} AND finance_transaction_categories.name in(?) #{filter_conditions}",
          plugin_categories] + filter_values,
        :joins => joins, :group => 'finance_transaction_categories.name',
        :select => "ifnull(sum(case when transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}' then finance_transactions.amount end),0) as amount_1,ifnull(sum(case when transaction_date >= '#{@start_date2}' and transaction_date <= '#{@end_date2}' then finance_transactions.amount end),0)  as amount_2,finance_transaction_categories.is_income as is_income, finance_transaction_categories.name as pl_name").group_by(&:pl_name)
      income_total = 0
      expenses_total = 0
      income_total_2 = 0
      expenses_total_2 = 0

      # advance fees comparison
      w_c_amount, w_c_amount2, w_d_amount, w_d_amount2 = AdvanceFeeCategory.comparison_for_advance_fees(@start_date, @end_date, @start_date2, @end_date2, (account_id.present? ? account_id : nil))


      data=[]
      data << t('transaction_comparision')
      data << [t('start_date'), format_date(@start_date), t('to'), format_date(@end_date)]
      data << [t('end_date'), format_date(@start_date2), t('to'), format_date(@end_date2)]
      data << ""
      data << [t('finance_categories'), "#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}", "#{format_date(@start_date2)} #{t('to')} #{format_date(@end_date2)}"]
      data << ""
      data << t('income')
      data << ""
      data<<[t('donations'), precision_label(@donations_total.first), precision_label(@donations_total.second)]
      income_total +=@donations_total.first.to_f
      income_total_2 +=@donations_total.second.to_f
      data <<[t('student_fees'), precision_label(@transactions_fees.first), precision_label(@transactions_fees.second)]
      income_total +=@transactions_fees.first.to_f
      income_total_2 +=@transactions_fees.second.to_f
      data <<[t('advance_fees_credit_text'), precision_label(w_c_amount), precision_label(w_c_amount2)]
      income_total +=w_c_amount.to_f
      income_total_2 +=w_c_amount2.to_f
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        row=[]
        plugin_present="#{category[:plugin_name]}".present? ? FedenaPlugin.can_access_plugin?("#{category[:plugin_name]}") : true
        if plugin_present == true
          unless @plugin_amount[category[:category_name].camelize].nil?
            if @plugin_amount[category[:category_name].camelize].first.is_income.to_f==1
              row << "#{t(category[:category_name].underscore.gsub(/\s+/, '_')+'_fees')}"
              row << precision_label(@plugin_amount[category[:category_name].camelize].first.amount_1)
              row << precision_label(@plugin_amount[category[:category_name].camelize].first.amount_2)
              income_total +=@plugin_amount[category[:category_name].camelize].first.amount_1.to_f
              income_total_2 +=@plugin_amount[category[:category_name].camelize].first.amount_2.to_f
              data << row
            end
          end
        end
      end
      @other_transaction_categories.each_with_index do |t, i|
        if t.is_income
          row= []
          row << t.name
          row << precision_label(t.first)
          row << precision_label(t.second)
          income_total +=t.first.to_f
          income_total_2 +=t.second.to_f
          data << row
        end
      end
      data << [t('total_income'), precision_label(income_total), precision_label(income_total_2)]
      data << ""
      data << [t('expenses')]
      data << ""
      data << [t('employee_salary'), precision_label(@salary.first), precision_label(@salary.second)]
      expenses_total+=@salary.first.to_f
      expenses_total_2 +=@salary.second.to_f
      data <<[t('advance_fees_debit_text'), precision_label(w_d_amount), precision_label(w_d_amount2)]
      expenses_total +=w_d_amount.to_f
      expenses_total_2 +=w_d_amount2.to_f
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        row=[]
        plugin_present="#{category[:plugin_name]}".present? ? FedenaPlugin.can_access_plugin?("#{category[:plugin_name]}") : true
        if plugin_present == true
          unless @plugin_amount[category[:category_name].camelize].nil?
            unless @plugin_amount[category[:category_name].camelize].first.is_income.to_f==1
              row << "#{t(category[:category_name].underscore.gsub(/\s+/, '_')+'_account')}"
              row << precision_label(@plugin_amount[category[:category_name].camelize].first.amount_1)
              row << precision_label(@plugin_amount[category[:category_name].camelize].first.amount_2)
              expenses_total +=@plugin_amount[category[:category_name].camelize].first.amount_1.to_f
              expenses_total_2 +=@plugin_amount[category[:category_name].camelize].first.amount_2.to_f
              data << row
            end
          end
        end
      end
      @other_transaction_categories.each_with_index do |t, i|
        unless t.is_income
          row= []
          row << t.name
          row << precision_label(t.first)
          row << precision_label(t.second)
          expenses_total +=t.first.to_f
          expenses_total_2 +=t.second.to_f
          data << row
        end
      end
      grand_total_1=income_total-expenses_total
      grand_total_2=income_total_2-expenses_total_2
      data << [t('total_expenses'), precision_label(expenses_total), precision_label(expenses_total_2)]
      data << [t('grand_total'), precision_label(grand_total_1), precision_label(grand_total_2)]
      return data
    end

    def fixed_category_name
      @cat_names = ['Fee', 'Salary', 'Donation']
      @plugin_cat = []
      FedenaPlugin::FINANCE_CATEGORY.each do |category|
        @cat_names << "#{category[:category_name]}"
        @plugin_cat << "#{category[:category_name]}"
      end
      @fixed_cat_ids = FinanceTransactionCategory.find(:all, :conditions => {:name => @cat_names}).collect(&:id)
    end

    def group_wise_employee_payslips_csv(data_hash)
      data ||= Array.new
      data << ["#{data_hash[:payroll_group].name} - #{data_hash[:payroll_group].salary_type_value} - #{data_hash[:payroll_group].payment_period_value}"]
      data << ["#{t('pay_period')}", "#{data_hash[:payslips_date_range].date_range}"]
      data << ["#{t('payslip_generated')}", "#{data_hash[:payslips].length} #{t('of')} #{data_hash[:payroll_group].employees.count} #{t('employees')}"]
      data << ["#{t('approved')}", data_hash[:approved]]
      data << ["#{t('pending')}", data_hash[:pending]]
      data << ["#{t('rejected')}", data_hash[:rejected]]
      data << ["#{t('total_net_pay')}", precision_label(data_hash[:total_cost])]

      row = ["", "", "", "#{t('earnings')}"]
      data_hash[:earnings].each { |e| row << "" }
      row += ["", "", "#{t('deductions')}"]
      data << row

      header = ["#{t('status')}", "#{t('employee_text')}", "#{t('department')}"]
      data_hash[:earnings].each { |e| header << e.name }
      header += ["#{t('individual_earnings')}", "#{t('others')}", "#{t('total_salary')}"]
      data_hash[:deductions].each { |e| header << e.name }
      header << "#{t('lop_short')}" if data_hash[:is_lop]
      header += ["#{t('individual_deductions')}", "#{t('others')}", "#{t('total_deduction')}", "#{t('net_salary')}"]
      data << header

      data_hash[:payslips_list].each do |p|
        row = [p.payslip_status, "#{p.full_name} (#{p.employee_number})", p.dept_name]
        earnings = 0
        categories = p.employee_payslip_categories
        data_hash[:earnings].each do |e|
          cat = categories.detect { |c| c.payroll_category_id == e.id }
          if cat.present?
            row << precision_label(cat.amount)
            earnings += cat.amount.to_f
          else
            row << '-'
          end
        end
        if p.individual_earnings.present?
          ind_ear = []
          ind_ear_total = p.individual_earnings_total
          p.individual_earnings.each do |ie|
            ind_ear << "#{ie.name} : #{precision_label(ie.amount)}"
          end
          row << ind_ear.join("\n")
          row << ind_ear_total
          earnings += ind_ear_total.to_f
        else
          row += ["", precision_label(0.0)]
        end
        row << precision_label(earnings)

        deductions = 0
        data_hash[:deductions].each do |e|
          cat = categories.detect { |c| c.payroll_category_id == e.id }
          if cat.present?
            row << precision_label(cat.amount)
            deductions += cat.amount.to_f
          else
            row << '-'
          end
        end
        if data_hash[:is_lop]
          row << (p.lop.nil? ? '-' : "#{p.lop}(#{p.days_count+t('days_text', {:count => p.days_count})})")
        end
        if p.individual_deductions.present?
          ind_ded = []
          ind_ded_total = p.individual_deductions_total
          p.individual_deductions.each do |id|
            ind_ded << "#{id.name} : #{precision_label(id.amount)}"
          end
          row << ind_ded.join("\n")
          row << ind_ded_total
          deductions += ind_ded_total.to_f
        else
          row += ["", precision_label(0.0)]
        end
        row << precision_label(deductions)
        row << precision_label(p.net_pay)
        data << row
      end
      return data
    end

    def gradebook_subject_report_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "gradebook_subject_report"
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def gradebook_consolidated_reports_data(params)
      data_hash ||= Hash.new
      data_hash[:method] = "gradebook_consolidated_reports"
      data_hash[:parameters] = params
      find_report_type(data_hash)
    end

    def gradebook_consolidated_reports_csv(data_hash)
      type = data_hash[:parameters][:exam].split('_').first
      batch = Batch.find(data_hash[:parameters][:batch])
      exam = AssessmentGroup.find(data_hash[:parameters][:exam].split('_').last.to_i) if type == "exam"
      exam = AssessmentPlan.find(data_hash[:parameters][:exam].split('_').last.to_i) if type == "plan"
      exam = AssessmentTerm.find(data_hash[:parameters][:exam].split('_').last.to_i) if type == "term"
      data ||= Array.new
      data<<"Gradebook #{t('consolidated_reports')}"
      data<<["#{t('academic_year').titleize}",batch.academic_year.name]
      data<<[t('course'),Course.find(data_hash[:parameters][:course]).course_name]
      data<<[t('batch'),batch.name]
      data<<[t('exam_text'),exam.name]
      #hhhh
      data<<[t('type'),map_report_type(data_hash[:parameters][:type])]
      data<<""
      if ["exam","planner","obtained_grade","percent"].include? data_hash[:parameters][:type] and type == "exam"
        data = consolidated_planner_score_csv(data,data_hash,exam,batch)
      elsif data_hash[:parameters][:type] == "attribute"
        data = consolidated_attribute_report_csv(data,data_hash,exam,batch)
      elsif data_hash[:parameters][:type] == "obtained_score"
        data = consolidated_activity_report_csv(data,data_hash,exam,batch)
      elsif type == "term"
        data = consolidated_term_report_csv(data,data_hash,batch)
      elsif type == "plan"
        data = consolidated_plan_report_csv(data,data_hash,batch)
      end
      data
    end

    def map_report_type(type)
      case type
      when "exam"
        exam_type = t('exam_score')
      when "planner"
        exam_type = t('planner_score')
      when "obtained_grade"
        exam_type = t('obtained_grade')
      when "percent"
        exam_type = t('percentage')
      when "attribute"
        exam_type = t('attribute_score')
      when "obtained_score"
        exam_type = t('obtained_score')
      end
      exam_type
    end

    def consolidated_plan_report_csv(data,data_hash,batch)
      id = data_hash[:parameters][:exam].split('_').last.to_i
      roll_num_enabled = Configuration.enabled_roll_number?
      row = []
      subjects = []
      report_generator = GradebookDetailedReportGenerator.new(data_hash[:parameters])
      report = report_generator.create_report
      score_hash = report.fetch_report_data.dup
      header_hash = report.fetch_report_headers
      terms = AssessmentPlan.find(id).assessment_terms
      terms.each do |term|
        subjects[term.id] = Subject.all(:conditions=>["id in (?) and batch_id = ? and !no_exams and !is_deleted",header_hash[term.id].keys.uniq, batch])
      end
      students = batch.effective_students
      terms.each do |term|
        subjects[term.id].each do |sub|
          row<<"#{sub.name}(#{term.name})"
          (1...header_hash[term.id][sub.id.to_s].count).each{row<<""}
        end
      end
      row = ["","",""]+row
      data<<row
      if roll_num_enabled
        row = [t('no_text'),t('single_student'),t('roll_nos')]
      else
        row = [t('no_text'),t('single_student'),t('admission_no')]
      end
      terms.each do |term|
        subjects[term.id].each do |sub|
          header_hash[term.id][sub.id.to_s].each do |ag|
            if data_hash[:parameters][:type] == "planner" or ag.ag_type == "DerivedAssessmentGroup" or !ag.is_single_mark_entry or data_hash[:parameters][:type] == "percent"
              overrided_mark = report.over_marks[term.id][ag.ag_id.to_i].find{|obj| obj.subject_code == sub.code } if report.over_marks[term.id][ag.ag_id.to_i].present?
              if overrided_mark.present?
                unless ag.scoring_type == "2"
                  row<<"#{ag.ag_name}(#{overrided_mark.maximum_marks})"
                else
                  row<<"#{ag.ag_name}"
                end
              else
                unless ag.scoring_type == "2"
                  row<<"#{ag.ag_name}(#{ag.max_mark})"
                else
                  row<<"#{ag.ag_name}"
                end
              end
            else
              unless ag.scoring_type == "2"
                row<<"#{ag.ag_name}(#{report.exam_max_marks[term.id][sub.id][ag.ag_id.to_i]})"
              else
                row<<"#{ag.ag_name}"
              end
            end
          end
        end
      end

      if data_hash[:parameters][:total] == "1"
        row<<t('total')
        row<<t('percentage')
        aggregate_hash = report.calculate_total
      end
      if data_hash[:parameters][:rank] == "1"
        row<<t('rank')
        rank = report.find_rank
      end
      data<<row
      students.each_with_index do |student,i|
        row = []
        row<<i+1
        row<<student.full_name
        if roll_num_enabled
          row<<student.roll_number
        else
          row<<student.admission_no
        end
        terms.each do |term|
          subjects[term.id].each do |sub|
            header_hash[term.id][sub.id.to_s].collect(&:ag_id).each do |ag_id|
              row<<(score_hash[sub.id][student.s_id][term.id][ag_id.to_i][:mark].present? ? score_hash[sub.id][student.s_id][term.id][ag_id.to_i][:mark] : "-")
            end
          end
        end
        if data_hash[:parameters][:total] == "1"
          row<<(aggregate_hash[student.s_id][:total].present? ? aggregate_hash[student.s_id][:total] : "-")
          row<<(aggregate_hash[student.s_id][:percentage].present? ? "#{precision_label(aggregate_hash[student.s_id][:percentage])}%" : "-")
        end
        if data_hash[:parameters][:rank] == "1"
          row<<(rank[student.s_id][:rank].present? ? rank[student.s_id][:rank] : "-")
        end
        data<<row
      end
      cell = []
      if data_hash[:parameters][:highest] == "1"
        row = ["","","#{t('highest')}"]
        highest = report.find_highest
        terms.each do |term|
          subjects[term.id].each do |sub|
            header_hash[term.id][sub.id.to_s].collect {|x| x.ag_id.to_i}.each do |ag_id|
              cell<<(highest[sub.id][term.id][ag_id].present? ?  highest[sub.id][term.id][ag_id].round(2) : "-")
              cell<<"%"  if data_hash[:parameters][:type] == "percent" and highest[sub.id][term.id][ag_id].present?
              row<<cell
              cell = []
            end
          end
        end
        data<<row
      end
      if data_hash[:parameters][:average] == "1"
        avg_hash = report.calculate_average.dup
        row = ["","","#{t('average')}"]
        terms.each do |term|
          subjects[term.id].each do |sub|
            header_hash[term.id][sub.id.to_s].collect {|x| x.ag_id.to_i}.each do |ag_id|
              cell<<(avg_hash[sub.id][term.id][ag_id].present? ?  avg_hash[sub.id][term.id][ag_id].round(2) : "-")
              cell<<"%"  if data_hash[:parameters][:type] == "percent" and avg_hash[sub.id][term.id][ag_id].present?
              row<<cell
              cell = []
            end
          end
        end
        data<<row
      end
      data
    end

    def consolidated_term_report_csv(data,data_hash,batch)
      roll_num_enabled = Configuration.enabled_roll_number?
      row = []
      report_generator = GradebookDetailedReportGenerator.new(data_hash[:parameters])
      report = report_generator.create_report
      score_hash = report.fetch_report_data.dup
      header_hash = report.fetch_report_headers
      subjects = Subject.all(:conditions=>["id in (?) and !no_exams",header_hash.keys])
      students = batch.effective_students
      subjects.each do |sub|
        row<<sub.name
        (1...header_hash[sub.id.to_s].count).each{row<<""}
      end
      row = ["","",""]+row
      data<<row
      if roll_num_enabled
        row = [t('no_text'),t('single_student'),t('roll_nos')]
      else
        row = [t('no_text'),t('single_student'),t('admission_no')]
      end
      subjects.each do |sub|
        header_hash[sub.id.to_s].each do |ag|
          overrided_mark = report.over_marks[ag.ag_id.to_i].find{|obj| obj.subject_code == sub.code } if report.over_marks[ag.ag_id.to_i].present?
          unless ag.scoring_type == "2"
            if data_hash[:parameters][:type] == "planner" or ag.ag_type == "DerivedAssessmentGroup" or !ag.is_single_mark_entry or data_hash[:parameters][:type] == "percent"
              if overrided_mark.present?
                row<<"#{ag.ag_name}(#{overrided_mark.maximum_marks})"
              else
                row<<"#{ag.ag_name}(#{ag.max_mark})"
              end
            else
              row<<"#{ag.ag_name}(#{report.exam_max_marks[sub.id][ag.ag_id.to_i]})"
            end
          else
            row<<"#{ag.ag_name}"
          end
        end
      end
      if data_hash[:parameters][:total] == "1"
        row<<t('total')
        row<<t('percentage')
        aggregate_hash = report.calculate_total
      end
      if data_hash[:parameters][:rank] == "1"
        row<<t('rank')
        rank = report.find_rank
      end
      data<<row
      students.each_with_index do |student,i|
        row = []
        row<<i+1
        row<<student.full_name
        if roll_num_enabled
          row<<student.roll_number
        else
          row<<student.admission_no
        end
        subjects.each do |sub|
          header_hash[sub.id.to_s].collect(&:ag_id).each do |ag_id|
            row<<(score_hash[ag_id.to_i][sub.id][student.s_id][:mark].present? ? score_hash[ag_id.to_i][sub.id][student.s_id][:mark] : "-")
          end
        end
        if data_hash[:parameters][:total] == "1"
          row<<(aggregate_hash[student.s_id][:total].present? ? aggregate_hash[student.s_id][:total] : "-")
          row<<(aggregate_hash[student.s_id][:percentage].present? ? "#{precision_label(aggregate_hash[student.s_id][:percentage])}%" : "-")
        end
        if data_hash[:parameters][:rank] == "1"
          row<<(rank[student.s_id][:rank].present? ? rank[student.s_id][:rank] : "-")
        end
        data<<row
      end
      cell = []
      if data_hash[:parameters][:highest] == "1"
        row = ["","","#{t('highest')}"]
        highest = report.find_highest
        subjects.each do |subject|
          header_hash[subject.id.to_s].collect {|x| x.ag_id.to_i}.each do |ag_id|
            cell<<(highest[subject.id][ag_id].present? ? highest[subject.id][ag_id].round(2) : "-")
            cell<<"%"  if data_hash[:parameters][:type] == "percent" and highest[subject.id][ag_id].present?
            row<<cell
            cell = []
          end
        end
        data<<row
      end
      cell = []
      if data_hash[:parameters][:average] == "1"
        avg_hash = report.calculate_average
        row = ["","","#{t('average')}"]
        subjects.each do |subject|
          header_hash[subject.id.to_s].collect {|x| x.ag_id.to_i}.each do |ag_id|
            cell<<(avg_hash[subject.id][ag_id].is_a?(Hash) ? "-" : precision_label(avg_hash[subject.id][ag_id]))
            cell<<"%"  if data_hash[:parameters][:type] == "percent" and avg_hash[subject.id][ag_id].present?
            row<<cell
            cell = []
          end
        end
        data<<row
      end
      data
    end

    def consolidated_activity_report_csv(data,data_hash,assessment_group,batch)
      roll_num_enabled = Configuration.enabled_roll_number?
      row = []
      agb = AssessmentGroupBatch.first(:conditions=>["batch_id=? and assessment_group_id=?",batch.id,assessment_group.id])
      students = batch.effective_students
      report_generator = GradebookReportGenerator.new(data_hash[:parameters],agb.id)
      report = report_generator.create_report
      score_hash = report.fetch_report_data.dup
      header_hash = report.fetch_report_headers
      if roll_num_enabled
        row = [t('no_text'),t('single_student'),t('roll_nos')]
      else
        row = [t('no_text'),t('single_student'),t('admission_no')]
      end
      header_hash[:names].each do |activity_name|
        row<<activity_name
      end
      data<<row
      students.each_with_index do |student,i|
        row = []
        row<<i+1
        row<<student.full_name
        if roll_num_enabled
          row<<student.roll_number
        else
          row<<student.admission_no
        end
        header_hash[:ids].each do |id|
          row<<(score_hash[id][student.s_id][:grade].present? ? score_hash[id][student.s_id][:grade] : "-")
        end
        data<<row
      end
      data
    end

    def consolidated_attribute_report_csv(data,data_hash,assessment_group,batch)
      roll_num_enabled = Configuration.enabled_roll_number?
      row = []
      agb = AssessmentGroupBatch.first(:conditions=>["batch_id=? and assessment_group_id=?",batch.id,assessment_group.id])
      subjects = Subject.all(:joins=>:subject_attribute_assessments,:conditions=>["assessment_group_batch_id=? and !no_exams",agb.id])
      subjects = subjects.sort_by{|sb| sb.priority.to_i}
      students = batch.effective_students
      report_generator = GradebookReportGenerator.new(data_hash[:parameters],agb.id)
      report = report_generator.create_report
      score_hash = report.fetch_report_data.dup
      header_hash = report.fetch_report_headers
      subjects.each do |sub|
        row<<sub.name
        (1...header_hash[sub.id].count).each{row<<""}
      end
      row = ["","",""]+row
      data<<row
      if roll_num_enabled
        row = [t('no_text'),t('single_student'),t('roll_nos')]
      else
        row = [t('no_text'),t('single_student'),t('admission_no')]
      end
      subjects.each do |sub|
        header_hash[sub.id].each do |attr|
          row<<"#{attr.name}(#{attr.maximum_marks})"
        end
      end
      if data_hash[:parameters][:total] == "1"
        row<<t('total')
        row<<t('percentage')
        aggregate_hash = report.calculate_total
      end
      if data_hash[:parameters][:rank] == "1"
        row<<t('rank')
        rank = report.find_rank
      end
      data<<row
      students.each_with_index do |student,i|
        row = []
        row<<i+1
        row<<student.full_name
        if roll_num_enabled
          row<<student.roll_number
        else
          row<<student.admission_no
        end
        subjects.each do |sub|
          header_hash[sub.id].each do |attr|
            case assessment_group.scoring_type
            when 1
              row<<(score_hash[sub.id][student.s_id][attr.id][:mark].present? ? score_hash[sub.id][student.s_id][attr.id][:mark] : "-")
            when 2
              row<<(score_hash[sub.id][student.s_id][attr.id][:grade].present? ? score_hash[sub.id][student.s_id][attr.id][:grade] : "-")
            when 3
              row<<(score_hash[sub.id][student.s_id][attr.id].present? ? "#{score_hash[sub.id][student.s_id][attr.id][:mark]}(#{score_hash[sub.id][student.s_id][attr.id][:grade]})" : "-")
            end
          end
        end
        if data_hash[:parameters][:total] == "1"
          row<<(aggregate_hash[student.s_id][:total].present? ? aggregate_hash[student.s_id][:total] : "-")
          row<<(aggregate_hash[student.s_id][:percentage].present? ? "#{precision_label(aggregate_hash[student.s_id][:percentage])}%" : "-")
        end
        if data_hash[:parameters][:rank] == "1"
          row<<(rank[student.s_id][:rank].present?? rank[student.s_id][:rank] : "-")
        end
        data<<row
      end
      if data_hash[:parameters][:highest] == "1"
        highest = report.find_highest
        row = ["","","#{t('highest')}"]
        subjects.each do |subject|
          header_hash[subject.id].each do |attr|
            if data_hash[:parameters][:type] == "percent"
              row << (highest[subject.id][attr.id].present? ? "#{highest[subject.id][attr.id]}%" : "-")
            else
              row << (highest[subject.id][attr.id].present? ? highest[subject.id][attr.id] : "-")
            end
          end
        end
        data<<row
      end
      if data_hash[:parameters][:average] == "1"
        average = report.calculate_average
        row = ["","","#{t('average')}"]
        subjects.each do |subject|
          header_hash[subject.id].each do |attr|
            if data_hash[:parameters][:type] == "percent"
              row << (average[subject.id][attr.id].present? ? "#{average[subject.id][attr.id].round(2)}%" : "-")
            else
              row << (average[subject.id][attr.id].present? ? average[subject.id][attr.id].round(2) : "-")
            end
          end
        end
        data<<row
      end
      data
    end

    def consolidated_planner_score_csv(data,data_hash,assessment_group,batch)
      roll_num_enabled = Configuration.enabled_roll_number?
      row = []
      agb = AssessmentGroupBatch.first(:conditions=>["batch_id=? and assessment_group_id=?",batch.id,assessment_group.id])
      subjects = Subject.all(:joins=>:converted_assessment_marks,:conditions=>["assessment_group_batch_id=? and !no_exams",agb.id],:group=>:name)
      subjects = subjects.sort_by{|sb| sb.priority.to_i}
      students = batch.effective_students
      report_generator = GradebookReportGenerator.new(data_hash[:parameters],agb.id)
      report = report_generator.create_report
      score_hash = report.fetch_report_data.dup
      subjects.each do |sub|
        row<<sub.name
      end
      row = ["","",""]+row
      data<<row
      if roll_num_enabled
        row = [t('no_text'),t('single_student'),t('roll_nos')]
      else
        row = [t('no_text'),t('single_student'),t('admission_no')]
      end
      subjects.each do |sub|
        if data_hash[:parameters][:type] == "exam"
          row<<(report.headers[sub.id].present? ? report.headers[sub.id] : "#{t('grade')}")
        else
          row<<(assessment_group.maximum_marks.present? ? assessment_group.maximum_marks_for(sub,batch.course) : "#{t('grade')}")
        end
      end
      if data_hash[:parameters][:total] == "1"
        row<<t('total')
        row<<t('percentage')
        aggregate_hash = report.calculate_total
      end
      if data_hash[:parameters][:rank] == "1"
        row<<t('rank')
        rank = report.find_rank
      end
      data<<row
      students.each_with_index do |student,i|
        row = []
        row<<i+1
        row<<student.full_name
        if roll_num_enabled
          row<<student.roll_number
        else
          row<<student.admission_no
        end
        subjects.each do |subject|
          cell = []
          if data_hash[:parameters][:type] == "percent"
            cell << (score_hash[subject.id][student.s_id].present? ? "#{score_hash[subject.id][student.s_id][:mark]}%" : "-") if ([1,3].include? assessment_group.scoring_type)
          else
            cell << (score_hash[subject.id][student.s_id][:grade].present? ? (score_hash[subject.id][student.s_id][:mark].present? ? score_hash[subject.id][student.s_id][:mark] : score_hash[subject.id][student.s_id][:grade]) : (score_hash[subject.id][student.s_id][:mark].present? ? score_hash[subject.id][student.s_id][:mark] : "-")) if ([1,3].include? assessment_group.scoring_type)
            if (assessment_group.scoring_type == 3) and score_hash[subject.id][student.s_id][:grade].present?
              cell<<"(#{score_hash[subject.id][student.s_id][:grade]})"
            elsif (assessment_group.scoring_type == 2)
              cell << (score_hash[subject.id][student.s_id][:grade].present? ? score_hash[subject.id][student.s_id][:grade] : "-")
            end
          end
          row<<cell
        end
        if data_hash[:parameters][:total] == "1"
          row<<(aggregate_hash[student.s_id][:total].present?? aggregate_hash[student.s_id][:total] : "-")
          row<<(aggregate_hash[student.s_id][:percentage].present?? "#{precision_label(aggregate_hash[student.s_id][:percentage])}%" : "-")
        end
        if data_hash[:parameters][:rank] == "1"
          row<<(rank[student.s_id][:rank].present? ? rank[student.s_id][:rank] : "-")
        end
        data<<row
      end
      if data_hash[:parameters][:highest] == "1"
        highest = report.find_highest
        row = ["","","#{t('highest')}"]
        subjects.each do |subject|
          if data_hash[:parameters][:type] == "percent"
            row << (highest[subject.id].present? ? "#{highest[subject.id]}%" : "-")
          else
            row << (highest[subject.id].present? ? highest[subject.id] : "-")
          end
        end
        data<<row
      end
      if data_hash[:parameters][:average] == "1"
        average = report.calculate_average
        row = ["","","#{t('average')}"]
        subjects.each do |subject|
          if data_hash[:parameters][:type] == "percent"
            row << (average[subject.id].present? ? "#{average[subject.id].to_f.round(2)}%" : "-")
          else
            row << (average[subject.id].present? ? average[subject.id].to_f.round(2) : "-")
          end
        end
        data<<row
      end
      data
    end

    def gradebook_subject_report_csv(data_hash)
      @assessment_group = AssessmentGroup.find data_hash[:parameters][:exam]
      batch = Batch.find(data_hash[:parameters][:batch])
      data ||= Array.new
      data<<"Gradebook #{t('subject_reports')}"
      data<<["#{t('academic_year').titleize}",batch.academic_year.name]
      data<<[t('course'),Course.find(data_hash[:parameters][:course]).course_name]
      data<<[t('batch'),batch.name]
      data<<[t('subject'),Subject.find(data_hash[:parameters][:subject]).name]
      data<<[t('exam_text'),@assessment_group.name]
      if data_hash[:parameters][:subject_attribute].present?
        data = subject_attribute_report_csv(data,data_hash)
      elsif data_hash[:parameters][:derived_exam].present?
        data = derived_exam_report_csv(data,data_hash)
      elsif data_hash[:parameters][:subject_exam_report].present?
        data = subject_exam_report_csv(data,data_hash)
      end
      return data
    end

    def subject_exam_report_csv(data,data_hash)
      @assessment_group = AssessmentGroup.find data_hash[:parameters][:exam]
      roll_num_enabled = Configuration.enabled_roll_number?
      @report = ConvertedAssessmentMark.fetch_subject_wise_report(data_hash[:parameters])
      @report_hash = @report.group_by(&:student_id)
      @student_ids = @report.collect(&:student_id)
      @students = ConvertedAssessmentMark.fetch_gradebook_students(data_hash[:parameters]).select{|obj| @student_ids.include? obj.s_id}
      row = []
      row<<t('no_text')
      row<<t('student_text')
      if roll_num_enabled
        row<<t('roll_nos')
      else
        row<<t('admission_no')
      end
      if ([1,3].include? @assessment_group.scoring_type)
        row<<"#{t('marks')}(#{data_hash[:parameters][:max_marks]})"
      end
      if ([2,3].include? @assessment_group.scoring_type)
        row<<t('grade')
      end
      data<<row
      @students.each_with_index do |student,i|
        @report_hash[student.s_id].each do |obj|
          row = []
          row<<i+1
          row<<student.full_name
          if roll_num_enabled
            row<<student.roll_number
          else
            row<<student.admission_no
          end
          if ([1,3].include? @assessment_group.scoring_type)
            obj.mark.present? ? row<<obj.mark : row<<"-"
          end
          if ([2,3].include? @assessment_group.scoring_type)
            obj.grade.present? ? row<<obj.grade : row<<"-"
          end
          data<<row
        end
      end
      return data
    end

    def subject_attribute_report_csv(data,data_hash)
      @assessment_group = AssessmentGroup.find data_hash[:parameters][:exam]
      roll_num_enabled = Configuration.enabled_roll_number?
      row = []
      @report = ConvertedAssessmentMark.fetch_subject_wise_report(data_hash[:parameters])
      @report_hash = @report.group_by(&:student_id)
      @student_ids = @report.collect(&:student_id)
      @students = ConvertedAssessmentMark.fetch_gradebook_students(data_hash[:parameters]).select{|obj| @student_ids.include? obj.s_id}
      @assessment_attributes = AssessmentAttribute.all
      @attrib_report = @report.find{|r| r.actual_mark.present?}
      @attrib_count = @attrib_report.actual_mark.keys.count if @attrib_report.present?
      @attrib_report.actual_mark.each_pair do |key,val|
        attrib_name = @assessment_attributes.find{|a| a.id == key}.name
        row<<attrib_name
        if @assessment_group.scoring_type == 3
          row<<""
        end
      end
      row = ["","",""]+row
      data<<row
      if roll_num_enabled
        row = [t('no_text'),t('single_student'),t('roll_nos')]
      else
        row = [t('no_text'),t('single_student'),t('admission_no')]
      end
      @attrib_report.actual_mark.each_pair do |key,val|
        if @assessment_group.scoring_type == 3
          row<<val[:max_mark]
          row<<t('grade')
        else
          row<<val[:max_mark]
        end
      end
      row<<t('final_score')
      if @assessment_group.scoring_type == 3
        row<<t('grade')
      end
      data<<row
      @students.each_with_index do |student,i|
        @report_hash[student.s_id].each do |report|
          row = []
          row<<i+1
          row<<student.full_name
          if roll_num_enabled
            row<<student.roll_number
          else
            row<<student.admission_no
          end
          if report.actual_mark.present?
            report.actual_mark.each_pair do |key,val|
              val[:mark].present? ? row<<val[:mark] : row<<"-"
              if @assessment_group.scoring_type == 3
                val[:grade].present? ? row<<val[:grade] : row<<"-"
              end
            end
          end
          row<<report.mark
          if @assessment_group.scoring_type == 3
            row<<report.grade
          end
          data<<row
        end
      end
      return data
    end

    def derived_exam_report_csv(data,data_hash)
      @assessment_group = AssessmentGroup.find data_hash[:parameters][:exam]
      roll_num_enabled = Configuration.enabled_roll_number?
      row = []
      @report = ConvertedAssessmentMark.fetch_subject_wise_report(data_hash[:parameters])
      @report_hash = @report.group_by(&:student_id)
      @student_ids = @report.collect(&:student_id)
      @students = ConvertedAssessmentMark.fetch_gradebook_students(data_hash[:parameters]).select{|obj| @student_ids.include? obj.s_id}
      @exam_groups = @assessment_group.assessment_groups
      @exam_groups.each do |eg|
        row<<eg.name
        if eg.scoring_type == 3
          row<<""
        end
      end
      row = ["","",""]+row
      data<<row
      if roll_num_enabled
        row = [t('no_text'),t('single_student'),t('roll_nos')]
      else
        row = [t('no_text'),t('single_student'),t('admission_no')]
      end
      @exam_groups.each do |eg|
        if eg.scoring_type == 3
          row<<eg.maximum_marks
          row<<t('grade')
        else
          row<<eg.maximum_marks
        end
      end
      row<<t('final_score')
      if @assessment_group.scoring_type == 3
        row<<t('grade')
      end
      data<<row
      @students.each_with_index do |student,i|
        @report_hash[student.s_id].each do |report|
          row = []
          row<<i+1
          row<<student.full_name
          if roll_num_enabled
            row<<student.roll_number
          else
            row<<student.admission_no
          end
          @exam_groups.each do |eg|
            report.actual_mark[eg.id].present? ? row<<report.actual_mark[eg.id][:mark] : row<<"-"
            if eg.scoring_type == 3
              report.actual_mark[eg.id].present? ? row<<report.actual_mark[eg.id][:grade] : row<<"-"
            end
          end
          row<<report.mark
          if @assessment_group.scoring_type == 3
            row<<report.grade
          end
          data<<row
        end
      end
      return data
    end

    def precision_label(val)
      precision_count = Configuration.get_config_value('PrecisionCount')
      precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count.to_i
      return sprintf("%0.#{precision}f", val)
    end

    def roll_number_enabled?
      return Configuration.find_or_create_by_config_key('EnableRollNumber').config_value == "1" ? true : false
    end

    def employee_leave_balance_data(params)
      params = params[:params] if params.key?(:params)
      if params[:department_id].present? and params["start_date"].present? and params[:end_date].present?
        select = "employees.*, ed.name as dept_name"
        leave_balance_on_end_date_hash = Hash.new
        leave_balance_on_start_date_hash = Hash.new
        leave_taken_in_between_hash = Hash.new
        leave_added_in_between_hash = Hash.new
        if params[:department_id] == "all"
          employees_dep = Employee.all(:joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id",
            :select => select,
            :include => [{:employee_leaves => :employee_leave_type},:employee_attendances,:employee_leave_balances, :employee_additional_leaves])
          employees_dep.each do |employee|
            leave_balance_hash = employee.leave_balance(params[:start_date],params[:end_date],"csv")
            leave_balance_on_end_date_hash[employee.id] = leave_balance_hash[:leave_balance_on_end_date_hash]
            leave_balance_on_start_date_hash[employee.id] = leave_balance_hash[:leave_balance_on_start_date_hash]
            leave_taken_in_between_hash[employee.id] = leave_balance_hash[:leave_taken_in_between_hash]
            leave_added_in_between_hash[employee.id] = leave_balance_hash[:leave_added_in_between_hash]
          end if employees_dep.present?
          employees = employees_dep.group_by(&:dept_name)
        else
          employees_dep = Employee.find_all_by_employee_department_id(params[:department_id],
            :joins =>"inner join employee_departments ed on ed.id = employees.employee_department_id",
            :select => select,
            :include => [{:employee_leaves => :employee_leave_type},:employee_attendances,:employee_leave_balances, :employee_additional_leaves])
          employees_dep.each do |employee|
            leave_balance_hash = employee.leave_balance(params[:start_date],params[:end_date],"csv")
            leave_balance_on_end_date_hash[employee.id] = leave_balance_hash[:leave_balance_on_end_date_hash]
            leave_balance_on_start_date_hash[employee.id] = leave_balance_hash[:leave_balance_on_start_date_hash]
            leave_taken_in_between_hash[employee.id] = leave_balance_hash[:leave_taken_in_between_hash]
            leave_added_in_between_hash[employee.id] = leave_balance_hash[:leave_added_in_between_hash]
          end if employees_dep.present?
          employees = employees_dep.group_by(&:dept_name)
        end
        data = get_employee_leave_balance_date(employees,leave_balance_on_end_date_hash,leave_balance_on_start_date_hash,leave_taken_in_between_hash,leave_added_in_between_hash)
        return data
      end
    end

    def get_employee_leave_balance_date(employees,leave_balance_on_end_date_hash,leave_balance_on_start_date_hash,leave_taken_in_between_hash,leave_added_in_between_hash)
      if employees.present?
        data = []
        row = [t('employee_text'),t('leave_balance_on_start')," ",t('leaves_added')," ",t('leaves_taken')," ",t('leave_balance_on_end')," "]
        data << row
        employees.each do |dpt, emp|
          data << " "
          data << dpt
          emp.each do |e|
            row = ["#{e.full_name} (#{e.employee_number})"]
            leave_balance_on_start_date_hash[e.id].each_with_index do |(k,v),index|
              row << "" unless index == 0
              row << k
              row << (v.present? ?  v : "-")
              row << k
              row << (leave_added_in_between_hash[e.id][k].present? ? leave_added_in_between_hash[e.id][k] : "-")
              row << k
              row << (leave_taken_in_between_hash[e.id][k].present? ? leave_taken_in_between_hash[e.id][k] : "-")
              row << k
              row << (leave_balance_on_end_date_hash[e.id][k].present? ? leave_balance_on_end_date_hash[e.id][k] : "-")
              data << row
              row = []
            end
          end
        end
        return data
      end
    end

  end
end
