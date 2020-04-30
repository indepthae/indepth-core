module PaymentRetry
  module Payu
    def self.process_single_fee(gateway_response,post_back_url,hostname)
      load_the_required_details(post_back_url, 'normal')
      single_payment = SingleFeePayment.new(:payee => @student, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway)
      if single_payment.save
        fee_title = "#{I18n.t('receipt_no')}. F#{@financefee.id}"
        transaction = build_finance_transaction(gateway_response, @student,@financefee, fee_title, 'Fee')
        if transaction.save
          finance_payment = build_finance_payment(single_payment, transaction, 'finance_fee_collection')
          unless @financefee.is_paid?
            amount_from_gateway = gateway_response[:amount]
            unless amount_from_gateway.to_f <= 0.0
              unless @financefee.transaction_id.nil?
                tid = @financefee.transaction_id.to_s + ",#{transaction.id}"
              else
                tid=transaction.id
              end
              #is_paid = (@financefee.balance.to_f == amount_from_gateway.to_f) ? true : false
              #@financefee.update_attributes(:transaction_id => tid, :is_paid => is_paid)
              @financefee.update_attributes(:transaction_id => tid)
              status = SingleFeePayment.payment_status_mapping[:success]
              single_payment.update_attributes(:status_description => status)
              online_transaction_id = single_payment.gateway_response[:transaction_reference]
              user = @student.user
              if @student.is_email_enabled && user.email.present? && @gateway_status
                begin
                  Delayed::Job.enqueue(PaymentMail.new(finance_payment.fee_collection.name, user.email, user.full_name, @custom_gateway.name, FedenaPrecision.set_and_modify_precision(single_payment.amount), online_transaction_id, single_payment.gateway_response, user.school_details, hostname))
                rescue Exception => e
                  puts "Error------#{e.message}------#{e.backtrace.inspect}"
                  return
                end
              end
              return "done"
            else
              status = SingleFeePayment.payment_status_mapping[:failed]
              single_payment.update_attributes(:status_description => status)
              return "error"
            end
          end
        else
          return "error"
        end  
      else
        return "refund"
      end
    end
    
    def self.process_transport_fee(gateway_response,post_back_url,hostname)
      load_the_required_details(post_back_url, 'transport')
      payment = SingleFeePayment.new(:payee => @student,:gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway)
      if payment.save and !@transport_fee.is_paid?
        amount_from_gateway = gateway_response[:amount]
        if amount_from_gateway.to_f > 0.0 and payment.status
          fee_title = @transport_fee.transport_fee_collection.name
          transaction = build_finance_transaction(gateway_response, @student,@transport_fee, fee_title, 'Transport')
          if transaction.save
            finance_payment = build_finance_payment(payment, transaction, 'transport_fee_collection')
            online_transaction_id = payment.gateway_response[:transaction_reference]
          end
          if @gateway_status
            status = SingleFeePayment.payment_status_mapping[:success]
            payment.update_attributes(:status_description => status)
            user = @student.user
            if @student.is_email_enabled && user.email.present?
              begin
                Delayed::Job.enqueue(OnlinePayment::PaymentMail.new(finance_payment.fee_collection.name, user.email, user.full_name, @custom_gateway.name, FedenaPrecision.set_and_modify_precision(payment.gateway_response[:amount]), online_transaction_id, payment.gateway_response, user.school_details, hostname))
              rescue Exception => e
                puts "Error------#{e.message}------#{e.backtrace.inspect}"
                return
              end
            end
          end
          return "done"
        else
          status = SingleFeePayment.payment_status_mapping[:failed]
          payment.update_attributes(:status_description => status)
          return "error"
        end
      else
        return "refund"
      end
    end
    
    def self.process_hostel_fee(gateway_response,post_back_url,hostname)
      load_the_required_details(post_back_url, 'hostel')
      payment = SingleFeePayment.new(:payee => @student, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway)
      if payment.save and !@hostel_fee.is_paid?
        amount_from_gateway = gateway_response[:amount]
        if amount_from_gateway.to_f > 0.0 and payment.status
          fee_title = @hostel_fee.hostel_fee_collection.name
          transaction = build_finance_transaction(gateway_response, @student,@hostel_fee, fee_title, 'Hostel')
          if transaction.save
            finance_payment = build_finance_payment(payment, transaction, 'hostel_fee_collection')
            online_transaction_id = payment.gateway_response[:transaction_reference]
          end
          if @gateway_status
            status = SingleFeePayment.payment_status_mapping[:success]
            payment.update_attributes(:status_description => status)
            user = @student.user
            if @student.is_email_enabled && user.email.present?
              begin
                Delayed::Job.enqueue(OnlinePayment::PaymentMail.new(payment.fee_collection.name, user.email, user.full_name, @custom_gateway.name, FedenaPrecision.set_and_modify_precision(payment.amount), online_transaction_id, payment.gateway_response, user.school_details, hostname))
              rescue Exception => e
                puts "Error------#{e.message}------#{e.backtrace.inspect}"
                return
              end
            end
          end
          return "done"
        else
          status = Payment.payment_status_mapping[:failed]
          payment.update_attributes(:status_description => status)
          return "error"
        end
      else
        return "refund"
      end
    end
    
    
    def self.load_the_required_details(post_back_url, type)
      student_id = post_back_url.split('/')[-2]
      @student=Student.find(student_id)
      fee_collection_id = post_back_url.split('?')[-2].split("/")[-1]
      if type == 'hostel'
        @hostel_fee= HostelFee.find_by_hostel_fee_collection_id_and_student_id(fee_collection_id, student_id)
        @fee_collection = HostelFeeCollection.find(fee_collection_id)
      elsif type == 'transport'
        @transport_fee= TransportFee.find_by_transport_fee_collection_id_and_receiver_id(fee_collection_id, student_id)
        @fee_collection = TransportFeeCollection.find(fee_collection_id)
      else
        @financefee =  FinanceFee.find_by_fee_collection_id_and_student_id(fee_collection_id, student_id)
      end  
      @gateway_status = true
      @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
      if @active_gateway.present?
        @custom_gateway = CustomGateway.find(@active_gateway)
      end
      Fedena.present_user = User.find(:first,:conditions=>["admin=?",true])
    end
    
    def self.build_finance_transaction(gateway_response, student, financefee, fee_title, ft_category)
      FinanceTransaction.new(
        :title => fee_title,
        :category => FinanceTransactionCategory.find_by_name(ft_category),
        :payee => student,
        :finance => financefee,
        :amount => gateway_response[:amount],
        #        :fine_included => (@fine.to_f ).zero? ? false : true,
        #        :fine_amount => @fine.to_f,
        :transaction_date => FedenaTimeSet.current_time_to_local_time(Time.now).to_date,
        :payment_mode => "Online Payment",
        :reference_no => gateway_response[:transaction_reference]
      )
    end
    
    def self.build_finance_payment(single_payment, transaction, fee_collection)
      FinancePayment.create(
        :payment_id => single_payment.id, 
        :fee_payment => transaction.finance, 
        :fee_collection => transaction.finance.send(fee_collection),
        :finance_transaction_id => transaction.id
      )
    end
    
    
  end
 
end
