class PaytmPaymentsController < ApiController
  
  filter_access_to :all
  
  # fetch fees
  def get_all_fees_list
    transport_plugin = FedenaPlugin.can_access_plugin?("fedena_transport")
    hostel_plugin = FedenaPlugin.can_access_plugin?("fedena_hostel")
    include_plugins = [{:finance_fees => [:finance_transactions, :finance_fee_collection]}]
    include_plugins << {:transport_fees => [:finance_transactions, :transport_fee_collection]} if transport_plugin
    include_plugins << {:hostel_fees => [:finance_transactions, :hostel_fee_collection]} if hostel_plugin
    response_obj = []
    response = Hash.new
    if params[:regnumber].present?
      @student = Student.find_by_admission_no(params[:regnumber], :include => include_plugins)
      if @student.present?
        fee_details = FeeDetails.new({:student => @student,:list_type => "each-fee"})
        pending_fee_hash = fee_details.get_pending_fee_details_for_student
        if pending_fee_hash.present?
          response["error_code"] = 100
          response_obj << response
          response_obj << pending_fee_hash
        else
          response["error_code"] = 103
          response_obj << response
        end
      else
        response["error_code"] = 102
        response_obj << response
      end
    else
      response["error_code"] = 101
      response_obj << response
    end
    respond_to do |format|
      response_obj.flatten!
      format.json {render :json => response_obj}
    end
  end
  
  def get_all_fees
    transport_plugin = FedenaPlugin.can_access_plugin?("fedena_transport")
    hostel_plugin = FedenaPlugin.can_access_plugin?("fedena_hostel")
    include_plugins = [{:finance_fees => [:finance_transactions, :finance_fee_collection]}]
    include_plugins << {:transport_fees => [:finance_transactions, :transport_fee_collection]} if transport_plugin
    include_plugins << {:hostel_fees => [:finance_transactions, :hostel_fee_collection]} if hostel_plugin
    response_obj = []
    response = Hash.new
    if params[:enrolment_no].present?
      @student = Student.find_by_admission_no(params[:enrolment_no], :include => include_plugins)
      if @student.present?
        fee_details = FeeDetails.new({:student => @student,:list_type => "all-fee"})
        pending_fee_hash = fee_details.get_pending_fee_details_for_student
        if pending_fee_hash.present? and (pending_fee_hash.first.to_f > 0.0)
          response["error_code"] = 100
          response["Name"] = @student.full_name
          response["Enrolment_no"] = @student.admission_no
          response["Class"] = @student.batch.full_name
          response["Due_amount"] = pending_fee_hash.first
          response_obj << response
        else
          response["error_code"] = 103
          response_obj << response
        end
      else
        response["error_code"] = 102
        response_obj << response
      end
    else
      response["error_code"] = 101
      response_obj << response
    end
    respond_to do |format|
      response_obj.flatten!
      format.json {render :json => response_obj}
    end
  end
  
  #pay fees
  def pay_student_pending_all_fee
    @transport_plugin = FedenaPlugin.can_access_plugin?("fedena_transport")
    @hostel_plugin = FedenaPlugin.can_access_plugin?("fedena_hostel")
    include_plugins = [{:finance_fees => [:finance_transactions, :finance_fee_collection]}]
    include_plugins << {:transport_fees => [:finance_transactions, :transport_fee_collection]}  if @transport_plugin
    include_plugins << {:hostel_fees => [:finance_transactions, :hostel_fee_collection]} if @hostel_plugin
    @error_code = 101
    acknowledgement = ''
    amount_check = ''
    response_obj = Hash.new
    
    if params[:enrolment_no].present? 
      if params[:amount].present? and params[:order_id].present?
        existing_record =  PaytmPaymentRecord.find(:all,:conditions=>["order_id = ? AND item_id IS NULL","#{params[:order_id]}"])
        unless existing_record.present?
          
          reference_no = params[:order_id].present? ? "#{params[:order_id]}" : nil
          transaction_date = Date.today
          transaction_date = transaction_date.to_date.strftime if transaction_date.present?
          @student = Student.find_by_admission_no(params[:enrolment_no], :include => include_plugins)
          paying_amount = params[:amount]
          if @student.present?
            pay_fee = FeeDetails.new({:student => @student,:amount => paying_amount,
                :reference_no => reference_no,:transaction_date => transaction_date,:list_type => "all-fee",
                :order_id => params[:order_id]})
            status,acknowledgement,amount_check = pay_fee.pay_fees_for_student
            receipt_no = acknowledgement
            if status == "Failed"
              if amount_check == 104
                response_obj["error_code"] = 104
              else
                response_obj["error_code"] = 101
              end
            else
              response_obj["error_code"] = 100
              response_obj["Transaction_status"] = status
              response_obj["Receipt_id"] = receipt_no
            end
          else
            response_obj["error_code"] = 102 # need to change
          end
        else 
          response_obj["error_code"] = 103
        end
      else
        response_obj["error_code"] = 102
      end
    else
      response_obj["error_code"] = 102
    end
    respond_to do |format|
      unless params[:enrolment_no].present? or params[:amount].present? 
        format.json {render :json => response_obj}
      else
        format.json {render :json => response_obj}
      end
    end
  end
  
  def pay_student_pending_collection_fee
    @transport_plugin = FedenaPlugin.can_access_plugin?("fedena_transport")
    @hostel_plugin = FedenaPlugin.can_access_plugin?("fedena_hostel")
    include_plugins = [{:finance_fees => [:finance_transactions, :finance_fee_collection]}]
    include_plugins << {:transport_fees => [:finance_transactions, :transport_fee_collection]}  if @transport_plugin
    include_plugins << {:hostel_fees => [:finance_transactions, :hostel_fee_collection]} if @hostel_plugin
    @status = true
    status = "Failed"
    amount_check = ''
    response_obj = Hash.new
    if params[:regnumber].present? and params[:feeName].present? and params[:feeType].present? and params[:feeID].present?
      if params[:payable].present? and params[:paymentstatus] == "success" and params[:paytmitemid].present? and  params[:paytmorderid].present?
        existing_record = PaytmPaymentRecord.find(:all,:conditions=>["order_id = ? AND item_id = ?","#{params[:paytmorderid]}","#{params[:paytmitemid]}"])
        existing_item_id = PaytmPaymentRecord.find(:all,:conditions=>["order_id IS NOT NULL AND item_id = ?","#{params[:paytmitemid]}"])
        unless existing_record.present?
          unless existing_item_id.present?
            reference_no = params[:paytmorderid].present? ? "#{params[:paytmorderid]}" : nil
            transaction_date = Date.today
            transaction_date = transaction_date.to_date.strftime if transaction_date.present?
            payment_note = params[:paytmitemid].present? ? "#{params[:paytmitemid]}" : nil
            @student = Student.find_by_admission_no(params[:regnumber], :include => include_plugins)
            paying_amount = params[:payable]
            paying_fee_collection_name = params[:feeName]
            paying_fee_collection_type = params[:feeType]
            paying_fee_collection_id = params[:feeID]
            if @student.present?
              pay_fee = FeeDetails.new({:student => @student,:amount => paying_amount,
                  :reference_no => reference_no,:payment_note => payment_note,:transaction_date => transaction_date,
                  :fee_collection_name => paying_fee_collection_name,:list_type => "each-fee",
                  :fee_collection_type => paying_fee_collection_type, :fee_collection_id => paying_fee_collection_id,
                  :order_id => params[:paytmorderid],:item_id => params[:paytmitemid]})
              status,acknowledgement,amount_check = pay_fee.pay_fees_for_student
              if status == "Failed" 
                if amount_check == 104
                  response_obj["error_code"] = 104
                else
                  response_obj["error_code"] = 101
                end
              else
                response_obj["error_code"] = 100
              end
            else
              response_obj["error_code"] = 102 # need to change
            end
          else
            response_obj["error_code"] = 106
          end
        else
          response_obj["error_code"] = 103
        end
      else
        response_obj["error_code"] = 102
      end
    else
      response_obj["error_code"] = 102
    end
    respond_to do |format|
      unless params[:regnumber].present? or params[:amount].present? 
        format.json {render :json => response_obj}
      else
        format.json {render :json => response_obj}
      end
    end
  end
  
  #status check
  
  def status_check
    response_obj = Hash.new
    if params[:order_id].present?
      existing_record =  PaytmPaymentRecord.find(:all,:conditions=>["order_id = ? AND item_id IS NULL","#{params[:order_id]}"])
      if existing_record.present?
        response_obj["error_code"] = 100
      else
        response_obj["error_code"] = 101
      end
    elsif params[:paytmorderid].present? and (params[:paymentstatus].present? and params[:paymentstatus] == "success" ) and params[:paytmitemid].present?
      existing_record =  PaytmPaymentRecord.find(:all,:conditions=>["order_id = ? AND item_id = ? ","#{params[:paytmorderid]}","#{params[:paytmitemid]}"])
      if existing_record.present?
        response_obj["error_code"] = 100
      else
        response_obj["error_code"] = 101
      end
    else
      response_obj["error_code"] = 101
    end
    respond_to do |format|
      format.json {render :json => response_obj}
    end
  end
  
