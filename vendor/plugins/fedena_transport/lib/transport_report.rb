class TransportReport
  
  cattr_accessor :report_columns, :default_headers
  
  @@report_columns = YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_transport/lib", "report_columns.yml")) if File.exists?("#{Rails.root}/vendor/plugins/fedena_transport/lib/report_columns.yml")
  @@default_headers = [:name, :admission_no, :batch_full_name, :employee_number, :employee_department, 
    :vehicle_no, :student_name, :employee_name, :total, :attnd_percentage, :transport_allocation_status, :stop,
    :driver_name, :drive_mobile_phone, :stops, :transport_allocation_type, :pickup_route, :pickup_stop, :drop_route, :drop_stop, :vehicle
  ]
  class << self
    
    def transport_allocation_report(selectors, page, is_csv = false)
      if selectors[:passenger] == "Student"
        result = Student.student_transport_details(academic_year_id(selectors))
        result = result.alotted_student_transports if selectors[:selection_type] == "allocated"
        result = result.batch_wise_student_transport(selectors[:batch_id]) if selectors[:batch_id].present?
        result = result.transport_sort_order(selectors[:sort_order]) if selectors[:sort_order].present?
      elsif selectors[:passenger] == "Employee"
        result = Employee.employee_transport_details(academic_year_id(selectors))
        result = result.alotted_employee_transports if selectors[:selection_type] == "allocated"
        result = result.department_wise_employee_transport(selectors[:employee_department_id]) if selectors[:employee_department_id].present?
        result = result.transport_sort_order(selectors[:sort_order]) if selectors[:sort_order].present?
      end
      result = result.paginate(:per_page => 10, :page => page) unless is_csv
      return result
    end
    
        
    def transport_allocation_report_csv(result, selectors, columns, passenger_type)
      FasterCSV.generate do |csv|
        csv << [I18n.t('transport.passenger'), (selectors[:passenger] == "Student" ? I18n.t('student_text') : I18n.t('employee_text'))]
        if selectors[:passenger] == "Student"
          course = Course.find(selectors[:course_id])
          batches = Batch.find(selectors[:batch_id])
          csv << [I18n.t('course'), course.course_name]
          csv << [I18n.t('batch'), batches.collect(&:name).join(", ")]
        else
          dept = EmployeeDepartment.find(selectors[:employee_department_id])
          csv << [I18n.t('department'), dept.name]
        end
        csv << [I18n.t('selection_type'), (selectors[:selection_type] == "allocated" ? I18n.t('allocated_passengers') : I18n.t('all_passengers'))]
        csv << [I18n.t('academic_year'), fetch_academic_year(selectors).try(:name)]
        csv << []
        row = [I18n.t('sl_no')]
        columns["#{passenger_type.downcase}_details"].each{|col| row << I18n.t(col) }
        columns["transport_details"].each do |col| 
          if col.to_sym == :pickup_route and Configuration.common_route
            row << I18n.t(:route_text) 
          else
            row << I18n.t(col) 
          end
        end
        csv << row
        result.each_with_index do |res, i|
          row = [i+1]
          columns["#{passenger_type.downcase}_details"].each{|col| row << res.send(col) }
          columns["transport_details"].each{|col| row << res.send(col) }
          csv << row
        end
      end
    end
    
    def route_wise_report(selectors, page, is_csv = false)
      if selectors[:passenger] == "Student"
        result = Student.student_transport_details(academic_year_id(selectors))
      elsif selectors[:passenger] == "Employee"
        result = Employee.employee_transport_details(academic_year_id(selectors))
      end
      result = result.route_filter(selectors[:route_type], selectors[:route_id]) if selectors[:route_type].present? and selectors[:route_id].present? 
      result = result.transport_sort_order(selectors[:sort_order]) if selectors[:sort_order].present?
      result = result.paginate(:per_page => 10, :page => page) unless is_csv
      return result
    end
    
    def route_wise_report_csv(result, selectors, columns, passenger_type)
      FasterCSV.generate do |csv|
        csv << [I18n.t('transport.passenger'), (selectors[:passenger] == "Student" ? I18n.t('student_text') : I18n.t('employee_text'))]
        csv << [I18n.t('academic_year'), fetch_academic_year(selectors).try(:name)]
        csv << [I18n.t('transport_attendance.route_type'), (selectors[:route_type] == "pickup" ? I18n.t('transport_attendance.pickup') : I18n.t('transport_attendance.drop'))]
        route = Route.find(selectors[:route_id])
        csv << [I18n.t('routes.route'), route.name]
        csv << []
        row = [I18n.t('sl_no')]
        columns["#{passenger_type.downcase}_details"].each{|col| row << I18n.t(col) }
        columns["transport_details"].each{|col| row << I18n.t(col) }
        csv << row
        result.each_with_index do |res, i|
          row = [i+1]
          columns["#{passenger_type.downcase}_details"].each{|col| row << res.send(col) }
          columns["transport_details"].each do |col|
            row << (col.to_sym == :stop ? res.stop(selectors[:route_type]) : (col.to_sym == :vehicle ? res.vehicle_name(selectors[:route_type]) : res.send(col)))
          end
          csv << row
        end
      end
    end
    
    def route_details_report(selectors, page, is_csv = false)
      Route.set_additional_methods
      result = Route.in_academic_year(academic_year_id(selectors)).route_details
      result = result.route_sort_order(selectors[:sort_order]) if selectors[:sort_order].present?
      result = result.paginate(:per_page => 10, :page => page) unless is_csv
      return result
    end
    
    def route_details_report_csv(result, selectors, columns, passenger_type)
      FasterCSV.generate do |csv|
        csv << [I18n.t('academic_year'), fetch_academic_year(selectors).try(:name)]
        csv << []
        row = [I18n.t('sl_no')]
        columns["route_details"].each{|col| row << I18n.t(col) }
        (columns["additional_details"]||{}).each{|method, col| row << method.last}
        csv << row
        result.each_with_index do |res, i|
          row = [i+1]
          columns["route_details"].each{|col| row << res.send(col) }
          (columns["additional_details"]||{}).each{|method, col| row << res.send(method.first) }
          csv << row
        end
      end
    end
    
    def transport_attendance_report(selectors, page, is_csv = false)
      if selectors[:mode] == "monthly"
        date = '01-' + selectors[:month] + '-' + selectors[:year]
        start_date = date.to_date
        end_date = start_date.end_of_month
      else
        start_date = selectors[:start_date].to_date
        end_date = selectors[:end_date].to_date
      end
      start_date, end_date = validate_date(start_date, end_date)
      result = Transport.in_academic_year(academic_year_id(selectors))
      result = result.send("#{selectors[:passenger].downcase}_transports_with_attendance", start_date, end_date)if selectors[:passenger].present? and start_date.present? and end_date.present?
      result = result.route_filter(selectors[:route_type], selectors[:route_id]) if selectors[:route_type].present? and selectors[:route_id].present?
      includes = ((selectors[:passenger] == "Student") ? {:receiver => [:father, :mother]} : {})
      unless is_csv
        result = result.paginate(:per_page => 10, :page => page, :include => includes)
      else
        result = result.all(:include => includes)
      end
      fetch_attendance_percentage(selectors[:passenger], result, start_date, end_date)
      return result
    end
    
    def fetch_attendance_percentage(passenger, result, start_date, end_date)
      @attendance_result = {}
      if(passenger == "Student")
        batch_ids = result.collect(&:batch_id).uniq.compact
        sections = Batch.find(batch_ids, :include => [:events, {:attendance_weekday_sets => {:weekday_set => :weekday_sets_weekdays}}])
      else
        dept_ids = result.collect(&:department_id)
        sections = EmployeeDepartment.find(dept_ids, :include => :events)
      end
      @working_days = {}
      sections.each do |section|
        @working_days[section.id] = section.working_days_for_range(start_date,end_date)
      end
      result.each do |res|
        working_days = ((passenger == "Student") ? @working_days[res.batch_id.to_i] : @working_days[res.department_id.to_i])
        admission_date = res.admission_date.to_date
        student_academic_days = (admission_date <= end_date && admission_date >= start_date) ? 
          (working_days.select {|x| x >= admission_date }.length) : 
          (start_date >= admission_date ? (working_days.count) : 0)
        @attendance_result[res.id] = if student_academic_days > 0
          {:total => "#{student_academic_days - res.total_days_absent.to_i} / #{student_academic_days}",
            :attnd_percentage => (((student_academic_days - res.total_days_absent.to_i).to_f/student_academic_days)*100).round(2)
          }
        else
          {:total => "-", :attnd_percentage => '-'
          }
        end
      end
    end
    
    def fetch_attendance_result(passenger_id)
      @attendance_result[passenger_id]
    end
    
    def transport_attendance_report_csv(result, selectors, columns, passenger_type)
      FasterCSV.generate do |csv|
        csv << [I18n.t('transport.passenger'), (selectors[:passenger] == "Student" ? I18n.t('student_text') : I18n.t('employee_text'))]
        csv << [I18n.t('academic_year'), fetch_academic_year(selectors).try(:name)]
        csv << [I18n.t('transport_attendance.route_type'), (selectors[:route_type] == "pickup" ? I18n.t('transport_attendance.pickup') : I18n.t('transport_attendance.drop'))]
        route = Route.find(selectors[:route_id])
        csv << [I18n.t('routes.route'), route.name]
        csv << [I18n.t('mode'), (selectors[:mode] == "monthly" ? I18n.t(:monthly) : I18n.t(:custom_date))]
        
        if selectors[:mode] == "monthly"
          csv << [I18n.t('month_and_year'), "#{I18n.t(Date::MONTHNAMES[selectors[:month].to_i].downcase)} #{selectors[:year]}"]
        else
          csv << [I18n.t('start_date'), selectors[:start_date]]
          csv << [I18n.t('end_date'), selectors[:end_date]]
        end
        csv << []
        row = [I18n.t('sl_no')]
        columns["#{passenger_type.downcase}_details"].each{|col| row << I18n.t(col) }
        columns["transport_details"].each{|col| row << I18n.t(col) }
        csv << row
        result.each_with_index do |res, i|
          row = [i+1]
          columns["#{passenger_type.downcase}_details"].each{|col| row << res.send(col) }
          data = fetch_attendance_result(res.id)
          columns["transport_details"].each{|col| row << data[col.to_sym]}
          csv << row
        end
      end
    end
    
    def transport_fee_report(selectors, page, is_csv = false)
      is_student = (selectors[:passenger] == "Student")
      passengers = if is_student
        fetch_transport_students(selectors, page, is_csv)
      else
        fetch_transport_employees(selectors, page, is_csv)
      end
      academic_year = fetch_academic_year(selectors)
      transport_fees = TransportFee.all(:joins => "INNER JOIN transport_fee_collections tfc
                                                           ON tfc.id = transport_fees.transport_fee_collection_id
                                              LEFT OUTER JOIN fee_accounts fa ON fa.id = tfc.fee_account_id",
        :conditions=>["(fa.id IS NULL OR fa.is_deleted = false) AND receiver_type= ? and receiver_id in (?) AND
((transport_fee_collections.start_date BETWEEN ? AND ?) OR (transport_fee_collections.due_date BETWEEN ? AND ?))", 
          selectors[:passenger], passengers.collect(&:id), academic_year.start_date, academic_year.end_date, 
          academic_year.start_date, academic_year.end_date], :include =>  [:transport_fee_collection, :finance_transactions, :transport_fee_discounts])
      @collections = {}
      @collection_headers = transport_fees.map{|tf| [tf.transport_fee_collection.name, tf.transport_fee_collection.name.
            downcase.split.join] if tf.transport_fee_collection.present?}.compact.uniq
      collection_names = transport_fees.map{|tf| [tf.transport_fee_collection.id, tf.transport_fee_collection.name.
            downcase.split.join] if tf.transport_fee_collection.present?}.compact.uniq
      collection_names.each do |id, col|
        if @collections.has_key? col
          @collections[col] << id
        else
          @collections[col] = [id]
        end
      end
      @passenger_details = fetch_passenger_details(passengers, is_student)
      @result_fees = fetch_fee_values(passengers, transport_fees, is_student)
      return passengers
    end
    
    def transport_fee_report_csv(result, selectors, columns, passenger_type)
      # FasterCSV.generate do |csv|
      csv = []
      csv << [I18n.t('transport.passenger'), (selectors[:passenger] == "Student" ? I18n.t('student_text') : I18n.t('employee_text'))]
      if selectors[:passenger] == "Student"
        course = Course.find(selectors[:course_id])
        batches = Batch.find(selectors[:batch_id])
        csv << [I18n.t('course'), course.course_name]
        csv << [I18n.t('batch'), batches.collect(&:name).join(", ")]
      else
        dept = EmployeeDepartment.find(selectors[:employee_department_id])
        csv << [I18n.t('department'), dept.name]
      end
      csv << [I18n.t('academic_year'), fetch_academic_year(selectors).try(:name)]
      csv << []
      row = [I18n.t('sl_no')]
      currency = Configuration.currency
      columns["#{passenger_type.downcase}_details"].each{|col| row << I18n.t(col) }
      (columns["additional_details"]||{}).each{|method, col| row << col }
      [:total_fees, :total_fees_paid, :total_expected_fine, :total_fine_paid, :total_fees_due].each do |f|
        row << (f == :total_fees ? "#{I18n.t(f)} (#{currency})" : I18n.t(f))
      end
      get_collection_names.each do |name, method|
        [:fees_text, :fees_paid, :expected_fine, :total_fine_paid, :fees_due].each do |f|
          row << (f == :fees_text ? "#{name} - #{I18n.t(f)} (#{currency})" : "#{name} - #{I18n.t(f)}")
        end
      end
      csv << row
      result.each_with_index do |res, i|
        row = [i+1]
        details = TransportReport.get_passenger_details(res.id)
        columns["#{passenger_type.downcase}_details"].each{|col| row << details[col.to_sym] }
        (columns["additional_details"]||{}).each{|method, col| row << details[method.to_sym] }
        data = get_total_data_for_cell(res.id)
        has_fees = (data.values.sum > 0)
        [:fees, :paid, :fine, :fine_paid, :due].each do |f|
          row << (has_fees ? data[f] : '-')
        end
        get_collection_names.each do |name, method|
          data = get_data_for_cell(res.id, method)
          has_fees = (data.values.sum > 0)
          [:fees, :paid, :fine, :fine_paid, :due].each do |f|
            row << (has_fees ? data[f] : '-')
          end
        end
        csv << row
      end
      # end
      return csv
    end
    
    def get_data_for_cell(student_id, collection_name)
      collection_ids = @collections[collection_name]
      student_data = @result_fees[student_id]
      data = {:fine=>0.0, :paid=>0.0, :fees=>0.0, :due=>0.0, :fine_paid=>0.0}
      
      values = student_data.map{|k, values| values if collection_ids.include? k}.compact
      student_data.each do |col_id, col_data|
        if collection_ids.include? col_id
          data.merge!(col_data){|k, old_v, new_v| old_v + new_v}
        end
      end
      data
    end
    
    def get_passenger_details(passenger_id)
      @passenger_details[passenger_id]
    end
    
    def get_total_data_for_cell(student_id)
      student_data = @result_fees[student_id]
      data = {:fine=>0.0, :paid=>0.0, :fees=>0.0, :due=>0.0, :fine_paid=>0.0}
      
      student_data.each do |col_id, col_data|
        data.merge!(col_data){|k, old_v, new_v| old_v + new_v}
      end
      data
    end
    
    def get_collection_names
      @collection_headers
    end
    
    def fetch_fee_values(passengers, transport_fees, is_student)
      all_fees = {}
      #      student_batches =  BatchStudent.all(:joins=>[:batch],:conditions=>["batches.is_active = true and batch_students.student_id in (?)", passengers.collect(&:id)])
      # && student_batch_ids.include?(tf.groupable_id) 
      passengers.each do |pa|
        pas_transport_fees = if is_student
          unless pa.former.to_i == 1
            transport_fees.select{|tf| tf.receiver_type = 'Student' && 
                tf.receiver_id == pa.id && tf.is_active && !tf.transport_fee_collection.is_deleted && 
                (tf.groupable_type == "Batch")}
          else
            transport_fees.select{|tf| tf.receiver_type = 'Student' && 
                tf.receiver_id == pa.id && !tf.transport_fee_collection.is_deleted && 
                (tf.groupable_type == "Batch")}
          end
        else
          unless pa.former.to_i == 1
            transport_fees.select{|tf| tf.receiver_type = 'Employe' && 
                tf.receiver_id == pa.id && tf.is_active && !tf.transport_fee_collection.is_deleted && 
                (tf.groupable_type == "EmployeeDepartment")}
          else
            transport_fees.select{|tf| tf.receiver_type = 'Employe' && 
                tf.receiver_id == pa.id && !tf.transport_fee_collection.is_deleted && 
                (tf.groupable_type == "EmployeeDepartment")}
          end
        end
        passenger_fees = {}
        pas_transport_fees.each do |t|
          collection= t.transport_fee_collection
          fees=0.0; discount=0.0; paid=0.0; due=0.0; fine_paid=0.0; fine=0.0; tax_amount=0.0; tax_paid=0.0; tax_enabled=false;
          fees= t.bus_fare
          fine_paid= t.finance_transactions.collect(&:fine_amount).sum.to_f
          paid= t.finance_transactions.collect(&:amount).sum.to_f
          paid = paid -fine_paid
          discount = t.total_discount_amount
          tax_enabled = t.tax_enabled.present? ? t.tax_enabled : false
          if tax_enabled
            tax_amount = t.tax_amount.to_f if t.tax_amount.present?
            #            tax_paid = t.is_paid? ? t.tax_amount.to_f : t.finance_transactions.collect(&:tax_amount).sum.to_f
          end
          
          amount_after_discount = fees - discount
          amount_after_discount = 0 if  amount_after_discount < 0
          amount_after_tax = amount_after_discount + tax_amount
          #due calculation
          due = amount_after_tax - (paid)
          due = due.zero? && 0.0 || due #avoid -0.0 case --(negative zero)
          due_date= collection.due_date.to_date
          auto_fine=0.0; days=0; today = Date.today
          if t.is_paid?
            last_transaction= t.finance_transactions.sort{|x,y| x.transaction_date <=> y.transaction_date}.last
            if last_transaction.present?
              last_transaction_date = last_transaction.transaction_date

              if last_transaction_date <= due_date
                days=0
              elsif last_transaction_date <= today
                days=(last_transaction_date - due_date).to_i
              elsif last_transaction_date > today
                days=(today - due_date).to_i
              else
              end
            else
              # no transactons - but is_paid= true --- cases like 100% discount
              days=0
            end
          else
            #not paid yet
            days=(today - due_date).to_i
          end
          if collection.fine.present? and days > 0 and !t.is_fine_waiver
            applicable_fine_rule = collection.fine.fine_rules.select{|fr| fr.fine_days <= days && fr.created_at <= collection.created_at }.sort{|x,y| x.fine_days <=> y.fine_days}.last
            if Configuration.is_fine_settings_enabled? && t.balance_fine.present? && t.balance <= 0
              auto_fine = t.balance_fine + fine_paid
            elsif applicable_fine_rule.present?
              auto_fine = auto_fine + (applicable_fine_rule.is_amount ? applicable_fine_rule.fine_amount : (amount_after_discount * applicable_fine_rule.fine_amount)/100 )
            end
