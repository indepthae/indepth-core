# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class FeeDetails
  
  #initialize this class :- 
  #student - student object (both fetching and paying fees)
  #amount to pay :- total amount to pay (if paying fees only) 
  def initialize args = {}
    @student = Student.find args[:student].id
    @paying_amount = args[:amount].to_f
    @reference_no = args[:reference_no].present? ? args[:reference_no] : nil
    @payment_note = args[:payment_note].present? ? args[:payment_note] : nil
    @transaction_date = args[:transaction_date].present? ? args[:transaction_date] : Date.today
    @amount_type = args[:list_type].present? ? args[:list_type] : nil
    @collection_name = args[:fee_collection_name].present? ? args[:fee_collection_name] : nil
    @collection_type = args[:fee_collection_type].present? ? args[:fee_collection_type] : nil
    @collection_id = args[:fee_collection_id].present? ? args[:fee_collection_id] : nil
    @order_id = args[:order_id].present? ? args[:order_id] : nil
    @item_id = args[:item_id].present? ? args[:item_id] : nil
  end
  
  #code for fetching balance fees for a student 
  ##############***************################
  def get_pending_fee_details_for_student
    fees =  get_pending_fees(@student)
    if @amount_type == "each-fee"
      payment_details = get_fee_detail_hash(fees,@student,@amount_type)
      payment_details = payment_details.sort_by{|x| x["due_date"]}      
    elsif @amount_type == "all-fee"
      payment_details = get_fee_detail_hash(fees,@student,@amount_type)
    end
    return payment_details
  end
  
  def get_pending_fees(student)
    fees = fetch_all_fees()
  end
  
  def get_fee_detail_hash(fees, student, amount_fee_type)
    return_array = []
    total_amount = 0.0
    if amount_fee_type == "each-fee"
      fees.each do |fee|
        return_hash_temp = {}
        return_hash_temp["admno"] = student.admission_no
        return_hash_temp["stdName"] = student.full_name
        return_hash_temp["feeName"] = fee.fee_name 
        return_hash_temp["feetype"] = fee.class.name
        return_hash_temp["feeID"] = fee.id.to_s
        return_hash_temp["amount"] = fee.balances.to_f + fetch_fine_amount(fee)
        return_hash_temp["due_date"] = fee.fee_due_date
        return_array << return_hash_temp
      end
    elsif amount_fee_type == "all-fee"
      fees.each do |fee|
        return_hash_temp = 0.0
        return_hash_temp += fee.balances.to_f + fetch_fine_amount(fee)
        total_amount += return_hash_temp
      end
      return_array << total_amount
    end
    return_array.flatten
  end
##############***************################  


#code for paying balance fees for a student  
##############***************################

  def pay_fees_for_student
    status = "Failed"
    amount_check = ''
    data = []
    student = Student.find @student.id if @student.present?
    if student.present?
      total_amount = @paying_amount.to_f if @paying_amount.present?
      if total_amount.present? and total_amount > 1
        if @collection_name.present?
          status,amount_check = fetch_fee_and_pay(student,total_amount,@collection_name,@collection_type,@collection_id)
        else  
          status,data,amount_check = fetch_all_fee_and_pay(student,total_amount)
        end
      else
        data << "amount :- #{total_amount} should be greater than 1"
      end
    else
      data << "Student record not found"
    end
    return status,data,amount_check
  end
  
  def fetch_all_fee_and_pay(student,total_amount)
    @flag = false
#    @record = Hash.new
#    data = []
    receipt_number = []
    amount_check = ''
    @total_credits = total_amount.to_f
    ledger_amount = total_amount.to_f
    @student = student
