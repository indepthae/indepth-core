class CollectionReport
  def initialize(start_date, end_date, batch_ids, active_batches_selection, per_page, page)
    #initialize variables required
    @start_date = start_date
    @end_date = end_date
    @batch_ids = batch_ids
    if !@batch_ids.present?
      @batch_ids = []
    end
    @active_batches_selection = active_batches_selection
    @per_page = per_page
    @page = page
    setup_values()
  end


  def setup_values
    #loading up students
    load_required_students()

    @table = []
    @collection_names = []
    @finance_collection_names = []
    @transport_collection_names = []
    @hostel_collection_names = []
    @instant_fee_collection_names = []
    @total_tax_enabled = false

    set_plugin_availability()
    #Eager loading
    eager_load()
    build_table()
  end


  def set_collections_availability
    @fee_collection_present = @fee_collection_present || FinanceFee.first(:joins => "#{account_active_joins}",
        :conditions=>["finance_fees.batch_id in (?) AND #{account_active_conditions}",@required_batch_ids] ).present?
    if @transport_active
      @fee_collection_present = @fee_collection_present || TransportFee.first(:joins => "#{account_active_joins(true, 'transport_fees')}",
        :conditions=>[" groupable_type ='Batch' && groupable_id in (?) AND #{account_active_conditions}",@required_batch_ids] ).present?
    end
    if @hostel_active
      @fee_collection_present = @fee_collection_present || HostelFee.first(:joins => "#{account_active_joins(true, 'hostel_fees')}",
        :conditions=>["hostel_fees.batch_id in (?) AND #{account_active_conditions}",@required_batch_ids] ).present?
    end
    if @instant_fee_active
      @fee_collection_present = @fee_collection_present || InstantFee.first(:joins => "#{account_active_ft_joins('instant_fees')}",
        :conditions=>["pay_date >= ? and pay_date <= ? AND #{account_active_conditions}", @start_date, @end_date]).present?
    end
  end


  def set_plugin_availability
    @transport_active = FedenaPlugin.can_access_plugin?('fedena_transport')
    @hostel_active = FedenaPlugin.can_access_plugin?('fedena_hostel')
    @instant_fee_active = FedenaPlugin.can_access_plugin?('fedena_instant_fee')
  end

  def student_ids_for_inactive_batches
    #In case of Inactive batch - Fetch Students
    archived_students_in_inactive_batch =  ArchivedStudent.all(:conditions=>["batch_id in (?)", @batch_ids], :order=>'updated_at DESC')
    archived_student_ids = archived_students_in_inactive_batch.collect(&:former_id)
    batch_student = BatchStudent.all(:conditions=>["batch_id in (?) ", @batch_ids], :order=>'updated_at DESC')
    s_ids = (batch_student.collect(&:student_id) + archived_student_ids ).uniq
    #TIMELINE RECREATION - Assuming student only belongs in it's last inactive batch
    grouped_archived_students = archived_students_in_inactive_batch.group_by(&:former_id)
    inactive_student_batches = BatchStudent.all(:joins => [:batch] ,:conditions=>["batch_students.student_id in (?) and batches.is_active=false and batches.is_deleted = false and
    ((batches.start_date >= ? and batches.start_date <= ? ) or (batches.end_date >= ? and batches.end_date <= ?) or (batches.start_date <= ? and batches.end_date >= ?))",
    s_ids, @start_date, @end_date, @start_date, @end_date, @start_date, @end_date], :order=>'updated_at DESC')
    #FILTERING Students
    s_ids.each_with_index do |s_id, index|
      students_batches =  inactive_student_batches.select{|bs| bs.student_id == s_id}
      if archived_student_ids.include?(s_id)
        #in case of archival  -- assuming archival doesnt have any further transfers
        original_last_batch = grouped_archived_students[s_id].first.batch_id
      else
        original_last_batch = students_batches.first.batch_id if students_batches.present?
      end
      # Show this student only if -- origianl_last_batch (last inactive batch irrespective of selected batch_ids) is present in @batch_ids
      if original_last_batch.present?
        if !@batch_ids.include?(original_last_batch)
          s_ids[index] = nil
        end
      end
    end
    #Unwanted s_ids were made nil -- remove them
    s_ids = s_ids.compact
    return s_ids
  end


  def load_inactive_batches_students_with_pagination
    #Get required student_ids based on inactive batch selection
    s_ids = student_ids_for_inactive_batches()

    @students = Student.paginate_by_sql(["SELECT id, first_name, middle_name, last_name, batch_id, admission_no
    FROM students
    WHERE school_id = ? and students.id IN (?)
    UNION
    SELECT former_id AS id, first_name, middle_name, last_name, batch_id,admission_no
    FROM archived_students
    WHERE school_id = ? and archived_students.former_id IN (?)
    ORDER BY batch_id DESC, first_name ASC, middle_name ASC, last_name ASC", MultiSchool.current_school.id, s_ids, MultiSchool.current_school.id, s_ids],:page => @page, :per_page =>@per_page)
  end


  def load_active_batches_students_with_pagination
    @students = Student.paginate_by_sql(["SELECT id, first_name, middle_name, last_name, batch_id, admission_no
    FROM students use index(index_students_on_batch_id)
    WHERE school_id = ? and batch_id IN (?)
    UNION
    SELECT former_id AS id, first_name, middle_name, last_name, batch_id,admission_no
    FROM archived_students use index(index_archived_students_on_batch_id)
    WHERE school_id = ? and batch_id IN (?)
    ORDER BY batch_id DESC, first_name ASC, middle_name ASC, last_name ASC", MultiSchool.current_school.id, @batch_ids, MultiSchool.current_school.id, @batch_ids],:page => @page, :per_page =>@per_page)
  end


  def load_all_inactive_batches_students
    #Get required student_ids based on inactive batch selection
    s_ids = student_ids_for_inactive_batches()
    @students = Student.find_by_sql(["SELECT id, first_name, middle_name, last_name, batch_id, admission_no,
    immediate_contact_id, sibling_id, phone2, 'present' AS current_type FROM students
    WHERE school_id = ? and students.id IN (?)
    UNION
    SELECT former_id AS id, first_name, middle_name, last_name, batch_id,admission_no,
    immediate_contact_id, sibling_id, phone2, 'archived' AS current_type FROM archived_students
    WHERE school_id = ? and archived_students.former_id IN (?)
    ORDER BY batch_id DESC, first_name ASC, middle_name ASC, last_name ASC", MultiSchool.current_school.id, s_ids, MultiSchool.current_school.id, s_ids])
  end


  def load_all_active_batches_students
    @students = Student.find_by_sql(["SELECT id, first_name, middle_name, last_name, batch_id, admission_no, 
    immediate_contact_id, sibling_id, phone2, 'present' AS current_type FROM students use index(index_students_on_batch_id)
    WHERE school_id = ? and batch_id IN (?)
    UNION
    SELECT former_id AS id, first_name, middle_name, last_name, batch_id,admission_no,
    immediate_contact_id, sibling_id, phone2, 'archived' AS current_type FROM archived_students use index(index_archived_students_on_batch_id)
    WHERE school_id = ? and batch_id IN (?)
    ORDER BY batch_id DESC, first_name ASC, middle_name ASC, last_name ASC", MultiSchool.current_school.id, @batch_ids, MultiSchool.current_school.id, @batch_ids])
  end


  def load_students_with_pagination
    if @active_batches_selection
      load_active_batches_students_with_pagination()
    else
      load_inactive_batches_students_with_pagination()
    end
    #Assign students count
    @students_count = @students.total_entries
  end


  def load_all_students
    if @active_batches_selection
      load_all_active_batches_students()
    else
      load_all_inactive_batches_students()
    end
    @students_count = @students.count
  end


  def load_required_students
    if @batch_ids.present?
      if @per_page.present?
        load_students_with_pagination()
      else
        load_all_students()
      end
    else
      @students=[]
    end
    #required student_ids
    @student_ids = @students.collect(&:id)
  end

  def account_active_conditions
    "(fa.id IS NULL OR fa.is_deleted = false)"
  end

  def account_active_joins other_collection = false, fee_name = nil
    fee_name = other_collection ? (fee_name.present? ? fee_name : "finance_fees") : "finance_fees"
    collection_name = "#{fee_name.singularize}_collections"
    (other_collection.present? ?
        "INNER JOIN #{collection_name} ON #{collection_name}.id = #{fee_name}.#{collection_name.singularize}_id" :
        " INNER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id") +
        " LEFT JOIN fee_accounts fa ON fa.id = #{collection_name}.fee_account_id "
  end

  def account_active_ft_joins object_name
    "INNER JOIN finance_transactions ft ON ft.finance_id = #{object_name}.id AND ft.finance_type = '#{object_name}'
     INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
      LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
  end

  def eager_load
    #calculating @required_batch_ids to minimize eager load
    if @active_batches_selection
      @students_active_student_batches =  BatchStudent.all(:joins=>[:batch],:conditions=>["batches.is_active = true and batch_students.student_id in (?)", @student_ids])
      @required_batch_ids = (@students.collect(&:batch_id) + @students_active_student_batches.collect(&:batch_id)).uniq
    else
      @batch_student_history = BatchStudent.all(:conditions=>["student_id in (?)", @student_ids], :order=>'updated_at DESC')
      @required_batch_ids = (@batch_student_history.collect(&:batch_id) + @students.collect{|s| s.batch_id if @batch_ids.include?(s.batch_id)}).uniq
      #filter based on batch_ids selected
      #@required_batch_ids = @required_batch_ids.select{|b_id| @batch_ids.include?(b_id) }
    end
    @required_batch_ids = @required_batch_ids.compact
    set_collections_availability()

    #EAGER LOADING
    @loaded_finance_fees = FinanceFee.all(:conditions=>["#{account_active_conditions} AND student_id in (?) and
    finance_fees.batch_id in (?)",@student_ids, @required_batch_ids ], :joins => "#{account_active_joins}",
    :include =>[:fee_transactions, :finance_transactions, :student_category,{:finance_fee_collection => [{:collection_particulars =>{:finance_fee_particular => :receiver}},
    {:collection_discounts => {:fee_discount => :receiver}}, {:fine=>:fine_rules} ]}, :batch, :student_category,{:tax_collections => :tax_slab}])

    if @transport_active
      @loaded_transport_fees = TransportFee.all(:conditions=>["#{account_active_conditions} AND receiver_type='Student' and
      receiver_id in (?) and groupable_type = 'Batch' and groupable_id in (?)",@student_ids, @required_batch_ids ],
      :include =>  [:transport_fee_collection, :finance_transactions, :transport_fee_discounts],
      :joins => "#{account_active_joins(true, 'transport_fees')}")
    end

    if @hostel_active
      @loaded_hostel_fees = HostelFee.all(:conditions=>["#{account_active_conditions} AND student_id in (?) and
            hostel_fees.batch_id in (?)", @student_ids, @required_batch_ids ],
      :include => [:hostel_fee_collection, :finance_transactions],
      :joins => "#{account_active_joins(true, 'hostel_fees')}")
    end

    if @instant_fee_active
      @loaded_instant_fees = InstantFee.all(:conditions=>["#{account_active_conditions} AND
         instant_fees.payee_type='Student' and instant_fees.payee_id in (?) and groupable_type = 'Batch' and
         groupable_id in (?)",@student_ids,@required_batch_ids ],
      :include=> [:instant_fee_category,:instant_fee_details], :joins => "#{account_active_ft_joins('instant_fees')}")
    end
    @batches = Batch.all(:conditions=>["id in (?)",@required_batch_ids], :include =>[:course])
  end


  def build_table
    details = UserAdditionalDetails.new(@students, 'Student', false)
    addl_details = details.fetch_additional_details
    #build hash for displaying table
    @students.each_with_index do |s, i|
      #setting up required data for student from Eager load
      if @active_batches_selection
        active_batch_ids = @students_active_student_batches.select{|b| b.student_id == s.id}.collect(&:batch_id)
        current_student_batch_ids = [s.batch_id] + active_batch_ids
        student_batch_ids = @required_batch_ids.select{|b_id| current_student_batch_ids.include?(b_id)}
      else
        # Get Last inactive batch and corresponding desendent batches of student
        #Note batch_student_history is ordered by updated_at (DESC)
        student_batches = @batch_student_history.select{|h| h.student_id == s.id}
        #for current student find latest batch selected
        if @batch_ids.include?(s.batch_id)
          #in case of archival  -- assuming archival doesnt have any further transfers
          latest_batch_selected = s.batch_id
        else
          latest_student_batch = student_batches.select{|sb| @batch_ids.include?(sb.batch_id)}.first
          latest_batch_selected = latest_student_batch.batch_id if latest_student_batch.present?
        end
        current_student_batch_ids =  (student_batches.collect(&:batch_id))
        current_student_batch_ids =  [s.batch_id] + current_student_batch_ids if @batch_ids.include?(s.batch_id)
        if latest_batch_selected.present?
          index = current_student_batch_ids.index(latest_batch_selected)
          current_student_batch_ids =  current_student_batch_ids[(index)...(current_student_batch_ids.length)] if index.present?
          #current_student_batch_ids =  current_student_batch_ids.split(latest_batch_selected).drop(1).flatten
          #current_student_batch_ids = [latest_batch_selected] + current_student_batch_ids
        end
        current_student_batch_ids = current_student_batch_ids.uniq
        student_batch_ids = current_student_batch_ids

      end
      student_batch_names = @batches.select{|b| student_batch_ids.include?(b.id)}.collect{|b| b.full_name}.join(", ")

      balance=0
      finance_fees = @loaded_finance_fees.select{|ff| ff.student_id == s.id &&  !ff.finance_fee_collection.is_deleted && (student_batch_ids.include?(ff.batch_id)  )}
      if @transport_active
        transport_fees = @loaded_transport_fees.select{|tf| tf.receiver_type = 'Student' && tf.receiver_id == s.id && tf.is_active && !tf.transport_fee_collection.is_deleted && (tf.groupable_type == "Batch" && student_batch_ids.include?(tf.groupable_id) )}
      end
      if @hostel_active
        hostel_fees = @loaded_hostel_fees.select{|hf| hf.student_id == s.id && !hf.hostel_fee_collection.is_deleted && (student_batch_ids.include?(hf.batch_id) ) }
      end
      if @instant_fee_active
        instant_fees = @loaded_instant_fees.select{|inst_fee| inst_fee.payee_id == s.id && (inst_fee.pay_date.to_date >= @start_date.to_date && inst_fee.pay_date.to_date <= @end_date.to_date)}
      end

      @table[i]={
        :name=>s.full_name,
        :admn_no=>s.admission_no,
        :batch_name=>student_batch_names,
        :total_fees=>0,
        :fees_paid=>0,
        :fees_due=>0,
        :total_discount_given=>0,
        :total_expected_fine=>0,
        :total_fine_paid=>0
      }.merge(addl_details[s.id])
      #For total calculation
      @table[i]["finance_fee_collection"]={}
      @table[i]["transport_fee_collection"]={}
      @table[i]["hostel_fee_collection"]={}
      @table[i]["instant_fee_collection"]={}
      @table[i][:total_fees] = 0.0
      @table[i][:total_discount_given] = 0.0
      @table[i][:fees_paid] = 0.0
      @table[i][:fees_due] = 0.0
      @table[i][:total_expected_fine] = 0.0
      @table[i][:total_fine_paid] = 0.0
      @table[i][:total_tax_amount]= 0.0
      @table[i][:total_tax_paid] = 0.0

      #building finance_fees
      finance_fee_section(finance_fees,i,s)

      #building transport_fees
      if @transport_active
        transport_fee_section(transport_fees,i)
      end

      #building hostel_fees
      if @hostel_active
        hostel_fee_section(hostel_fees,i)
      end

      #building instant_fees
      if @instant_fee_active
        instant_fee_section(instant_fees,i)
      end
    end
    join_collection_names()
  end


  def join_collection_names
    @finance_collection_names = @finance_collection_names.uniq
    @collection_names = @collection_names + @finance_collection_names.to_a

    @hostel_collection_names = @hostel_collection_names.uniq
    @collection_names = @collection_names + @hostel_collection_names.to_a

    @transport_collection_names = @transport_collection_names.uniq
    @collection_names = @collection_names + @transport_collection_names.to_a

    @instant_fee_collection_names = @instant_fee_collection_names.uniq
    @collection_names = @collection_names + @instant_fee_collection_names.to_a
  end


  def add_up_total(index, fees, discount, paid, due, fine_paid, fine, tax_amount, tax_paid)
    @table[index][:total_fees] += fees
    @table[index][:total_discount_given] += discount
    @table[index][:fees_paid] += paid
    @table[index][:fees_due] += due
    @table[index][:total_fine_paid] += fine_paid
    @table[index][:total_expected_fine] += fine
    @table[index][:total_tax_amount] += tax_amount
    @table[index][:total_tax_paid] += tax_paid
  end


  def finance_fee_section(finance_fees,i,student)
    #FINANCE FEE COLLECTION SECTION ----------------------------------------------------------------------------------------------------------------------------------
    finance_fees.each do |f|
      collection= f.finance_fee_collection
      #For calculating per collection
      fees=0.0; discount=0.0; paid=0.0; due=0.0; fine_paid=0.0; fine=0.0; tax_paid=0.0; tax_amount=0.0; tax_enabled=false;
      if f.particular_total.present?
        fees=f.particular_total.to_f
      else
        #particular_total column was not present (old) -- so  calculate
        f.finance_fee_collection.collection_particulars.each do |cp|
          if cp.finance_fee_particular.present? and ((cp.finance_fee_particular.batch_id==f.batch_id) and
                ((cp.finance_fee_particular.receiver_id==student.id and cp.finance_fee_particular.receiver_type=="Student") or
                (cp.finance_fee_particular.receiver_id==f.batch.id and cp.finance_fee_particular.receiver_type=="Batch") or
                (cp.finance_fee_particular.receiver_id==f.student_category.id and cp.finance_fee_particular.receiver_type=="StudentCategory")))

            fees= fees + cp.finance_fee_particular.amount
          end
        end
      end

      #discount calculation
      if f.discount_amount.present?
        discount=f.discount_amount.to_f
      else
        #discount_amount column was not present (old) -- so  calculate
        f.finance_fee_collection.collection_discounts.each do |cd|
          if cd.fee_discount.present? and ((cd.fee_discount.batch_id==f.batch_id and cd.fee_discount.receiver.present?) and (cd.fee_discount.receiver==student or
                  cd.fee_discount.receiver==f.batch or cd.fee_discount.receiver==f.student_category ))
            d= cd.fee_discount
            discount = discount + (d.master_receiver_type=='FinanceFeeParticular' ?
                (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) :
                fees * d.discount.to_f/(d.is_amount? ? fees : 100)).to_f
          end
        end
      end

      if @start_date.present? && @end_date.present?
        #paid amount calculation
        paid= f.finance_transactions.compact.select{|t| t.transaction_date.to_date <= @end_date }.collect(&:amount).sum.to_f
        fine_paid= f.finance_transactions.compact.select{|t| t.transaction_date.to_date <= @end_date }.collect(&:fine_amount).sum.to_f
        #isolating fine portion from paid amount
        paid= paid-fine_paid
      end

      tax_enabled = f.tax_enabled.present? ? f.tax_enabled : false
      if tax_enabled
        #tax
        @total_tax_enabled=true
        tax_amount = f.tax_amount.to_f  if f.tax_amount.present?
        tax_paid = f.finance_transactions.compact.select{|t|  t.transaction_date.to_date <= @end_date  }.collect(&:tax_amount).sum.to_f
      end
      @finance_collection_names << {:name=>collection.name, :id=>collection.id, :collection_type=>"finance_fee_collection", :tax_enabled=>tax_enabled }
      amount_after_discount = fees - discount
      amount_after_discount = 0 if  amount_after_discount < 0
      amount_after_tax = amount_after_discount + tax_amount

      #fine calculation till - end date
      due_date= collection.due_date.to_date
      auto_fine=0.0; days=0;
      if f.is_paid
        last_transaction= f.finance_transactions.sort{|x,y| x.transaction_date <=> y.transaction_date}.last
        if last_transaction.present?
          last_transaction_date = last_transaction.transaction_date

          if last_transaction_date <= due_date
            days=0
          elsif last_transaction_date <= @end_date
            days=(last_transaction_date - due_date).to_i
          elsif last_transaction_date > @end_date
            days=(@end_date - due_date).to_i
          else
          end
        else
          # no transactons - but is_paid= true --- cases like 100% discount
          days=0
        end
      else
        #not paid yet
        days=(@end_date - due_date).to_i
      end
      if collection.fine.present? and days > 0 and !f.is_fine_waiver
        if Configuration.is_fine_settings_enabled? && f.balance <= 0 && f.is_paid == false && !f.balance_fine.nil?
          auto_fine = auto_fine + f.balance_fine
        else
        applicable_fine_rule = collection.fine.fine_rules.select{|fr| fr.fine_days <= days && fr.created_at <= collection.created_at }.sort{|x,y| x.fine_days <=> y.fine_days}.last
        if applicable_fine_rule.present?
          auto_fine = auto_fine + (applicable_fine_rule.is_amount ? applicable_fine_rule.fine_amount : (amount_after_discount * applicable_fine_rule.fine_amount)/100 )
        end
        end
      end
      fine = auto_fine

      #due calculation
      due = amount_after_tax - (paid)
      due = due.zero? && 0.0 || due #avoid -0.0 case --(negative zero)

      @table[i]["finance_fee_collection"][collection.id] = {
        :fees=> fees,
        :paid=>paid,
        :due=>due,
        :discount=>discount,
        :fine=>fine,
        :fine_paid=>fine_paid,
        :tax_amount=>tax_amount,
        :tax_paid=> tax_paid,
        :tax_enabled=> tax_enabled
      }
      @table[i][:total_fees] += fees
      @table[i][:total_discount_given] += discount
      @table[i][:fees_paid] += paid
      @table[i][:fees_due] += due
      @table[i][:total_fine_paid] += fine_paid
      @table[i][:total_expected_fine] += fine
      @table[i][:total_tax_amount] += tax_amount
      @table[i][:total_tax_paid] += tax_paid
    end
  end


  def transport_fee_section(transport_fees,i)
    # TRANSPORT FEE COLLECTION SECTION ----------------------------------------------------------------------------------------------------------------------------------
    transport_fees.each do |t|
      collection= t.transport_fee_collection

      fees=0.0; discount=0.0; paid=0.0; due=0.0; fine_paid=0.0; fine=0.0; tax_amount=0.0; tax_paid=0.0; tax_enabled=false;
      fees= t.bus_fare
      if @start_date.present? && @end_date.present?
        #paid amount calculation
        paid= t.finance_transactions.select{|ft| ft.transaction_date.to_date <= @end_date  }.collect(&:amount).sum.to_f
        fine_paid= t.finance_transactions.select{|ft| ft.transaction_date.to_date <= @end_date  }.collect(&:fine_amount).sum.to_f
        paid = paid -fine_paid
      end

      discount = t.total_discount_amount

      tax_enabled = t.tax_enabled.present? ? t.tax_enabled : false
      if tax_enabled
        #tax
        @total_tax_enabled=true
        tax_amount = t.tax_amount.to_f if t.tax_amount.present?
        tax_paid = t.is_paid? ? t.tax_amount.to_f : t.finance_transactions.select{|ft| ft.transaction_date.to_date <= @end_date  }.collect(&:tax_amount).sum.to_f
      end
      @transport_collection_names << {:name=>collection.name,:id=>collection.id, :collection_type=>"transport_fee_collection" ,:tax_enabled=>tax_enabled}

      #fine amount is paid amount - only manual fine present
      fine=fine_paid
      #calculate discount here -- when discount feature is added
      amount_after_discount = fees - discount
      amount_after_discount = 0 if  amount_after_discount < 0
      amount_after_tax = amount_after_discount + tax_amount

      #due calculation
      due = amount_after_tax - (paid)
      due = due.zero? && 0.0 || due #avoid -0.0 case --(negative zero)

      due_date= collection.due_date.to_date
      auto_fine=0.0; days=0;
      if t.is_paid?
        last_transaction= t.finance_transactions.sort{|x,y| x.transaction_date <=> y.transaction_date}.last
        if last_transaction.present?
          last_transaction_date = last_transaction.transaction_date

          if last_transaction_date <= due_date
            days=0
          elsif last_transaction_date <= @end_date
            days=(last_transaction_date - due_date).to_i
          elsif last_transaction_date > @end_date
            days=(@end_date - due_date).to_i
          else
          end
        else
          # no transactons - but is_paid= true --- cases like 100% discount
          days=0
        end
      else
        #not paid yet
        days=(@end_date - due_date).to_i
      end
      if collection.fine.present? and days > 0
        applicable_fine_rule = collection.fine.fine_rules.select{|fr| fr.fine_days <= days && fr.created_at <= collection.created_at }.sort{|x,y| x.fine_days <=> y.fine_days}.last
        if applicable_fine_rule.present?
          auto_fine = auto_fine + (applicable_fine_rule.is_amount ? applicable_fine_rule.fine_amount : (amount_after_discount * applicable_fine_rule.fine_amount)/100 )
        end
      end
      fine = auto_fine

      @table[i]["transport_fee_collection"][collection.id] = {
        :fees=> fees,
        :paid=>paid,
        :due=>due,
        :discount=>discount,
        :fine=>fine,
        :fine_paid=>fine_paid,
        :tax_amount=>tax_amount,
        :tax_paid=> tax_paid,
        :tax_enabled=> tax_enabled
      }
      add_up_total(i, fees, discount, paid, due, fine_paid, fine, tax_amount, tax_paid)
    end
  end


  def hostel_fee_section(hostel_fees,i)
    #HOSTEL FEE COLLECTION SECTION ----------------------------------------------------------------------------------------------------------------------------------
    hostel_fees.each do |h|
      collection= h.hostel_fee_collection

      fees=0.0; discount=0.0; paid=0.0; due=0.0; fine_paid=0.0; fine=0.0; tax_amount=0.0; tax_paid=0.0; tax_enabled=false;
      fees= h.rent
      if @start_date.present? && @end_date.present?
        #paid amount calculation
        paid= h.finance_transactions.select{|ft| ft.transaction_date.to_date <= @end_date  }.collect(&:amount).sum.to_f
        fine_paid= h.finance_transactions.select{|ft| ft.transaction_date.to_date <= @end_date  }.collect(&:fine_amount).sum.to_f
        paid = paid - fine_paid
      end
      #fine amount is paid amount - only manual fine present
      fine=fine_paid

      tax_enabled = h.tax_enabled.present? ? h.tax_enabled : false
      if tax_enabled
        #tax
        @total_tax_enabled=true
        tax_amount = h.tax_amount.to_f if h.tax_amount.present?
        tax_paid = h.finance_transactions.select{|ft| ft.transaction_date.to_date <= @end_date  }.collect(&:tax_amount).sum.to_f
      end
      @hostel_collection_names << {:name=>collection.name,:id=>collection.id, :collection_type=>"hostel_fee_collection",:tax_enabled=>tax_enabled }

      #calculate discount here -- when discount feature is added
      amount_after_discount = fees - discount
      amount_after_discount = 0 if  amount_after_discount < 0
      amount_after_tax = amount_after_discount + tax_amount

      #due calculation
      due = amount_after_tax - (paid)
      due = due.zero? && 0.0 || due #avoid -0.0 case --(negative zero)


      @table[i]["hostel_fee_collection"][collection.id] = {
        :fees=> fees,
        :paid=>paid,
        :due=>due,
        :discount=>discount,
        :fine=>fine,
        :fine_paid=>fine_paid,
        :tax_amount=>tax_amount,
        :tax_paid=> tax_paid,
        :tax_enabled=> tax_enabled
      }
      add_up_total(i, fees, discount, paid, due, fine_paid, fine, tax_amount, tax_paid)
    end
  end


  def instant_fee_section(instant_fees,i)
    #INSTANT FEE  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    instant_fees.each do |inst_fee|
      fees=0.0; discount=0.0; paid=0.0; due=0.0; fine_paid=0.0; fine=0.0; tax_amount=0.0; tax_paid=0.0; tax_enabled=false;
      fees = inst_fee.instant_fee_details.collect(&:amount).sum
      paid = inst_fee.amount
      due = 0.0
      fine = 0.0
      discount = inst_fee.instant_fee_details.collect{|d| ((d.amount * d.discount)/100).to_f}.sum
      fine_paid = 0.0
      tax_enabled = inst_fee.tax_enabled.present? ? inst_fee.tax_enabled : false
      if tax_enabled
        #tax
        @total_tax_enabled=true
        tax_amount = inst_fee.instant_fee_details.collect(&:tax_amount).sum if inst_fee.tax_amount.present?
        tax_paid =  tax_amount
      end
      key = inst_fee.instant_fee_category_id.present? ? inst_fee.instant_fee_category_id : "custom"+inst_fee.id.to_s
      head_already_added = false
      @instant_fee_collection_names.each do |hash|
        if hash[:id] == key
          head_already_added = true
        end
      end
      if head_already_added && @table[i]["instant_fee_collection"][key].present?
        #category already added -- append data
        
          @table[i]["instant_fee_collection"][key][:fees] += fees
          @table[i]["instant_fee_collection"][key][:paid] += paid
          @table[i]["instant_fee_collection"][key][:due] += due
          @table[i]["instant_fee_collection"][key][:discount] += discount
          @table[i]["instant_fee_collection"][key][:fine] += fine
          @table[i]["instant_fee_collection"][key][:fine_paid] += fine_paid
          @table[i]["instant_fee_collection"][key][:tax_amount] += tax_amount
          @table[i]["instant_fee_collection"][key][:tax_paid] += tax_paid
          @table[i]["instant_fee_collection"][key][:tax_enabled] = @table[i]["instant_fee_collection"][key][:fees] || tax_enabled
        
      else
        name =  inst_fee.instant_fee_category_id.present? ? inst_fee.instant_fee_category.name : inst_fee.custom_category
        @instant_fee_collection_names << {:name=>name,:id=>key, :collection_type=>"instant_fee_collection",:tax_enabled=> tax_enabled }

        @table[i]["instant_fee_collection"][key] = {
          :fees=> fees,
          :paid=>paid,
          :due=>due,
          :discount=>discount,
          :fine=>fine,
          :fine_paid=>fine_paid,
          :tax_amount=>tax_amount,
          :tax_paid=> tax_paid,
          :tax_enabled=> tax_enabled
        }
      end
      add_up_total(i, fees, discount, paid, due, fine_paid, fine, tax_amount, tax_paid)
    end
  end


  def get_report()
    @table = @table.compact
    report={}
    report[:table] = @table
    report[:collection_names] = @collection_names
    report[:students] = @students
    report[:students_count] = @students_count
    report[:fee_collection_present] = @fee_collection_present
    report[:total_tax_enabled] =  @total_tax_enabled
    return report
  end

end