#            if applicable_fine_rule.present?
#              auto_fine = auto_fine + (applicable_fine_rule.is_amount ? applicable_fine_rule.fine_amount : (amount_after_discount * applicable_fine_rule.fine_amount)/100 )
#            end
          end
          fine = auto_fine
          passenger_fees[t.transport_fee_collection_id] = {
            :fees => amount_after_tax,
            :paid => paid,
            :due => due,
            #            :discount=>discount,
            :fine=>fine,
            :fine_paid=>fine_paid,
            #            :tax_amount=>tax_amount,
            #            :tax_paid=> tax_paid,
            #            :tax_enabled=> tax_enabled
          }
        end
        all_fees[pa.id] = passenger_fees
      end
      all_fees
    end
    
    def fetch_passenger_details(passengers, is_student)
      type = (is_student ? 'Student': 'Employee')
      details = UserAdditionalDetails.new(passengers, type, false)
      addl_details = details.fetch_additional_details
      all_details = {}
      passengers.each do |pa|
        all_details[pa.id] = if is_student
          {:name => pa.name, :admission_no => pa.admission_no, :batch_full_name => pa.batch_full_name}
        else
          {:name => pa.name, :employee_number => pa.employee_number, :employee_department => pa.employee_department_name}
        end.merge(addl_details[pa.id])
      end
      all_details
    end
    
    def fetch_transport_students(selectors, page, is_csv)
      school_id = MultiSchool.current_school.id
      query = "SELECT t_students.*, CONCAT(courses.code, '-', batches.name) AS batch_full_name FROM 
