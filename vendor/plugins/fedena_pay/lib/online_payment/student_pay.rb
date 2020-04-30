module OnlinePayment
  class << self;
    attr_accessor_with_default :return_url, String.new;
  end
  module StudentPay
    def self.included(base)
      base.alias_method_chain :fee_details, :gateway
    end

    def fee_details_with_gateway
      @transaction_date = Date.today_with_timezone
      @fine_detail_flag = true
      financial_year_check
      if FedenaPlugin.can_access_plugin?("fedena_pay")
        if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_student_fee_enabled? and CustomGateway.available_gateways.present? and @financial_year_enabled) #TODO
          if params[:create_transaction].present?
            gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>params[:transaction_ref], :status=>0})
            gateway_record.update_attribute('status', true) if gateway_record.present?
            @active_gateway = gateway_record.present? ? gateway_record.gateway : 0
          else  
            @active_gateway = PaymentConfiguration.first_active_gateway
          end
           #payment configuration should move logic to payment
          if (@active_gateway.nil? or @active_gateway==0)
            fee_details_without_gateway and return
          else
            @custom_gateway = CustomGateway.find_by_id(@active_gateway)
          end
          hostname = "#{request.protocol}#{request.host_with_port}"
          current_school_name = Configuration.find_by_config_key('InstitutionName').try(:config_value)
          #          @date  = FinanceFeeCollection.find(params[:id2])
          @financefee = find_student.finance_fee_by_date fee_collection
          unless @financefee.present?
            flash[:notice] = "#{t('flash_msg5')}"
            redirect_to :controller => "user", :action => "dashboard"
          else
            @particular_wise_paid = @fee_collection.discount_mode != "OLD_DISCOUNT" && @financefee.finance_transactions.map(&:trans_type).include?("particular_wise")
            flash.now[:notice]="#{t('particular_wise_paid_fee_payment_disabled')}" if @particular_wise_paid
            #          @fee_collection = FinanceFeeCollection.find(params[:id2])
            @due_date = fee_collection.due_date
            @fee_category = fee_category
            @categorized_particulars = fee_collection_particular.group_by(&:receiver_type)
            @categorized_discounts = fee_discounts.group_by(&:master_receiver_type)
            @total_discount = 0
            @total_payable = fee_collection_particular.map { |s| s.amount }.sum.to_f
            @total_discount = fee_discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ? (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100) }.sum.to_f unless @discounts.nil?
            total_fees = total_fee_amount
            bal=(@total_payable-@total_discount).to_f
            days=(Date.today-@due_date.to_date).to_i
            auto_fine=fee_collection.fine
            if @financefee.tax_enabled?
              @tax_collections = @financefee.tax_collections.all(:include => :tax_slab)
              @total_tax = @tax_collections.map(&:tax_amount).sum.to_f
              #            @tax_slabs = @tax_collections.map {|tax_col| tax_col.tax_slab }.uniq
              @tax_slabs = @tax_collections.group_by {|x| x.tax_slab }
            end
            @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
            # calculating advance fees used
            @advance_fee_used = @paid_fees.sum(&:wallet_amount) if @paid_fees.present?
            @fine_amount = 0
            if days > 0 and auto_fine and !@financefee.is_fine_waiver
              @fine=params[:fine].to_f if params[:fine].present? and params[:fine].to_f > 0.0
              @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{fee_collection.created_at}'"], :order => 'fine_days ASC')
              if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
                @fine_amount = @financefee.balance_fine
              else
                @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
                if @fine_rule and @financefee.balance==0
                  @fine_amount=@fine_amount-@financefee.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
                end
              end
            end
            @amount = total_fees + @fine_amount
            total_fees = 0
            total_fees = @fee_collection.student_fee_balance(@student)+params[:special_fine].to_f
            unless @particular_wise_paid
              OnlinePayment.return_url = "http://#{request.host_with_port}/student/fee_details/#{params[:id]}/#{params[:id2]}?create_transaction=1" unless OnlinePayment.return_url.nil?
              if params[:create_transaction].present?
                gateway_response = Hash.new
                if @custom_gateway.present?
                  if params[:return_hash].present?
                    return_value = params[:return_hash]
                    @decrypted_hash = PaymentConfiguration.payment_decryption(return_value)
                  end
                  @custom_gateway.gateway_parameters[:response_parameters].each_pair do |k, v|
                    unless ["success_code","pending_code"].include?(k.to_s)
                      gateway_response[k.to_sym] = params[:return_hash].present? ? @decrypted_hash[v.to_sym] : params[v.to_sym]
                    end
                  end
                  if params[:return_hash].present?
                    if @decrypted_hash[:split_statuses].present?
                      gateway_response[:split_status] = @decrypted_hash[:split_statuses]
                    end
                  else
                    if params[:split_statuses].present?
                      gateway_response[:split_status] = params[:split_statuses]
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
                if amount_from_gateway.to_f != precision_label(@amount).to_f
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
                            transaction = build_finance_transaction(gateway_response, params[:wallet_amount_applied], params[:wallet_amount])
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
                            flash[:notice] = "#{t('payment_success')} <br>  #{t('payment_reference')} : #{online_transaction_id}"
                            tr_status = "success"
                            tr_ref = online_transaction_id
                            reason = single_payment.gateway_response[:reason_code]
                          end
                        else
                          status = SingleFeePayment.payment_status_mapping[:failed]
                          single_payment.update_attributes(:status_description => status)
                          flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{single_payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{single_payment.gateway_response[:transaction_reference] || 'N/A'}"
                          tr_status = "failure"
                          tr_ref = single_payment.gateway_response[:transaction_reference]
                          reason = single_payment.gateway_response[:reason_code]
                        end
                      else
                        status = SingleFeePayment.payment_status_mapping[:failed]
                        single_payment.update_attributes(:status_description => status)
                        flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{single_payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{single_payment.gateway_response[:transaction_reference] || 'N/A'}"
                        tr_status = "failure"
                        tr_ref = single_payment.gateway_response[:transaction_reference]
                        reason = single_payment.gateway_response[:reason_code]
                      end
                    end
                    if current_user.parent?
                      user = current_user
                    else
                      user = @student.user
                    end
                    if @student.is_email_enabled && user.email.present? && @gateway_status
                      begin
                        Delayed::Job.enqueue(PaymentMail.new(finance_payment.fee_collection.name, user.email, user.full_name, @custom_gateway.name, FedenaPrecision.set_and_modify_precision(single_payment.amount), online_transaction_id, single_payment.gateway_response, user.school_details, hostname))
                      rescue Exception => e
                        puts "Error------#{e.message}------#{e.backtrace.inspect}"
                        return
                      end
                    end

                    if session[:mobile] == true
                      redirect_to :controller=>"payment_settings", :action=>"complete_payment", :student_id=>@student.id, :fee_collection_id=>fee_collection.id, :collection_type=>"general", :transaction_status=>tr_status, :reason=>reason, :transaction_id=>tr_ref
                    else
                      redirect_to :controller => 'student', :action => 'fee_details', :id => params[:id], :id2 => params[:id2]
                    end
                  else
                    reason = single_payment.status == false ? single_payment.gateway_response[:reason_code] : "#{t('partial_payment_disabled')}"
                    if session[:mobile] == true
                      redirect_to :controller=>"payment_settings", :action=>"complete_payment", :student_id=>@student.id, :fee_collection_id=>fee_collection.id, :collection_type=>"general", :transaction_status=>"failure", :reason=>reason, :transaction_id=>single_payment.gateway_response[:transaction_reference]
                    else
                      flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{reason}"
                      redirect_to :controller => 'student', :action => 'fee_details', :id => params[:id], :id2 => params[:id2]
                    end
                  end
                else
                  flash[:notice] = "#{t('flash_payed')}"
                  tr_status = "failure"
                  tr_ref = single_payment.gateway_response[:transaction_reference]
                  reason = "#{t('flash_payed')}"
                  redirect_to :controller => 'student', :action => 'fee_details', :id => params[:id], :id2 => params[:id2]
                end
              else
                @fine_amount=0 if (@student.finance_fee_by_date fee_collection).is_paid
                render 'gateway_payments/paypal/fee_details'
              end
            else
              @fine_amount=0 if (@student.finance_fee_by_date fee_collection).is_paid
              render 'gateway_payments/paypal/fee_details'
            end
            #render 'student/fee_details'
          end
        else
          fee_details_without_gateway
        end
      else
        fee_details_without_gateway
      end
    end

    def build_finance_transaction(gateway_response, wallet_amount_applied, wallet_amount)
      total_amount = 0.00
      if wallet_amount_applied == "true"
        total_amount = wallet_amount.to_f
      end
      FinanceTransaction.new(
        :title => "#{t('receipt_no')}. F#{@financefee.id}",
        :category => FinanceTransactionCategory.find_by_name("Fee"),
        :payee => @student,
        :finance => @financefee,
        :amount => (wallet_amount_applied.eql? "true") ? (gateway_response[:amount].to_f + total_amount) : gateway_response[:amount],
        :fine_included => (@fine.to_f ).zero? ? false : true,
        :fine_amount => @fine.to_f,
        :transaction_date => FedenaTimeSet.current_time_to_local_time(Time.now).to_date,
        :payment_mode => "Online Payment",
        :reference_no => gateway_response[:transaction_reference],
        :wallet_amount_applied => wallet_amount_applied,
        :wallet_amount => wallet_amount
      )
    end

    def balance_fee_amount
      fee_collection.balance.to_f #todo check fine amount also
    end

    def fee_discounts
       student_id = @student_type == 'former' ? @student.former_id : @student.id
      @discounts ||= fee_collection.fee_discounts.all(
        :conditions => "batch_id=#{@financefee.batch_id}"
      ).select { |par| (par.receiver.present? || @student_type == 'former' ) and (((@student_type == 'former' && par.receiver_id == student_id ) or (par.receiver.present? and  par.receiver==@financefee.student) or (par.receiver.present? and par.receiver==@financefee.student_category) or par.receiver==@financefee.batch) and (par.master_receiver_type!='FinanceFeeParticular' or (par.master_receiver_type=='FinanceFeeParticular' and (par.master_receiver.receiver.present? and @fee_particulars.collect(&:id).include? par.master_receiver_id) and (par.master_receiver.receiver==@financefee.student or (par.master_receiver.receiver==@financefee.student_category) or par.master_receiver.receiver==@financefee.batch)))) }
    end

    def get_student
      @student ||= Student.find(params[:id])
    end

    def fee_collection
      @fee_collection ||= FinanceFeeCollection.find(params[:id2])
    end

    def fee_collection_particular
      student_id = @student_type == 'former' ? @student.former_id : @student.id
      @fee_particulars ||= fee_collection.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present? || @student_type == 'former') and (par.receiver_id == student_id or ((par.receiver.present? and par.receiver==@financefee.student_category)) or par.receiver==@financefee.batch) }
    end

    def fee_category
      FinanceFeeCategory.find(fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    end

    def total_fee_amount
      @financefee.balance.to_f + params[:special_fine].to_f + (params[:fine].nil? ? 0 : params[:fine].to_f)
    end
  end

  #URI.parse("http://192.168.1.30:3000/student/fee_details/#{params[:id]}/#{params[:id2]}?create_transaction=1")
  module StudentPayReceipt

    def self.included(base)
      base.alias_method_chain :student_fee_receipt_pdf, :gateway
    end

    def student_fee_receipt_pdf_with_gateway
      if FedenaPlugin.can_access_plugin?("fedena_pay")
        @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
        unless @active_gateway.present?
          student_fee_receipt_pdf_without_gateway and return
        end
        if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_student_fee_enabled?)
          @date = @fee_collection = FinanceFeeCollection.find(params[:id2])
          @student = Student.find(params[:id])
          @financefee = @student.finance_fee_by_date @date
          unless @financefee.present?
            flash[:notice] = "#{t('flash_msg5')}"
            redirect_to :controller => "user", :action => "dashboard"
          else
            @due_date = @fee_collection.due_date

            @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
            @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
            @currency_type = currency

            @fee_particulars = @date.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==@student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) }
            @categorized_particulars=@fee_particulars.group_by(&:receiver_type)
            if @financefee.tax_enabled?
              @tax_collections = @financefee.tax_collections.all(:include => :tax_slab)
              @total_tax = @tax_collections.map(&:tax_amount).sum.to_f
              @tax_slabs = @tax_collections.map { |tax_col| tax_col.tax_slab }.uniq
              @tax_collections = @tax_collections.group_by { |x| x.slab_id.to_i }
              @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
                                                                        'FinanceTaxIdentificationNumber']) if @tax_slabs.present?
            end
            @discounts=@date.fee_discounts.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and ((par.receiver==@financefee.student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) and (par.master_receiver_type!='FinanceFeeParticular' or (par.master_receiver_type=='FinanceFeeParticular' and (par.master_receiver.receiver.present? and @fee_particulars.collect(&:id).include? par.master_receiver_id) and (par.master_receiver.receiver==@financefee.student or par.master_receiver.receiver==@financefee.student_category or par.master_receiver.receiver==@financefee.batch)))) }
            @categorized_discounts=@discounts.group_by(&:master_receiver_type)
            @total_discount = 0
            @total_payable=@fee_particulars.map { |s| s.amount }.sum.to_f
            @total_discount =@discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ? (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100) }.sum.to_f unless @discounts.nil?
            bal=(@total_payable-@total_discount).to_f
            days=(Date.today-@date.due_date.to_date).to_i
            auto_fine=@date.fine
            if days > 0 and auto_fine
              @fine=params[:fine].to_f if params[:fine].present? and params[:fine].to_f > 0.0
              @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
              @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
              if @fine_rule and @financefee.balance==0
                @fine_amount=@fine_amount-@financefee.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
              end
            end
            @fine_amount=0 if @financefee.is_paid
            respond_to do |format|
              format.pdf do
                render :pdf => "student_fee_receipt",
                       :template => 'gateway_payments/paypal/student_fee_receipt_pdf'
              end
            end
          end
        else
          student_fee_receipt_pdf_without_gateway
        end
      else
        student_fee_receipt_pdf_without_gateway
      end
    end
  end

  class PaymentMail < Struct.new(:fee_name, :email, :payee, :active_gateway, :amount, :txn_ref, :gateway_response, :school_details, :hostname)
    def perform
      EmailNotifier.deliver_send_transaction_details(fee_name, email, payee, active_gateway, amount, txn_ref, gateway_response, school_details, hostname)
    end
  end
end
