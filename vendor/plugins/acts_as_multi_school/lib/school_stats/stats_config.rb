SchoolStats.config do
  entity :academics  do |e|
    e.fetch_query={:select=>"schools.id,schools.name,count(DISTINCT courses.id) as total_courses,
       count(DISTINCT students.id) as total_students,count(DISTINCT IF(employee_departments.status=1,employee_departments.id,NULL)) as total_emp_dpts",
      :skip_multischool=>true,
      :joins=>"LEFT OUTER JOIN courses on courses.school_id=schools.id AND courses.is_deleted=0 LEFT OUTER JOIN students on students.school_id=schools.id LEFT OUTER JOIN employee_departments on employee_departments.school_id=schools.id ",:group=>"schools.id"}
    e.model="school"
    e.has_child :total_courses,:entity=>:course
    e.has_child :total_emp_dpts,:entity=>:employee_department
    e.fields=[:name, :total_courses ,:total_students, :total_emp_dpts]
  end

  entity :course do |e|
    e.fetch_query={:select=>"courses.id, courses.course_name, count(DISTINCT batches.id) as total_batches,
    count(DISTINCT (students.id)) as total_students,count(DISTINCT IF(students.gender like '%m%',students.id,NULL)) as male_students,
    count(DISTINCT IF(students.gender like '%f%',students.id,NULL)) as female_students,count(DISTINCT archived_students.id) as relieved_students,
    FORMAT(IFNULL(sum(IF(finance_fee_collections.is_deleted=0 AND finance_fee_collections.due_date < '#{Date.today}',finance_fees.balance,NULL))/count(finance_fees.id)*count(DISTINCT finance_fees.id),0),3) as dues_live",:group=>"courses.id",
      :joins=>"LEFT OUTER JOIN batches as batch_a ON batch_a.course_id=courses.id AND batch_a.is_deleted=0 AND batch_a.is_active=1 LEFT OUTER JOIN  students ON students.batch_id=batch_a.id LEFT OUTER JOIN archived_students ON archived_students.batch_id=batch_a.id LEFT OUTER JOIN batches ON batches.course_id=courses.id AND batches.is_deleted=0 AND batches.is_active=1  LEFT OUTER JOIN batches as batch_b ON batch_b.course_id=courses.id AND batch_b.is_deleted=0 LEFT OUTER JOIN finance_fees INNER JOIN students as students_have_fee_due ON finance_fees.student_id=students_have_fee_due.id ON finance_fees.batch_id=batch_b.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id ",
      :conditions=>["courses.is_deleted=0 and batches.is_active=1"],
      :skip_multischool=>true}
    e.model="course"
    e.has_child :total_batches,:entity=>:batch
    e.fields=[:course_name,:total_batches,:total_students,:male_students,:female_students,:relieved_students, :dues_live ]

  end

  entity :batch do |e|
    e.fetch_query={:select=>"batches.id, batches.name as batch_name,count(DISTINCT (students.id)) as total_students,
      count(DISTINCT IF(students.gender like '%m%',students.id,NULL)) as male_students,count(DISTINCT IF(students.gender like '%f%',students.id,NULL)) as female_students,
      count(DISTINCT archived_students.id) as relieved_students,
      FORMAT(IFNULL(sum(IF(finance_fee_collections.is_deleted=0 AND finance_fee_collections.due_date < '#{Date.today}',finance_fees.balance,0))/count(*)*count(DISTINCT finance_fees.id),0),3) as dues_live",:group=>"batches.id",
      :joins=>"LEFT OUTER JOIN  students ON students.batch_id=batches.id LEFT OUTER JOIN archived_students ON archived_students.batch_id=batches.id  LEFT OUTER JOIN finance_fees INNER JOIN students as students_have_fee_due ON finance_fees.student_id=students_have_fee_due.id on finance_fees.batch_id=batches.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",
      :conditions=>["batches.is_deleted=0 AND batches.is_active=1"],
      :skip_multischool=>true}
    e.model="batch"
    e.fields=[:batch_name,:total_students,:male_students,:female_students,:relieved_students, :dues_live ]
    
  end
  
  entity :employee_department do |e|
    e.fetch_query={:select=>"employee_departments.id,employee_departments.name as emp_dpt_name,
      count(DISTINCT employees.id) as total_employees,count(DISTINCT IF(employees.gender like '%m%',employees.id,NULL)) as male_employees,
      count(DISTINCT IF(employees.gender like '%f%',employees.id,NULL)) as female_employees,count(DISTINCT archived_employees.id) as relieved_employees",
      :joins=>"LEFT OUTER JOIN employees ON employees.employee_department_id=employee_departments.id LEFT OUTER JOIN archived_employees on archived_employees.employee_department_id=employee_departments.id",
      :conditions=>["employee_departments.status=1"],:group=>"employee_departments.id",:skip_multischool=>true}
    e.model="employee_department"
    e.fields=[:emp_dpt_name,:total_employees,:male_employees,:female_employees,:relieved_employees]
    
  end
  if FedenaPlugin::AVAILABLE_MODULES.collect{|mod| mod[:name] }.include?"fedena_hostel"
    entity :hostel do |e|
      e.fetch_query={:select=>"schools.id,schools.name,count(DISTINCT hostels.id) as total_hostels,count(DISTINCT room_details.id) as total_rooms,
    count(DISTINCT room_details.id)-count(DISTINCT IF(room_allocations.is_vacated=0,room_details.id,NULL)) as available,
    count(DISTINCT room_details.id)-(count(DISTINCT room_details.id)-count(DISTINCT IF(room_allocations.is_vacated=0,room_details.id,NULL))) as occupied ",
        :joins=>"LEFT OUTER JOIN hostels ON hostels.school_id=schools.id LEFT OUTER JOIN `room_details` ON room_details.hostel_id = hostels.id LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",
        :group=>"schools.id"}
      e.model='school'
      e.has_child :total_hostels,:entity=>:school_wise_hostels
      e.fields=[:name,:total_hostels,:total_rooms,:available,:occupied]
    end

    entity :school_wise_hostels do |e|
      e.fetch_query={:select=>"hostels.id,hostels.name as hostel_name,hostels.hostel_type,count(DISTINCT room_details.id) as total_rooms,
    count(DISTINCT room_details.id)-count(DISTINCT IF(room_allocations.is_vacated=0,room_details.id,NULL)) as available,
    count(DISTINCT room_details.id)-(count(DISTINCT room_details.id)-count(DISTINCT IF(room_allocations.is_vacated=0,room_details.id,NULL))) as occupied",
        :joins=>"LEFT OUTER JOIN `room_details` ON room_details.hostel_id = hostels.id LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id ",:group=>'hostels.id',
        :skip_multischool=>true}
      e.model='hostel'
      e.has_child :hostel_name,:entity=>:room_details
      e.fields=[:hostel_name,:hostel_type,:total_rooms,:available,:occupied]
    end

    entity :room_details do |e|
      e.fetch_query={:select=>"hostel_id,FORMAT(room_details.rent,3) as total_rent,room_details.id,room_details.room_number,room_details.students_per_room as capability,(students_per_room-count(DISTINCT IF(room_allocations.is_vacated=0,room_allocations.id,NULL))) as available" ,
        :joins=>"LEFT OUTER JOIN `room_allocations` ON room_allocations.room_detail_id = room_details.id",
        :group=>'room_details.id',:skip_multischool=>true}
      e.model="room_detail"
      e.fields=[:room_number,:capability,:available,:total_rent]
    end
  end
  if FedenaPlugin::AVAILABLE_MODULES.collect{|mod| mod[:name] }.include?"fedena_transport"
    entity :transport do |e|
      e.fetch_query={:select=>"schools.id,schools.name,count(DISTINCT IF(vehicles.status='Active',vehicles.id,NULL)) as total_vehicles,
      count(DISTINCT IF(routes.main_route_id IS NULL,routes.id,NULL)) as total_routes",
        :joins=>"LEFT OUTER JOIN vehicles ON vehicles.school_id=schools.id LEFT OUTER JOIN routes ON routes.school_id=schools.id",
        :group=>"schools.id"}
      e.model='school'
      e.has_child :name,:entity=>:vehicle_details
      e.fields=[:name,:total_vehicles,:total_routes]
    end
    entity :vehicle_details do |e|
      e.fetch_query={:select=>"vehicles.vehicle_no,routes.destination,vehicles.no_of_seats-count(DISTINCT transports.id) as available_seats,vehicles.no_of_seats as total_seats",
        :joins=>"LEFT OUTER JOIN routes ON routes.id=vehicles.main_route_id LEFT OUTER JOIN transports ON transports.vehicle_id=vehicles.id",
        :group=>"vehicles.id",:skip_multischool=>true}
      e.model='vehicle'
      e.fields=[:vehicle_no,:destination,:total_seats,:available_seats]
    end
  end
  if FedenaPlugin::AVAILABLE_MODULES.collect{|mod| mod[:name] }.include?"fedena_library"
    entity :library do |e|
      e.fetch_query={:select=>"schools.id,schools.name,count(DISTINCT books.id) as total_books,count(DISTINCT IF(books.status='available',books.id,NULL)) as available,
      count(DISTINCT IF(books.status='borrowed',books.id,NULL)) as borrowed,count(DISTINCT IF(books.status='lost',books.id,NULL)) as lost",
        :joins=>"LEFT OUTER JOIN books on books.school_id=schools.id",:group=>"schools.id"}
      e.model='school'
      e.has_child :total_books , :entity=>:total_books
      e.has_child :available,:entity=>:available_books
      e.has_child :borrowed,:entity=>:borrowed_books
      e.has_child :lost,:entity=>:lost_books
      e.fields=[:name,:total_books,:available,:borrowed,:lost]
    end

    entity :total_books do |e|
      e.fetch_query={:select=>"books.title,books.author,books.book_number,books.status",:skip_multischool=>true}
      e.model='book'
      e.fields=[:book_number,:title,:author,:status]
    end
    entity :available_books do |e|
      e.fetch_query={:select=>"books.title,books.author,books.book_number",:conditions=>["books.status='available'"],:skip_multischool=>true}
      e.model='book'
      e.fields=[:book_number,:title,:author]
    end
    entity :borrowed_books do |e|
      e.fetch_query={:select=>"books.title,books.author,books.book_number",:conditions=>["books.status='borrowed'"],:skip_multischool=>true}
      e.model='book'
      e.fields=[:book_number,:title,:author]
    end
    entity :lost_books do |e|
      e.fetch_query={:select=>"books.title,books.author,books.book_number",:conditions=>["books.status='lost'"],:skip_multischool=>true}
      e.model='book'
      e.fields=[:book_number,:title,:author]
    end
  end


  # live statistics

  entity :student_admissions_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      admissions=School.find(:first,:select=>"((count(DISTINCT IF(students.admission_date BETWEEN '#{start_date}' AND '#{end_date}',students.id,NULL))) + (count(DISTINCT IF(archived_students.admission_date BETWEEN '#{start_date}' AND '#{end_date}',archived_students.id,NULL)))) as new_students_live, ((count(DISTINCT students.id)) + (count(DISTINCT archived_students.id))) as total_students_live",:joins=>"INNER JOIN  students ON students.school_id=schools.id LEFT OUTER JOIN archived_students ON archived_students.school_id = students.school_id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids])
      {"new_students_live"=>"#{admissions.new_students_live.to_i}","total_students_live"=>"#{admissions.total_students_live.to_i}"}
    end
    e.fields=[:new_students_live,:total_students_live]
    e.type=:live
    e.model= "school"
    e.has_child :new_students_live,:entity=>:school_wise_students_live
    e.has_child :total_students_live,:entity=>:school_wise_students_live
  end

  entity :school_wise_students_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      School.paginate(:all,:select=>"schools.name as school_name ,schools.id,((count(DISTINCT IF(students.admission_date BETWEEN '#{start_date}' AND '#{end_date}',students.id,NULL))) + (count(DISTINCT IF(archived_students.admission_date BETWEEN '#{start_date}' AND '#{end_date}',archived_students.id,NULL)))) as new_students_live, (count(DISTINCT students.id) + (count(DISTINCT archived_students.id))) as total_students_live",:joins=>"LEFT OUTER JOIN  students ON students.school_id=schools.id LEFT OUTER JOIN archived_students ON archived_students.school_id = students.school_id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
    end
    e.fields=[:school_name,:new_students_live,:total_students_live]
  end

  entity :archived_students_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      admissions=School.find(:first,:select=>"count(DISTINCT IF(archived_students.date_of_leaving BETWEEN '#{start_date}' AND '#{end_date}',archived_students.id,NULL)) as new_archived_students_live, count(DISTINCT archived_students.id) as total_archived_students_live",:joins=>"INNER JOIN  archived_students ON archived_students.school_id=schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids])
      {"new_archived_students_live"=>"#{admissions.new_archived_students_live.to_i}","total_archived_students_live"=>"#{admissions.total_archived_students_live}"}
    end
    e.fields=[:new_archived_students_live,:total_archived_students_live]
    e.type=:live
    e.model= "school"
    e.has_child :new_archived_students_live,:entity=>:school_wise_archived_students_live
    e.has_child :total_archived_students_live,:entity=>:school_wise_archived_students_live
  end

  entity :school_wise_archived_students_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      School.paginate(:all,:select=>"schools.name as school_name ,schools.id,count(DISTINCT IF(archived_students.date_of_leaving BETWEEN '#{start_date}' AND '#{end_date}',archived_students.id,NULL)) as new_archived_students_live, count(DISTINCT archived_students.id) as total_archived_students_live",:joins=>"LEFT OUTER JOIN  archived_students ON archived_students.school_id=schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
    end
    e.fields=[:school_name,:new_archived_students_live,:total_archived_students_live]
  end


  entity :employee_admissions_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      admissions=School.find(:first,:select=>"count(DISTINCT IF(employees.joining_date BETWEEN '#{start_date}' AND '#{end_date}',employees.id,NULL)) as new_employees_live, count(DISTINCT employees.id) as total_employees_live",:joins=>"INNER JOIN  employees ON employees.school_id=schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids])
      {"new_employees_live"=>"#{admissions.new_employees_live.to_i}","total_employees_live"=>"#{admissions.total_employees_live.to_i}"}
    end
    e.fields=[:new_employees_live,:total_employees_live]
    e.type=:live
    e.model="school"
    e.has_child :new_employees_live,:entity=>:school_wise_employees_live
    e.has_child :total_employees_live,:entity=>:school_wise_employees_live
  end

  entity :school_wise_employees_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      School.paginate(:all,:select=>"schools.name as school_name ,schools.id,count(DISTINCT IF(employees.joining_date BETWEEN '#{start_date}' AND '#{end_date}',employees.id,NULL)) as new_employees_live, count(DISTINCT employees.id) as total_employees_live",:joins=>"LEFT OUTER JOIN  employees ON employees.school_id=schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
    end
    e.fields=[:school_name,:new_employees_live,:total_employees_live]
  end

  entity :archived_employees_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      admissions=School.find(:first,:select=>"count(DISTINCT IF(archived_employees.created_at BETWEEN '#{start_date}' AND '#{end_date}',archived_employees.id,NULL)) as new_archived_employees_live, count(DISTINCT archived_employees.id) as total_archived_employees_live",:joins=>"INNER JOIN  archived_employees ON archived_employees.school_id=schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids])
      {"new_archived_employees_live"=>"#{admissions.new_archived_employees_live.to_i}","total_archived_employees_live"=>"#{admissions.total_archived_employees_live.to_i}"}
    end
    e.fields=[:new_archived_employees_live,:total_archived_employees_live]
    e.type=:live
    e.model="school"
    e.has_child :new_archived_employees_live,:entity=>:school_wise_archived_employees_live
    e.has_child :total_archived_employees_live,:entity=>:school_wise_archived_employees_live
  end

  entity :school_wise_archived_employees_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      School.paginate(:all,:select=>"schools.name as school_name ,schools.id,count(DISTINCT IF(archived_employees.created_at BETWEEN '#{start_date}' AND '#{end_date}',archived_employees.id,NULL)) as new_archived_employees_live, count(DISTINCT archived_employees.id) as total_archived_employees_live",:joins=>"LEFT OUTER JOIN  archived_employees ON archived_employees.school_id=schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
    end
    e.fields=[:school_name,:new_archived_employees_live,:total_archived_employees_live]
  end



  entity :courses_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      courses=School.find(:first,:select=>"count(DISTINCT IF(courses.created_at BETWEEN '#{start_date}' AND '#{end_date}',courses.id,NULL)) as new_courses_live, count(DISTINCT courses.id) as total_courses_live",:joins=>"INNER JOIN  courses ON courses.school_id=schools.id",:conditions=>["courses.is_deleted=0 AND schools.id IN (?) AND schools.is_deleted=0",school_ids])
      {"new_courses_live"=>"#{courses.new_courses_live.to_i}","total_courses_live"=>"#{courses.total_courses_live.to_i}"}
    end
    e.fields=[:new_courses_live,:total_courses_live]
    e.type=:live
    e.model="school"
    e.has_child :new_courses_live,:entity=>:school_wise_courses_live
    e.has_child :total_courses_live,:entity=>:school_wise_courses_live
  end

  entity :school_wise_courses_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      School.paginate(:all,:select=>"schools.name as school_name ,schools.id,count(DISTINCT IF(courses.is_deleted=0 AND courses.created_at BETWEEN '#{start_date}' AND '#{end_date}',courses.id,NULL)) as new_courses_live, count(DISTINCT IF(courses.is_deleted=0,courses.id,NULL)) as total_courses_live",:joins=>"LEFT OUTER JOIN  courses ON courses.school_id=schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
    end
    e.fields=[:school_name,:new_courses_live,:total_courses_live]
  end

  entity :finance_transactions_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      transactions= School.find(:first,:select=>"FORMAT(IFNULL(sum(IF((finance_transactions.transaction_date BETWEEN '#{start_date}' AND '#{end_date}') and (finance_transaction_categories.is_income=0), finance_transactions.amount,0)),0),3) as expense_live,FORMAT(IFNULL(sum(IF((finance_transactions.transaction_date BETWEEN '#{start_date}' AND '#{end_date}') and (finance_transaction_categories.is_income=1), finance_transactions.amount,0)),0),3) as income_live ",:joins=>"INNER JOIN finance_transactions on finance_transactions.school_id=schools.id INNER JOIN finance_transaction_categories ON finance_transaction_categories.id=finance_transactions.category_id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids])
      {"income_live"=>"#{transactions.income_live}","expense_live"=>"#{transactions.expense_live}"}
    end
    e.fields=[:income_live,:expense_live]
    e.type=:live
    e.model="school"
    e.has_child :income_live,:entity=>:school_wise_finance_transactions_live
    e.has_child :expense_live,:entity=>:school_wise_finance_transactions_live
  end

  entity :school_wise_finance_transactions_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      School.paginate(:select=>"schools.name as school_name ,schools.id , FORMAT(sum(IF((finance_transactions.transaction_date BETWEEN '#{start_date}' AND '#{end_date}') and (finance_transaction_categories.is_income=0), finance_transactions.amount,0))/count(*)*count(DISTINCT finance_transactions.id),3) as expense_live,FORMAT(sum(IF((finance_transactions.transaction_date BETWEEN '#{start_date}' AND '#{end_date}') and (finance_transaction_categories.is_income=1), finance_transactions.amount,0))/count(*)*count(DISTINCT finance_transactions.id),3) as income_live ",:joins=>"LEFT OUTER JOIN finance_transactions on finance_transactions.school_id=schools.id LEFT OUTER JOIN finance_transaction_categories ON finance_transaction_categories.id=finance_transactions.category_id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
    end
    e.fields=[:school_name,:income_live,:expense_live]
  end

  entity :finance_fee_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      fees_live=FinanceTransaction.find(:first,:select=>"FORMAT(IFNULL(sum(IF((finance_transactions.transaction_date BETWEEN '#{start_date}' AND '#{end_date}') AND (finance_transactions.finance_type='FinanceFee'),finance_transactions.amount,0)),0),3) as fees_live",:skip_multischool=>true,:conditions=>["finance_transactions.school_id IN (?)",school_ids])
      fees=FinanceFee.find(:first,:select=>"FORMAT(IFNULL(sum(IFNULL(finance_fees.balance,0)),0),3) as dues_live",:joins=>"INNER JOIN students  on students.id=finance_fees.student_id INNER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id",:skip_multischool=>true,:conditions=>["finance_fees.school_id IN (?) AND finance_fee_collections.is_deleted=0 AND finance_fee_collections.due_date  < '#{end_date}'",school_ids])
      {"fees_live"=>"#{fees_live.fees_live}","dues_live"=>"#{fees.dues_live}"}
    end
    e.fields=[:fees_live,:dues_live]
    e.type=:live
    e.model="school"
    e.has_child :fees_live,:entity=>:school_wise_finance_fee_live
    e.has_child :dues_live,:entity=>:school_wise_finance_fee_live
  end

  entity :school_wise_finance_fee_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      #      School.paginate(:select=>"schools.name as school_name ,schools.id,FORMAT(IFNULL(sum(finance_transactions.amount)/count(*)*count(DISTINCT finance_transactions.id),0),3) as fees_live, FORMAT(sum(IF(finance_fee_collections.is_deleted=0 AND finance_fee_collections.due_date < '#{end_date}',finance_fees.balance,0))/count(*)*count(DISTINCT finance_fees.id),3) as dues_live",:joins=>"LEFT OUTER JOIN finance_transactions ON finance_transactions.school_id=schools.id and finance_transactions.transaction_date BETWEEN '#{start_date}' and '#{end_date}' and finance_transactions.finance_type='FinanceFee' LEFT OUTER JOIN finance_fees on finance_fees.school_id=schools.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id ",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
      fees_due=School.paginate(:select=>"schools.name as school_name ,schools.id,FORMAT(sum(IF(finance_fee_collections.is_deleted=0 AND finance_fee_collections.due_date < '#{end_date}',finance_fees.balance,0)),3) as dues_live",:joins=>" LEFT OUTER JOIN finance_fee_collections  ON finance_fee_collections.school_id=schools.id LEFT OUTER JOIN finance_fees  INNER JOIN students on students.id=finance_fees.student_id on finance_fees.fee_collection_id=finance_fee_collections.id ",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
      School.paginate(:all,:select=>"schools.name as school_name ,schools.id,FORMAT(sum(IF((finance_transactions.transaction_date BETWEEN '#{start_date}' AND '#{end_date}') AND (finance_transactions.finance_type='FinanceFee'),finance_transactions.amount,0)),3) as fees_live",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:joins=>"LEFT OUTER JOIN finance_transactions ON finance_transactions.school_id = schools.id and finance_transactions.finance_type='FinanceFee'",:group=>"schools.id",:page=>page,:per_page=>per_page).each{|f| f['dues_live']=fees_due.select{|s| s.id==f.id}.first.dues_live}
    end
    e.fields=[:school_name,:fees_live,:dues_live]
  end

  entity :student_attendance_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      attendance=School.find(:first,:select=>"count(DISTINCT attendances.id) as absentees,count(DISTINCT students.id) as total,IFNULL(ROUND((100-(count(DISTINCT attendances.id)/count(DISTINCT students.id))*100),3),0.0) as percentage",:joins=>"LEFT OUTER JOIN attendances ON attendances.school_id=schools.id AND attendances.month_date='#{end_date.to_date}' LEFT OUTER JOIN students ON students.school_id=schools.id AND students.created_at <='#{end_date}'",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids])
      {"percentage"=>"#{attendance.percentage.to_d.truncate(1).to_f}%","absentees"=>"#{attendance.absentees}<span class='stat-small-text'> Absent / #{attendance.total}","total"=>attendance.total}
    end
    e.fields=[:percentage,:absentees]
    e.type=:attendance
    e.model="school"
    e.has_child :percentage,:entity=>:school_wise_student_attendance_live
  end

  entity :school_wise_student_attendance_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      School.paginate(:select=>"schools.name as school_name,CONCAT(count(DISTINCT attendances.id),'<span class=''stat-small-text''> Absent/',count(DISTINCT students.id),'</span>') as absentees,CONCAT(IFNULL(ROUND((100-(count(DISTINCT attendances.id)/count(DISTINCT students.id))*100),1),0.0),'%') as percentage",:joins=>"LEFT OUTER JOIN attendances ON attendances.school_id=schools.id AND attendances.month_date='#{end_date.to_date}' LEFT OUTER JOIN students ON students.school_id=schools.id AND students.created_at <='#{end_date}'",:group=>"schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:page=>page,:per_page=>per_page)
    end
    e.type=:attendance_live
    e.fields=[:school_name,:percentage,:absentees]
  end

  entity :employee_attendance_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
      attendance=School.find(:first,:select=>"count(DISTINCT employee_attendances.id) as absentees,ROUND((100-(count(DISTINCT employee_attendances.id)/(count(DISTINCT employees.id)))*100),3) as percentage, count(DISTINCT employees.id) as total",:joins=>"LEFT OUTER JOIN employee_attendances on employee_attendances.school_id=schools.id AND employee_attendances.attendance_date='#{end_date.to_date}' LEFT OUTER JOIN employees on employees.school_id=schools.id AND employees.created_at <='#{end_date}'",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids])
      {"percentage"=>"#{attendance.percentage.to_d.truncate(1).to_f}%","absentees"=>"#{attendance.absentees}<span class='stat-small-text'> Absent / #{attendance.total}","total"=>attendance.total}
    end
    e.fields=[:percentage,:absentees]
    e.type=:attendance
    e.model="school"
    e.has_child :percentage,:entity=>:school_wise_employee_attendance_live
  end

  entity :school_wise_employee_attendance_live do |e|
    e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
      School.paginate(:select=>"schools.name as school_name,schools.id,CONCAT(count(DISTINCT employee_attendances.id),'<span class=''stat-small-text''> Absent/',count(DISTINCT employees.id),'</span>') as absentees,CONCAT(ROUND((100-(count(DISTINCT employee_attendances.id)/(count(DISTINCT employees.id)))*100),1),'%') as percentage",:joins=>"LEFT OUTER JOIN employee_attendances on employee_attendances.school_id=schools.id AND employee_attendances.attendance_date='#{end_date.to_date}' LEFT OUTER JOIN employees on employees.school_id=schools.id AND employees.created_at <='#{end_date}'",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:group=>"schools.id",:page=>page,:per_page=>per_page)
    end
    e.type=:attendance_live
    e.fields=[:school_name,:percentage,:absentees]
  end
  if FedenaPlugin::AVAILABLE_MODULES.collect{|mod| mod[:name] }.include?"fedena_applicant_registration"
    entity :applicant_registrations_live do |e|
      e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids|
        applicants=School.find(:first,:select=>"count(DISTINCT IF(applicants.submitted = true AND applicants.created_at BETWEEN '#{start_date}' AND '#{end_date}',applicants.id,NULL)) as registrations,count(DISTINCT IF(applicants.created_at BETWEEN '#{start_date}' AND '#{end_date}' AND application_statuses.name='alloted',applicants.id,NULL)) as allotted",:joins=>"INNER JOIN applicants ON applicants.school_id=schools.id LEFT OUTER JOIN application_statuses ON application_statuses.id = applicants.status",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids])
        {"registrations"=>applicants.registrations,"allotted"=>applicants.allotted}
      end
      e.type=:live
      e.fields=[:registrations,:allotted]
      e.model='school'
      e.has_child :registrations,:entity=>:school_wise_applicant_registrations
    end

    entity :school_wise_applicant_registrations do |e|
      e.fetch_query_proc=Proc.new do |start_date,end_date,school_ids,page,per_page|
        School.paginate(:all,:select=>"schools.id,schools.name as school_name,count(DISTINCT IF(applicants.submitted = true AND applicants.created_at BETWEEN '#{start_date}' AND '#{end_date}',applicants.id,NULL)) as registrations,count(DISTINCT IF(applicants.created_at BETWEEN '#{start_date}' AND '#{end_date}' AND application_statuses.name = 'alloted',applicants.id,NULL)) as allotted",:joins=>"LEFT OUTER JOIN applicants ON applicants.school_id=schools.id LEFT OUTER JOIN application_statuses ON application_statuses.id = applicants.status",:group=>"schools.id",:conditions=>["schools.id IN (?) AND schools.is_deleted=0",school_ids],:page=>page,:per_page=>per_page)
      end
      e.fields=[:school_name,:registrations,:allotted]
    end
  end
  
end