(SELECT students.id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS name, admission_no, batch_id, false AS former,
students.school_id, transports.academic_year_id, immediate_contact_id, sibling_id, phone2, 'present' AS current_type FROM students 
INNER JOIN transports ON transports.receiver_type = 'Student' AND transports.receiver_id = students.id 
WHERE transports.school_id = #{school_id}
UNION 
SELECT former_id AS id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS name, admission_no, batch_id, true AS former, 
archived_students.school_id, ar_t.academic_year_id,immediate_contact_id, sibling_id, phone2, 'archived' AS current_type FROM archived_students 
INNER JOIN archived_transports AS ar_t ON ar_t.receiver_type = 'ArchivedStudent' AND ar_t.receiver_id = archived_students.id
WHERE ar_t.school_id = #{school_id}) 
t_students 
INNER JOIN batches ON batches.id = batch_id 
INNER JOIN courses ON courses.id = batches.course_id 
WHERE batch_id IN (?) AND t_students.academic_year_id = ?
ORDER BY batch_id DESC, t_students.name ASC"
      result = unless is_csv
        Student.paginate_by_sql([query, selectors[:batch_id], academic_year_id(selectors)], :per_page => 10, :page => page)
      else
        Student.find_by_sql([query, selectors[:batch_id], academic_year_id(selectors)])
      end
      result
    end
    
    def fetch_transport_employees(selectors, page, is_csv)
      school_id = MultiSchool.current_school.id
      query = "SELECT t_employees.*, employee_departments.name AS employee_department_name FROM 
(SELECT employees.id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS name, employee_number, false AS former, 
employee_department_id, employees.school_id, transports.academic_year_id, 'present' AS current_type FROM employees 
INNER JOIN transports ON  transports.receiver_type = 'Employee' AND transports.receiver_id = employees.id
WHERE transports.school_id = #{school_id}
UNION 
SELECT former_id AS id, CONCAT(first_name, ' ', middle_name, ' ', last_name) AS name, employee_number, true AS former, 
employee_department_id, archived_employees.school_id, ar_t.academic_year_id, 'archived' AS current_type FROM  archived_employees 
INNER JOIN archived_transports AS ar_t ON ar_t.receiver_type = 'ArchivedEmployee' AND ar_t.receiver_id = archived_employees.id
WHERE ar_t.school_id = #{school_id}) 
t_employees 
INNER JOIN employee_departments ON employee_departments.id = employee_department_id 
WHERE employee_department_id IN (?) AND academic_year_id = ? 
ORDER BY employee_department_id DESC, t_employees.name ASC"
      result = unless is_csv
        Employee.paginate_by_sql([query, selectors[:employee_department_id], academic_year_id(selectors)], :per_page => 10, :page => page)
      else
        Employee.find_by_sql([query, selectors[:employee_department_id], academic_year_id(selectors)])
      end
      result
    end
    
    def academic_year_id(selectors)
      selectors[:academic_year_id]||AcademicYear.active.first.id 
    end
    
    def fetch_academic_year(selectors)
      if selectors[:academic_year_id].present?
        AcademicYear.find(selectors[:academic_year_id])
      else
        AcademicYear.active.first
      end
    end
    
    def validate_date(start_date, end_date)
      today = Configuration.default_time_zone_present_time.to_date
      start_date = today if (start_date > today) 
      end_date = today if (end_date > today)
      [start_date, end_date]
    end
    
    def fetch_columns(type, passenger, all_columns = false)
      actual_columns = report_columns[type]
      columns = make_deep_copy(actual_columns)
      if passenger.present?
        if passenger.downcase == "student"
          columns = columns.except("employee_details") 
          columns["student_details"].reject!{|c| c.to_sym == :roll_number} unless Configuration.enabled_roll_number?
          columns["additional_details"] = StudentAdditionalField.get_fields if all_columns && type == "transport_fee_report"
        elsif passenger.downcase == "employee"
          columns = columns.except("student_details") 
          columns["additional_details"] = AdditionalField.get_fields if all_columns && type == "transport_fee_report"
        end
        
      end
      unless all_columns
        columns.each do |col, values|
          columns[col] = values & default_headers unless col == "additional_details"
        end
      else
        if type == "route_details_report"
          columns["additional_details"] = Route.additional_field_methods_with_values
        end
      end
      if type == "transport_allocation_report"
        columns["transport_details"].reject!{|c| c.to_sym == :drop_route} if Configuration.common_route
      end
      columns
    end
    
    def make_deep_copy(value)
      Marshal.load(Marshal.dump(value))
    end
    
    def convert_additional_columns(type, passenger, selected_columns)
      if selected_columns.present? and selected_columns["additional_details"].present?
        addl_fields = Route.additional_field_methods_with_values if type == "route_details_report"
        if type == "transport_fee_report"
          addl_fields = StudentAdditionalField.get_fields.stringify_keys if passenger.downcase == "student"
          addl_fields = AdditionalField.get_fields.stringify_keys if passenger.downcase == "employee"
        end
        selected_columns["additional_details"] = selected_columns["additional_details"].each_with_object({}){|f, hsh| hsh[f] = addl_fields[f.to_s]}
      end
      selected_columns
    end
    
    def transport_fee_csv_export(param_list)
      @type = param_list[:type]
      @search_params = param_list[:search_params]
      page = param_list[:page]
      file_name = param_list[:file_name]
      @columns = param_list[:columns]
      @passenger_type = param_list[:passenger_type]
      result = TransportReport.send(@type, (@search_params||{}), page, true)
      return_hash = fetch_transport_report_columns(false,param_list)
      @columns = return_hash[:columns]
      @report_columns = return_hash[:return_columns]
      @selected_columns = return_hash[:selected_columns]
      data = TransportReport.send("#{@type}_csv", result, (@search_params||{}), @columns, @passenger_type)
      return data
    end
    
    def fetch_transport_report_columns(all_columns = false,params_list={})
      report_columns = TransportReport.fetch_columns(params_list[:type], params_list[:passenger_type], all_columns)
      columns = params_list[:selected_columns]||report_columns
      selected_columns = nil
      selected_columns = TransportReport.convert_additional_columns(params_list[:type], params_list[:passenger_type], params_list[:selected_columns]) if params_list[:type] == "route_details_report" and params_list[:page].nil?
      return {:report_columns=>report_columns,:columns=>columns,:selected_columns=>selected_columns}
    end
  
  end
end
