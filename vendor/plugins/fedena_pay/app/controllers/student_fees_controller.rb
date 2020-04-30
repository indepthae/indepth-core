class StudentFeesController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation
  include StudentFeesHelper
  include FinancePaidFees
  skip_before_filter :verify_authenticity_token 

  filter_access_to [:all_fees],:attribute_check=>true, :load_method => lambda { Student.find(params[:id])}

  before_filter :set_student
  before_filter :set_precision

  before_filter :login_required, :except=>[:initialize_all_fees_payment]

  def all_fees
    @enable_all_fee = PaymentConfiguration.find_by_config_key("enabled_pay_all").try(:config_value) || "true"
    if @enable_all_fee == "true"
      @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) : @student.batch
      @all_batches= (@student.previous_batches+[@student.batch]).uniq
      @available_gateways = CustomGateway.available_gateways
      active_gateway
      @finance_fees = payable_fees
      @transaction_date = Date.today_with_timezone.to_date
      @is_tax_present = @finance_fees.map(&:tax_enabled).include?(true)
      @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
          'FinanceTaxIdentificationNumber']) if @is_tax_present
    
      @disabled_fee_ids = FinanceFee.find_all_by_id(@finance_fees.map(&:id), 
        :joins => "INNER JOIN finance_fee_collections ffc 
                                  ON ffc.id = finance_fees.fee_collection_id AND 
                                        ffc.discount_mode <> 'OLD_DISCOUNT'
                      INNER JOIN finance_transactions fts 
                                  ON fts.trans_type = 'particular_wise' AND 
                                        fts.finance_type = 'FinanceFee' AND 
                                        fts.finance_id = finance_fees.id" ).map(&:id) 
      #    @disabled_fee_ids = FinanceFee.find_all_by_id(@finance_fees.map(&:id), 
      #      :joins => "INNER JOIN finance_transactions fts 
      #                         ON fts.trans_type = 'particular_wise' AND 
      #                            fts.finance_type = 'FinanceFee' AND 
      #                            fts.finance_id = finance_fees.id" ).map(&:id)    
      @paid_fees = paid_fees
      
      # calculating advance fees used
      @advance_fee_used = @paid_fees.collect(&:finance_transactions).flatten.compact.sum(&:wallet_amount).to_f if @paid_fees.present?
      
      # @unlinked_disabled = FinanceFee.all(
      #     :select => "SUM(IF(ffp.master_fee_particular_id IS NULL,1,0)) as unlinked_particulars,
      #               SUM(IF(ffp.master_fee_particular_id IS NOT NULL,1,0)) as linked_particulars,
      #               SUM(IF(fd.master_fee_discount_id IS NULL,1,0)) as unlinked_discounts,
      #               SUM(IF(fd.master_fee_discount_id IS NOT NULL,1,0)) as linked_discounts,
      #               finance_fees.id ff_id",
      #     :conditions => ["finance_fees.student_id = ? and finance_fees.batch_id = ?", @student.id, @current_batch.id],
      #     :joins => "INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
      #               LEFT JOIN collection_particulars cp ON cp.finance_fee_collection_id = ffc.id
      #               LEFT JOIN collection_discounts cd ON cd.finance_fee_collection_id = ffc.id
      #               LEFT JOIN finance_fee_particulars ffp ON ffp.id = cp.finance_fee_particular_id
      #               LEFT JOIN fee_discounts fd ON fd.id = cd.fee_discount_id",
      #     :group => "finance_fees.id"
      # )
      @partial_payment_enabled = PaymentConfiguration.is_partial_payment_enabled?
      @financial_year_enabled = FinancialYear.has_valid_transaction_date(@transaction_date)
      flash[:notice] = t('financial_year_payment_disabled_admin') unless @financial_year_enabled
    else
      flash[:notice] = t('pay_all_fee_disabled')
      redirect_to :controller => "user",:action => "dashboard"
    end  
  end
  
  def change_gateway
    @active_gateway = params[:g_id]
    @payment_id = params[:payment_id]
    render :update do |page|
      page.replace_html 'proceed_button',:partial => "proceed_button"
    end
  end

  def initialize_pay_all_fees
    parameters = params
    params = []
    params = AdvanceFeePayment.update_amount_by_wallet_multi_fees(parameters)
    block_partial_payment = false
    @student = Student.find(params[:id])
    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) : @student.batch
    @all_finance_fees = payable_fees
    @detailed_entry = @all_finance_fees.map{|x| x.attributes}
    @enable_all_fee = PaymentConfiguration.find_by_config_key("enabled_pay_all").try(:config_value) || "true"

    @transaction_date = Date.today_with_timezone
    financial_year_check
    if (FedenaPlugin.can_access_plugin?("fedena_pay") and PaymentConfiguration.config_value("enabled_fees").present? and
          PaymentConfiguration.op_enabled? and @enable_all_fee == "true" and @financial_year_enabled)
      student_payment = build_paymentrequest
      total_amount =  precision_label(params[:transaction_extra][:total_amount].to_f).to_f
      paid_total = 0
      total_transaction_count = 0
      equal_amount_transactions=0
      params[:transactions].each do |key,transaction|
        total_transaction_count = total_transaction_count+1
        paid_total = (transaction[:wallet_amount_applied].eql? "true") ? paid_total + transaction[:amountt].to_f : paid_total + transaction[:amount].to_f
        trans = @detailed_entry.select{|x| x["id"]== transaction[:finance_id].to_i && x["fee_type"] == transaction[:finance_type]}.first 
        trans_fine =(trans["is_paid"] ? 0 : (trans["is_amount"].to_i ==1 ? trans["fine_amount"].to_f : ((trans["actual_amount"].to_f) * (trans["fine_amount"].to_f / 100).to_f - 
                (trans["paid_fine"].to_f > 0 ? trans["paid_fine"].to_f : 0))))
        final_amount = precision_label(trans["balance"].to_f).to_f+ trans_fine.to_f
        if precision_label(transaction[:amount].to_f) == precision_label(final_amount)
          equal_amount_transactions = equal_amount_transactions+1
        else
          equal_amount_transactions = -10000
        end
      end
      if equal_amount_transactions == total_transaction_count
        block_partial_payment = true
      end
      paid_total = precision_label(paid_total).to_f
      @amount_total = paid_total
      unless PaymentConfiguration.is_partial_payment_enabled? or block_partial_payment
        flash[:notice] = t('partial_payment_disabled')
        redirect_to :back
      else
        if student_payment.save
          @active_gateways = PaymentConfiguration.config_value("fedena_gateway")
          @active_gateway = PaymentConfiguration.first_active_gateway
          @payment_id = student_payment.id
          render :layout => false
        else
          redirect_to :back
        end
      end
    else
      flash[:notice] = t('online_payment_is_currently_disabled')
      flash[:notice] = t('financial_year_payment_disabled_admin') unless @financial_year_enabled
      redirect_to :controller => "user",:action => "dashboard"
    end
  end
  
  def initialize_all_fees_payment
    enable_all_fee = PaymentConfiguration.find_by_config_key("enabled_pay_all").try(:config_value) || "true"

    @financial_year_payment_enabled = FinancialYear.has_valid_transaction_date Date.today_with_timezone
    if (FedenaPlugin.can_access_plugin?("fedena_pay") and PaymentConfiguration.config_value("enabled_fees").present? and
          PaymentConfiguration.op_enabled? and enable_all_fee == "true" and @financial_year_payment_enabled)
      @student_payment = PaymentRequest.find_by_id(params[:payment_id])
      gateway = params[:gateway_id]
      @custom_gateway = CustomGateway.find(gateway)
      @hash_for_user_payment = user_payment_hash
      if PaymentConfiguration.is_encrypted(@custom_gateway)==true
        @encrypted_hash = PaymentConfiguration.payment_encryption(gateway,@hash_for_user_payment,"all")
      end
      render :layout => false
    else
      flash[:notice] = t('online_payment_is_currently_disabled')
      flash[:notice] = t('financial_year_payment_disabled_admin') unless @financial_year_enabled
      redirect_to :controller => "user",:action => "dashboard"
    end
  end
   
  def procees_pay_all_fees
   	if params[:create_transaction].present?
      gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>params[:transaction_ref], :status=>0})
      if gateway_record.present?
        gateway_record.update_attribute('status', true)
        active_gateway = gateway_record.gateway
        #active_gateway = gateway_record.present? ? gateway_record.gateway : 0
        hostname = "#{request.protocol}#{request.host_with_port}"
        multi_fees_transactions = MultiFeePayment.create_multi_fees_transactions(params,hostname,nil,active_gateway)
        if multi_fees_transactions.status
          flash[:notice] = "#{t('payment_success')} <br>  #{t('payment_reference')} : #{multi_fees_transactions.gateway_response[:transaction_reference]}"
        else
          flash[:notice] = "#{t('payment_failed')} <br>  #{t('reason')} : #{multi_fees_transactions.gateway_response[:reason_code]}"
        end
      else
        flash[:notice] = t('flash_msg3')
      end
   	else
   		flash[:notice] = t('payment_failed')
   	end
   	redirect_to all_fees_student_fee_path(@student)
  end
    
  # transaction history
  def paginate_paid_fees
    @student=Student.find params[:id]
    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) :
      @student.batch
    get_paid_fees(@student.id, @current_batch.id)
    render :update do |page|
      page.replace_html "pay_fees1", :partial => "/finance_extensions/recently_paid_fees"
    end
  end


  private

  def paid_fees
   	query_object.get_paid_fees({:paginate => true, :paginate_options => {:page => params[:page], 
          :per_page => 10, :order => 'creation_time desc'}})
  end

  def payable_fees
   	query_object.fetch_all_fees(true)
  end

  def query_object
    set_current_batch
   	object ||= FinanceQuery.new(@student,@current_batch,PaymentConfiguration.get_assigned_fees)
  end

  def build_paymentrequest
   	student_payment = PaymentRequest.new(
   		:user_id => @student.try(:user_id),
   		:transaction_parameters => wrapp_parameter
    )
  end
  def set_student
   	@student ||= Student.find(params[:id])
  end

  def wrapp_parameter
   	{:multi_fees_transaction => params[:multi_fees_transaction].merge({:transactions=>params[:transactions], :wallet_amount_applied => params[:wallet_amount_applied]})}
  end

	def active_gateway #ToDo code duplication
		@active_gateway = PaymentConfiguration.first_active_gateway
  end

  def set_current_batch
    @student.batch=@current_batch
  end
end
