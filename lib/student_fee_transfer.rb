class StudentFeeTransfer
  
  def initialize(batch_id, transport=true, hostel=true)
    @batch = Batch.find_by_id(batch_id)
    @transport = transport
    @hostel = hostel
  end

  
  def transfer_fee_collections
    batch_students.each do |student|
      inspect_and_transfer_fees(student)
    end
  end
  
  private
  
  def inspect_and_transfer_fees(student)
    if check_eligibility(student)
      fetch_fees_and_transfer(student, 'finance') 
      fetch_fees_and_transfer(student, 'transport')  if @transport
      fetch_fees_and_transfer(student, 'hostel')  if @hostel
    end
  end
  
  #previous batch availability check
  def check_eligibility(student)
    previous_batch(student) == student.batch_id ? 
      failed_condition("For student #{student.admission_no} in batch #{@batch.name}, Does not have previous batches ") : true
  end
  
  #check fee collections present for the current batch and initiate the transfer
  def fetch_fees_and_transfer(student, fee_type)
    fees_of_student(student, fee_type).each do |ff|
      if fee_collection_for_batch(ff, fee_type).present?
        finace_fee_check(fee_type) ? transfer_fees(student, ff, fee_type) : transfer_other_fees(student, ff, fee_type)
      end
    end
  end
  
  #transfer and modify record initiate
  def transfer_fees(student, ff, fee_type)
    if ff.finance_transactions.empty?
      transfer_fees_to_batch(student, ff)
    else
      modify_fee_records(ff,student, fee_type)
    end
  end
  
  #modify transport and hostel fee batch id
  def transfer_other_fees(student, ff, fee_type)
    modify_fee_records(ff,student, fee_type)
  end
  
  #delete old entry and create new entry for new batch
  def transfer_fees_to_batch(student, ff)
    ffc = fee_collection(ff, 'finance')
    if ff.destroy
      FinanceFee.new_student_fee(ffc,student)
    else
      failed_condition("unable Reassign Fee #{ffc.name} for student #{student.admission_no} due to #{ff.errors.full_messages}")
    end
  end
 
  #update batch id in particular reports and finance fee
  def modify_fee_records(ff, student, fee_type)
    modify_reports(ff, fee_type)
    modify_ff(ff, fee_type)
  end
  
  #modify finance fee record
  def modify_ff(ff, fee_type)
    if entry_type_check(fee_type)
      ff.batch_id = @batch.id
    else
      ff.groupable_id = @batch.id
    end
    ff.send(:update_without_callbacks)
  end
  
  #modify expected and paid record reports
  def modify_reports(ff, fee_type)
    type = fee_model_name(fee_type)
    
    [0,1].each do |ind|
      modify_particular_reports(ff, ind, type)
    end
  end
  
  #fetch_fee_collection_name
  def fee_model_name(fee_type)
    "#{fee_type.capitalize}FeeCollection"
  end
  
  #update batch id in particular reports
  def modify_particular_reports(ff, ind, type)
    report_record(ff, ind, type).each do |report|
      report.batch_id = @batch.id
      report.send(:update_without_callbacks)
    end
  end
  
  #fetch report data for previous batch
  def report_record(ff, ind, type)
    collection_id = fee_collection_id(ff, type)
    batch_id = fee_collection_batch_id(ff, type)
    student_id = fee_collection_student_id(ff, type)
    if ind == 0
      CollectionMasterParticularReport.find_all_by_student_id_and_collection_id_and_collection_type_and_batch_id(student_id, collection_id, type, batch_id)
    else
      MasterParticularReport.find_all_by_student_id_and_collection_id_and_collection_type_and_batch_id(student_id, collection_id, type, batch_id)
    end
  end
  
  def fee_collection_student_id(ff, type)
    type == 'TransportFeeCollection' ? ff.receiver_id : ff.student_id
  end
  
  def fee_collection_batch_id(ff, type)
    type == 'TransportFeeCollection' ? ff.groupable_id : ff.batch_id
  end
  
  def fee_collection_id(ff, type)
    case type
    when 'FinanceFeeCollection'
      ff.fee_collection_id
    when 'TransportFeeCollection'
      ff.transport_fee_collection_id
    when 'HostelFeeCollection'
      ff.hostel_fee_collection_id
    end
  end
  #check presence of collection for current batch
  def fee_collection_for_batch(ff, fee_type)
    collection = fee_collection(ff, fee_type)
    collection_check =  collection.present? ? 
      check_collection_for_current_batch(collection, fee_type) : failed_condition("For student #{student_info(ff, fee_type)} in batch #{@batch.name} with Fee #{ff.id} and type #{fee_type}, Does not have fee collection ")
    return collection_check
  end
  
  #fetch student info
  def student_info(ff, fee_type)
    finace_fee_check(fee_type) ? ff.student.admission_no : ff.receiver.admission_no
  end
  
  #check collection presence for the current batch
  def check_collection_for_current_batch(collection, fee_type)
    collection_batch_check(collection, fee_type) ? 
      true : failed_condition("Fee collection #{collection.name} not assigned for batch #{@batch.name}, type #{fee_type}")
  end
  
  #fee collection presence check for batch
  def collection_batch_check(collection, fee_type)
    if fee_type=='hostel'
      #HostelFeeCollection.find_by_name_and_batch_id_and_is_deleted_and_start_date_and_due_date(collection.name, @batch.id, collection.is_deleted, 
      #  collection.start_date, collection.due_date)
      true
    else
      collection.batches.collect(&:id).include? @batch.id
    end
  end
  
  #fee collection presence check
  def fee_collection(ff, fee_type)
    send("#{fee_type}_fee_collection",ff)
  end
  
  #finance_fee_collection check
  def finance_fee_collection(ff)
    ff.finance_fee_collection.present? ? ff.finance_fee_collection : ""
  end
  
  #transport_fee_collection check
  def transport_fee_collection(ff)
    ff.transport_fee_collection.present? ? ff.transport_fee_collection : ""
  end
  
  #hostel_fee_collection check
  def hostel_fee_collection(ff)
    ff.hostel_fee_collection.present? ? ff.hostel_fee_collection : ""
  end
  
  #all the previous fee details which the same course
  def fees_of_student(student, fee_type)
    send("#{fee_type}_fee_records",student)
  end
  
  #flag to check fiance fee collection or not
  def finace_fee_check(fee_type)
    fee_type == 'finance'
  end
  
  def entry_type_check(fee_type)
    (fee_type == 'finance') or (fee_type == 'hostel')
  end
  
  #transport fee details
  def transport_fee_records(student)
    student.transport_fees.active.all(:conditions=>["transport_fees.groupable_id in (?) and transport_fees.groupable_type = ?",batchids_for_course, 'Batch'])
  end
  
  #hostel fee details
  def hostel_fee_records(student)
    student.hostel_fees.active.all(:conditions=>["hostel_fees.batch_id in (?)",batchids_for_course])
  end
  
  #finance fee details
  def finance_fee_records(student)
    student.finance_fees.active.all(:conditions=>["finance_fees.batch_id in (?)",batchids_for_course])
  end
  
  #all batch ids of current batch expect selected batch
  def batchids_for_course
    @batch.course.batches.active.collect(&:id) - [@batch.id]
  end
  
  #students inside the batch
  def batch_students
    @batch.students
  end
  
  #method for all failed condition, which will write the error log and return false
  def failed_condition(msg)
    log_it(msg)
    return false
  end
  
  #fetch student previuo _batch_id
  def previous_batch(student)
    batch_student_last_record = student.batch_students.last
    batch_id = batch_student_last_record.present? ? batch_student_last_record.batch_id : student.batch_id
    return batch_id
  end
  
  #create logger and log the errors
  def log_it(details)
    logit = Logger.new(log_name)
    logit.info(details)
  end
  
  def log_name
    "log/#{MultiSchool.current_school.id}.log"
  end
  
end
