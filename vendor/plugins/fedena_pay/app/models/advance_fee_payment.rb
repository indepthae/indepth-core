class AdvanceFeePayment < Payment

    def self.create_advance_fees_transactions(params,hostname,identification_token=nil,gateway=0)
      if params[:return_hash].present?
        @decrypted_hash = PaymentConfiguration.payment_decryption(params[:return_hash])
      end
      if identification_token.present?
        gateway_response = params
        gateway_status = true
        payment_request = PaymentRequest.find_by_identification_token(identification_token)
        @custom_gateway = CustomGateway.find_by_id(gateway)
      else
        gateway_response = params[:return_hash].present? ? custom_gateway_hash(gateway,@decrypted_hash) : custom_gateway_hash(gateway,params)
        success_code = custom_gateway(gateway).gateway_parameters[:response_parameters][:success_code]
        gateway_status = gateway_response[:transaction_status] == success_code ? true : false
        payment_request = PaymentRequest.find_by_identification_token(params[:identification_token])
      end
      advance_fee_payment = self.new(:payee => payment_request.advance_fee_payee,:gateway_response => gateway_response,
                                   :status => gateway_status, :amount => gateway_response[:fees_paid].to_f, :gateway => gateway)
      if advance_fee_payment.save
        amount_from_gateway = @custom_gateway.present? ?  gateway_response[:amount].to_i : 0
        advance_fee_transaction = []
        logger = Logger.new("#{RAILS_ROOT}/log/payment_processor_error.log")

        if gateway_status
          @advance_fee_collection = AdvanceFeeCollection.new(payment_request.advance_fee_transaction)
          @advance_fee_collection.reference_no = gateway_response[:transaction_reference]
          if @advance_fee_collection.save
            @advance_fee_collection.create_the_transaction_data
              @status = AdvanceFeePayment.payment_status_mapping[:success]
          end
        else
          @status = AdvanceFeePayment.payment_status_mapping[:failed]
        end

        advance_fee_payment.update_attributes(:status_description => @status)


        user = advance_fee_payment.payee.user
        if advance_fee_payment.payee.is_email_enabled && user.email.present? && gateway_status
          begin
            Delayed::Job.enqueue(OnlinePayment::PaymentMail.
                                     new(t('advance_fees_payment'),user.email,user.full_name, @custom_gateway.name,
                                         FedenaPrecision.set_and_modify_precision(advance_fee_payment.amount),
                                         gateway_response[:transaction_reference],advance_fee_payment.gateway_response,
                                         user.school_details,hostname))
          rescue Exception => e
            puts "Error------#{e.message}------#{e.backtrace.inspect}"
            return
          end
        end
      end
      advance_fee_payment
    end

    # update amount by advance fee amount
    def self.update_amount_by_wallet_multi_fees(data_hash)
      total_advance_fee_amount = 0.00
      if data_hash[:wallet_amount_applied].present? and data_hash[:wallet_amount_applied] == "true"
        data_hash[:transactions].values.each do |f|
          total_advance_fee_amount += f[:wallet_amount].to_f if f[:wallet_amount_applied] == "true"
        end
        # if total_advance_fee_amount == data_hash[:wallet_amount]
          data_hash[:transaction_extra][:total_amount] = data_hash[:transaction_extra][:total_amount].to_f - total_advance_fee_amount.to_f
          # data_hash[:multi_fees_transaction][:amount] = data_hash[:multi_fees_transaction][:amount].to_f - total_advance_fee_amount.to_f
          data_hash
        # end
      else
        data_hash
      end
    end

    # update amount by advance fee amount
    def self.update_amount_by_wallet_single(data_hash)
      total_advance_fee_amount = 0.00
      if data_hash[:wallet_amount_applied].present? and data_hash[:wallet_amount_applied] == "true"
        data_hash[:amount] = data_hash[:amount].to_f - data_hash[:wallet_amount].to_f
        data_hash
      else
        data_hash
      end
    end
end
