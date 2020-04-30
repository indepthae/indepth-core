class Payment < ActiveRecord::Base

  attr_accessor :payment_type

  #validation
  validate  :validate_uniqueness_transaction_referense

  #relationships
  belongs_to :payee, :polymorphic => true
  has_many :finance_payments

  serialize :gateway_response
      
      
  def validate_uniqueness_transaction_referense
    errors.add_to_base("It is already done") unless unique_gateway_responses.empty?
  end
  
  def before_create
    if payment_type == "Application"
      if Payment.find_by_payee_id_and_payee_type_and_status(payee_id,'Applicant',1).present?
        false
      else
        true
      end
    end
  end

  def payee_name
    if payee.nil?
      if payee_type == 'Student'
        ArchivedStudent.find_by_former_id(payee_id).try(:full_name) || "NA"
      elsif payee_type == 'Guardian'
        ArchivedGuardian.find_by_former_id(payee_id).try(:full_name) || "NA"
      elsif payee_type == 'Applicant'
        "NA"
      end
    else
      payee.full_name
    end
  end

  def payee_user
    if payee.nil?
      if payee_type == 'Student'
        ArchivedStudent.find_by_former_id(payee_id).try(:admission_no) || "NA"
      elsif payee_type == 'Guardian'
        ArchivedGuardian.find_by_former_id(payee_id).try(:user).try(:username) || "NA"
      elsif payee_type == 'Applicant'
        "NA"
      end
    else
      payee_type == 'Applicant' ? payee.try(:reg_no) : payee.try(:user).try(:username)
    end
  end

  def self.payment_status_mapping
    {
      :success => 1,
      :reverted => 2,
      :failed => 3
    }
  end

  #def to use by child class  STI

  # def self.create_finance_transaction(transaction_attributes) #to create finance_transaction
  #   finance_transaction = FinanceTransaction.create!(transaction_attributes)
  # end

  def self.custom_gateway(gateway_id=0) #fetch custom_gateway
    #@custom_gateway ||= CustomGateway.find(active_gateway)
    @custom_gateway = CustomGateway.find_by_id(gateway_id)
  end
  def self.active_gateway #to set active gateway
    #@active_gateway ||= PaymentConfiguration.active_gateway
    @active_gateway = PaymentConfiguration.active_gateway
  end

  def self.custom_gateway_hash(gateway,params) #is to map gateway parameters to custom parameters
    custom_gateway(gateway).custom_gateway_response(params)
  end
  
  def self.reconcile_finance_payment(student_id,fee_collection_id,t_ref,payment_params)
    resp = Hash.new
    @student = Student.find(student_id)
    @fee_collection = FinanceFeeCollection.find(fee_collection_id)
    Fedena.present_user = @student.user
    @transaction_date = Date.today_with_timezone
    @financial_year_enabled = FinancialYear.has_valid_transaction_date(@transaction_date)
    flash_text = "financial_year_payment_disabled#{Fedena.present_user.admin || Fedena.present_user.employee ? '' : '_admin'}"
    resp[:reconciliation_status] = I18n.t(flash_text) unless @financial_year_enabled
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_student_fee_enabled? and CustomGateway.available_gateways.present? and @financial_year_enabled) #TODO
        
        gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>t_ref, :status=>0})
        gateway_record.update_attribute('status', true) if gateway_record.present?
        @active_gateway = gateway_record.present? ? gateway_record.gateway : 0
        #payment configuration should move logic to payment
        if (@active_gateway.nil? or @active_gateway==0)
          resp[:reconciliation_status] = "Payment Gateway not found."
        else
          @custom_gateway = CustomGateway.find_by_id(@active_gateway)
        end
        @financefee = @student.finance_fee_by_date @fee_collection
        unless @financefee.present?
          resp[:reconciliation_status] = "#{I18n.t('flash_msg5')}"
          return resp
        else
          @particular_wise_paid = @fee_collection.discount_mode != "OLD_DISCOUNT" && @financefee.finance_transactions.map(&:trans_type).include?("particular_wise")
          if @particular_wise_paid
            resp[:reconciliation_status] = "#{I18n.t('particular_wise_paid_fee_payment_disabled')}"
          end
          @due_date = @fee_collection.due_date
          @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
          @fee_particulars = @fee_collection.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==@student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) }
          @categorized_particulars=@fee_particulars.group_by(&:receiver_type)
          @discounts = @fee_collection.fee_discounts.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and ((par.receiver==@financefee.student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) and (par.master_receiver_type!='FinanceFeeParticular' or (par.master_receiver_type=='FinanceFeeParticular' and (par.master_receiver.receiver.present? and @fee_particulars.collect(&:id).include? par.master_receiver_id) and (par.master_receiver.receiver==@financefee.student or par.master_receiver.receiver==@financefee.student_category or par.master_receiver.receiver==@financefee.batch)))) }
          @categorized_discounts = @discounts.group_by(&:master_receiver_type)
          @total_discount = 0
          @total_payable = @fee_particulars.map { |s| s.amount }.sum.to_f
          @total_discount = @discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ? (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100) }.sum.to_f unless @discounts.nil?
          total_fees = @financefee.balance.to_f
          bal=(@total_payable-@total_discount).to_f
          days=(Date.today-@due_date.to_date).to_i
          auto_fine=@fee_collection.fine
          if @financefee.tax_enabled?
            @tax_collections = @financefee.tax_collections.all(:include => :tax_slab)
            @total_tax = @tax_collections.map(&:tax_amount).sum.to_f
            #            @tax_slabs = @tax_collections.map {|tax_col| tax_col.tax_slab }.uniq
            @tax_slabs = @tax_collections.group_by {|x| x.tax_slab }
          end
          @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
          @fine_amount = 0
          if days > 0 and auto_fine
            #@fine=params[:fine].to_f if params[:fine].present? and params[:fine].to_f > 0.0
            @fine = nil
            @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@fee_collection.created_at}'"], :order => 'fine_days ASC')
            @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
            if @fine_rule and @financefee.balance==0
              @fine_amount=@fine_amount-@financefee.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
            end
          end
          @amount = total_fees + @fine_amount
          total_fees = 0
          total_fees = @fee_collection.student_fee_balance(@student)
          unless @particular_wise_paid
            
            gateway_response = Hash.new
            if @custom_gateway.present?
              @custom_gateway.gateway_parameters[:response_parameters].each_pair do |k, v|
                unless ["success_code","pending_code"].include?(k.to_s)
                  gateway_response[k.to_sym] =  payment_params[v.to_sym]
                end
              end
            end
            @gateway_status = false
            @pending_status = false
            if @custom_gateway.present?
              success_code = @custom_gateway.gateway_parameters[:response_parameters][:success_code]
              pending_code = @custom_gateway.gateway_parameters[:response_parameters][:pending_code]
              @gateway_status = true if (gateway_response[:transaction_status] == success_code or gateway_response[:transaction_status] == pending_code)
              @pending_status = true if gateway_response[:transaction_status] == pending_code
            end
            amount_from_gateway = 0
            amount_from_gateway = gateway_response[:amount] if @custom_gateway.present?
            wrong_amount = false
            if amount_from_gateway.to_f != FinanceFee.precision_label(@amount).to_f
              wrong_amount = true unless PaymentConfiguration.is_partial_payment_enabled?
            end
            single_payment = SingleFeePayment.new(:payee => @student, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway, :is_pending=>@pending_status)
            if single_payment.save
              finance_payment = FinancePayment.create(:payment_id => single_payment.id, :fee_payment => @financefee, :fee_collection => @financefee.finance_fee_collection)
              unless wrong_amount
                tr_status = ""
                tr_ref = ""
                reason = ""
                unless @financefee.is_paid?
                  amount_from_gateway = 0
                  if @custom_gateway.present?
                    amount_from_gateway = gateway_response[:amount]
                  end
                  unless amount_from_gateway.to_f <= 0.0
                    if @gateway_status == true
                      pay_status = false
                      logger = Logger.new("#{RAILS_ROOT}/log/payment_processor_error.log")
                      begin
                        retries ||= 0
                        pay_status = true
                        transaction = FinanceTransaction.new(
                          :title => "#{I18n.t('receipt_no')}. F#{@financefee.id}",
                          :category => FinanceTransactionCategory.find_by_name("Fee"),
                          :payee => @student,
                          :finance => @financefee,
                          :amount => gateway_response[:amount],
                          :fine_included => (@fine.to_f ).zero? ? false : true,
                          :fine_amount => @fine.to_f,
                          :transaction_date => FedenaTimeSet.current_time_to_local_time(Time.now).to_date,
                          :payment_mode => "Online Payment",
                          :reference_no => gateway_response[:transaction_reference]
                        )
                        transaction.ledger_status = "PENDING" if @pending_status==true
                        transaction.save
                      rescue ActiveRecord::StatementInvalid => er
                        # run code again  to  avoid duplications
                        pay_status = false
                        retry if (retries += 1) < 2
                        logger.info "Error------#{er.message}----for --#{gateway_response}" unless (retries += 1) < 2
                      rescue Exception => e
                        pay_status = false
                        logger.info "Errror-----#{e.message}------for---#{gateway_response}"
                      end

                      if pay_status
                        #finance_payment = FinancePayment.create(:payment_id => single_payment.id, :fee_payment => transaction.finance, :fee_collection => transaction.finance.finance_fee_collection)
                        finance_payment.update_attribute("finance_transaction_id", transaction.id)

                        unless @financefee.transaction_id.nil?
                          tid = @financefee.transaction_id.to_s + ",#{transaction.id}"
                        else
                          tid=transaction.id
                        end
                        is_paid = (sprintf("%0.2f", total_fees.to_f+@fine.to_f + @fine_amount.to_f).to_f == amount_from_gateway.to_f) ? true : false
                        @financefee.update_attributes(:transaction_id => tid, :is_paid => is_paid)
                        @paid_fees = FinanceTransaction.find(:all, :include => :transaction_ledger,
                          :conditions => "FIND_IN_SET(id,\"#{tid}\")")
                        status = SingleFeePayment.payment_status_mapping[:success]
                        online_transaction_id = single_payment.gateway_response[:transaction_reference]
                        resp[:reconciliation_status] = "success"
                        tr_status = "success"
                        tr_ref = online_transaction_id
                        reason = single_payment.gateway_response[:reason_code]
                      end
                    else
                      status = SingleFeePayment.payment_status_mapping[:failed]
                      single_payment.update_attributes(:status_description => status)
                      resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{single_payment.gateway_response[:reason_code] || 'N/A'} <br> #{I18n.t('transaction_id')} : #{single_payment.gateway_response[:transaction_reference] || 'N/A'}"
                      tr_status = "failure"
                      tr_ref = single_payment.gateway_response[:transaction_reference]
                      reason = single_payment.gateway_response[:reason_code]
                    end
                  else
                    status = SingleFeePayment.payment_status_mapping[:failed]
                    single_payment.update_attributes(:status_description => status)
                    
                    resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{single_payment.gateway_response[:reason_code] || 'N/A'} <br> #{I18n.t('transaction_id')} : #{single_payment.gateway_response[:transaction_reference] || 'N/A'}"
            
                    tr_status = "failure"
                    tr_ref = single_payment.gateway_response[:transaction_reference]
                    reason = single_payment.gateway_response[:reason_code]
                  end
                end
                
                return resp
                
              else
                reason = single_payment.status == false ? single_payment.gateway_response[:reason_code] : "#{I18n.t('partial_payment_disabled')}"
                resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{reason}"
                return resp
                
              end
            else
              resp[:reconciliation_status] = "#{I18n.t('flash_payed')}"
              tr_status = "failure"
              tr_ref = single_payment.gateway_response[:transaction_reference]
              reason = "#{I18n.t('flash_payed')}"
              resp[:reconciliation_status] = "#{t('flash_payed')}"
              return resp
            end
         
          else
            @fine_amount=0 if (@student.finance_fee_by_date @fee_collection).is_paid
            
            return resp
            
          end
          #render 'student/fee_details'
        end
      else
        resp[:reconciliation_status] = "Online payment disabled."
        return resp
      end
    else
      resp[:reconciliation_status] = "Online payment disabled."
      return resp
    end
  end
  
  def self.reconcile_transport_payment(student_id,fee_collection_id,t_ref,payment_params)
    resp = Hash.new
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if ((PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_transport_fee_enabled?))
        
        gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>t_ref, :status=>0})
        gateway_record.update_attribute('status', true) if gateway_record.present?
        @active_gateway = gateway_record.present? ? gateway_record.gateway : 0
        
        @custom_gateway = (@active_gateway.nil? or @active_gateway==0) ? false : CustomGateway.find(@active_gateway)
        @partial_payment_enabled = PaymentConfiguration.is_partial_payment_enabled?
      end
    end

    hostname = nil

    @student=Student.find(student_id)
    @transport_fee= TransportFee.find_by_transport_fee_collection_id_and_receiver_id(fee_collection_id, @student.id)
    @fee_collection = TransportFeeCollection.find(fee_collection_id)
    @date = @fee_collection
    @amount = @transport_fee.bus_fare
    @paid_fees = @transport_fee.finance_transactions(:include => :transaction_ledger)
    @receiver_profile = true
    Fedena.present_user = @student.user
    @transaction_date = @payment_date = Date.today_with_timezone
    @financial_year_enabled = FinancialYear.has_valid_transaction_date(@transaction_date)
    flash_text = "financial_year_payment_disabled#{Fedena.present_user.admin || Fedena.present_user.employee ? '' : '_admin'}"
    resp[:reconciliation_status] = I18n.t(flash_text) unless @financial_year_enabled
    @transport_fee_discounts = @transport_fee.transport_fee_discounts
    @discount_amount = @transport_fee.total_discount_amount
    days=(Date.today_with_timezone-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    @fine_amount=0
    @paid_fine=0
    bal= (@transport_fee.bus_fare-@discount_amount).to_f
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      if @fine_rule.present?
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 
        @fine_amount=@fine_amount-@transport_fee.finance_transactions.find(:all, 
          :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
      end
    end
    
    @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
    if @custom_gateway != false
      gateway_response = Hash.new
      
      if @custom_gateway.present?
        @custom_gateway.gateway_parameters[:response_parameters].each_pair do|k,v|
          unless ["success_code","pending_code"].include?(k.to_s)
            gateway_response[k.to_sym] = payment_params[v.to_sym]
          end
        end
      end
      @gateway_status = false
      @pending_status = false
      if @custom_gateway.present?
        success_code = @custom_gateway.gateway_parameters[:response_parameters][:success_code]
        pending_code = @custom_gateway.gateway_parameters[:response_parameters][:pending_code]
        @gateway_status = true if (gateway_response[:transaction_status] == success_code or gateway_response[:transaction_status] == pending_code)
        @pending_status = true if gateway_response[:transaction_status] == pending_code
      end
      amount_to_pay = FinanceFee.precision_label(@transport_fee.balance.to_f).to_f
      amount_to_pay += FinanceFee.precision_label(@fine_amount).to_f if @fine_amount.present?
      amount_from_gateway = 0
      amount_from_gateway = gateway_response[:amount] if @custom_gateway.present?
      wrong_amount = false
      if amount_from_gateway.to_f != amount_to_pay
        wrong_amount = true unless PaymentConfiguration.is_partial_payment_enabled?
      end
      payment = SingleFeePayment.new(:payee => @student,:gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway, :is_pending=>@pending_status)
      if payment.save
        finance_payment = FinancePayment.create(:payment_id=>payment.id,:fee_payment => @transport_fee,:fee_collection => @transport_fee.transport_fee_collection)
        unless wrong_amount
          tr_status = ""
          tr_ref = ""
          reason = ""
          if !@transport_fee.is_paid
            amount_from_gateway = gateway_response[:amount]
            if amount_from_gateway.to_f > 0.0 and payment.status
              logger = Logger.new("#{RAILS_ROOT}/log/payment_processor_error.log")
              pay_status = false
              begin
                retries ||= 0
                pay_status = true
                transaction = FinanceTransaction.new
                transaction.title = @transport_fee.transport_fee_collection.name
                transaction.category_id = FinanceTransactionCategory.find_by_name('Transport').id
                transaction.finance = @transport_fee
                transaction.amount = amount_from_gateway.to_f
                transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
                transaction.payment_mode = "Online Payment"
                transaction.reference_no = gateway_response[:transaction_reference]
                transaction.payee = @transport_fee.receiver
                transaction.ledger_status = "PENDING" if @pending_status==true
                transaction.save
              rescue ActiveRecord::StatementInvalid => er
                # run code again  to  avoid duplications
                pay_status = false
                retry if (retries += 1) < 2
                logger.info "Error------#{er.message}----for --#{gateway_response}" unless (retries += 1) < 2
              rescue Exception => e
                pay_status = false
                logger.info "Errror-----#{e.message}------for---#{gateway_response}"
              end
            
            

              if pay_status
                #            @transport_fee.update_attributes(:transaction_id => transaction.id)
                #finance_payment = FinancePayment.create(:payment_id=>payment.id,:fee_payment => transaction.finance,:fee_collection => transaction.finance.transport_fee_collection)
                finance_payment.update_attributes(:finance_transaction_id => transaction.id)
                #            online_transaction_id = payment.gateway_response[:transaction_id]
                #            online_transaction_id ||= payment.gateway_response[:x_trans_id]
                #            online_transaction_id ||= payment.gateway_response[:payment_reference]
                online_transaction_id = payment.gateway_response[:transaction_reference]
              end
              if @gateway_status and pay_status
                status = SingleFeePayment.payment_status_mapping[:success]
                payment.update_attributes(:status_description => status)
                resp[:reconciliation_status] = "success"
                tr_status = "success"
                tr_ref = online_transaction_id
                reason = payment.gateway_response[:reason_code]

              else
                status = SingleFeePayment.payment_status_mapping[:failed]
                payment.update_attributes(:status_description => status)
                resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{I18n.t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
                tr_status = "failure"
                tr_ref = payment.gateway_response[:transaction_reference]
                reason = payment.gateway_response[:reason_code]
              end

            else
              status = SingleFeePayment.payment_status_mapping[:failed]
              payment.update_attributes(:status_description => status)
              resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{I18n.t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
              tr_status = "failure"
              tr_ref = payment.gateway_response[:transaction_reference]
              reason = payment.gateway_response[:reason_code]
            end

          else
            resp[:reconciliation_status] = "#{I18n.t('flash_payed')}"
            tr_status = "failure"
            tr_ref = payment.gateway_response[:transaction_reference]
            reason = "#{I18n.t('flash_payed')}"
          end
        else
          reason = payment.status == false ? payment.gateway_response[:reason_code] : "#{I18n.t('partial_payment_disabled')}"
          resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{reason}"
          tr_status = "failure"
          tr_ref = payment.gateway_response[:transaction_reference]
        end
      else
        resp[:reconciliation_status] = "#{I18n.t('flash_payed')}"
        tr_status = "failure"
        tr_ref = payment.gateway_response[:transaction_reference]
        reason = "#{I18n.t('flash_payed')}"
      end
      return resp
    else
      return resp
    end
  end
  
  def self.reconcile_applicant_payment(student_id,fee_collection_id,t_ref,payment_params)
    resp = Hash.new
    @currency = Configuration.currency
    @applicant = Applicant.find(student_id)
    if @applicant.has_paid == true
      resp[:reconciliation_status] = "applicant already marked as paid"
      return resp
    else
      hostname = nil
      
      gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>t_ref, :status=>0})
      gateway_record.update_attribute('status', true) if gateway_record.present?
      @active_gateway = gateway_record.present? ? gateway_record.gateway : 0
      if (@active_gateway.nil? or @active_gateway==0)
        resp[:reconciliation_status] = "#{I18n.t('already_payed')}"
        return resp
      else
        @custom_gateway = CustomGateway.find_by_id(@active_gateway)
      end
    
      gateway_response = Hash.new
      if @custom_gateway.present?
        @custom_gateway.gateway_parameters[:response_parameters].each_pair do|k,v|
          unless ["success_code","pending_code"].include?(k.to_s)
            gateway_response[k.to_sym] = payment_params[v.to_sym]
          end
        end
      end
      amount_from_gateway = gateway_response[:amount]
      receipt = gateway_response[:transaction_reference]
      gateway_status = false
      pending_status = false
      if @custom_gateway.present?
        success_code = @custom_gateway.gateway_parameters[:response_parameters][:success_code]
        pending_code = @custom_gateway.gateway_parameters[:response_parameters][:pending_code]
        gateway_status = true if (gateway_response[:transaction_status] == success_code or gateway_response[:transaction_status] == pending_code)
        pending_status = true if gateway_response[:transaction_status] == pending_code
      end
      payment = SingleFeePayment.new(:payee => @applicant, :gateway_response => gateway_response, :status => gateway_status, :amount => amount_from_gateway.to_f, :gateway => @active_gateway, :is_pending=>pending_status)
      #      payment = Payment.new(:payee => @applicant,:payment_type => "Application",:payment_id => ActiveSupport::SecureRandom.hex,:gateway_response => gateway_response, :status => gateway_status, :amount => amount_from_gateway.to_f, :gateway => @active_gateway)
      if payment.save
        finance_payment =  FinancePayment.create(:payment_id=>payment.id,:fee_payment_type => "Application")
        if gateway_status.to_s == "true" and @applicant.amount.to_f == amount_from_gateway.to_f
          @applicant.payment_pending = true if pending_status == true 
          transaction = @applicant.mark_paid
          finance_payment.update_attributes(:finance_transaction_id => transaction.id)
          online_transaction_id = payment.gateway_response[:transaction_reference]
          transaction.payment_mode = "Online Payment"
          transaction.reference_no = online_transaction_id
          transaction.save
          resp[:reconciliation_status] = "success"
        else
          resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{gateway_status.to_s == 'true' ? 'Transaction Amount mismatch' : payment.gateway_response[:reason_code]} <br> #{I18n.t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
        end
      else
        resp[:reconciliation_status] = "#{I18n.t('already_payed')}"
      end
      return resp
    end
  end
  
  def self.reconcile_hostel_payment(student_id,fee_collection_id,t_ref,payment_params)
    resp = Hash.new
    @student = Student.find(student_id)
    @hostel_fee = HostelFee.find_by_hostel_fee_collection_id_and_student_id(fee_collection_id, @student.id)
    @amount = @hostel_fee.rent
    @fee_collection = HostelFeeCollection.find(fee_collection_id)
    if @hostel_fee.tax_enabled?
      @tax_slab = @fee_collection.collection_tax_slabs.try(:last)
    end
    Fedena.present_user = @student.user
    @paid_fees = @hostel_fee.finance_transactions(:include => :transaction_ledger)
    @transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    @financial_year_enabled = FinancialYear.has_valid_transaction_date(@transaction_date)
    flash_text = "financial_year_payment_disabled#{Fedena.present_user.admin || Fedena.present_user.employee ? '' : '_admin'}"
    resp[:reconciliation_status] = I18n.t(flash_text) unless @financial_year_enabled
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if ((PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_hostel_fee_enabled?))
        gateway_record = GatewayRequest.find(:first, :conditions => {:transaction_reference => t_ref, :status => 0})
        gateway_record.update_attribute('status', true) if gateway_record.present?
        @active_gateway = gateway_record.present? ? gateway_record.gateway : 0
        @custom_gateway = (@active_gateway.nil? or @active_gateway==0) ? false : CustomGateway.find(@active_gateway)
        @partial_payment_enabled = PaymentConfiguration.is_partial_payment_enabled?
      end
      hostname = nil
      if @custom_gateway != false
        gateway_response = Hash.new
        if @custom_gateway.present?
          @custom_gateway.gateway_parameters[:response_parameters].each_pair do |k, v|
            unless ["success_code","pending_code"].include?(k.to_s)
              gateway_response[k.to_sym] = payment_params[v.to_sym]
            end
          end
        end
        @gateway_status = false
        @pending_status = false
        if @custom_gateway.present?
          success_code = @custom_gateway.gateway_parameters[:response_parameters][:success_code]
          pending_code = @custom_gateway.gateway_parameters[:response_parameters][:pending_code]
          @gateway_status = true if (gateway_response[:transaction_status] == success_code or gateway_response[:transaction_status] == pending_code)
          @pending_status = true if gateway_response[:transaction_status] == pending_code
        end
        amount_to_pay = FinanceFee.precision_label(@hostel_fee.balance.to_f).to_f
        amount_from_gateway = 0
        amount_from_gateway = gateway_response[:amount] if @custom_gateway.present?
        wrong_amount = false
        if amount_from_gateway.to_f != amount_to_pay
          wrong_amount = true unless PaymentConfiguration.is_partial_payment_enabled?
        end
        payment = SingleFeePayment.new(:payee => @student, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway, :is_pending=>@pending_status)
        if payment.save
          finance_payment = FinancePayment.create(:payment_id => payment.id, :fee_payment => @hostel_fee, :fee_collection => @hostel_fee.hostel_fee_collection)
          unless wrong_amount
            tr_status = ""
            tr_ref = ""
            reason = ""
            #payment = SingleFeePayment.new(:payee => @student, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway)

            if !@hostel_fee.is_paid?
              amount_from_gateway = gateway_response[:amount]
              if amount_from_gateway.to_f > 0.0 and payment.status
                logger = Logger.new("#{RAILS_ROOT}/log/payment_processor_error.log")
                pay_status = false
                begin
                  retries ||= 0
                  pay_status = true
                  transaction = FinanceTransaction.new
                  transaction.title = @hostel_fee.hostel_fee_collection.name
                  transaction.category_id = FinanceTransactionCategory.find_by_name('Hostel').id
                  transaction.finance = @hostel_fee
                  transaction.amount = amount_from_gateway.to_f
                  transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
                  transaction.payment_mode = "Online Payment"
                  transaction.reference_no = gateway_response[:transaction_reference]
                  transaction.payee = @hostel_fee.student
                  transaction.ledger_status = "PENDING" if @pending_status==true
                  transaction.save
                rescue ActiveRecord::StatementInvalid => er
                  # run code again  to  avoid duplications
                  pay_status = false
                  retry if (retries += 1) < 2
                  logger.info "Error------#{er.message}----for --#{gateway_response}" unless (retries += 1) < 2
                rescue Exception => e
                  pay_status = false
                  logger.info "Errror-----#{e.message}------for---#{gateway_response}"
                end


                if pay_status
                  #finance_payment =  FinancePayment.create(:payment_id=>payment.id,:fee_payment => transaction.finance,:fee_collection => transaction.finance.hostel_fee_collection)
                  #              @fee.update_attributes(:finance_transaction_id => transaction.id)
                  finance_payment.update_attributes(:finance_transaction_id => transaction.id)
                  #              online_transaction_id = payment.gateway_response[:transaction_id]
                  #              online_transaction_id ||= payment.gateway_response[:x_trans_id]
                  #              online_transaction_id ||= payment.gateway_response[:payment_reference]
                  online_transaction_id = payment.gateway_response[:transaction_reference]
                end
                if @gateway_status and pay_status
                  status = SingleFeePayment.payment_status_mapping[:success]
                  payment.update_attributes(:status_description => status)
                  resp[:reconciliation_status] = "success"
                  tr_status = "success"
                  tr_ref = online_transaction_id
                  reason = payment.gateway_response[:reason_code]
                else
                  status = Payment.payment_status_mapping[:failed]
                  payment.update_attributes(:status_description => status)
                  resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{I18n.t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
                  tr_status = "failure"
                  tr_ref = payment.gateway_response[:transaction_reference]
                  reason = payment.gateway_response[:reason_code]
                end
              else
                status = Payment.payment_status_mapping[:failed]
                payment.update_attributes(:status_description => status)
                resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{I18n.t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
                tr_status = "failure"
                tr_ref = payment.gateway_response[:transaction_reference]
                reason = payment.gateway_response[:reason_code]
              end
            else
              resp[:reconciliation_status] = "#{I18n.t('already_paid')}"
              tr_status = "failure"
              tr_ref = payment.gateway_response[:transaction_reference]
              reason = "#{I18n.t('already_paid')}"
            end
          else
            reason = payment.status == false ? payment.gateway_response[:reason_code] : "#{I18n.t('partial_payment_disabled')}"
            resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br> #{I18n.t('reason')} : #{reason}"
            tr_status = "failure"
            tr_ref = payment.gateway_response[:transaction_reference]
          end
        else
          resp[:reconciliation_status] = "#{I18n.t('flash_payed')}"
          tr_status = "failure"
          tr_ref = payment.gateway_response[:transaction_reference]
          reason = "#{I18n.t('flash_payed')}"
        end

        return resp
      else

        return resp
      end
    else

      return resp
    end
  end
  
  def self.reconcile_multi_fees_payment(student_id,tr_ref,id_token,payment_params)
    resp = Hash.new
    @student = Student.find(student_id)
    Fedena.present_user = @student
    all_params = HashWithIndifferentAccess.new
    all_params[:id] = student_id
    all_params[:transaction_ref] = tr_ref
    all_params[:identification_token] = id_token
    all_params = all_params.merge(payment_params)
    gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>tr_ref, :status=>0})
    if gateway_record.present?
      gateway_record.update_attribute('status', true)
      active_gateway = gateway_record.gateway
      #active_gateway = gateway_record.present? ? gateway_record.gateway : 0
      hostname = nil
      multi_fees_transactions = MultiFeePayment.create_multi_fees_transactions(all_params,hostname,nil,active_gateway)
      if multi_fees_transactions.status
         
        resp[:reconciliation_status] = "success"
      else
        resp[:reconciliation_status] = "#{I18n.t('payment_failed')} <br>  #{I18n.t('reason')} : #{multi_fees_transactions.gateway_response[:reason_code]}"
      end
    else
      resp[:reconciliation_status] = I18n.t('flash_msg3')
    end
   	return resp
  end

  
  private
  
  def unique_gateway_responses
    Payment.all.select do |payment| 
      payment.gateway_response.to_a == self.gateway_response.to_a
    end
  end
  
end
