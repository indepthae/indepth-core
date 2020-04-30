class PaymentApiController < ActionController::Base
  require 'json'
  require "uri"
  require "net/http"
  before_filter :restrict_access
  
  def online_transaction_list
    @tr_date = params[:tr_date]
    @mih_ids = JSON.parse(params[:transaction_ids])
    #@transactions = Payment.find(:all,:conditions=>["DATE(created_at) = ?",@tr_date.to_date])
    @sucess = @transactions = FinanceTransaction.find(:all,:conditions=>['payment_mode = ? AND reference_no IN (?)',"Online Payment",@mih_ids]).collect(&:reference_no)
    @remaing = @mih_ids - @sucess
    render :json => @remaing.to_json
  end
  
  def reconciliate_transaction
    resp_body = Hash.new
    payment_params = HashWithIndifferentAccess.new(JSON.parse(params[:payment_params]))
    if payment_params.present? and payment_params["razorpay_payment_id"].present?
      ft = FinanceTransaction.find_by_payment_mode_and_reference_no("Online Payment",payment_params["razorpay_payment_id"])
      if ft.present?
        resp_body[:reconciliation_status] = "payment already successful"
      else
        if params[:fee_type] == "finance_fee"
          resp_body = Payment.reconcile_finance_payment(params[:student_id],params[:fee_collection_id],params[:t_ref],payment_params)
        elsif params[:fee_type] == "pay_all_fees"
          resp_body = Payment.reconcile_multi_fees_payment(params[:student_id],params[:t_ref],params[:id_token],payment_params)
        elsif params[:fee_type] == "hostel_fee"
          resp_body = Payment.reconcile_hostel_payment(params[:student_id],params[:fee_collection_id],params[:t_ref],payment_params)
        elsif params[:fee_type] == "transport_fee"
          resp_body = Payment.reconcile_transport_payment(params[:student_id],params[:fee_collection_id],params[:t_ref],payment_params)
        elsif params[:fee_type] == "application_fee"
          resp_body = Payment.reconcile_applicant_payment(params[:student_id],params[:fee_collection_id],params[:t_ref],payment_params)
        end
      end
    end
    render :json => resp_body
  end
  
  def reconciliate_single_transaction
    if params[:transaction_id].present?
      ft = FinanceTransaction.find_by_payment_mode_and_reference_no("Online Payment",params[:transaction_id])
      if ft.present?
        ftl = ft.transaction_ledger
        if ftl.status == "PENDING"
          payment_record = ft.finance_payment.payment
          g_r = payment_record.gateway_response
          g_r[:transaction_status] = params[:status]
          g_r[:reason_code] = params[:reason]
          payment_record.gateway_response = g_r
          payment_record.is_pending = false
          payment_record.status = params[:status] == "success" ? true : false
          payment_record.save
          if params[:status] == "success"
            ftl.update_attributes(:status=>"ACTIVE")
          else
            ftl.mark_cancelled
          end
        end
      end
      render :status=>200, :nothing=>true
    end
  end
  
  def transaction_process
    hostname = "#{request.protocol}#{request.host_with_port}"
    parameters = params[:the_id]
    param_hash = eval(parameters)
    postbackparam_url = param_hash["postBackParam"]['postUrl']
    refund_check = FinanceTransaction.find_by_reference_no(param_hash["postBackParam"]["mihpayid"])
    unless refund_check.present?
      param_to_pass = {}
      param_to_pass[:transaction_reference] = param_hash["postBackParam"]["mihpayid"]
      param_to_pass[:amount] = param_hash["postBackParam"]["amount"]
      param_to_pass[:reason_code] = param_hash["postBackParam"]["error_Message"]
      param_to_pass[:transaction_status] = param_hash["postBackParam"]["status"]
      if postbackparam_url.include? "process_pay_all_fees"
        identification_token = postbackparam_url.split("all_fees/")[1].split("?create")[0]
        payment_req = PaymentRequest.find_by_identification_token(identification_token)
        Authorization.current_user = payment_req.payee.user
        begin
          multi_fees_transactions = MultiFeePayment.create_multi_fees_transactions(param_to_pass,hostname,identification_token)
          status = multi_fees_transactions.status ?  "done" : "error"
        rescue Exception => e
          status = "refund"
        end  
      elsif postbackparam_url.include? "student/fee_details"
        status = PaymentRetry::Payu.process_single_fee(param_to_pass,postbackparam_url,hostname)
      elsif postbackparam_url.include? "transport_fee"
        status = PaymentRetry::Payu.process_transport_fee(param_to_pass,postbackparam_url,hostname)
      elsif postbackparam_url.include? "hostel_fee"
        status = PaymentRetry::Payu.process_hostel_fee(param_to_pass,postbackparam_url,hostname) 
      end
    else
      status = "refund"
    end
    render :json => status.to_json
  end
  
  private

  def restrict_access
    config=YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_pay/config", "payment_keys.yml"))
    access_key = config["payment_api_access_key"]
    header_key  = response.template.controller.request.headers["HTTP_AUTHORIZATION"] # <= env
    if header_key && (header_key == access_key)
      return true
    else
      respond_to do |format|
        msg = {:errors => "message:Bad Authentication data,code:215"}
        format.json { render :json => msg }
      end
    end
  end
  
end

