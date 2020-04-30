SupportTaskEngine.config do

  # single employee leave reset
  support_task('individual_employee_leave_reset', 'change_individual_employee_reset_date', {'employee_number'=>'string', 'reset_date'=>'date'}) do
    check do |params, stats|
      reset_date = params['reset_date'].to_date
      employee = Employee.find_by_employee_number(params['employee_number'])
      if employee.present?
        log_it(stats, "Error!! Reset date(#{reset_date}) cannot be future date.") if reset_date > Date.today
        log_it(stats, "Error!! Leave reset date(#{reset_date}) cannot be before the employee joining date(#{employee.joining_date}).") if reset_date < employee.joining_date
      else  
        log_it(stats, "Error!! Employee Record not found #{params['employee_number']}")
      end
      true
    end
    
    run do |params, stats|
      reset_date = params['reset_date'].to_date
      employee = Employee.find_by_employee_number(params['employee_number'])
      if employee.present? and (reset_date <= Date.today) and (reset_date >= employee.joining_date)
        employee_leaves = EmployeeLeave.find_all_by_employee_id_and_reset_date(employee.id, employee.last_reset_date)
        employee_leaves.each do |em_leave|
          em_leave.update_attributes(:reset_date => reset_date)
          log_it(stats, "Employee Leave date updated for leave type #{em_leave.employee_leave_type.name}.")
        end
        employee.update_attributes(:last_reset_date => reset_date)
        log_it(stats, "Employee Leave reset completed for #{employee.employee_number}.")
        status_flag = true
      else
        log_it(stats, "Error!! Employee Leave Reset Failed #{params['employee_number']}. Please run the check task.")
        status_flag = false
      end
      status_flag
    end
  end
  
  #bulk employee leave reset
  support_task('bulk_employee_leave_reset', 'change_bulk_employee_reset_date_using_csv', {'csv_file'=>'file'}, {'employee_number'=>'0', 'reset_date'=>'1'}) do
    check do |params, stats|
      require 'fastercsv'
      csv_file_path = params['csv_file']
      i = 0
      FasterCSV.foreach(csv_file_path) do |row|
        unless i==0
          employee_no = row[0].to_s.strip
          reset_date = row[1].to_s.strip
          line_no = i+1
          log_it(stats, "Error!! line no - #{line_no}, Employee number not present.") unless employee_no.present?
          log_it(stats, "Error!! line no - #{line_no}, Reset date not present.") unless reset_date.present?
          if employee_no.present? and reset_date.present?
            begin
              leave_reset_date = Date.parse(reset_date.gsub('/','-'))
            rescue ArgumentError
              leave_reset_date = ""
            end
            employee = Employee.find_by_employee_number(employee_no)
            log_it(stats, "Error!! line no - #{line_no}, Employee record not present for #{employee_no}.") unless employee.present?
            log_it(stats, "Error!! line no - #{line_no}, Incorrect date format #{reset_date}.") unless leave_reset_date.present?
            if employee.present? and leave_reset_date.present?
              log_it(stats, "Error!! line no - #{line_no}, Reset date(#{leave_reset_date}) cannot be future date.") if leave_reset_date > Date.today
              log_it(stats, "Error!! line no - #{line_no}, Leave reset date(#{leave_reset_date}) cannot be before the employee joining date(#{employee.joining_date}).") if leave_reset_date < employee.joining_date
            end
          end
        end
        i += 1
      end
      true
    end
    
    run do |params, stats|
      require 'fastercsv'
      csv_file_path = params['csv_file']
      i = 0
      FasterCSV.foreach(csv_file_path) do |row|
        unless i==0
          employee_no = row[0].to_s.strip
          reset_date = row[1].to_s.strip
          line_no = i+1
          if employee_no.present? and reset_date.present?
            begin
              leave_reset_date = Date.parse(reset_date.gsub('/','-'))
            rescue ArgumentError
              leave_reset_date = ""
            end
            employee = Employee.find_by_employee_number(employee_no)
            if employee.present? and leave_reset_date.present? and (leave_reset_date <= Date.today) and (leave_reset_date >= employee.joining_date)
              log_it(stats, "line no - #{line_no}, Employee Leave reset started for #{employee.employee_number}.")
              employee_leaves = EmployeeLeave.find_all_by_employee_id_and_reset_date(employee.id, employee.last_reset_date)
              employee_leaves.each do |em_leave|
                em_leave.update_attributes(:reset_date => leave_reset_date)
                log_it(stats, "line no - #{line_no}, Employee Leave date updated for leave type #{em_leave.employee_leave_type.name}.")
              end
              employee.update_attributes(:last_reset_date => leave_reset_date)
              log_it(stats, "line no - #{line_no}, Employee Leave reset completed for #{employee.employee_number}.")
            else
              log_it(stats, "Error!! line no - #{line_no}, Please run check task for more info.")
            end
          else
            log_it(stats, "Error!! line no - #{line_no}, Please run check task for more info.")
          end
        end
        i += 1
      end
      true 
    end
  end
  
  # bulk student delete
  support_task('bulk_student_delete', 'delete_all_student_data_along_with_dependencies', {'batch_id'=>'integer'}, {'To delete specific batch - batch_id'=>'a','To delete all the students - 0'=>'b'}) do
    check do |params, stats|
      batch_id = params['batch_id']
      unless batch_id == "0"
        batch = Batch.find_by_id(batch_id)
        log_it(stats, "Error!! Batch not present.") unless batch.present?
      end
      true
    end
    
    run do |params, stats|
      batch_id = params['batch_id']
      admin = User.first(:conditions=>{:admin=>true})
      if batch_id == "0"
        Student.all.each do |st|
          Delayed::Job.enqueue(DelayedStudentDependencyDelete.new(st.id,admin))
        end
      else  
        batch = Batch.find_by_id(batch_id)
        if batch.present?
          all_students = batch.students
          all_students.each do |st|
            Delayed::Job.enqueue(DelayedStudentDependencyDelete.new(st.id, admin))
          end
        end
      end
      true
    end
  end
  
  #employee subject association
  support_task('employee_subject_association', 'employee_subject_association_using_csv', {'csv_file'=>'file'}, 
    {'employee_number'=>'0', 'subject_code'=>'1', 'batch_name'=>'2', 'course_code'=>'3'}) do
    check do |params, stats|
      require 'fastercsv'
      csv_file_path = params['csv_file']
      i = 0
      FasterCSV.foreach(csv_file_path) do |row|
        unless i==0
          employee_no = row[0].to_s.strip
          sub_code = row[1].to_s.strip
          course_code = row[3].to_s.strip
          batch_name = row[2].to_s.strip
          line_no = i+1
          log_it(stats, "Error!! line no - #{line_no}, Employee number not present.") unless employee_no.present?
          log_it(stats, "Error!! line no - #{line_no}, Subject Code not present.") unless sub_code.present?
          log_it(stats, "Error!! line no - #{line_no}, Course Code not present.") unless course_code.present?
          log_it(stats, "Error!! line no - #{line_no}, Batch name not present.") unless batch_name.present?
          if employee_no.present? and sub_code.present? and course_code.present? and batch_name.present?
            batch_name.slice! "#{course_code} - "
            course = Course.find_by_code(course_code)
            employee = Employee.find_by_employee_number(employee_no)
            log_it(stats, "Error!! line no - #{line_no}, Course Record for #{course_code} Not found.") unless course.present?
            log_it(stats, "Error!! line no - #{line_no}, Employee Record #{employee_no} Not found.") unless employee.present?
            if course.present? and employee.present?
              batch = Batch.find_by_name_and_course_id(batch_name, course.id)
              unless batch.present?
                log_it(stats, "Error!! line no - #{line_no}, Batch Record for #{batch_name} Not found.")
              else
                subject = Subject.find(:first, :conditions=>{:code=> sub_code, :batch_id=> batch.id})
                unless subject.present?
                  log_it(stats, "Error!! line no - #{line_no}, Subject Record for #{sub_code} Not found.")
                end
              end
            end
          end
        end
        i += 1
      end
      true
    end
    
    run do |params, stats|
      require 'fastercsv'
      csv_file_path = params['csv_file']
      i = 0
      FasterCSV.foreach(csv_file_path) do |row|
        unless i==0
          employee_no = row[0].to_s.strip
          sub_code = row[1].to_s.strip
          course_code = row[3].to_s.strip
          batch_name = row[2].to_s.strip
          line_no = i+1
          if employee_no.present? and sub_code.present? and course_code.present? and batch_name.present?
            batch_name.slice! "#{course_code} - "
            course = Course.find_by_code(course_code)
            employee = Employee.find_by_employee_number(employee_no)
            if course.present? and employee.present?
              batch = Batch.find_by_name_and_course_id(batch_name, course.id)
              unless batch.present?
                log_it(stats, "Error!! line no - #{line_no}, Please run check task for more info.")
              else
                subject = Subject.find(:first, :conditions=>{:code=> sub_code, :batch_id=> batch.id})
                if subject.present?
                  EmployeesSubject.create(:employee_id=> employee.id, :subject_id=> subject.id)
                  log_it(stats, "line no - #{line_no}, Success.")
                else  
                  log_it(stats, "Error!! line no - #{line_no}, Please run check task for more info.")
                end
              end
            else
              log_it(stats, "Error!! line no - #{line_no}, Please run check task for more info.")
            end
          else
            log_it(stats, "Error!! line no - #{line_no}, Please run check task for more info.")
          end
        end
        i += 1
      end
      true
    end
  end
  
end

#>> SupportTaskEngine.scripts.last.check('name' => 'Ding', 'admission_no'=>'sadasd')
