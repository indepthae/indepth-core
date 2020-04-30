class MultiFeePayment < Payment
  #has many payments for single multi payment
  has_many :finance_payments,:foreign_key=>"payment_id"
  has_one :finance_transactions,:through=> :finance_payments

  #to make finance transaction and payment entry



  def self.create_multi_fees_transactions(params,hostname,identification_token=nil,gateway=0)
    if params[:return_hash].present?
      @decrypted_hash = PaymentConfiguration.payment_decryption(params[:return_hash])
    end
    if identification_token.present?
      gateway_response = params
      gateway_status = true
      pending_status = false
      payment_request = PaymentRequest.find_by_identification_token(identification_token)
      @custom_gateway = CustomGateway.find_by_id(gateway)
    else
      gateway_response = params[:return_hash].present? ? custom_gateway_hash(gateway,@decrypted_hash) : custom_gateway_hash(gateway,params)
      if params[:return_hash].present?
        if @decrypted_hash[:split_statuses].present?
          gateway_response[:split_status] = @decrypted_hash[:split_statuses]
        end
      else
        if params[:split_statuses].present?
          gateway_response[:split_status] = params[:split_statuses]
        end
      end
      success_code = custom_gateway(gateway).gateway_parameters[:response_parameters][:success_code]
      pending_code = custom_gateway(gateway).gateway_parameters[:response_parameters][:pending_code]
      gateway_status = [success_code,pending_code].include?(gateway_response[:transaction_status]) ? true : false
      pending_status = gateway_response[:transaction_status] == pending_code ? true : false
      
      payment_request = PaymentRequest.find_by_identification_token(params[:identification_token])
    end
    multi_fee_payment = self.new(:payee => payment_request.payee,:gateway_response => gateway_response,
      :status => gateway_status, :amount => gateway_response[:amount].to_f, :gateway => gateway, :is_pending=>pending_status)
    if multi_fee_payment.save
      amount_from_gateway = @custom_gateway.present? ?  gateway_response[:amount].to_i : 0
      transactions = []
      FinanceTransaction.send_sms=false
      logger = Logger.new("#{RAILS_ROOT}/log/payment_processor_error.log")

      if gateway_status
        multi_fees = build_multi_fees_transaction(multi_fee_payment, payment_request, gateway_response, pending_status)
      else
        payment_request.transactions.each do |key, transaction_params|
          finance_transaction = FinanceTransaction.new(transaction_params.except(:amountt))
          multi_fee_payment.finance_payments.
            create(:fee_payment => finance_transaction.finance,
            :fee_collection => finance_transaction.get_collection)
        end
      end
      # payment_request.transactions.each do |key,transaction_params|
      #   begin
      #     retries ||= 0
      #     finance_transaction = FinanceTransaction.new(transaction_params.merge(
      #         {:transaction_ledger_id => multi_fees.id, :transaction_type => multi_fees.transaction_type,
      #           :transaction_mode => multi_fees.transaction_mode}))
      #     finance_transaction.payment_mode = "Online Payment"
      #     finance_transaction.reference_no = gateway_response[:transaction_reference]
      #     finance_transaction.transaction_date = Date.today_with_timezone.to_date
      #     finance_payment = multi_fee_payment.finance_payments.create(:fee_payment => finance_transaction.finance,:fee_collection => finance_transaction.get_collection)
      #     if amount_from_gateway.to_f > 0.0 and gateway_status and finance_transaction.amount.to_f > 0.0
      #       finance_transaction.save
      #       finance_payment.update_attribute("finance_transaction_id",finance_transaction.id)
      #       transactions << finance_transaction
      #     end
      #     # assigning to multifee finance_transaction join table
      #   rescue ActiveRecord::StatementInvalid => er
      #     # run code again  to  avoid duplications
      #     finance_payment.destroy
      #     retry if (retries += 1) < 4
      #     logger.info "Error------#{er.message}----for --#{transaction_params}" unless (retries += 1) < 2
      #   rescue Exception => e
      #     logger.info "Errror-----#{e.message}------for---#{transaction_params}"
      #   end
      # end

      FinanceTransaction.send_sms = true
      # unless transactions.empty?
      if gateway_status
        unless multi_fees.finance_transactions.empty?
          @status = MultiFeePayment.payment_status_mapping[:success]
          multi_fees.send_sms
          multi_fees.notify_users
        else
          @status = MultiFeePayment.payment_status_mapping[:failed]
        end
      else
        @status = MultiFeePayment.payment_status_mapping[:failed]
      end

      multi_fee_payment.update_attributes(:status_description => @status)
      
      if hostname.present?
        user = multi_fee_payment.payee.user
        if multi_fee_payment.payee.is_email_enabled && user.email.present? && gateway_status
          begin
            Delayed::Job.enqueue(OnlinePayment::PaymentMail.
                new(t('multi_fees'),user.email,user.full_name, @custom_gateway.name,
                FedenaPrecision.set_and_modify_precision(multi_fee_payment.amount),
                gateway_response[:transaction_reference],multi_fee_payment.gateway_response,
                user.school_details,hostname))
          rescue Exception => e
            puts "Error------#{e.message}------#{e.backtrace.inspect}"
            return
          end
        end
      end
    end
    multi_fee_payment
  end


  private

  def self.build_multi_fees_transaction(multi_fee_payment, payment_request, gateway_response, pending_status)
    if payment_request.transaction_parameters[:multi_fees_transaction]["wallet_amount_applied"] == "true"
      total_amount = 0.00
      payment_request.transaction_parameters[:multi_fees_transaction]["transactions"].values.each do |f|
        total_amount += f["amount"].to_f
      end
      multi_fee_payment.amount = total_amount
    end
    payment_request.transactions.values.each{|v| v.delete(:amountt) if v[:amountt].present?}
    ledger_info = {
      :amount => multi_fee_payment.amount,
      :payment_mode => "Online Payment",
      :transaction_date => Date.today_with_timezone.to_date,
      :payee_id => multi_fee_payment.payee_id,
      :payee_type => 'Student',
      :transaction_type => 'MULTIPLE',
      :category_is_income => true,
      :multi_fee_payment => multi_fee_payment,
      :status => (pending_status == true ? "PENDING" : "ACTIVE")
    }
    
    FinanceTransactionLedger.safely_create(ledger_info, payment_request.transactions, gateway_response)

    #		MultiFeesTransaction.create(
    # FinanceTransactionLedger.create({
    #                                     :amount => multi_fee_payment.amount,
    #                                     :payment_mode => "Online Payment",
    #                                     :transaction_date => Date.today_with_timezone.to_date,
    #                                     :payee_id => multi_fee_payment.payee_id,
    #                                     :payee_type => 'Student',
    #                                     :transaction_type => 'MULTIPLE',
    #                                     :category_is_income => true}
    # )
  end
end