#  private
#  
#  def verify_user
#    MultiSchool.current_school = School.first
#    Fedena.present_user = User.first
#    session[:user_id] = User.first
#    return true
#    valid_school = false
#    if params[:schoolID].present? and params[:regnumber].present?
#      school = School.find_by_id(params[:schoolID])
#      if school.present?
#        valid_school = true
#        MultiSchool.current_school = school
#        Fedena.present_user = User.first
#        session[:user_id] = User.first
#      end
#    end
#
#    respond_to do |format|
#      if params[:schoolID].present? and params[:regnumber].present? and valid_school == true
#        return true
#      else
#        response_obj = Hash.new
#        if !params[:schoolID].present? or !params[:regnumber].present?
#          response_obj["error_code"] = 102
#          format.json {render :json => response_obj}
#        elsif valid_school == false
#          response_obj["error_code"] = 102
#          format.json {render :json => response_obj}
#        end
#          render "user_error_details.xml", :status => :bad_request  and return
#      end
#    end
#  end
  
#  def restrict_access
#    config=YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_pay/config", "payment_keys.yml"))
#    access_key = config["payment_api_access_key"]
#    header_key  = response.template.controller.request.headers["HTTP_AUTHORIZATION"] # <= env
#    if header_key && (header_key == access_key)
#      return true
#    else
#      respond_to do |format|
#        msg = {:errors => "message:Bad Authentication data,code:215"}
#        format.json { render :json => msg }
#      end
#    end
#  end
  
end