#    @donee = []
#    @error = []
    @payment_mode = "PAYTM"
    @all_fees = fetch_all_fees()
    total_fine_amounts = 0
    @all_fees.each do |x|
      total_fine_amounts += (x.is_amount == "1" ? x.fee_fine_amount.to_f : ((x.actual_amount.to_f * x.fee_fine_amount.to_f)/100.0)) if x.is_amount.present?
    end
    
    total_balance_to_pay = 0
    @all_fees = @all_fees.uniq
    @all_fees = @all_fees.sort_by{|s| s.fee_due_date}
    @all_fees.each do |x|
      total_balance_to_pay+= x.balances.to_f
    end
    total_fees_to_pay = total_balance_to_pay.to_f + total_fine_amounts.to_f
    if @all_fees.present?
      if @total_credits == total_fees_to_pay or @total_credits < total_fees_to_pay
        
        @transactions = Hash.new
        @all_fees.each_with_index do |finace_ffees, i|
          unless @total_credits.to_f == 0.to_f
            
            unless finace_ffees.ftype == "HostelFee"
              @fine_amounts = 0.0
              @fine_amounts += (finace_ffees.is_amount == "1" ? finace_ffees.fee_fine_amount.to_f : ((finace_ffees.actual_amount.to_f * finace_ffees.fee_fine_amount.to_f)/100.0)) if finace_ffees.is_amount.present?
              
              if finace_ffees.is_amount.present? and finace_ffees.balances==0
                if finace_ffees.ftype == "FinanceFee"
                  @obj = FinanceFee.find_by_id(finace_ffees.id)
                  @fine_amounts = @fine_amounts - @obj.finance_transactions.all(
                  :conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
                else
                  @obj = TransportFee.find_by_id(finace_ffees.id)
                  @fine_amounts = @fine_amounts - @obj.finance_transactions.all(
                  :conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
                end
                
              end
            end
              
            total_fees = finace_ffees.balances.to_f + @fine_amounts.to_f
            if @total_credits >= total_fees
              paying_fees = total_fees
              @total_credits -= total_fees
            else
              paying_fees = @total_credits
              @total_credits -= paying_fees
            end
            @financefee = finace_ffees
            payment_mode = @payment_mode
            payment_note = @payment_note
            refer_note = @reference_no
            finance_type = finace_ffees.ftype
            if finace_ffees.ftype == "FinanceFee"
              category_name = "Fee"
            elsif finace_ffees.ftype == "TransportFee"
              category_name = "Transport" 
            elsif finace_ffees.ftype == "HostelFee"
              category_name = "Hostel"
            end
            
            unless FedenaPrecision.set_and_modify_precision(paying_fees).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
              
              
              # ii is temporary hash to store the transaction details for each loop and saved to @transactions Hash
              
              each_transaction = Hash.new
              each_transaction[:payee_type] = "Student"
              each_transaction[:payee_id] = @student.id
              each_transaction[:finance_id] = @financefee.id.to_s
              each_transaction[:category_id] = FinanceTransactionCategory.find_by_name(category_name).id
              (total_fees.to_f > paying_fees.to_f) ? title = "#{I18n.t('receipt_no')}. (#{I18n.t('partial')}) F#{@financefee.id}" : title = "#{I18n.t('receipt_no')}. F#{@financefee.id}"
              each_transaction[:title] = title
              each_transaction[:finance_type] = finance_type
              each_transaction[:payment_mode] = payment_mode
              each_transaction[:payment_note] = payment_note
              each_transaction[:transaction_date] = @transaction_date
              each_transaction[:amount] = paying_fees
              each_transaction[:reference_no] = refer_note
              @transactions[i+1] = each_transaction
              
              #"transactions"=>{"1"=>{
              #"title"=>"Receipt No.. \r\n      (Multiple Fees) F1", 
              #"payment_mode"=>"Cash", 
              #"finance_id"=>"1", 
              #"payment_note"=>"", 
              #"reference_no"=>"", 
              #"finance_type"=>"FinanceFee", 
              #"amount"=>"10000.00", 
              #"payee_id"=>"1", 
              #"payee_type"=>"Student", 
              #"transaction_date"=>"2019-06-20", 
              #"category_id"=>"3"}}, 
               
#              @donee << "#{finace_ffees.id}"
            else
#              @error << "the error #{finace_ffees.id}"
            end
          end
        end
        #######
        #"multi_fees_transaction"=>{
        #"payment_mode"=>"Cash", 
        #"payment_note"=>"", 
        #"reference_no"=>"", 
        #"amount"=>"10000.00", 
        #"payee_id"=>"1", 
        #"transaction_date"=>"2019-06-20", 
        #"payee_type"=>"Student"}}
        
        @multi_fees_transaction = Hash.new
        @multi_fees_transaction[:payee_id] = @student.id
        @multi_fees_transaction[:payee_type] = "Student"
        @multi_fees_transaction[:payment_mode] = "PAYTM"
        @multi_fees_transaction[:payment_note] = @payment_note
        @multi_fees_transaction[:transaction_date] = @transaction_date
        @multi_fees_transaction[:reference_no] = @reference_no
        @multi_fees_transaction[:amount] = ledger_amount.to_f
       
        particular_paid = false
        FinanceTransactionLedger.transaction do        
          if !particular_paid
            status=true
            transaction_ledger = FinanceTransactionLedger.safely_create(@multi_fees_transaction.
                except(:cheque_date, :bank_name).
                merge({:transaction_type => 'MULTIPLE', :category_is_income => true,
                :current_batch => @student.batch,:is_waiver => false}),@transactions)        
        
            FinanceTransaction.send_sms=true
            if status and !(transaction_ledger.new_record?)
              tids = transaction_ledger.finance_transactions.collect(&:id)
              trans_code=[]
              tids.each do |tid|
                trans_code << "transaction_id%5B%5D=#{tid}"
              end
              # send sms for a payall transaction
              transaction_ledger.send_sms
              trans_code=trans_code.join('&')
              # saving paytm payment record
              ppr = PaytmPaymentRecord.new()
              ppr.transaction_ledger = transaction_ledger
              ppr.order_id = @order_id
              ppr.item_id = @item_id
              ppr.amount = @paying_amount
              ppr.save
              @flag = true
#              @record[:status] = "Success"
#              @record[:description] = "Fee amount #{ledger_amount.to_f} paid successfully for student with admission number #{@student.admission_no}."
#              @record[:description] = ""
              receipt_number = transaction_ledger.finance_transactions.collect {|x| x.transaction_receipt.receipt_number}.uniq
            else
#              @record[:status] = "Failed"
#              @record[:description] = "Rollback 1"
              raise ActiveRecord::Rollback
            end
          else        
#            @record[:status] = "Failed"
#            @record[:description] = "Rollback 2"
            raise ActiveRecord::Rollback
          end
        end
      else
#        @record[:status] = "Failed"
#        @record[:description] = "Fee balance is #{total_fees_to_pay} less than the given amount #{@total_credits} for student with admission number #{@student.admission_no}."
        amount_check = 104
      end
    else
#      @record[:status] = "Failed"
#      @record[:description] = "No fee balance for the student with admission no #{@student.admission_no}."
    end
#    data << @record[:description]
    if @flag
      status = "Success"
    else
      status = "Failed"
    end
    return status,receipt_number,amount_check
  end
  
  
  def fetch_fee_and_pay(student,paying_amount,collection_name,collection_type,collection_id)
    if collection_name.present? and collection_type.present? and collection_id.present?
      status = "Failed"
      amount_check = ''
      fee,balance,record = fetch_fee(collection_type,collection_id)
      @flag = false
      @record = Hash.new
      data = []
      @total_credits = paying_amount.to_f
      @student = student
      @donee = []
      @payment_mode = "PAYTM"
      if fee.present?
        if paying_amount.to_f <= balance.to_f
          status,transaction_ledger = make_transaction_record(fee,paying_amount,balance,record)
        else
          amount_check = 104
        end
      end
      if status == "Success"
        # saving paytm payment record
        ppr = PaytmPaymentRecord.new()
        ppr.transaction_ledger = transaction_ledger
        ppr.order_id = @order_id
        ppr.item_id = @item_id
        ppr.amount = @paying_amount
        ppr.save
      end
      return status,amount_check
    end
  end
  
  def fetch_fee(collection_type,collection_id)
    case collection_type
    when "FinanceFee" 
      fee = find_fee(collection_type)
      balance = fee.first.balances.to_f + fetch_fine_amount(fee.first).to_f
      record = FinanceFee.find(fee.first.id)
    when "TransportFee"
      fee = find_fee(collection_type)
      balance = fee.first.balances.to_f + fetch_fine_amount(fee.first).to_f
      record = TransportFee.find(fee.first.id)
    when "HostelFee"
      fee = find_fee(collection_type)
      balance = fee.first.balances.to_f
      record = HostelFee.find(fee.first.id)
    end
    return fee.first,balance,record
  end
  
  def fetch_fine_amount(fee)
    fine_amount = 0
    fine_amount += (fee.is_amount == "1" ? fee.fee_fine_amount.to_f : ((fee.actual_amount.to_f * fee.fee_fine_amount.to_f)/100.0)) if fee.is_amount.present?
    if fee.is_amount.present? and fee.balances==0
      if fee.ftype == "FinanceFee"
        @obj = FinanceFee.find_by_id(fee.id)
        fine_amount = fine_amount - @obj.finance_transactions.all(
        :conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      else
        @obj = TransportFee.find_by_id(fee.id)
        fine_amount = fine_amount - @obj.finance_transactions.all(
        :conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
      end
    end
    fine_amount
  end
  
  
  def make_transaction_record(fee,paying,balance,record)
    if fee.class.name == "FinanceFee"
      category_name = "Fee"
    elsif fee.class.name == "TransportFee"
      category_name = "Transport" 
    elsif fee.class.name == "HostelFee"
      category_name = "Hostel"
    end
    fee_record = record
    unless FedenaPrecision.set_and_modify_precision(paying).to_f > FedenaPrecision.set_and_modify_precision(balance).to_f
      transaction = FinanceTransaction.new
      ActiveRecord::Base.transaction do
        (fee.balances.to_f > paying.to_f) ? transaction.title = "#{I18n.t('receipt_no')}. (#{I18n.t('partial')}) F#{fee.id}" : transaction.title = "#{I18n.t('receipt_no')}. F#{fee.id}"
        transaction.category = FinanceTransactionCategory.find_by_name(category_name)
        transaction.payee = @student
        transaction.finance = fee_record
        transaction.amount = paying.to_f
        transaction.transaction_type = 'SINGLE'
        transaction.transaction_date = @transaction_date
        transaction.payment_mode = "PAYTM"
        transaction.reference_no = @reference_no
        transaction.payment_note = @payment_note
        transaction.safely_create
        if transaction.errors.present?
          raise ActiveRecord::Rollback
          return "Failed"
        else
          return "Success",transaction.transaction_ledger
        end
      end
    else
      return "Failed"
    end   
  end
  
  def find_fee(collection_type)
    case collection_type
    when "FinanceFee"
      fee=@student.finance_fees.all(:joins => "INNER JOIN finance_fee_collections on finance_fee_collections.id = finance_fees.fee_collection_id ",
        :conditions=>["finance_fees.is_paid = ? AND finance_fees.id = ?",false,@collection_id.to_i],
        :select=>["finance_fees.id as id,finance_fees.balance as balances,concat('FinanceFee') as ftype,finance_fee_collections.due_date as fee_due_date,
                   finance_fee_collections.name as fee_name,
        (SELECT is_amount   FROM fine_rules ffr WHERE ffr.fine_id = finance_fee_collections.fine_id AND   
                      ffr.created_at <= finance_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{@transaction_date}'),CURDATE()),  
                      finance_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS is_amount,
                   (SELECT fine_amount FROM fine_rules ffr WHERE ffr.fine_id = finance_fee_collections.fine_id AND   
                      ffr.created_at <= finance_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{@transaction_date}'),CURDATE()),  
                      finance_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS fee_fine_amount, 
                      (IFNULL((finance_fees.particular_total - finance_fees.discount_amount),
                                 finance_fees.balance + 
                                 (SELECT IFNULL(SUM(finance_transactions.amount - 
                                                    finance_transactions.fine_amount),
                                               0)
                                    FROM finance_transactions
                                   WHERE finance_transactions.finance_id=finance_fees.id AND 
                                         finance_transactions.finance_type='FinanceFee'
                                 ) - 
                                 IF(finance_fees.tax_enabled,finance_fees.tax_amount,0)
                                 ) 
                                ) AS actual_amount"])
    when "TransportFee"
      fee=@student.transport_fees.all(:joins => "INNER JOIN transport_fee_collections on transport_fee_collections.id = transport_fees.transport_fee_collection_id ",
        :conditions=>{:is_paid=> false,:is_active=> true,:id => @collection_id.to_i},
        :select=>["transport_fees.id as id,transport_fees.balance as balances,concat('TransportFee') as ftype,transport_fee_collections.due_date as fee_due_date, 
                  transport_fee_collections.name as fee_name,
        (SELECT is_amount   FROM fine_rules ffr WHERE ffr.fine_id = transport_fee_collections.fine_id AND   
                      ffr.created_at <= transport_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{@transaction_date}'),CURDATE()),  
                      transport_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS is_amount,
                   (SELECT ffr.fine_amount FROM fine_rules ffr WHERE ffr.fine_id = transport_fee_collections.fine_id AND   
                      ffr.created_at <= transport_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{@transaction_date}'),CURDATE()),  
                      transport_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS fee_fine_amount, 
                                 (transport_fees.balance + 
                                 (SELECT IFNULL(SUM(finance_transactions.amount - 
                                                    finance_transactions.fine_amount),
                                               0)
                                    FROM finance_transactions
                                   WHERE finance_transactions.finance_id=transport_fees.id AND 
                                         finance_transactions.finance_type='TransportFee'
                                 ) - 
                                 IF(transport_fees.tax_enabled,transport_fees.tax_amount,0)
                                 ) 
                                 AS actual_amount"])
    when "HostelFee"
      fee=@student.hostel_fees.all(:joins => "INNER JOIN hostel_fee_collections on hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id ",
        :conditions=>["hostel_fees.id = ? AND hostel_fees.balance > ? AND hostel_fees.is_active = ?", @collection_id.to_i, 0, true],
        :select=>["hostel_fees.id as id,hostel_fees.balance as balances,concat('HostelFee') as ftype,hostel_fee_collections.due_date as fee_due_date,
                  hostel_fee_collections.name as fee_name,
                    concat('-') as is_amount,concat('-') as fee_fine_amount,concat('-') as actual_amount"])
    end
    fee
  end
  
  def fetch_all_fees
    @all_fees=@student.finance_fees.all(:joins => "INNER JOIN finance_fee_collections on finance_fee_collections.id = finance_fees.fee_collection_id ",
      :conditions=>{:is_paid=> false},
      :select=>["finance_fees.id as id,finance_fees.balance as balances,concat('FinanceFee') as ftype,finance_fee_collections.due_date as fee_due_date,
                finance_fee_collections.name as fee_name,
      (SELECT is_amount   FROM fine_rules ffr WHERE ffr.fine_id = finance_fee_collections.fine_id AND   
                    ffr.created_at <= finance_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{@transaction_date}'),CURDATE()),  
                    finance_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS is_amount,
                 (SELECT fine_amount FROM fine_rules ffr WHERE ffr.fine_id = finance_fee_collections.fine_id AND   
                    ffr.created_at <= finance_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{@transaction_date}'),CURDATE()),  
                    finance_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS fee_fine_amount, 
                    (IFNULL((finance_fees.particular_total - finance_fees.discount_amount),
                               finance_fees.balance + 
                               (SELECT IFNULL(SUM(finance_transactions.amount - 
                                                  finance_transactions.fine_amount),
                                             0)
                                  FROM finance_transactions
                                 WHERE finance_transactions.finance_id=finance_fees.id AND 
                                       finance_transactions.finance_type='FinanceFee'
                               ) - 
                               IF(finance_fees.tax_enabled,finance_fees.tax_amount,0)
                               ) 
                              ) AS actual_amount"])
    @all_fees+=@student.transport_fees.all(:joins => "INNER JOIN transport_fee_collections on transport_fee_collections.id = transport_fees.transport_fee_collection_id ",
      :conditions=>{:is_paid=> false,:is_active=> true},
      :select=>["transport_fees.id as id,transport_fees.balance as balances,concat('TransportFee') as ftype,transport_fee_collections.due_date as fee_due_date, 
                transport_fee_collections.name as fee_name,
      (SELECT is_amount   FROM fine_rules ffr WHERE ffr.fine_id = transport_fee_collections.fine_id AND   
                    ffr.created_at <= transport_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{@transaction_date}'),CURDATE()),  
                    transport_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS is_amount,
                 (SELECT ffr.fine_amount FROM fine_rules ffr WHERE ffr.fine_id = transport_fee_collections.fine_id AND   
                    ffr.created_at <= transport_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{@transaction_date}'),CURDATE()),  
                    transport_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS fee_fine_amount, 
                               (transport_fees.balance + 
                               (SELECT IFNULL(SUM(finance_transactions.amount - 
                                                  finance_transactions.fine_amount),
                                             0)
                                  FROM finance_transactions
                                 WHERE finance_transactions.finance_id=transport_fees.id AND 
                                       finance_transactions.finance_type='TransportFee'
                               ) - 
                               IF(transport_fees.tax_enabled,transport_fees.tax_amount,0)
                               ) 
                               AS actual_amount"])
    @all_fees+=@student.hostel_fees.all(:joins => "INNER JOIN hostel_fee_collections on hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id ",
      :conditions=>["hostel_fees.balance > ? AND hostel_fees.is_active = ?", 0, true],
      :select=>["hostel_fees.id as id,hostel_fees.balance as balances,concat('HostelFee') as ftype,hostel_fee_collections.due_date as fee_due_date,
                hostel_fee_collections.name as fee_name,
                  concat('-') as is_amount,concat('-') as fee_fine_amount,concat('-') as actual_amount"])
  end
  
##############***************################    
end
