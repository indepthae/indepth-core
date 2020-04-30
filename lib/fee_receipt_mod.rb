module FeeReceiptMod
  def invoice_student_data(student)
    return unless student.present?

    @inv_data["full_name"] = student.full_name
    @inv_data["roll_number"] = student.roll_number
    @inv_data["admission_no"] = student.admission_no
    @inv_data["full_course_name"] = student.batch.full_name
    @inv_data["guardian_name"] = student.try(:immediate_contact).try(:full_name)
  end

  def get_student_invoice(fee, finance_type)
    @inv_data = Hash.new
    @inv_data["finance_type"] = fee.class.name
    @inv_data["invoice_no"] = fee.invoice_no
    @inv_data["currency"] = Configuration.currency
    if fee.tax_enabled? and fee.tax_collections.present?
      @inv_data['tax_slab_collections'] = fee.tax_collections.group_by { |tc| tc.tax_slab }
      @inv_data['total_tax'] = fee.tax_collections.present? ? fee.tax_collections.map do |x|
        FedenaPrecision.set_and_modify_precision(x.tax_amount).to_f
      end.sum.to_f : 0
    end
    @inv_data["collection"] = collection = fee.send("#{finance_type.singularize}_collection")
    @inv_data["done_transactions"] = done_transactions = @inv_data["paid_fees"] = fee.finance_transactions
    done_amount=0
    done_transactions.each { |t| done_amount += t.amount }
    @inv_data["done_amount"] = done_amount
    case finance_type
      when 'finance_fees'
        student = fee.student || fee.former_student
        invoice_student_data(student)
        @inv_data["due_date"] = collection.due_date
        @inv_data["fee_category"] = collection.fee_category
        # TODO Refractor this method
        # particulars
        @inv_data["fee_particulars"] = fee.finance_fee_particulars
        @inv_data["categorized_particulars"] = @inv_data["fee_particulars"].group_by(&:receiver_type)
        # discounts
        @inv_data["discounts"] = fee.fee_discounts
        @inv_data["categorized_discounts"] = @inv_data["discounts"].group_by(&:master_receiver_type)

        @inv_data["total_discounts"]= 0
        @inv_data["total_payable"] = @inv_data["fee_particulars"].map { |s| s.amount }.sum.to_f

        @inv_data["total_discount"] = @inv_data["discounts"].map { |d|
          d.master_receiver_type=='FinanceFeeParticular' ?
              (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) :
              @inv_data["total_payable"] * d.discount.to_f/(d.is_amount? ?
                  @inv_data["total_payable"] : 100) }.sum.to_f unless @inv_data["discounts"].nil?

        @inv_data["remainder_amount"] = @inv_data["total_payable"] -
            @inv_data["total_discount"] - @inv_data["done_amount"]

        bal = (@inv_data["total_payable"] - @inv_data["total_discount"]).to_f

        days = fee.is_paid ? (done_transactions.present? ?
            (done_transactions.last.created_at.to_date - collection.due_date.to_date) : 0) :
            (Date.today - collection.due_date.to_date).to_i
        auto_fine = collection.fine
        @inv_data["balance_fine_status"]= (fee.balance_fine.present? && fee.balance_fine > 0) ? false : true
        if days > 0 and auto_fine and !fee.is_fine_waiver
          if Configuration.is_fine_settings_enabled? && fee.balance == 0 && fee.is_paid == false && fee.balance_fine.present?
            @inv_data["fine_amount"] = fee.balance_fine
          else
          @inv_data["fine_rule"]=auto_fine.fine_rules.find(:last,
                                                           :conditions => ["fine_days <= '#{days}' and
                           created_at <= '#{collection.created_at}'"],
                                                           :order => 'fine_days ASC')
          @inv_data["fine_amount"] = @inv_data["fine_rule"].is_amount ?
              @inv_data["fine_rule"].fine_amount : (bal*@inv_data["fine_rule"].fine_amount)/100 if @inv_data["fine_rule"]
          end
        end

        # Extract discount hash
        discounts=[]

        @inv_data["discounts"].each do |d|
          # discount_text = d.is_amount == true ? "Discount: #{d.name}" : "#{d.name}-#{d.discount}% "
          discount_text = d.is_amount == true ? "#{d.name} " : "#{d.name}-#{d.discount}% "
          if d.master_receiver_type=='FinanceFeeParticular'
            particular=d.master_receiver
            name="#{discount_text}  &#x200E;(#{particular.name}) &#x200E;"
            amount=particular.amount * d.discount.to_f/ (d.is_amount? ? particular.amount : 100)
          else
            name=discount_text
            amount = @inv_data["total_payable"] * d.discount.to_f/ (d.is_amount? ? @inv_data["total_payable"] : 100)
          end
          discounts << {"name" => name, "amount" => amount}
        end

        @inv_data["discounts_list"]=discounts

        # Generate fine list
        fine_list=[]
        #      unless (@inv_data["fine"].present? && @inv_data["fine"].to_f > 0.0) #No need to list fines for particular wise payments
        #        fine=OpenStruct.new #TODO check whether this save memmory
        #        unless @fts_hash[ft.id]["fine_amount"].blank? || @fts_hash[ft.id]["fine_amount"].to_f ==0.0
        #          name= "#{t('fine_on')} " + format_date(Date.today)
        #          amount= @fts_hash[ft.id]["fine_amount"].to_f
        #          fine=OpenStruct.new({:name => name, :amount => amount})
        #          # fine_list<<fine #FIXME fine is duplicated
        #        end
        #      end
        # paid fees
        paid_fine=false
        paid_automatic_fine=0.to_f
        @inv_data["paid_fees"].each do |transaction|
          if transaction.fine_included
            paid_fine=true
            paid_automatic_fine = paid_automatic_fine + transaction.fine_amount.to_f if transaction.description=='fine_amount_included'
            name= "#{t('fine_on')} " + format_date(transaction.transaction_date)
            amount= transaction.fine_amount.to_f
            fine_list << {"name" => name, "amount" => amount}
          end
        end
        #fine rules
        unless @inv_data["financefee"].blank?
          if @inv_data["fine_rule"].present?
            name= t('fine_on') +' '+ format_date(collection.due_date.to_date + @inv_data["fine_rule"].fine_days.days)
            name += @inv_data["fine_rule"].is_amount ? "" : " (#{@inv_data["fine_rule"].fine_amount}&#x200E;%)"
            amount = @inv_data["fine_amount"].to_f - paid_automatic_fine
            fine_list<< {"name" => name, "amount" => amount} if amount > 0
          end
        end
        @inv_data["fine_list"] = fine_list
        @inv_data["total_fine_amount"] = fine_list.sum { |fine| fine["amount"].to_f }
        # Total amount to pay
        @inv_data["total_amount_to_pay"] = @inv_data["total_payable"] -
            @inv_data["total_discount"] + @inv_data["total_fine_amount"]
        @inv_data["total_amount_to_pay"] += @inv_data["total_tax"] if fee.tax_enabled? and fee.tax_collections.present?

        @inv_data["total_amount_paid"] = done_amount
        @inv_data["total_due_amount"] = @inv_data["total_amount_to_pay"] -
            @inv_data["total_amount_paid"].to_f
      when 'hostel_fees'
        student = fee.student || fee.former_student
        invoice_student_data(student)
        struct=OpenStruct.new({"name" => "Rent", "amount" => fee.rent})
        @inv_data["categorized_particulars"]=[[[struct]]]
        #      @inv_data["particulars"]= {"name" => "Rent", "amount" => fee.rent}
        @inv_data["due_date"] = collection.due_date
        #      @inv_data["invoice_no"]=""
        @inv_data["fine"] = fee.fine_amount.to_f
        @inv_data["total_payable"] = @inv_data["rent"] = fee.rent
        @inv_data["total_discount"]=0.0
        @inv_data["fine_amount"]=@inv_data["fine"]
        @inv_data["total_amount_to_pay"] = fee.rent
        @inv_data["total_amount_to_pay"] += @inv_data["fine"]
        @inv_data["total_amount_to_pay"] += @inv_data["total_tax"].to_f if fee.tax_enabled? and fee.tax_collections.present?
        @inv_data["total_amount_paid"] = done_amount #ft.finance.rent.to_f-ft.hostel_fee_finance_transaction.transaction_balance.to_f+@inv_data["fine"]
        #      @inv_data["total_due_amount"] = fee.hostel_fee_finance_transaction.transaction_balance.to_f
        @inv_data["total_due_amount"]= (@inv_data["total_amount_to_pay"] - done_amount).to_f
        @inv_data["total_fine_amount"] = @inv_data["fine"]
      when 'transport_fees'
        student = fee.receiver || fee.former_student
        invoice_student_data(student)
        #        struct=OpenStruct.new({:name => "Fare", :amount => (ft.finance.bus_fare-ft.fine_amount)})
        struct=OpenStruct.new({"name" => "Rent", "amount" => fee.bus_fare})
        # TODO Refractor the code base so that we don't have to use 3 dimensional array workaround
        @inv_data["categorized_particulars"]=[[[struct]]]

        @inv_data["due_date"] = collection.due_date

        #      @inv_data["fine"] = fee.fine_amount.to_f
        @inv_data["total_payable"] = @inv_data["bus_fare"] = fee.bus_fare

        #----------------------Discount-------------------------------------------------------------
        @inv_data["discounts"] = fee.transport_fee_discounts
        @inv_data["total_discount"] = fee.total_discount_amount

        #--------------Fine from Finance Transaction----------------------------------
        @inv_data["fine_list"] = fee.finance_transactions_with_fine

        #--------------Auto Fine Amount-------------------------------------------------------------
        @inv_data["fine_amount"] = 0.0
        bal = (fee.bus_fare - fee.total_discount_amount).to_f
        days = fee.is_paid ? (done_transactions.present? ?
            (done_transactions.last.created_at.to_date - collection.due_date.to_date) : 0) :
            (Date.today - collection.due_date.to_date).to_i
        auto_fine = collection.fine
        if days > 0 and auto_fine
          @inv_data["fine_rule"]=auto_fine.fine_rules.find(:last,
                                                           :conditions => ["fine_days <= '#{days}' and
                           created_at <= '#{collection.created_at}'"],
                                                           :order => 'fine_days ASC')
          @inv_data["fine_amount"] = @inv_data["fine_rule"].is_amount ?
              @inv_data["fine_rule"].fine_amount : (bal*@inv_data["fine_rule"].fine_amount)/100 if @inv_data["fine_rule"]
        end

        @inv_data["total_amount_to_pay"]= fee.bus_fare

        #---------------------Tax-------------------------------------------------------------------
        if fee.tax_enabled? and fee.tax_collections.present? and fee.tax_amount.present?
          @inv_data["tax_slab"] = collection.collection_tax_slabs.try(:last) if fee.tax_enabled?
          @inv_data["total_tax"] = fee.tax_amount.to_f
          @inv_data["total_amount_to_pay"] += @inv_data["total_tax"].to_f
        end

        #      @inv_data["done_amount"]=done_amount
        @inv_data["total_amount_paid"]=done_amount
        @inv_data["total_due_amount"]= (@inv_data["total_amount_to_pay"] - done_amount).to_f
      #      @inv_data["total_amount_to_pay"] += @inv_data["fine"].to_f
      #      @inv_data["total_fine_amount"]=@inv_data["fine"]    
      else
        return
    end
  end

  def get_student_fee_receipt_new(*args) #transaction_ids, particular_wise=false, particular_id=nil)    
    transaction_ids = args.first[:transaction_ids]
    particular_wise = args.first[:particular_wise] || false
    particular_id = args.first[:particular_id] || nil
    include_tax = args.first[:include_tax]
    tax_associations = include_tax ? {:tax_collections => :tax_slab} : {}
    transactions_hash = Hash.new { |h, k| h[k] = OpenStruct.new(&h.default_proc) }
    transactions = FinanceTransaction.find_all_by_id(transaction_ids,
                                                     :joins => "",
                                                     :include => [{:finance => tax_associations}, :transaction_receipt, :payee],
                                                     :select => "finance_transactions.*")
    overall_tax_enabled = false
    default_config_hash = ['InstitutionName', 'InstitutionAddress', 'PdfReceiptSignature',
                           'PdfReceiptSignatureName', 'PdfReceiptCustomFooter', 'PdfReceiptAtow', 'PdfReceiptNsystem',
                           'PdfReceiptHalignment', 'FinanceTaxIdentificationLabel', 'FinanceTaxIdentificationNumber']
    default_configs = OpenStruct.new(Configuration.get_multiple_configs_as_hash default_config_hash)
    default_configs.default_currency = Configuration.default_currency
    default_configs.currency_symbol = Configuration.currency
    transactions.each do |transaction|
      ff = transaction.finance
      transaction_data = transactions_hash[transaction.id]
      transaction_data.particular_wise = particular_wise
      transaction_data.default_configs = default_configs
      transaction_data.transaction_date = transaction_data.date = transaction.transaction_date
      transaction_data.formated_date = format_date(transaction_data.transaction_date, :format => :short_date)
      transaction_data.receipt_title = I18n.t('fee_receipt')
      # using precision recorded by system during time of transaction creation
      transaction_data.tax_enabled = ff.respond_to?(:tax_enabled?) ? ff.tax_enabled? : false
      #      overall_tax_enabled = true if tax_enabled
      transaction_data.precision_count = transaction.finance_transaction_receipt_record.precision_count
      transaction_data.amount = FedenaPrecision.set_and_modify_precision(transaction.amount, transaction_data.precision)
      transaction_data.auto_fine = transaction.auto_fine
      transaction_data.bank_name = transaction.bank_name.present? ? transaction.bank_name : '-'
      transaction_data.cheque_date = transaction.cheque_date.present? ? transaction.cheque_date : '-'
      transaction_data.currency = default_configs.currency_symbol
      transaction_data.finance_type = transaction.finance_type
      transaction_data.fine_amount = transaction.fine_amount
      transaction_data.invoice_no = transaction.finance_type == "InstantFee" ? "" :
          (ff.respond_to?(:invoice_no) ? ff.invoice_no : nil)
      transaction_data.payment_mode = transaction.payment_mode
      transaction_data.payment_note = transaction.payment_note
      transaction_data.receipt_no = transaction.receipt_number
      transaction_data.reference_no = transaction.reference_no
      transaction_data.wallet_amount_applied = transaction.wallet_amount_applied
      transaction_data.wallet_amount = transaction.wallet_amount
      transaction_data.reference_label = (
      if transaction_data.payment_mode == "Online Payment"
        I18n.t('transaction_id')
      elsif transaction_data.payment_mode == "Cheque"
        I18n.t('cheque_no')
      elsif transaction_data.payment_mode == "Card Payment"
        I18n.t('transaction_id')
      elsif transaction_data.payment_mode == "DD"
        I18n.t('dd_no')
      else
        I18n.t('reference_no')
      end)
      #      transaction_data.tax_enabled = tax_enabled
      # student / employee info
      fetch_transaction_student_employee_info transaction, transaction_data

      # fetch taxes collected
      fetch_transaction_tax_data transaction, transaction_data if transaction_data.tax_enabled

      # process transaction data as per fees or module that triggered the transaction
      case transaction.finance_type
        when 'FinanceFee' # core fee / finance fee transaction
          fetch_finance_fee_transaction_data transaction, transaction_data, particular_id

        when 'HostelFee' # hostel fee transaction
          fetch_hostel_fee_transaction_data transaction, transaction_data

        when 'InstantFee' # instant fee transaction
          # TODO attributes
          fetch_instant_fee_transaction_data transaction, transaction_data

        when 'TransportFee' # transport fee transaction
          fetch_transport_fee_transaction_data transaction, transaction_data

        when 'RegistrationCourse' # applicant registration fee transaction
          #        update here :: applicants_admins#generate_fee_receipt_pdf
          #        update here :: applicants#generate_fee_receipt_pdf
          fetch_registration_course_fee_transaction_data transaction, transaction_data

        when 'BookMovement' # library fine transaction update :: books#generate_library_fine_receipt_pdf
          fetch_book_movement_fine_transaction_data transaction, transaction_data

        else # TO DO :: either remove transaction from hash for other income type transactions or add some default case

      end
    end

    transactions_hash
    #    @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
    #        'FinanceTaxIdentificationNumber']) if overall_tax_enabled
  end


  def fetch_transaction_tax_data transaction, transaction_data
    if transaction_data.tax_enabled and transaction.trans_type == "collection_wise"
      tax_collections = (transaction.finance_type != 'FinanceFee') ?
          transaction.finance.tax_collections.all(:include => :tax_slab) : tax_collections = transaction.finance.tax_collections
      #      unless transaction.finance_type == 'TransportFee'
      tax_hash = Hash.new
      total_tax = 0
      tax_collections.each do |x|
        tax_hash[x.tax_slab.id] ||= OpenStruct.new({:name => x.tax_slab.name, :rate => x.tax_slab.rate.to_f,
                                                    :tax_amount => [], :display_name => "#{x.tax_slab.name} &#x200E;(
  #{FedenaPrecision.set_and_modify_precision(x.tax_slab.rate, transaction_data.precision)}%)&#x200E;"})
        tax_hash[x.tax_slab.id].tax_amount << x.tax_amount.to_f
        total_tax += FedenaPrecision.set_and_modify_precision(x.tax_amount.to_f, transaction_data.precision_count).to_f
      end
      transaction_data.tax_slab_collections = tax_hash
      transaction_data.total_tax = FedenaPrecision.set_and_modify_precision(total_tax.to_f, transaction_data.precision_count)
      #      end
    end
  end

  def fetch_transaction_student_employee_info transaction, transaction_data
    if transaction.payee_type == "Applicant"
      transaction_data.payee = OpenStruct.new({:payee_type => transaction.payee_type,
                                               :payee_id => transaction.payee_id})
      transaction_data.payee.full_name = transaction.payee.full_name
      transaction_data.payee.reg_no = transaction.payee.reg_no

      r_course = transaction.payee.registration_course

      transaction_data.payee.full_course_name = r_course.display_name.present? ?
          "#{r_course.display_name} &#x200E;(#{r_course.course.course_name})&#x200E;" :
          "#{r_course.course.course_name} &#x200E;(#{r_course.course.code})&#x200E;"

    elsif transaction.payee_type == "Student"
      unless transaction.payee.present?
        ars = ArchivedStudent.find_by_former_id(transaction.payee_id)
        transaction.payee = ars
        transaction_data.payee = OpenStruct.new({:payee_type => 'Student', :payee_id => ars.former_id})
      end
      transaction_data.payee ||= OpenStruct.new({:payee_type => transaction.payee_type,
                                                 :payee_id => transaction.payee_id})
      transaction_data.payee.full_name = transaction.payee.full_name
      transaction_data.payee.roll_number = transaction.payee.roll_number
      transaction_data.payee.admission_no = transaction.payee.admission_no

      transaction_data.payee.full_course_name = transaction.fetch_finance_batch.nil? ?
          transaction.payee.batch.full_name : transaction.fetch_finance_batch.full_name

      transaction_data.payee.guardian_name = transaction.payee.try(:immediate_contact).try(:full_name)
    elsif transaction.payee_type == "Employee"
      unless transaction.payee.present?
        ae = ArchivedEmployee.find_by_former_id(transaction.payee_id)
        transaction.payee = ae
        transaction_data.payee = OpenStruct.new({:payee_type => 'Employee', :payee_id => ae.former_id})
      end
      transaction_data.payee ||= OpenStruct.new({:payee_type => transaction.payee_type,
                                                 :payee_id => transaction.payee_id})
      transaction_data.payee.full_name = transaction.payee.full_name
      transaction_data.payee.employee_number = transaction.payee.employee_number
      transaction_data.payee.employee_department_name = transaction.payee.employee_department.name
    elsif transaction.payee_type == "User"
      #TO DO :: Add as per need
    else
      if transaction_data.finance_type == 'InstantFee'
        ff = transaction.finance
        transaction_data.payee = OpenStruct.new
        transaction_data.payee.payee_type = "Guest"
        transaction_data.payee.full_name = ff.guest_payee
      else
        transaction_data.payee = OpenStruct.new({:payee_type => "Guest",
                                                 :full_name => transaction.finance.guest_payee}) if transaction.payee.present?
      end
    end
  end

  def fetch_book_movement_fine_transaction_data transaction, transaction_data
    ff = transaction.finance
    transaction_data.receipt_title = I18n.t('library_fine_receipt')
    transaction_data.book_title = ff.book.title
    transaction_data.book_number = ff.book.book_number
    fine_title = "&#x200E;#{I18n.t('books.library_fine')} (#{transaction_data.book_number} : #{transaction_data.book_title})&#x200E;"
    #    book_name_and_no = (@ft.finance.book.book_number)+" : "+(@ft.finance.book.title)
    fine_amount = FedenaPrecision.set_and_modify_precision(transaction.amount, transaction_data.precision)

    transaction_data.fee_particulars = [
        OpenStruct.new({:name => fine_title, :amount => fine_amount})
    ]

    #    @online_transaction_id = nil
    #    @full_course_name = @ft.batch.full_name
    #    @roll_number = @ft.fetch_payee.roll_number
    #    @f_payee = @ft.fetch_payee.immediate_contact_id
    transaction_data.guardian_name = (
    if transaction.payee_type == 'Student'
      payee = transaction.payee.present? ? transaction.payee : ArchivedStudent.find_by_former_id(transaction.payee_id)
      Guardian.find_by_id(payee.immediate_contact) || ArchivedGuardian.find_by_former_id(payee.immediate_contact_id)
    end.try(:full_name))

    # begin
    # rescue
    # end

    transaction_data.payment_mode = I18n.t('offline')
    #    if @f_payee.present?
    #      @guardian = Guardian.find_by_id(@f_payee)
    #      if @guardian.present?
    #        @parent = @ft.fetch_payee.try(:immediate_contact).try(:full_name)
    #      else
    #        @parent = ArchivedGuardian.find_by_former_id(@f_payee).try(:full_name)
    #      end
    #    end
  end

  def fetch_finance_fee_transaction_data transaction, transaction_data, particular_id = nil
    #    transaction_data.collection = OpenStruct.new(transaction.finance.finance_fee_collection.
    #        attributes.slice('name','id','due_date','fine_id'))
    collection = transaction.finance.finance_fee_collection
    transaction_data.collection = OpenStruct.new({:title => I18n.t('finance_fee_collection'),
                                                  :name => collection.name, :due_date => collection.due_date, :fine_id => collection.fine_id
                                                 })
    transaction_data.invoice_enabled = collection.invoice_enabled
    transaction_data.financefee = OpenStruct.new(transaction.finance.attributes) #transaction.payee.finance_fee_by_date(transaction.finance.finance_fee_collection)
    transaction_data.due_date = transaction_data.collection.due_date
    transaction_data.formated_due_date = format_date(transaction_data.due_date, :format => :short_date)
    #        transaction_data.fee_category = FinanceFeeCategory.find(transaction.finance.finance_fee_collection.fee_category_id, :conditions => .is_deleted = false)
    # TODO Refractor this method
    # extract particular & discount details
    particular_and_discount_details1(transaction, transaction_data)

    if transaction.particular_wise?
      particular_payment_details(transaction, transaction_data)
      # transaction_data.due_date =""
      transaction_data.is_particular_wise = true
    else
      transaction_data.is_particular_wise = false
    end
    ff = transaction.finance
    transaction_data.paid_fees = ff.finance_transactions.
        all(:conditions => ["finance_transactions.id <= ? ", transaction.id]).
        map { |x| _os = OpenStruct.new(x.attributes); _os.transaction_id = x.id; _os }

    transaction_data.done_amount = 0

    #    transaction_data.done_transactions =
    ff.finance_transactions.all(
        :conditions => ["finance_transactions.id < ? ", transaction.id]).map do |x|
      transaction_data.done_amount += x.amount.to_f
      #      OpenStruct.new(x.attributes)
    end
    #        done_transactions.each do |t|
    #          done_amount += t['amount'].to_f
    #        end
    #        transaction_data.done_amount = done_amount
    transaction_data.remainder_amount = transaction_data.total_payable -
        transaction_data.total_discount - transaction_data.done_amount

    unless particular_id.nil?
      transaction_data.previous_payments = ff.finance_transactions.
          sum('finance_fee_particulars.amount',
              :joins => 'inner join particular_payments on particular_payments.finance_transaction_id=finance_transactions.id
                           letransaction outer join finance_fee_particulars on finance_fee_particulars.id=particular_payments.finance_fee_particular_id',
              :conditions => ["finance_transactions.id < ? and finance_fee_particulars.id =? ", transaction.id, particular_id])
    end

    bal = (transaction_data.total_payable - transaction_data.total_discount).to_f
    days = (transaction.transaction_date.to_date - transaction_data.due_date.to_date).to_i
    auto_fine = transaction.finance.finance_fee_collection.fine
    if days > 0 and auto_fine and !ff.is_fine_waiver && !transaction.fine_waiver
      fine_rule = auto_fine.fine_rules.find(:last,
                                            :conditions => "fine_days <= '#{days}' and created_at <= '#{transaction.finance.
                                                finance_fee_collection.created_at}'",
                                            :order => 'fine_days ASC')
      transaction_data.fine_rule = OpenStruct.new(fine_rule.attributes) if fine_rule.present?
      #            unless particular_wise==true
      if Configuration.is_fine_settings_enabled? && ff.balance <= 0 && ff.balance_fine.present?
        transaction_data.total_auto_fine_amount = FedenaPrecision.
          set_and_modify_precision( ff.finance_transactions.map{|i| i.auto_fine.to_f}.sum.to_f + ff.balance_fine.to_f, transaction_data.precision)
      else
      transaction_data.total_auto_fine_amount = FedenaPrecision.
          set_and_modify_precision(transaction_data.fine_rule.is_amount ?
                                       transaction_data.fine_rule.fine_amount :
                                       (bal * transaction_data.fine_rule.fine_amount.to_f)/100,
                                   transaction_data.precision) if transaction_data.fine_rule
      end
      #            end
    end

    # Extract discount hash
    #        discounts=[]
    #        unless transaction.particular_wise? #No need to list discounts for particular wise payments
    #          discount=OpenStruct.new #TODO check whether this save memmory
    #          transaction_data.discounts.each do |d|
    #            # discount_text = d.is_amount == true ? "Discount: #{d.name}" : "#{d.name}-#{d.discount}% "
    #            discount_text = d['is_amount'] == true ? "#{d['name']} " : "#{d['name']}-#{d['discount']}% "
    #            if d.master_receiver_type=='FinanceFeeParticular'
    #              particular=d.master_receiver
    #              name="#{discount_text}  &#x200E;(#{particular.name}) &#x200E;"
    #              amount=particular.amount * d.discount.to_f/ (d.is_amount? ? particular.amount : 100)
    #            else
    #              name=discount_text
    #              amount=transaction_data.total_payable * d.discount.to_f/ (d.is_amount? ? transaction_data.total_payable : 100)
    #            end
    #            discount=OpenStruct.new({:name => name, :amount => amount})
    #            discounts<<discount
    #          end
    #        end
    #        transaction_data[:discounts_list]=discounts
    # get particular wise hash
    if transaction.particular_wise?
      particulars = []
      transaction_data.particular_payments.each do |payment|
        amount = payment.particular_amount.to_f
        remaining_balance = payment.particular_amount.to_f - previous_payments(transaction.id, payment.particular_id).to_f
        discount = payment.payment_discount.to_f
        payment_amount = payment.payment_amount.to_f
        amount_paid = payment_amount - discount
        amount_paid = 0 if amount_paid < 0
        balance = remaining_balance - (amount_paid + discount)
        particular = OpenStruct.new({
                                        :name => payment.particular_name,
                                        :amount => FedenaPrecision.set_and_modify_precision(amount, transaction_data.precision),
                                        :remaining_balance => FedenaPrecision.set_and_modify_precision(remaining_balance, transaction_data.precision),
                                        :discount => FedenaPrecision.set_and_modify_precision(discount, transaction_data.precision),
                                        :amount_paid => FedenaPrecision.set_and_modify_precision(amount_paid, transaction_data.precision),
                                        :balance => FedenaPrecision.set_and_modify_precision(balance, transaction_data.precision)
                                    })
        particulars << particular
      end
      transaction_data.fee_particulars = particulars
    end

    fine_list = []
    # paid fines
    paid_fine = false
    transaction_data.total_paid_fine = 0
    transaction_data.total_fine_amount = 0
    paid_automatic_fine = 0.to_f

    transaction_ids = []
    transaction_data.paid_fees.each do |_transaction|
      transaction_ids << _transaction.transaction_id

      if _transaction.fine_included
        paid_fine = true
        paid_automatic_fine = paid_automatic_fine + _transaction.auto_fine.to_f if _transaction.description == 'fine_amount_included'
        name = "#{t('fine_on')} " + format_date(_transaction.transaction_date)
        amount = FedenaPrecision.set_and_modify_precision(_transaction.fine_amount.to_f, transaction_data.precision)
        transaction_data.total_paid_fine += amount.to_f
        transaction_data.total_fine_amount += amount.to_f
        fine = OpenStruct.new({:name => name, :amount => amount, :paid_fine => true})
        fine_list << fine
      end
    end

    # auto fine paid in current transaction
    unless transaction_ids.include?(transaction.id)
      if transaction.fine_included
        paid_fine = true
        paid_automatic_fine = paid_automatic_fine + transaction.auto_fine.to_f if transaction.description == 'fine_amount_included'
        name = "#{t('fine_on')} " + format_date(transaction.transaction_date)
        amount = FedenaPrecision.set_and_modify_precision(transaction.fine_amount.to_f, transaction_data.precision)
        transaction_data.total_paid_fine += amount.to_f
        transaction_data.total_fine_amount += amount.to_f
        fine = OpenStruct.new({:name => name, :amount => amount, :paid_fine => true})
        fine_list << fine
      end
    end

    # unpaid auto fine

    if transaction_data.fine_rule.present? and transaction_data.total_auto_fine_amount.to_f > paid_automatic_fine

      remaining_auto_fine = (transaction_data.total_auto_fine_amount.to_f - paid_automatic_fine)
      transaction_data.total_unpaid_fine = remaining_auto_fine.to_f
      transaction_data.total_unpaid_fine = FedenaPrecision.set_and_modify_precision(transaction_data.total_unpaid_fine,
                                                                                transaction_data.precision)
      transaction_data.total_fine_amount += remaining_auto_fine.to_f
      name = "#{t('fine_on')} " + format_date(transaction_data.due_date.to_date)
      name += "&#x200E;(#{transaction_data.fine_rule.fine_amount}%) &#x200E;" unless transaction_data.fine_rule.is_amount
      fine = OpenStruct.new({:name => name, :amount => remaining_auto_fine})
      fine_list << fine
    end
    transaction_data.total_paid_fine = FedenaPrecision.set_and_modify_precision(transaction_data.total_paid_fine,
                                                                                transaction_data.precision)

    # Generate fine list
    # fine_list = []
    # unless transaction.particular_wise? || (transaction_data.fine.present? && transaction_data.fine.to_f > 0.0) #No need to list fines for particular wise payments
    #   fine = OpenStruct.new #TODO check whether this save memmory
    #   unless transaction_data.fine_amount.blank? || transaction_data.fine_amount.to_f ==0.0
    #     name = "#{t('fine_on')} " + format_date(Date.today)
    #     amount = transaction_data.fine_amount.to_f
    #     fine = OpenStruct.new({:name => name, :amount => amount})
    #     # fine_list<<fine #FIXME fine is duplicated
    #   end
    # end
    # paid fees
    # paid_fine = false
    # paid_automatic_fine = 0.to_f
    # transaction_data.paid_fees.each do |transaction|
    #   if transaction.fine_included
    #     paid_fine = true
    #     paid_automatic_fine = paid_automatic_fine + transaction.fine_amount.to_f if transaction.description == 'fine_amount_included'
    #     name = "#{t('fine_on')} " + format_date(transaction.transaction_date)
    #     amount = transaction.fine_amount.to_f
    #     fine = OpenStruct.new({:name => name, :amount => amount})
    #     fine_list << fine
    #   end
    # end

    #fine rules
    # unless transaction_data.financefee.blank?
    #   if transaction_data.fine_rule.present?
    #     name = t('fine_on') + ' ' + format_date(transaction_data.due_date.to_date +
    #                                                 transaction_data.fine_rule.fine_days.days)
    #     name += transaction_data.fine_rule.is_amount ? "" :
    #         " (#{transaction_data.fine_rule.fine_amount}&#x200E;%)"
    #     amount = transaction_data.fine_amount.to_f - paid_automatic_fine
    #     if amount > 0
    #       fine = OpenStruct.new({:name => name, :amount => amount})
    #       fine_list << fine
    #     end
    #   end
    # end
    transaction_data.total_fine_amount = FedenaPrecision.set_and_modify_precision(transaction_data.total_fine_amount,
                                                                                  transaction_data.precision)
    transaction_data.total_fees = FedenaPrecision.
        set_and_modify_precision(transaction_data.total_payable - transaction_data.total_discount.to_f +
                                     transaction_data.total_fine_amount.to_f,
                                 transaction_data.precision)
    transaction_data.fine_list = fine_list
    # transaction_data.total_fine_amount = fine_list.sum { |fine| fine.amount }
    # Total amount to pay
    transaction_data.total_amount_to_pay = FedenaPrecision.
        set_and_modify_precision(transaction_data.total_payable - transaction_data.total_discount +
        transaction_data.total_fine_amount.to_f, transaction_data.precision)
    transaction_data.total_amount_to_pay = FedenaPrecision.
        set_and_modify_precision(transaction_data.total_amount_to_pay.to_f +
        transaction_data.total_tax.to_f, transaction_data.precision) if (transaction_data.tax_enabled and
        transaction_data.tax_slab_collections.present?)
    transaction_data.previously_paid_amount = transaction_data.done_amount
    transaction_data.total_amount_paid = FedenaPrecision.
        set_and_modify_precision(transaction_data.previously_paid_amount +
        transaction_data.amount.to_f, transaction_data.precision)
    transaction_data.total_due_amount = FedenaPrecision.
        set_and_modify_precision(transaction_data.total_amount_to_pay.to_f -
                                     transaction_data.total_amount_paid.to_f, transaction_data.precision)
  end

  def fetch_hostel_fee_transaction_data transaction, transaction_data
    hf = transaction.finance
    transaction_data.rent = FedenaPrecision.set_and_modify_precision(hf.rent, transaction_data.precision)
    transaction_data.is_particular_wise = false

    collection = transaction.finance.hostel_fee_collection
    transaction_data.collection = OpenStruct.new({:title => I18n.t('hostel_fee_collection'),
                                                  :name => collection.name, :due_date => collection.due_date
                                                 })
    transaction_data.invoice_enabled = collection.invoice_enabled
    transaction_data.due_date = transaction_data.collection.due_date
    transaction_data.formated_due_date = format_date(transaction_data.due_date, :format => :short_date)
    transaction_data.invoice_enabled = collection.invoice_enabled

    transaction_data.fee_particulars = OpenStruct.new({:name => I18n.t('hostel_fee.rent'),
                                                       :amount => FedenaPrecision.set_and_modify_precision(transaction_data.rent,
                                                                                                           transaction_data.precision)}).to_a
    #    transaction_data.done_amount = 0.0
    #    transaction_data.due_date  = transaction.finance.hostel_fee_collection.due_date
    #    transaction_data.receipt_no = transaction.receipt_no
    #    transaction_data.invoice_no = transaction.finance.invoice_no
    #    ff = transaction.finance
    fines = []
    transaction_data.total_fine_amount = 0
    previous_fine_transactions = transaction.previous_fine_transactions_for_hostel
    if previous_fine_transactions.present?
      previous_fine_transactions.each do |fine_transaction|
        transaction_data.fine_list ||= []
        name = "#{t('fine_on')} #{format_date(fine_transaction.transaction_date)}"
        amount = FedenaPrecision.set_and_modify_precision(fine_transaction.fine_amount,
                                                          transaction_data.precision)

        transaction_data.total_fine_amount += amount.to_f

        transaction_data.fine_list << OpenStruct.new({:name => name, :amount => amount})
      end
    end
    transaction_data.fine = FedenaPrecision.set_and_modify_precision(
        (transaction.fine_included ? transaction.fine_amount : 0.0), transaction_data.precision)
    #    if transaction.fine_included
    #      name = "#{t('fine_on')} " + format_date(transaction.transaction_date)
    #      amount = FedenaPrecision.set_and_modify_precision(transaction.fine_amount.to_f, transaction_data.precision)
    #      transaction_data.total_fine_amount += amount.to_f
    #      fine = OpenStruct.new({:name => name, :amount => amount})
    #      transaction_data.fine_list << fine
    #    end
    # Summary
    #        transaction_data.total_payable=transaction.finance.rent-transaction.fine_amount
    transaction_data.total_payable = transaction.finance.rent
    #        transaction_data.total_payable += transaction_data.total_tax if tax_enabled
    transaction_data.is_paid = hf.is_paid?
    transaction_data.total_discount = 0.0
    transaction_data.fine_amount = transaction_data.fine
    transaction_data.total_amount_to_pay = transaction.finance.rent
    transaction_data.total_amount_to_pay += transaction_data.total_fine_amount.to_f
    transaction_data.total_amount_to_pay += transaction_data.total_tax.to_f if transaction_data.tax_enabled
    paid_amount = transaction_data.previously_paid_amount
    transaction_data.previously_paid_amount = FedenaPrecision.set_and_modify_precision(paid_amount,
                                                                                       transaction_data.precision)
    transaction_data.total_amount_paid = FedenaPrecision.
        set_and_modify_precision(transaction_data.rent.to_f -
                                     transaction.hostel_fee_finance_transaction.transaction_balance.to_f +
                                     transaction_data.total_fine_amount.to_f +
                                     transaction_data.total_tax.to_f, transaction_data.precision)
    transaction_data.total_due_amount = FedenaPrecision.set_and_modify_precision(
        transaction.hostel_fee_finance_transaction.transaction_balance.to_f, transaction_data.precision)
    transaction_data.total_fine_amount = FedenaPrecision.set_and_modify_precision(
        transaction_data.total_fine_amount, transaction_data.precision)
  end

  def fetch_instant_fee_transaction_data transaction, transaction_data
    i_f = transaction.finance
    #    collection=transaction.finance.attributes.merge({:category_name => transaction.finance.category_name})
    transaction_data.collection = OpenStruct.new({:title => I18n.t('instant_fee_category'),
                                                  :name => i_f.category_name})
    #    transaction_data.category_name = i_f.category_name
    #    transaction_data.due_date = i_f.pay_date
    #    transaction_data.formated_due_date = format_date(transaction_hash.due_date, :format => :short_date)
    transaction_data.tax_enabled = i_f.tax_enabled
    transaction_data.invoice_enabled = false
    #    transaction_data.collection = OpenStruct.new(collection.attributes) 
    ##using struct to maintain backword compatiability , convert back to hash in future
    #    ff = transaction.finance
    #    transaction_data.instant_fee_details = i_f.instant_fee_details
    # Instant Fee is always particular wise
    transaction_data.is_particular_wise = true
    particulars = []
    tax_amounts = []
    total_discount = 0
    total_amount = 0
    i_f.instant_fee_details.each do |payment|
      amount = payment.amount.to_f
      remaining_balance = 0.0
      discount = ((payment.discount/100)*payment.amount).to_f
      payment_amount = payment.net_amount
      amount_paid = payment_amount
      total_amount += (payment_amount.to_f - payment.tax_amount.to_f)
      balance = 0.0
      total_discount += discount
      tax_amount = payment.tax_amount
      tax_amounts << payment.tax_amount
      particular = OpenStruct.new({
                                      :name => payment.particular_name,
                                      :amount => amount,
                                      :remaining_balance => remaining_balance,
                                      :discount => discount,
                                      :amount_paid => amount_paid,
                                      :balance => balance,
                                      :tax_amount => tax_amount
                                  })
      particulars << particular
    end
    transaction_data.fee_particulars = particulars
    #summary
    transaction_data.total_payable = total_amount #transaction.amount
    transaction_data.total_discount = total_discount
    transaction_data.total_tax = tax_amounts.compact.sum
    transaction_data.fine_amount = 0.0
    transaction_data.total_amount_to_pay = transaction.amount
    transaction_data.previously_paid_amount = 0.0
    transaction_data.total_amount_paid = transaction_data.amount
    transaction_data.total_due_amount = transaction_data.total_amount_to_pay -
        transaction_data.total_amount_paid.to_f
    transaction_data.total_fine_amount = 0.0
  end

  def fetch_registration_course_fee_transaction_data transaction, transaction_data
    #    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    transaction_data.receipt_title = I18n.t('applicant_fee_receipt')
    applicant = transaction.payee
    registration_course = applicant.registration_course
    subject_amounts = transaction.payee.subject_amounts
    transaction_data.amount = transaction.amount.to_f
    transaction_data.application_fee_title = I18n.t('applicants.application_fee')
    if subject_amounts.present?
      transaction_data.subject_amounts = true
      transaction_data.application_fee = FedenaPrecision.set_and_modify_precision(
          subject_amounts[:application_fee], transaction_data.precision)
      #normal subject fee amount
      transaction_data.normal_subject_amount = FedenaPrecision.set_and_modify_precision(
          subject_amounts[:normal_subject_amount].present? ?
              subject_amounts[:normal_subject_amount] : 0.to_f, transaction_data.precision)
      # elective subject fee amounts
      transaction_data.elective_subject_amount = FedenaPrecision.set_and_modify_precision(
          subject_amounts[:elective_subject_amounts].present? ?
              subject_amounts[:elective_subject_amounts].values.map do |x|
                FedenaPrecision.set_and_modify_precision(x, transaction_data.precision).to_f
              end.sum.to_f : 0.to_f, transaction_data.precision)

      transaction_data.elective_subject_ids = subject_amounts[:elective_subject_amounts].keys
      active_batch_ids = registration_course.course.batches.all(:conditions => {:is_active => true,
                                                                                :is_deleted => false}).collect(&:id)
      transaction_data.elective_subjects = Subject.find_all_by_code_and_batch_id(
          transaction_data.elective_subject_ids, active_batch_ids).map(&:name).flatten.compact.uniq.join(', ')
    else
      transaction_data.application_fee = FedenaPrecision.set_and_modify_precision(applicant.amount.to_f,
                                                                                  transaction_data.precision)
    end
    #    online_transaction_id = nil
    ## TO DO :: for old data which has online pay disabled now but previously online payments was done
    transaction_data.payment_mode = if FedenaPlugin.can_access_plugin?("fedena_pay")
                                      online_payment = Payment.find_by_payee_id_and_payee_type_and_status_and_amount(applicant.id, 'Applicant', true, applicant.amount)
                                      if online_payment.present?
                                        transaction_data.online_transaction_id = online_payment.gateway_response[:transaction_reference]
                                        I18n.t('online')
                                      end
                                    end || I18n.t('offline')
  end

  def fetch_transport_fee_transaction_data transaction, transaction_data
    transaction_data.is_particular_wise = false
    #    transaction_data.done_amount = 0.0
    transaction_data.total_discount = 0.0

    #    transaction_data.categorized_particulars = [[[struct]]]

    collection = transaction.finance.transport_fee_collection
    transaction_data.collection = OpenStruct.new({:title => I18n.t('transport_fee_collection'),
                                                  :name => collection.name, :due_date => collection.due_date,
                                                 })
    transaction_data.invoice_enabled = collection.invoice_enabled
    transaction_data.due_date = transaction_data.collection.due_date
    tf = transaction.finance
    transaction_data.fee_particulars = OpenStruct.new({:name => I18n.t('transport_fee.fare'),
                                                       :amount => FedenaPrecision.set_and_modify_precision(transaction.finance.bus_fare,
                                                                                                           transaction_data.precision)}).to_a
    #    transaction_data.transport_fee = OpenStruct.new({
    #        :bus_fare => FedenaPrecision.set_and_modify_precision(tf.bus_fare, transaction_data.precision),
    #        :is_paid => tf.is_paid
    #      })
    transaction_data.fine = transaction.fine_included ? transaction.fine_amount : 0.0
    #    transaction_data.discounts = OpenStruct.new(transaction.finance.transport_fee_discounts.map(&:attributes))
    transaction_data.discounts = transaction.finance.transport_fee_discounts.collect do |discount|
      transaction_data.total_discount += discount_amt = (discount.is_amount ? discount.discount :
          (transaction.finance.bus_fare.to_f * (discount.discount * 0.01)))
      discount_name = discount.name
      discount_name += "&#x200E;#{FedenaPrecision.set_and_modify_precision(discount.discount,
                                                                           transaction_data.precision)}%&#x200E;" unless discount.is_amount
      discount = OpenStruct.new({:name => discount_name,
                                 :discount_amount => FedenaPrecision.set_and_modify_precision(discount_amt, transaction_data.precision)})
      discount
    end

    #    if transaction_data.tax_enabled      
    #      slab = collection.collection_tax_slabs.try(:last)
    #      slab_name = slab.name 
    #      slab_name += "&#x200E;(#{FedenaPrecision.set_and_modify_precision(slab.rate, transaction_data.precision)}%)&#x200E;"      
    #      tax = FedenaPrecision.set_and_modify_precision(tf.tax_amount, transaction_data.precision)
    #      transaction_data.tax_slab_collections = OpenStruct.new({ :name => slab_name, 
    #          :amount => tax })
    #      transaction_data.total_tax = tax
    #    end

    #-------Auto Fine----------------------------------------------------
    transaction_data.fine_amount = 0.0
    bal = (transaction.finance.bus_fare.to_f - transaction_data.total_discount).to_f
    days = (transaction.transaction_date.to_date - transaction.finance.transport_fee_collection.due_date.to_date).to_i
    auto_fine = collection.fine
    fines = []
    auto_fine_to_pay = 0.0.to_f
    if days > 0 and auto_fine and !tf.is_fine_waiver and !transaction.fine_waiver
      fine_rule = auto_fine.fine_rules.find(:last, :order => 'fine_days ASC',
                                            :conditions => ["fine_days <= '#{days}' and created_at <= '#{collection.created_at}'"])
      transaction_data.fine_rule = OpenStruct.new({:rule_id => fine_rule.id, :fine_id => fine_rule.fine_id,
                                                   :fine_days => fine_rule.fine_days, :fine_amount => fine_rule.fine_amount,
                                                   :is_amount => fine_rule.is_amount}) if fine_rule.present?

      if transaction_data.fine_rule.present?
        if Configuration.is_fine_settings_enabled? && tf.balance <= 0 && tf.balance_fine.present?
          transaction_data.fine_amount += tf.balance_fine
        else
          transaction_data.fine_amount += transaction_data.fine_rule.is_amount ?
              transaction_data.fine_rule.fine_amount : (bal * transaction_data.fine_rule.fine_amount * 0.01)
          #            amount = transaction_data.fine_rule.is_amount ? transaction_data.fine_rule.fine_amount : (bal*transaction_data.fine_rule.fine_amount)/100
          transaction_data.fine_amount = transaction_data.fine_amount -
              transaction.finance.finance_transactions.find(:all,
                                                            :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
        end
        name = "#{t('fine_on')} " + format_date(collection.due_date.to_date + transaction_data.fine_rule.
                                                      fine_days.days) + (transaction_data.fine_rule.is_amount ? "" :
              " (#{transaction_data.fine_rule.fine_amount}&#x200E;%)")
        auto_fine_to_pay = transaction_data.fine_amount.to_f
        if transaction_data.fine_amount > 0 and transaction.finance.is_paid == false
          transaction_data.auto_fine_balance = OpenStruct.new({:name => name, :amount =>
                                                                  FedenaPrecision.set_and_modify_precision(transaction_data.fine_amount, transaction_data.precision)})
        else
          transaction_data.fine_amount = 0.0
        end
      end
    end
    # Paid Manual Fine
    transaction_data.total_manual_fine = 0
    transaction.finance.finance_transactions_with_fine.each do |t|
      name = "#{t('fine_on')} " + format_date(t.transaction_date)
      amount = t.fine_amount.to_f
      fines << OpenStruct.new({:name => name, :amount => FedenaPrecision.set_and_modify_precision(
                                  amount, transaction_data.precision)})
      transaction_data.fine_amount += amount
      transaction_data.total_manual_fine += amount
    end
    transaction_data.fine_list = fines # manual (paid) fine list

    # Summary

    transaction_data.total_payable = transaction.finance.bus_fare

    transaction_data.total_amount_to_pay = transaction.finance.bus_fare
    transaction_data.total_amount_to_pay -= transaction_data.total_discount
    transaction_data.total_amount_to_pay += transaction_data.fine_amount
    transaction_data.total_amount_to_pay += transaction_data.total_tax.to_f if transaction_data.tax_enabled and
        transaction_data.tax_slab_collections.present?
    previous_paid_amt = transaction.transport_fee_finance_transaction.try(:previous_payments) || 0
    transaction_data.previously_paid_amount = FedenaPrecision.set_and_modify_precision(previous_paid_amt,
                                                                                       transaction_data.precision) if previous_paid_amt.to_f > 0
    #    transaction_data.done_amount = transaction_data.previously_paid_amount
    transaction_data.total_amount_paid = FedenaPrecision.set_and_modify_precision(
        transaction.finance.finance_transactions.collect(&:amount).sum.to_f, transaction_data.precision)
    if transaction.transport_fee_finance_transaction.try(:transaction_balance).to_f == 0
      transaction_data.total_due_amount = FedenaPrecision.set_and_modify_precision(
          transaction.transport_fee_finance_transaction.try(:transaction_balance).to_f + auto_fine_to_pay,
          transaction_data.precision)
    else
      transaction_data.total_due_amount = transaction.transport_fee_finance_transaction.try(:transaction_balance).to_f +
          transaction_data.fine_amount
    end
    transaction_data.is_paid = tf.is_paid
    transaction_data.total_fine_amount = FedenaPrecision.set_and_modify_precision(transaction_data.fine_amount,
                                                                                  transaction_data.precision)
    transaction_data.total = FedenaPrecision.
        set_and_modify_precision(tf.bus_fare.to_f + transaction_data.fine_amount.to_f -
                                     transaction_data.total_discount.to_f + transaction_data.total_tax.to_f,
                                 transaction_data.precision)
  end

  def get_receipt_dummy_data(particular_wise = false)
    default_config_hash = ['InstitutionName', 'InstitutionAddress', 'PdfReceiptSignature',
                           'PdfReceiptSignatureName', 'PdfReceiptCustomFooter', 'PdfReceiptAtow', 'PdfReceiptNsystem',
                           'PdfReceiptHalignment', 'FinanceTaxIdentificationLabel', 'FinanceTaxIdentificationNumber',
                           'EnableInvoiceNumber', 'EnableFinanceTax', 'PrecisionCount']
    default_configs = OpenStruct.new(Configuration.get_multiple_configs_as_hash default_config_hash)
    default_configs.default_currency = Configuration.default_currency
    #    config_hash = 
    #    @config = Configuration.get_multiple_configs_as_hash 
    #    @default_currency = Configuration.default_currency
    #    @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
    #        'FinanceTaxIdentificationNumber']) if @tax_enabled

    # FIXME use HashWithIndifferentAccess ?
    transaction_hash = Hash.new { |h, k| h[k] = OpenStruct.new(&h.default_proc) }
    #    transaction_hash=HashWithIndifferentAccess.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    transaction_id=0
    transaction_data = transaction_hash[transaction_id]
    transaction_data.default_configs = default_configs
    transaction_data.precision = default_configs.precision_count
    transaction_data.finance_type = "FinanceFee"
    transaction_data.receipt_no = "receipt_no/001" #"#{Configuration.find_by_config_key('fee_receipt_no')}1"
    transaction_data.invoice_no = "invoice_no/001" #"#{Configuration.find_by_config_key('fee_invoice_no')}1"
    transaction_data.amount = 50.0
    transaction_data.fine_amount =""
    transaction_data.auto_fine = ""
    transaction_data.payment_mode = "Cash"
    transaction_data.payment_note = "Cash payment"
    transaction_data.reference_no = ""
    transaction_data.currency = Configuration.currency
    transaction_data.payee = OpenStruct.new({
                                                :payee_type => "Student",
                                                :full_name => "John Doe",
                                                :roll_number => "2",
                                                :admission_no => "23",
                                                :full_course_name => "Standard 1",
                                                :guardian_name => "Joseph Doe",
                                            })

    tax_enabled = transaction_data.tax_enabled = (default_configs.enable_finance_tax.to_i == 1)

    particulars = []

    4.times do |i|
      particulars << OpenStruct.new({:name => "Particular #{i+1}", :amount => 100})
    end

    transaction_data.fee_particulars = particulars
    transaction_data.collection = OpenStruct.new({:name => "Quarter 1 Fees",
                                                  :title => "Finance Fee Collection"})
    transaction_data.collection.invoice_enabled = (Configuration.get_config_value('EnableInvoiceNumber').to_i == 1)
    transaction_data.due_date = Date.today # ?
    transaction_data.transaction_date = Date.today # ?
    transaction_data.formated_date = format_date(transaction_data.transaction_date, :format => :short_date)
    transaction_data.fee_category = ""
    transaction_data.paid_fees = ""
    transaction_data.done_amount = 50.0
    transaction_data.total_amount_to_pay = ""
    # discounts
    tax_slab = OpenStruct.new({:name => "Tax", :rate => 5, :tax_amount => [100],
                               :display_name => "Tax &#x200E;(#{FedenaPrecision.set_and_modify_precision(5,
                                                                                                         transaction_data.precision)}%)&#x200E;"}) if tax_enabled
    #    tax = OpenStruct.new({:tax_amount => 100}) if tax_enabled
    transaction_data.tax_slab_collections = {1 => tax_slab} if tax_enabled

    discount = OpenStruct.new({:name => "discount", :discount_text => "discount",
                               :discount_amount => FedenaPrecision.set_and_modify_precision(100, transaction_data.precision),
                               :amount => 100, })
    transaction_data.discounts = discount.to_a

    #fine
    transaction_data.fine_amount =10.0
    fine = OpenStruct.new({:name => "fine", :amount => 10.0})
    fine_list = [fine]
    transaction_data.fine_list = fine_list
    # Particular amount
    transaction_data.particular_payments = OpenStruct.new({
                                                              :particular_name => "test",
                                                              :particular_amount => "200",
                                                              :remaining_balance => "150",
                                                              :discount => "50",
                                                              :paid_amount => "100",
                                                              :balance => "50"
                                                          })

    #    particular_payments = [particular_payment]
    #    transaction_data.particular_payments = particular_payments
    transaction_data.is_particular_wise = false
    # Summary
    transaction_data.total_payable = 400
    transaction_data.total_discount = 100.0
    transaction_data.total_tax = 100 if tax_enabled
    # transaction_data[:fine_amount]=10.0
    transaction_data.total_fine_amount = transaction_data.fine_amount
    transaction_data.total_amount_to_pay =400.0
    transaction_data.total_amount_to_pay = transaction_data.total_payable -
        transaction_data.total_discount + transaction_data.fine_amount
    transaction_data.total_amount_to_pay += transaction_data.total_tax if tax_enabled
    transaction_data.previously_paid_amount = transaction_data.done_amount
    transaction_data.total_amount_paid = transaction_data.previously_paid_amount + transaction_data.amount
    transaction_data.total_due_amount = transaction_data.total_amount_to_pay - transaction_data.total_amount_paid
    return transaction_hash
  end

  def particular_payment_details(transaction, transaction_data)
    #    transaction_data.particular_payments = transaction.particular_payments.all(
    transaction_data.particular_payments = transaction.particular_payments.all(
        :select => 'finance_fee_particulars.id as particular_id,
                      finance_fee_particulars.name as particular_name,
                      finance_fee_particulars.amount as particular_amount,
                      particular_payments.id as payment_id,
                      particular_payments.amount as payment_amount,
                      particular_discounts.id discount_id,
                      sum(particular_discounts.discount) as payment_discount',
        :joins => 'left outer join particular_discounts on particular_discounts.particular_payment_id=particular_payments.id
                     left outer join finance_fee_particulars on finance_fee_particulars.id=particular_payments.finance_fee_particular_id',
        :group => 'finance_fee_particulars.id')
    #                                        .map do |pp|
    #   _os = OpenStruct.new #(pp.attributes)
    #   _os.name = pp.particular_name
    #   _os.amount = FedenaPrecision.set_and_modify_precision(pp.particular_amount.to_f, transaction_data.precision_count)
    #   _os.discount = FedenaPrecision.set_and_modify_precision(pp.payment_discount.to_f, transaction_data.precision_count)
    #   _os.amount_paid = FedenaPrecision.set_and_modify_precision(pp.payment_amount.to_f - _os.discount.to_f,
    #                                                              transaction_data.precision_count)
    #   _os.remaining_balance = pp.particular_amount.to_f - previous_payments(transaction.id, pp.particular_id).to_f
    #   _os.remaining_balance = 0 if _os.remaining_balance < 0.to_f
    #   _os.balance = _os.remaining_balance.to_f - (_os.amount_paid.to_f + _os.discount.to_f)
    #   _os.remaining_balance = FedenaPrecision.set_and_modify_precision(_os.remaining_balance, transaction_data.precision_count)
    #   _os
    # end
  end

  def previous_payments(ftid, pid)
    ft=FinanceTransaction.find ftid
    ff=ft.finance
    payments=ff.finance_transactions.sum('particular_payments.amount', :joins => 'inner join particular_payments on particular_payments.finance_transaction_id=finance_transactions.id left outer join finance_fee_particulars on finance_fee_particulars.id=particular_payments.finance_fee_particular_id', :conditions => ["finance_transactions.id < ? and finance_fee_particulars.id =? ", ft.id, pid])
    payments
  end

  def particular_and_discount_details1(transaction, transaction_data)
    particulars = []
    transaction_data.total_discount = 0
    transaction_data.total_payable = 0
    transaction_data.fee_particulars = transaction.finance.finance_fee_collection.finance_fee_particulars.
        all(:conditions => "batch_id=#{transaction.finance.batch_id}").
        collect do |par|
      if ((par.receiver_type=='Student' and
          par.receiver_id==transaction.payee_id) ? par.receiver=transaction.payee : par.receiver; (par.receiver.present?) and
          (par.receiver==transaction.payee or
              par.receiver==transaction.finance.student_category or
              par.receiver==transaction.finance.batch))
        particulars << par
        par_amount = FedenaPrecision.set_and_modify_precision(par.amount.to_f, transaction_data.precision_count)
        transaction_data.total_payable += par_amount.to_f
        par.attributes.slice('name', 'amount', 'receiver_type')
        particular = OpenStruct.new({:name => par.name, :amount => par_amount,
                                     :receiver_type => par.receiver_type})
        #        particular.particular_id = par.id
        particular
      end
    end.compact #.collect {|x| particulars << x; OpenStruct.new(x.attributes.slice('id', 'name', 'amount', 'receiver_type'))}

    #    transactions_hash[transaction.id]["categorized_particulars"] = Hash[transactions_hash[transaction.id]["fee_particulars"].
    #        group_by {|x| x['receiver_type'] }.to_a]
    transaction_data.discounts = transaction.finance.finance_fee_collection.fee_discounts.all(
        :conditions => "batch_id=#{transaction.finance.batch_id}").collect do |par|
      if ((par.receiver.present?) and
          ((par.receiver==transaction.finance.student or
              par.receiver==transaction.finance.student_category or
              par.receiver==transaction.finance.batch) and
              (par.master_receiver_type!='FinanceFeeParticular' or
                  (par.master_receiver_type=='FinanceFeeParticular' and
                      (par.master_receiver.receiver.present? and
                          particulars.collect(&:id).include? par.master_receiver_id) and
                      (par.master_receiver.receiver==transaction.finance.student or
                          par.master_receiver.receiver==transaction.finance.student_category or
                          par.master_receiver.receiver==transaction.finance.batch)))))

        discount = OpenStruct.new(par.attributes.slice('name', 'discount', 'is_amount'))
        #        discount.discount_id = par.id
        discount_text = par.is_amount == true ? "#{par.name}" : "#{par.name}-#{par.discount}% "
        if par.master_receiver_type == 'FinanceFeeParticular'
          discount.discount_text = "#{discount_text}  &#x200E;(#{par.master_receiver.name}) &#x200E;"
          discount.discount_amount = (par.master_receiver.amount * par.discount.to_f / (par.is_amount? ? par.master_receiver.amount : 100))
        else
          discount.discount_text = discount_text
          discount.discount_amount = FedenaPrecision.set_and_modify_precision(transaction_data.total_payable *
                                                                                  par.discount.to_f / (par.is_amount? ? transaction_data.total_payable : 100), transaction_data.precision_count)
        end
        #        discount.discount_amount = par.master_receiver_type == 'FinanceFeeParticular' ? 
        #          (par.master_receiver.amount * par.discount.to_f / (par.is_amount? ? par.master_receiver.amount : 100)) : 
        #          transaction_data.total_payable * par.discount.to_f / (par.is_amount? ? transaction_data.total_payable : 100)      
        transaction_data.total_discount += discount.discount_amount.to_f

        discount
      end
    end.compact


    #    transaction_data.total_discounts = 0
    #    transaction_data.total_payable = particulars.map do |s| 
    #      FedenaPrecision.set_and_modify_precision(s.amount.to_f, transaction_data.precision_count).to_f
    #    end.sum.to_f

    #    transaction_data.total_discount = transaction_data.discounts.map do |d| 
    #      d.master_receiver_type == 'FinanceFeeParticular' ? 
    #        (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : 
    #        transactions_hash[transaction.id]["total_payable"] * d.discount.to_f/(d.is_amount? ? 
    #          transactions_hash[transaction.id]["total_payable"] : 100) 
    #    end.sum.to_f unless transactions_hash[transaction.id]["discounts"].nil?    
    #    transactions_hash[transaction.id]["discounts"] = transactions_hash[transaction.id]["discounts"].map do |x| 
    #      x.attributes
    #    end
    #    transactions_hash[transaction.id]["categorized_discounts"] = Hash[transactions_hash[transaction.id]["discounts"].
    #        group_by {|x| x['master_receiver_type'] }.to_a]
  end

  def payer_sql
    conditions = []
    conditions << "p.school_id=#{MultiSchool.current_school.id}" if defined?(MultiSchool)
    conditions << "1=1" unless defined?(MultiSchool)
    where_condition = conditions.join(" AND ")
    payer="(select p.id payer_id,IF(CONCAT(p.first_name,' ',p.middle_name,' ',  p.last_name) is NULL,
          CONCAT(p.first_name,' ',  p.last_name), CONCAT(p.first_name,' ',p.middle_name,' ',  p.last_name)) AS payer_name,
          null batchid,NULL as payer_batch_dept1,p.admission_no payer_no,'Student' payer_type,'Student' payer_type_info from students p  where (#{where_condition}))"
    payer+=" UNION ALL (select p.former_id payer_id,concat(p.first_name,' ',p.middle_name,' ',p.last_name) payer_name,NULL batchid,null as  payer_batch_dept1,p.admission_no payer_no,'Student' payer_type,'Archived Student' payer_type_info from archived_students p where (#{where_condition}))"
    payer+=" UNION ALL (select p.id payer_id,concat(p.first_name,' ',p.middle_name,' ',p.last_name) payer_name,NULL batchid,employee_departments.name payer_batch_dept1,p.employee_number payer_no,'Employee' payer_type,'Employee' payer_type_info from employees p inner join employee_departments on employee_departments.id=p.employee_department_id where (#{where_condition}))"
    payer+=" UNION ALL (select p.former_id payer_id,concat(p.first_name,' ',p.middle_name,' ',p.last_name) payer_name,NULL batchid,employee_departments.name payer_batch_dept1,p.employee_number payer_no,'Employee' payer_type,'Archived Employee' payer_type_info from archived_employees p inner join employee_departments on employee_departments.id=p.employee_department_id where (#{where_condition}))"
    payer+=" UNION ALL (select p.id payer_id,p.guest_payee payer_name,NULL batchid,NULL payer_batch_dept1,NULL payer_no,'Guest' payer_type,'Guest' payer_type_info from instant_fees p where p.guest_payee IS NOT NULL and (#{where_condition}))" if (FedenaPlugin.can_access_plugin?("fedena_instant_fee"))
    payer
  end

  def fee_sql(query=nil)
    unless query.nil?
      havings = ["having collection_name LIKE '%#{query}%'"]
    else
      havings = []
    end
    conditions=[]
    conditions << "cf.school_id=#{MultiSchool.current_school.id}" if defined?(MultiSchool)
    conditions << "1=1" unless defined?(MultiSchool)
    where_condition = conditions.join(" AND ")
    fee="(select c_batch.bat_id as batchid,c_batch.payer_batch_dept1 payer_batch_dept1,fc.name collection_name,cf.id fin_id,'FinanceFee' fin_type,cf.fee_collection_id collection_id from finance_fees cf inner join finance_fee_collections fc on fc.id=cf.fee_collection_id inner join  #{select_corresponding_batch_sql} c_batch on c_batch.bat_id = cf.batch_id where (#{where_condition}) group by cf.id #{havings})"
    fee+=" UNION ALL (select c_batch.bat_id as batchid,c_batch.payer_batch_dept1 payer_batch_dept1, hc.name collection_name,cf.id fin_id,'HostelFee' fin_type,cf.hostel_fee_collection_id collection_id from hostel_fees cf inner join hostel_fee_collections hc on hc.id=cf.hostel_fee_collection_id  inner join  #{select_corresponding_batch_sql} c_batch on c_batch.bat_id = cf.batch_id  where (#{where_condition}) group by cf.id #{havings})" if (FedenaPlugin.can_access_plugin?("fedena_hostel"))
    fee+=" UNION ALL (select c_batch.bat_id as batchid,c_batch.payer_batch_dept1 payer_batch_dept1, tc.name collection_name,cf.id fin_id,'TransportFee' fin_type,cf.transport_fee_collection_id collection_id from transport_fees cf inner join transport_fee_collections tc on tc.id=cf.transport_fee_collection_id  left outer join  #{select_corresponding_batch_sql} c_batch on c_batch.bat_id = cf.groupable_id  and cf.groupable_type='Batch' where (#{where_condition}) group by cf.id #{havings})" if (FedenaPlugin.can_access_plugin?("fedena_transport"))
    fee+=" UNION ALL (select c_instant_batch.bat_id as batchid,c_instant_batch.payer_batch_dept1 payer_batch_dept1,  ic.name collection_name,cf.id fin_id,'InstantFee' fin_type,cf.instant_fee_category_id collection_id from instant_fees cf inner join instant_fee_categories ic on ic.id=cf.instant_fee_category_id left outer join  #{select_corresponding_batch_sql} c_instant_batch on c_instant_batch.bat_id = cf.groupable_id  and cf.groupable_type='Batch'  where ic.name IS NOT NULL and (#{where_condition}) group by cf.id #{havings})" if (FedenaPlugin.can_access_plugin?("fedena_instant_fee"))
    fee+=" UNION ALL (select c_instant_batch.bat_id as batchid,c_instant_batch.payer_batch_dept1 as payer_batch_dept1,cf.custom_category collection_name,cf.id fin_id,'InstantFee' fin_type,NULL collection_id from instant_fees cf left outer join #{select_corresponding_batch_sql} c_instant_batch on c_instant_batch.bat_id = cf.groupable_id  where cf.custom_category IS NOT NULL and (#{where_condition}) group by cf.id #{havings})" if (FedenaPlugin.can_access_plugin?("fedena_instant_fee"))
    fee
  end

  def select_corresponding_batch_sql
    "(select concat(co.course_name,' - ',bat.name) as payer_batch_dept1,bat.id as bat_id from batches bat inner join courses co on co.id = bat.course_id)"
  end

  def fetched_fee_receipts(*args)
    FinanceTransaction.scoped(
        :select => "finance_transactions.id ftid,finance_transactions.trans_type,
                        finance_transactions.finance_type fin_type,finance_transactions.reference_no,
                        IFNULL(CONCAT(IFNULL(tr.receipt_sequence,''),tr.receipt_number),'-') receipt_no,
                        finance_transactions.payment_mode,
                        finance_transactions.transaction_date,finance_transactions.amount,f.batchid,
                        u.payer_type_info, u.payer_name,f.collection_id,u.payer_type,u.payer_no,u.payer_id,
                        (IFNULL(f.payer_batch_dept1,u.payer_batch_dept1)) as payer_batch_dept ,
                        CONCAT(c.first_name,' ',c.last_name) full_user_name,c.username uname,c.id user_id, f.collection_name,f.fin_id",
        :joins => "INNER JOIN finance_transaction_receipt_records ftrr
                           ON ftrr.finance_transaction_id = finance_transactions.id
                   INNER JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                   INNER JOIN (#{fee_sql}) f ON finance_transactions.finance_id=f.fin_id AND
                                                finance_transactions.finance_type=f.fin_type
              LEFT OUTER JOIN (#{payer_sql}) u
                           ON (IFNULL(finance_transactions.payee_id,finance_transactions.finance_id)=u.payer_id) AND
                               IFNULL(finance_transactions.payee_type,'Guest')=u.payer_type
              LEFT OUTER JOIN users c ON finance_transactions.user_id = c.id",
        :conditions => ["((finance_type IN ('TransportFee', 'HostelFee', 'FinanceFee', 'InstantFee')) AND
                           (ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false)))"],
        :order => "finance_transactions.id DESC"
    )
  end

  # def get_student_fee_receipt(transaction_ids, particular_wise=false, particular_id=nil)
  #   @fts_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  #   fts=FinanceTransaction.find_all_by_id(transaction_ids, :joins => :transaction_ledger,
  #                                         :include => [{:finance => {:tax_collections => :tax_slab}}],
  #                                         :select => "finance_transactions.*,if(finance_transaction_ledgers.transaction_mode = 'MULTIPLE',
  #                       finance_transactions.receipt_no, finance_transaction_ledgers.receipt_no) receipt_no")
  #   overall_tax_enabled = false
  #   fts.each do |ft|
  #     tax_enabled = ft.finance.tax_enabled?
  #     overall_tax_enabled = true if tax_enabled
  #     @fts_hash[ft.id]["finance_type"]=ft.finance_type
  #     @fts_hash[ft.id]["receipt_no"]=ft.receipt_no
  #     @fts_hash[ft.id]["invoice_no"]=ft.finance.invoice_no
  #     @fts_hash[ft.id]["amount"]=ft.amount
  #     @fts_hash[ft.id]["transaction_date"]=ft.transaction_date
  #     @fts_hash[ft.id]["fine_amount"]=ft.fine_amount
  #     @fts_hash[ft.id]["auto_fine"]=ft.auto_fine
  #     @fts_hash[ft.id]["payment_mode"]=ft.payment_mode
  #     @fts_hash[ft.id]["payment_note"]=ft.payment_note
  #     @fts_hash[ft.id]["reference_no"]=ft.reference_no
  #     @fts_hash[ft.id]["cheque_date"]=ft.cheque_date.present? ? ft.cheque_date : '-'
  #     @fts_hash[ft.id]["bank_name"]=ft.bank_name.present? ? ft.bank_name : '-'
  #     @fts_hash[ft.id]["currency"] = Configuration.currency
  #     if ft.payee_type == "Student"
  #       unless ft.payee.present?
  #         ars=ArchivedStudent.find_by_former_id(ft.payee_id)
  #         ft.payee=ars
  #         ft.payee_type='Student'
  #         ft.payee_id=ars.former_id
  #       end
  #       @fts_hash[ft.id]["payee"]["type"]=ft.payee_type
  #       @fts_hash[ft.id]["payee"]["full_name"]=ft.payee.full_name
  #       @fts_hash[ft.id]["payee"]["roll_number"]=ft.payee.roll_number
  #       @fts_hash[ft.id]["payee"]["admission_no"]=ft.payee.admission_no
  #       @fts_hash[ft.id]["payee"]["full_course_name"]= ft.fetch_finance_batch.nil? ? ft.payee.batch.full_name : ft.fetch_finance_batch.full_name
  #       @fts_hash[ft.id]["payee"]["guardian_name"]=ft.payee.try(:immediate_contact).try(:full_name)
  #     elsif ft.payee_type == "Employee"
  #       unless ft.payee.present?
  #         ae=ArchivedEmployee.find_by_former_id(ft.payee_id)
  #         ft.payee=ae
  #         ft.payee_type='Employee'
  #         ft.payee_id=ae.former_id
  #       end
  #       @fts_hash[ft.id]["payee"]["type"]=ft.payee_type
  #       @fts_hash[ft.id]["payee"]["full_name"]=ft.payee.full_name
  #       @fts_hash[ft.id]["payee"]["employee_number"]=ft.payee.employee_number
  #       @fts_hash[ft.id]["payee"]["employee_department_name"]=ft.payee.employee_department.name
  #     else
  #       @fts_hash[ft.id]["payee"]["full_name"]=ft.finance.guest_payee
  #     end
  #     @fts_hash[ft.id]["finance_transaction"]=ft
  #
  #     @fts_hash[ft.id]["tax_enabled"] = tax_enabled
  #     if @fts_hash[ft.id]['tax_enabled'] # fetch taxes collected
  #       tax_collections = (ft.finance_type != 'FinanceFee') ?
  #           ft.finance.tax_collections.all(:include => :tax_slab) : tax_collections = ft.finance.tax_collections
  #       unless ft.finance_type == 'TransportFee'
  #         @fts_hash[ft.id]['tax_slab_collections'] = tax_collections.group_by { |tc| tc.tax_slab }
  #         @fts_hash[ft.id]['total_tax'] = tax_collections.map { |x| FedenaPrecision.set_and_modify_precision(x.tax_amount).to_f }.sum.to_f
  #       end
  #     end
  #
  #     case ft.finance_type
  #       when 'FinanceFee'
  #         @fts_hash[ft.id]["collection"] = ft.finance.finance_fee_collection
  #         @fts_hash[ft.id]["financefee"] = ft.payee.finance_fee_by_date(ft.finance.finance_fee_collection)
  #         @fts_hash[ft.id]["due_date"] = ft.finance.finance_fee_collection.due_date
  #         @fts_hash[ft.id]["fee_category"] = FinanceFeeCategory.find(ft.finance.finance_fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
  #
  #         particular_and_discount_details1(ft)
  #         if particular_wise==true
  #           particular_payment_details(ft)
  #         end
  #         ff=ft.finance
  #         @fts_hash[ft.id]["paid_fees"] = ff.finance_transactions.all(:conditions => ["finance_transactions.id <= ? ", ft.id])
  #         @fts_hash[ft.id]["done_transactions"] = done_transactions = ff.finance_transactions.all(:conditions => ["finance_transactions.id < ? ", ft.id])
  #         done_amount=0
  #         done_transactions.each do |t|
  #           done_amount+=t.amount
  #         end
  #         @fts_hash[ft.id]["done_amount"] = done_amount
  #         @fts_hash[ft.id]["remainder_amount"] = @fts_hash[ft.id]["total_payable"]-@fts_hash[ft.id]["total_discount"]-@fts_hash[ft.id]["done_amount"]
  #         unless particular_id.nil?
  #           @fts_hash[ft.id]["previous_payments"]=ff.finance_transactions.sum('finance_fee_particulars.amount', :joins => 'inner join particular_payments on particular_payments.finance_transaction_id=finance_transactions.id left outer join finance_fee_particulars on finance_fee_particulars.id=particular_payments.finance_fee_particular_id', :conditions => ["finance_transactions.id < ? and finance_fee_particulars.id =? ", ft.id, particular_id])
  #         end
  #         bal=(@fts_hash[ft.id]["total_payable"]-@fts_hash[ft.id]["total_discount"]).to_f
  #         days=(ft.transaction_date.to_date - ft.finance.finance_fee_collection.due_date.to_date).to_i
  #         auto_fine=ft.finance.finance_fee_collection.fine
  #         if auto_fine.present? and (days > 0 and (!ft.finance.is_paid) or ft.successor_transactions.present?)
  #           @fts_hash[ft.id]["fine_rule"]=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{ft.finance.finance_fee_collection.created_at}'"], :order => 'fine_days ASC')
  #           unless particular_wise==true
  #             @fts_hash[ft.id]["fine_amount"]=@fts_hash[ft.id]["fine_rule"].is_amount ? @fts_hash[ft.id]["fine_rule"].fine_amount : (bal*@fts_hash[ft.id]["fine_rule"].fine_amount)/100 if @fts_hash[ft.id]["fine_rule"]
  #           end
  #         end
  #
  #
  #       when 'HostelFee'
  #         @fts_hash[ft.id]["collection"] = ft.finance.hostel_fee_collection
  #         # @finance_transaction=ft
  #         @fts_hash[ft.id]["finance"]=ft.finance
  #         @fts_hash[ft.id]["fine"] = ft.fine_included ? ft.fine_amount : 0.0
  #       when 'TransportFee'
  #         # @finance_transaction=ft
  #         @fts_hash[ft.id]["finance"]=ft.finance
  #         @fts_hash[ft.id]["collection"] = ft.finance.transport_fee_collection
  #         ff=ft.finance
  #         @fts_hash[ft.id]["fine"] = ft.fine_included ? ft.fine_amount : 0.0
  #         @fts_hash[ft.id]["due_date"] = ft.finance.transport_fee_collection.due_date
  #         @fts_hash[ft.id]["discounts"] = ft.finance.transport_fee_discounts
  #         @fts_hash[ft.id]["total_discount"] = 0
  #         @fts_hash[ft.id]["discounts"].each { |tfd| @fts_hash[ft.id]["total_discount"] =
  #             @fts_hash[ft.id]["total_discount"] + (tfd.is_amount ? tfd.discount :
  #                 (@fts_hash[ft.id]["finance"].bus_fare.to_f*(tfd.discount/100))) } if @fts_hash[ft.id]["discounts"].present?
  #         if @fts_hash[ft.id]['tax_enabled']
  #           @fts_hash[ft.id]['tax_slab_collections'] = @fts_hash[ft.id]["collection"].collection_tax_slabs.try(:last)
  #           @fts_hash[ft.id]['total_tax'] = ff.tax_amount
  #         end
  #         bal=(@fts_hash[ft.id]["finance"].bus_fare.to_f-@fts_hash[ft.id]["total_discount"]).to_f
  #         days=(ft.transaction_date.to_date - ft.finance.transport_fee_collection.due_date.to_date).to_i
  #         auto_fine=ft.finance.transport_fee_collection.fine
  #         if days > 0 and auto_fine
  #           @fts_hash[ft.id]["fine_rule"]=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{ft.finance.transport_fee_collection.created_at}'"], :order => 'fine_days ASC')
  #           if @fts_hash[ft.id]["fine_rule"]
  #             @fts_hash[ft.id]["fine_amount"]=@fts_hash[ft.id]["fine_rule"].is_amount ? @fts_hash[ft.id]["fine_rule"].fine_amount : (bal*@fts_hash[ft.id]["fine_rule"].fine_amount)/100
  #             @fts_hash[ft.id]["fine_amount"]=@fts_hash[ft.id]["fine_amount"]-@fts_hash[ft.id]["finance"].finance_transactions.find(:all,
  #                                                                                                                                   :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
  #             @fts_hash[ft.id]["auto_fine_to_pay"] = @fts_hash[ft.id]["fine_amount"]
  #           end
  #         end
  #       when 'InstantFee'
  #         @fts_hash[ft.id]["collection"] = ft.finance
  #         ff=ft.finance
  #         @fts_hash[ft.id]["instant_fee_details"] = ff.instant_fee_details
  #       else
  #         return
  #     end
  #   end
  #   @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
  #                                                             'FinanceTaxIdentificationNumber']) if overall_tax_enabled
  # end

  def overall_receipt_details(student_id, transaction_ids)
    @overall_receipt = OverallReceipt.new(student_id, transaction_ids)

  end

  class OverallReceipt < Struct.new(:student_id, :ledger_id, :batch_id, :query_sql)

    def finance_fee_sql
      "SELECT ft.wallet_amount_applied as wallet_amount_applied, ft.wallet_amount as wallet_amount, ft.id AS ft_id, tr.id AS tr_id, ft.transaction_date AS transaction_date, ft.reference_no AS reference_no,
                    ff.balance AS balance, ff.balance_fine AS balance_fine, ff.is_fine_waiver AS is_fine_waiver, ffc.name AS fee_collection_name, ffc.due_date,
                    ffc.tax_enabled AS tax_enabled,
                    IF(ffc.tax_enabled,ff.tax_amount,0) AS tax_amount, 
                    ft.amount AS transaction_amount, ft.fine_waiver AS trans_fine_waiver,
                    fine_rules.fine_amount AS fine_amount,

                    (SELECT SUM(IFNULL(finance_transactions.auto_fine,
                                                      IF(finance_transactions.fine_amount > finance_transactions.auto_fine,
                                                          finance_transactions.auto_fine, finance_transactions.fine_amount))
                                  )
                        FROM finance_transactions
                     WHERE finance_transactions.finance_id=ff.id AND 
                                 finance_transactions.finance_type='FinanceFee' AND 
                                 description= 'fine_amount_included'
                    ) AS paid_auto_fine,

                    (SELECT SUM(IFNULL(IF(description = 'fine_amount_included',
                                          IF(finance_transactions.fine_amount >= finance_transactions.auto_fine,
                                             finance_transactions.fine_amount - finance_transactions.auto_fine,
                                             0),
                                          finance_transactions.fine_amount),
                                       0)
                                )
                        FROM finance_transactions
                     WHERE finance_transactions.finance_id=ff.id AND 
                                 finance_transactions.finance_type='FinanceFee' 
                    ) AS paid_manual_fine,

                    fine_rules.is_amount,

                    (SELECT IFNULL(SUM(ft1.amount-ft1.fine_amount),0)
                        FROM finance_transactions ft1
                     WHERE ft1.finance_id=ff.id AND ft1.finance_type='FinanceFee' and 
                                 ft1.id > ft.id
                    ) AS balance_addition_due_amount,

                    (SELECT IFNULL(SUM(ft1.amount - ft1.fine_amount),0)
                        FROM finance_transactions ft1
                     WHERE ft1.finance_id=ff.id AND 
                                 ft1.finance_type='FinanceFee'
                    ) AS balance_addition_actual_amount,

                    ffc.invoice_enabled AS invoice_enabled,
                    IF(ffc.invoice_enabled, fi.invoice_number, NULL) AS invoice_number,
                    CONCAT(IFNULL(tr.receipt_sequence,''),tr.receipt_number) AS receipt_no,
                    ftl.transaction_mode AS receipt_gen_mode,
                    ftrr.fee_receipt_template_id AS receipt_template_id,
                    ftrr.precision_count,
                    ft.payment_mode payment_mode, ft.cheque_date cheque_date,
                    ft.bank_name bank_name, ft.payment_note payment_note,
                    IF(users.student OR users.parent, '', CONCAT(users.first_name,' ', users.last_name)) AS cname,
                    ffc.created_at as creation
      FROM finance_transactions ft
INNER JOIN users ON users.id = ft.user_id
INNER JOIN finance_transaction_ledgers ftl ON ftl.id = ft.transaction_ledger_id
INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
LEFT JOIN transaction_receipts AS tr ON tr.id = ftrr.transaction_receipt_id
INNER JOIN finance_fees ff ON ff.id = ft.finance_id AND ft.finance_type = 'FinanceFee'  
   LEFT JOIN fee_invoices fi ON fi.fee_id = ft.finance_id AND fi.fee_type = 'FinanceFee'                        
INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id #{fine_join_sql}  
      WHERE ftl.id = #{ledger_id} AND ft.school_id = #{MultiSchool.current_school.id}"
      #      WHERE ft.id IN (#{transaction_ids.join(',')}) AND ft.school_id = #{MultiSchool.current_school.id}"
    end

    def transport_fee_sql
      if defined? TransportFeeCollection
        "UNION ALL 
              SELECT ft.wallet_amount_applied as wallet_amount_applied, ft.wallet_amount as wallet_amount, ft.id AS ft_id, tr.id AS tr_id, ft.transaction_date AS transaction_date, ft.reference_no AS reference_no,
                          ff.balance AS balance, ff.balance_fine AS balance_fine, ff.is_fine_waiver AS is_fine_waiver, ffc.name AS fee_collection_name, ffc.due_date,
                          ffc.tax_enabled AS tax_enabled,
                          IF(ffc.tax_enabled,ff.tax_amount,0) AS tax_amount, 
                          ft.amount AS transaction_amount, NULL AS trans_fine_waiver,
                          fine_rules.fine_amount AS fine_amount,

                          (SELECT SUM(IFNULL(finance_transactions.auto_fine,
                                                           IF(finance_transactions.fine_amount > finance_transactions.auto_fine,
                                                               finance_transactions.auto_fine, finance_transactions.fine_amount))
                                               )
                              FROM finance_transactions
                           WHERE finance_transactions.finance_id=ff.id AND 
                                       finance_transactions.finance_type='TransportFee' AND 
                                       description= 'fine_amount_included'
                           ) AS paid_auto_fine,

                           (SELECT SUM(IFNULL(IF(description = 'fine_amount_included',
                                                 IF(finance_transactions.fine_amount > finance_transactions.auto_fine,
                                                    finance_transactions.fine_amount - finance_transactions.auto_fine,
                                                    0),
                                                 finance_transactions.fine_amount),
                                              0)
                                       )
                              FROM finance_transactions
                            WHERE finance_transactions.finance_id=ff.id AND 
                                        finance_transactions.finance_type='TransportFee' AND 
                                        description= 'fine_amount_included'
                           ) AS paid_manual_fine,

                           fine_rules.is_amount,

                           (SELECT IFNULL(SUM(ft1.amount-ft1.fine_amount),0)
                               FROM finance_transactions ft1
                            WHERE ft1.finance_id = ff.id AND ft1.finance_type = 'TransportFee' AND 
                                         ft1.id > ft.id
                           ) AS balance_addition_due_amount,

                           (SELECT IFNULL(SUM(ft1.amount - ft1.fine_amount),0)
                               FROM finance_transactions ft1
                            WHERE ft1.finance_id=ff.id AND ft1.finance_type='TransportFee'
                           ) AS balance_addition_actual_amount,

                           ffc.invoice_enabled AS invoice_enabled,
                           IF(ffc.invoice_enabled, fi.invoice_number, NULL) AS invoice_number,
                           CONCAT(IFNULL(tr.receipt_sequence,''),tr.receipt_number) AS receipt_no,
                           ftl.transaction_mode AS receipt_gen_mode,
                           ftrr.fee_receipt_template_id AS receipt_template_id,
                           ftrr.precision_count,
                           ft.payment_mode payment_mode, ft.cheque_date cheque_date,
                           ft.bank_name bank_name, ft.payment_note payment_note,
                           IF(users.student OR users.parent, '', CONCAT(users.first_name,' ', users.last_name)) AS cname,
                           ffc.created_at as creation
             FROM finance_transactions ft
       INNER JOIN users ON users.id = ft.user_id
       INNER JOIN finance_transaction_ledgers ftl ON ftl.id = ft.transaction_ledger_id
       INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
       LEFT JOIN transaction_receipts AS tr ON tr.id = ftrr.transaction_receipt_id
       INNER JOIN transport_fee_finance_transactions tfft ON tfft.finance_transaction_id=ft.id
       INNER JOIN transport_fees ff ON ff.id=ft.finance_id AND ft.finance_type='TransportFee'
         LEFT JOIN fee_invoices fi ON fi.fee_id = ft.finance_id AND fi.fee_type = 'TransportFee'
       INNER JOIN transport_fee_collections ffc ON ffc.id=ff.transport_fee_collection_id  #{fine_join_sql}
             WHERE ftl.id = #{ledger_id} AND (ft.school_id = #{MultiSchool.current_school.id})"
      else
        # plugin_disabled_fetch_query
      end
    end

    def hostel_fee_sql
      if defined? HostelFeeCollection
        "UNION ALL 
              SELECT ft.wallet_amount_applied as wallet_amount_applied, ft.wallet_amount as wallet_amount, ft.id AS ft_id, tr.id AS tr_id, ft.transaction_date AS transaction_date, ft.reference_no AS reference_no,
                          hf.balance AS balance, NULL AS balance_fine, NULL AS is_fine_waiver, hfc.name AS fee_collection_name, hfc.due_date,
                          hfc.tax_enabled AS tax_enabled,
                          IF(hfc.tax_enabled,hf.tax_amount,0) AS tax_amount, 
                          ft.amount AS transaction_amount, NULL AS trans_fine_waiver, 
                          '' AS fine_amount, 0 AS paid_auto_fine,

                          (SELECT SUM(IFNULL(finance_transactions.fine_amount,0))
                             FROM finance_transactions
                            WHERE finance_transactions.finance_id=hf.id AND
                                  finance_transactions.finance_type='HostelFee'
                           ) AS paid_manual_fine,

                           '' AS is_amount, 0 AS balance_addition_due_amount,
                          (hf.rent - hfft.transaction_balance) AS balance_addition_actual_amount,

                          hfc.invoice_enabled AS invoice_enabled,
                          IF(hfc.invoice_enabled, fi.invoice_number, NULL) AS invoice_number,
                          CONCAT(IFNULL(tr.receipt_sequence,''),tr.receipt_number) AS receipt_no,
                          ftl.transaction_mode AS receipt_gen_mode,
                          ftrr.fee_receipt_template_id AS receipt_template_id,
                          ftrr.precision_count,
                          ft.payment_mode payment_mode, ft.cheque_date cheque_date,
                          ft.bank_name bank_name, ft.payment_note payment_note,
                          IF(users.student OR users.parent, '', CONCAT(users.first_name,' ', users.last_name)) AS cname,
                          hfc.created_at as creation
              FROM finance_transactions ft
        INNER JOIN users ON users.id = ft.user_id
        INNER JOIN finance_transaction_ledgers ftl ON ftl.id = ft.transaction_ledger_id
        INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
        LEFT JOIN transaction_receipts AS tr ON tr.id = ftrr.transaction_receipt_id
        INNER JOIN hostel_fee_finance_transactions hfft  ON hfft.finance_transaction_id=ft.id
        INNER JOIN hostel_fees hf  ON hf.id=ft.finance_id AND ft.finance_type='HostelFee'
           LEFT JOIN fee_invoices fi ON fi.fee_id = ft.finance_id AND fi.fee_type = 'HostelFee'
        INNER JOIN hostel_fee_collections hfc ON hfc.id=hf.hostel_fee_collection_id
              WHERE ftl.id = #{ledger_id} AND (ft.school_id = #{MultiSchool.current_school.id})"
      else
        # plugin_disabled_fetch_query
      end
    end

    def fetch_transaction_data
      #      sql = "#{finance_fee_sql}".squish
      @ledger = FinanceTransactionLedger.find ledger_id
      sql = "#{finance_fee_sql} #{transport_fee_sql} #{hostel_fee_sql}".squish
      FinanceTransaction.find_by_sql(sql) #transaction_id transaction_ids.last      
    end

    def fetch_details
      transactions = fetch_transaction_data.sort_by(&:creation)

      data = OpenStruct.new
      #      config_keys = ['PdfReceiptSignature', 'PdfReceiptSignatureName', 
      #        'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment',
      #        'InstitutionAddress', 'InstitutionName' ]
      #      fetch_config_hash config_keys
      #      @default_currency = Configuration.default_currency
      #      @current_batch = Batch.find(params[:batch_id])
      default_config_hash = ['InstitutionName', 'InstitutionAddress', 'PdfReceiptSignature',
                             'PdfReceiptSignatureName', 'PdfReceiptCustomFooter', 'PdfReceiptAtow', 'PdfReceiptNsystem',
                             'PdfReceiptHalignment', 'FinanceTaxIdentificationLabel', 'FinanceTaxIdentificationNumber', 'EnableRollNumber']
      default_configs = OpenStruct.new(Configuration.get_multiple_configs_as_hash default_config_hash)
      default_configs.default_currency = Configuration.default_currency
      default_configs.currency = Configuration.currency
      data.default_configs = default_configs
      data.receipt_mode = transactions.first.receipt_gen_mode
      data.transaction_date = transactions.first.transaction_date
      data.reference_no = transactions.first.reference_no
      batch = Batch.find(batch_id)
      student = Student.find(student_id)
      data.batch_id = batch_id
      data.payee = OpenStruct.new({:full_name => student.full_name, :admission_no => student.admission_no,
                                   :roll_no => student.roll_number, :course_full_name => batch.course.full_name,
                                   :batch_full_name => batch.full_name, :guardian_name => student.try(:immediate_contact).try(:full_name)
                                  })
      # TO DO :: remove when completed
      #      data.all_transactions = transactions
      #      data[:transactions] = transactions.group_by {|x| x.receipt_template_id }
      #      if data[:receipt_mode] == "SINGLE"
      #        hsh = ActiveSupport::OrderedHash.new
      #        data[:transactions].group_by {|k,v| hsh[k] = v.group_by {|v1| v1.receipt_no } }
      #        data[:transactions] = hsh
      #      end      
      template_ids = []
      transaction_data = {}
      case data.receipt_mode
        when "MULTIPLE"
          transactions.group_by { |t| t.receipt_template_id }.each_pair do |template_id, t_transactions|
            template_ids << template_id
            tax_enabled, invoice_enabled = [], []
            t_transactions.each { |x| tax_enabled << x.tax_enabled; invoice_enabled << x.invoice_enabled; }
            is_tax_enabled = tax_enabled.uniq.include?("1")
            is_invoice_enabled = invoice_enabled.uniq.include?("1")
            transaction_data[template_id] = t_transactions.map do |t|
              transaction = OpenStruct.new(t.attributes.merge({:overall_tax_enabled => is_tax_enabled,
                                                               :overall_invoice_enabled => is_invoice_enabled}))
              calculations transaction
            end
          end
        when "SINGLE"
          #        hsh = ActiveSupport::OrderedHash.new
          template_ids = transactions.group_by { |t| t.receipt_template_id }.each_pair do |template_id, t_transactions|
            template_ids << template_id
            transaction_data[template_id] = {}
            t_transactions.group_by { |t| t.receipt_no }.each_pair do |receipt_no, r_transactions|

              tax_enabled, invoice_enabled = [], []
              t_transactions.each { |x| tax_enabled << x.tax_enabled; invoice_enabled << x.invoice_enabled; }
              is_tax_enabled = tax_enabled.uniq.include?("1")
              is_invoice_enabled = invoice_enabled.uniq.include?("1")

              transaction_data[template_id][receipt_no] = r_transactions.map do |t|
                transaction = OpenStruct.new(t.attributes.merge({:overall_tax_enabled => is_tax_enabled,
                                                                 :overall_invoice_enabled => is_invoice_enabled}))
                calculations transaction
              end
            end
          end


        #        transactions.group_by {|x| x.receipt_template_id}.group_by {|k,v| hsh[k] = v.group_by {|v1| v1.receipt_no } }
        #        transactions

        #        transactions.group_by {|x| x.receipt_template_id}.group_by {|k,v| hsh[k] = v.group_by {|v1| v1.receipt_no } }
        #        hsh
      end
      data.transactions = transaction_data
      data.template_ids = template_ids.compact.uniq
      #      templates = {}
      #      FeeReceiptTemplate.find(template_ids).each do |t| 
      #        templates[t.id] = OpenStruct.new(t.attributes.except("id"))
      #      end if template_ids.present?
      #      data.template_ids = {} #template_ids.present? ? FeeReceiptTemplate.find(template_ids).eac : {}      
      data
    end

    def calculations transaction

      is_amount = transaction.is_amount.to_i

      fine_amount = transaction.fine_amount

      actual_bal = transaction.balance.to_f + transaction.balance_addition_actual_amount.to_f
      total_bal = (transaction.tax_enabled == "1" ? actual_bal - transaction.tax_amount.to_f : actual_bal)
      if Configuration.is_fine_settings_enabled? && transaction.balance.to_f == 0 && transaction.balance_fine.present?
      fine_amount = transaction.paid_auto_fine.to_f + transaction.balance_fine.to_f
      else
      fine_amount = (is_amount == 1 ? fine_amount : (total_bal * fine_amount.to_f * 0.01))
      end
      fine_amount = 0.0 if (transaction.is_fine_waiver == "1" || transaction.trans_fine_waiver == "1")
      due_amount = transaction.balance.to_f + transaction.balance_addition_due_amount.to_f

      due_amount -= transaction.paid_auto_fine.to_f
      due_amount += fine_amount.to_f

      total_bal += transaction.paid_manual_fine.to_f + fine_amount.to_f
      total_bal += transaction.tax_amount.to_f if transaction.tax_enabled == "1"
      
      transaction.actual_amount = FedenaPrecision.set_and_modify_precision(total_bal, transaction.precision_count)
      transaction.fine_amount = FedenaPrecision.set_and_modify_precision(fine_amount, transaction.precision_count)
      transaction.due_amount = FedenaPrecision.set_and_modify_precision(due_amount, transaction.precision_count)
      transaction.tax_amount = FedenaPrecision.set_and_modify_precision(transaction.tax_amount, transaction.precision_count)
      transaction.transaction_amount = FedenaPrecision.set_and_modify_precision(transaction.transaction_amount,
                                                                                transaction.precision_count)

      transaction
    end

    def fine_join_sql
      transaction_date = @ledger.transaction_date
      "LEFT JOIN `fines` ON `fines`.id = `ffc`.fine_id AND fines.is_deleted is false
       LEFT JOIN `fine_rules` ON fine_rules.fine_id = fines.id  AND fine_rules.id = (
          SELECT id FROM fine_rules ffr 
          WHERE ffr.fine_id=fines.id AND ffr.created_at <= ffc.created_at AND ffr.fine_days <= DATEDIFF(
              IFNULL('#{transaction_date}', CURDATE()),ffc.due_date
            )
          ORDER BY fine_days DESC LIMIT 1
        )"
    end
  end

end
