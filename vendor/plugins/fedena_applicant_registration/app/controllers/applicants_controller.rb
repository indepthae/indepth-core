class ApplicantsController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation, :only => [:registration_return]
  require 'authorize_net'
  helper :authorize_net
  layout :choose_layout
  before_filter :login_required,:except=>[:new,:create,:success,:complete,:show_course_instructions,:show_form,:print_application,:show_pin_entry_form,:get_amount,:registration_return,:preview_application,:edit_application,:update_application,:submit_application,:discard_application, :generate_fee_receipt_pdf]
  before_filter :load_common
  before_filter :set_translate_options,:only=>[:new,:create,:success,:complete,:show_course_instructions,:show_form,:show_pin_entry_form,:preview_application,:edit_application, :print_application, :generate_fee_receipt_pdf]
  #before_filter :load_lang,:only=>[:new,:create,:success,:complete,:show_course_instructions,:show_form,:show_pin_entry_form,:preview_application,:edit_application]
  before_filter :load_lang,:only=>[:new]
  before_filter :set_precision
  before_filter :escape_dirty_params,:only => [:show_course_instructions,:show_form]
  after_filter :unasign_translate_options,:only=>[:new,:create,:success,:complete,:show_course_instructions,:show_form,:show_pin_entry_form,:preview_application,:edit_application]
  skip_before_filter :verify_authenticity_token, :only => [:registration_return]
  def choose_layout
    return 'application' if action_name == 'edit' or action_name == 'update'
    'applicants'
  end

  def index
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

  def new
    @registration_courses = RegistrationCourse.active(:include=>:course)
    @registration_settings = ApplicationInstruction.find_by_registration_course_id(nil)
  end

  def show_course_instructions
    if params[:registration_course_id].present?
      begin
        @registration_course = RegistrationCourse.find_by_id_and_is_active!(params[:registration_course_id],true)
        @registration_settings = ApplicationInstruction.find_by_registration_course_id(params[:registration_course_id].to_i)
      rescue ActiveRecord::RecordNotFound => exception
        flash[:notice] = "#{t('flash_msg2')} , #{t('registration_course_not_found')} ."
        logger.info "[FedenaRescue] AR-Record_Not_Found #{exception.to_s}"
        log_error exception
        redirect_to :controller=>:user ,:action=>:dashboard
      end
    end
    @registration_settings = ApplicationInstruction.find_by_registration_course_id(nil) unless @registration_settings.present?
    render :update do|page|
      page.replace_html "instruction-box", :partial=>"applicants_admins/application_instructions"
    end
  end

  def show_form
    if params[:registration_course][:course_id].present?
      begin
        @registration_course = RegistrationCourse.find_by_id_and_is_active!(params[:registration_course][:course_id],true)
        if @registration_course.pin_enabled_status
          unless PinNumber.pin_status(params[:pin_number], params[:registration_course][:course_id])
            flash[:notice] = "Please Enter a Valid Pin." 
            render :update do|page|
              page.replace_html "flashmsg-div", :inline => "<p class='flash-msg'> <%= flash[:notice] %> </p>"
              flash[:notice] = nil
            end
            return
          end
        end
        @application_section = @registration_course.application_section
        unless @application_section.present?
          @application_section = ApplicationSection.find_by_registration_course_id(nil)
        end
        @applicant = Applicant.new(:pin_number=>params[:pin_number])
        @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
        @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
        @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
        @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
        @selected_subject_ids = @applicant.subject_ids.nil? ? [] : @applicant.subject_ids
        @mandatory_attributes = []
        @mandatory_guardian_attributes = []
        @mandatory_previous_attributes = []
        @mandatory_addl_attributes =[]
        @mandatory_student_attributes = []
        @mandatory_attachment_attributes = []
        @currency = currency
        @application_fee= @registration_course.amount.to_f
        if @registration_course.is_subject_based_registration
          @subjects=@registration_course.get_elective_subjects_and_amount
          @normal_subject_amount = 0.to_f
          @total_fee= @application_fee + 0.to_f
          if @registration_course.subject_based_fee_colletion == true
            @normal_subject_amount=@registration_course.get_major_subjects_amount
            @total_fee= @application_fee+@normal_subject_amount
          end  
        else
          @normal_subject_amount = 0.to_f
          @total_fee= @application_fee + 0.to_f
        end
        render :update do|page|
          page.replace_html "form-box", :partial=>"application_form"
          page.replace_html "flashmsg-div", ""
          page << 'j("#view-instruction-tab").show();'
          page << 'j("#selection-box").hide();'
        end
      rescue ActiveRecord::RecordNotFound => exception
        flash[:notice] = "#{t('flash_msg2')} , #{t('registration_course_not_found')} ."
        logger.info "[FedenaRescue] AR-Record_Not_Found #{exception.to_s}"
        log_error exception
        redirect_to :controller=>:user ,:action=>:dashboard
      end
    end
  end

  def applicant_registration_report_pdf
    render :pdf => 'applicant_registration_report_pdf'
  end

  def create
    @registration_course = RegistrationCourse.find(params[:applicant][:registration_course_id])
    section_errors, field_errors, addl_fields_error_list = ApplicationSection.find_errors_in_form_submission(@registration_course.id, params[:applicant])
    if section_errors.present? || field_errors.present? || addl_fields_error_list.present?
      @applicant = Applicant.new
      section_errors.each{|f| @applicant.errors.add_to_base("#{t(f)} section is missing from form")} if section_errors.present?
      field_errors.each{|f| @applicant.errors.add_to_base("#{t(f)} field is missing from form")} if field_errors.present?
      addl_fields_error_list.each{|f| @applicant.errors.add_to_base("#{f} field is missing from form")} if addl_fields_error_list.present?
      render :partial=>"applicant_errors", :object=>@applicant
    else
      subject_amounts=@registration_course.course.subject_amounts
      if params[:applicant][:subject_ids].nil?
        params[:applicant][:subject_ids]=[]
        @ele_subject_amount=0
      else
        @ele_subject_amount=subject_amounts.find(:all,:conditions => {:code => params[:applicant][:subject_ids]}).flatten.compact.map(&:amount).sum.to_f
      end
      guardians =  params[:applicant][:applicant_guardians_attributes]
      @applicant = Applicant.new(params[:applicant])
      @applicant.guardians =  params[:applicant][:applicant_guardians_attributes]
      @applicant.submitted = false
      if @registration_course.is_subject_based_registration
        if @registration_course.subject_based_fee_colletion == true
          @normal_subject_amount=@registration_course.get_major_subjects_amount
          @registration_amount = @normal_subject_amount+@ele_subject_amount+@registration_course.amount.to_f
        else
          @registration_amount = @ele_subject_amount+@registration_course.amount.to_f
        end
      else
        @registration_amount = @registration_course.amount.to_f      
      end
      @applicant.amount = @registration_amount.to_f
      @applicant.has_paid=true if @applicant.amount==0.0
      if @applicant.save
        #flash[:notice] = t('flash_success')
        obj = {:resp_text=>"saved_successfully",:redirect_url=>url_for(:controller=>"applicants",:action=>"preview_application",:id=>@applicant.id)}
        render :json=>obj
        #render :js => "window.location = '#{success_applicants_path(:id=>@applicant.id)}'"
      else
        render :partial=>"applicant_errors", :object=>@applicant
      end
    end
  end
  
  def preview_application
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],false, :include=>[:applicant_previous_data,:application_status,:applicant_guardians,:applicant_addl_values,:applicant_additional_details,:applicant_addl_attachments])
    @registration_course = @applicant.registration_course
    @application_section = @registration_course.application_section
    unless @application_section.present?
      @application_section = ApplicationSection.find_by_registration_course_id(nil)
    end
    @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
    @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
    @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @currency = currency
  end
  
  def edit_application
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],false, :include=>[:applicant_previous_data,:application_status,:applicant_guardians,:applicant_addl_values,:applicant_additional_details,:applicant_addl_attachments])
    @registration_course = @applicant.registration_course
    @application_section = @registration_course.application_section
    unless @application_section.present?
      @application_section = ApplicationSection.find_by_registration_course_id(nil)
    end
    @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
    @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
    @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @subjects = @registration_course.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
    @selected_subject_ids = @applicant.subject_ids.nil? ? [] : @applicant.subject_ids
    @mandatory_attributes = []
    @mandatory_guardian_attributes = []
    @mandatory_previous_attributes = []
    @mandatory_addl_attributes =[]
    @mandatory_student_attributes = []
    @mandatory_attachment_attributes = []
    @currency = currency
    @application_fee = @registration_course.amount.to_f
    if @registration_course.is_subject_based_registration
      @subjects = @registration_course.get_elective_subjects_and_amount
      if @registration_course.subject_based_fee_colletion == true
        @normal_subject_amount = @registration_course.get_major_subjects_amount
        @total_fee = @application_fee + @normal_subject_amount
      else
        @normal_subject_amount = 0.to_f
        @total_fee = @application_fee + 0.to_f
      end
    end
    
  end
  
  def update_application
    @registration_course = RegistrationCourse.find(params[:applicant][:registration_course_id])
    subject_amounts = @registration_course.course.subject_amounts
    if params[:applicant][:subject_ids].nil?
      params[:applicant][:subject_ids]=[]
      @ele_subject_amount=0.to_f
    else
      @ele_subject_amount=subject_amounts.find(:all,:conditions => {:code => params[:applicant][:subject_ids]}).flatten.compact.map(&:amount).sum.to_f
    end
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],false)
    if @registration_course.is_subject_based_registration
      if @registration_course.subject_based_fee_colletion == true
        @normal_subject_amount = @registration_course.get_major_subjects_amount
        @registration_amount = @normal_subject_amount+@ele_subject_amount+@registration_course.amount.to_f
      else
        @registration_amount = @ele_subject_amount+@registration_course.amount.to_f
      end
    else
      @registration_amount = @registration_course.amount.to_f      
    end
    @applicant.amount = @registration_amount.to_f
    @applicant.has_paid = true if @applicant.amount==0.0
    if @applicant.update_attributes(params[:applicant])
      @applicant.save
      flash[:notice] = t('application_updated_successfully')
      obj = {:resp_text=>"saved_successfully",:redirect_url=>url_for(:controller=>"applicants",:action=>"preview_application",:id=>@applicant.id)}
      render :json=>obj
      #render :js => "window.location = '#{success_applicants_path(:id=>@applicant.id)}'"
    else
      render :partial=>"applicants/applicant_errors", :object=>@applicant
    end
  end
  
  def submit_application
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],false)
    @applicant.amount = (@applicant.amount == @applicant.total_amount) ? @applicant.amount : @applicant.total_amount
    registration_course = @applicant.registration_course
    application_fee = registration_course.amount.to_f
    normal_subject_amount = 0.to_f
    elective_subject_amounts = Hash.new
    if registration_course.is_subject_based_registration
      elective_subject_amounts = registration_course.get_applicant_elective_subject_amounts_hash(@applicant.subject_ids)
      if registration_course.subject_based_fee_colletion == true
        normal_subject_amount = registration_course.get_major_subjects_amount.to_f
      end
    end
    subject_amounts_hsh = Hash.new
    subject_amounts_hsh = {:application_fee => application_fee, :normal_subject_amount => normal_subject_amount, :elective_subject_amounts => elective_subject_amounts}
    @applicant.submitted = true
    if @applicant.amount == 0
      @applicant.has_paid=true
    end
    @applicant.subject_amounts = subject_amounts_hsh
    begin
      retries ||= 0  
      applicant_saved = @applicant.save
    rescue ActiveRecord::StatementInvalid => er
      if @applicant.reg_no.present?
        @applicant.reg_no = @applicant.reg_no.to_i + 1
      end
      # run code again  to  avoid reg no duplications
      retry if (retries += 1) < 3
    end
    if applicant_saved
      unless @applicant.pin_number.blank?
        pin_no = PinNumber.find_by_number(@applicant.pin_number)
        unless pin_no.is_registered.present?
          pin_no.update_attributes(:is_registered => true)
        else
          flash[:notice]=t('flash4')
          redirect_to "/register" and return
        end
      end
      flash[:notice] = t('flash_success')
      redirect_to :controller=>"applicants",:action=>"success",:id=>@applicant.print_token
    end
  end
  
  def discard_application
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],false)
    if @applicant.destroy
      flash[:notice] = t('application_discarded_successfully')
    end
    redirect_to "/register"
  end


  def success
    current_school_name = Configuration.find_by_config_key('InstitutionName').try(:config_value)
    @currency = currency
    @applicant = Applicant.find_by_print_token_and_submitted!(params[:id],true, :include=>[:applicant_previous_data,:application_status,:applicant_guardians,:applicant_addl_values,:applicant_additional_details,:applicant_addl_attachments])
    @financetransaction = FinanceTransaction.last(
      :joins => "INNER JOIN finance_transaction_receipt_records ftrr
                                              ON ftrr.finance_transaction_id = finance_transactions.id
                                       LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["payee_id = ? AND payee_type = 'Applicant' AND
                                            (fa.id IS NULL OR fa.is_deleted = false)", @applicant.id])
    @online_transaction_id = nil
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      online_payment = Payment.find_by_payee_id_and_payee_type_and_status_and_amount(@applicant.id,'Applicant',true,@applicant.amount)
      if online_payment.present?
        @online_transaction_id = online_payment.gateway_response[:transaction_reference]
      end
    end
    @registration_course = @applicant.registration_course
    @application_section = @registration_course.application_section
    unless @application_section.present?
      @application_section = ApplicationSection.find_by_registration_course_id(nil)
    end
    @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
    @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
    @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @financial_year_enabled = true
  end

  def complete
    @applicant = Applicant.find(params[:applicant])
  end


  def load_common
    @countries = Country.all
  end


  def print_application
    @currency = currency
    @applicant = Applicant.find_by_print_token_and_submitted!(params[:print_token],true, :include=>[:applicant_previous_data,:application_status,:applicant_guardians,:applicant_addl_values,:applicant_additional_details,:applicant_addl_attachments])
    @financetransaction=@applicant.finance_transaction
    @online_transaction_id = nil
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      online_payment = Payment.find_by_payee_id_and_payee_type_and_status_and_amount(@applicant.id,'Applicant',true,@applicant.amount)
      if online_payment.present?
        @online_transaction_id = online_payment.gateway_response[:transaction_reference]
      end
    end
    @registration_course = @applicant.registration_course
    @application_section = @registration_course.application_section
    unless @application_section.present?
      @application_section = ApplicationSection.find_by_registration_course_id(nil)
    end
    @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
    @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
    @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    
    #    @elective_name=[]
    #    if params[:token_check].nil?
    #      @applicant = Applicant.find(params[:id])
    #    else
    #      @applicant ||= Applicant.find_by_print_token(params[:token_check][:print_token])
    #    end
    #    @electives=@applicant.subject_ids
    #    @electives.each do |elec|
    #      @elective_name<<Subject.find_by_code(elec)
    #    end
    #    @addl_values = @applicant.applicant_addl_values
    #    @additional_details = @applicant.applicant_additional_details
    #    @financetransaction=FinanceTransaction.find_by_title("Applicant Registration - #{@applicant.reg_no} - #{@applicant.full_name}")
    #    if FedenaPlugin.can_access_plugin?("fedena_pay")
    #      @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
    #      if @active_gateway.nil?
    #        render :pdf => "application",:zoom => 0.90 and return
    #      end
    #      if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_applicant_registration_fee_enabled?)
    #        online_payment = Payment.find_by_payee_id_and_payee_type(@applicant.id,'Applicant')
    #        if online_payment.nil?
    #          @online_transaction_id = @applicant.has_paid == true ? nil : t('fee_not_paid')
    #        else
    #          @online_transaction_id = online_payment.gateway_response[:transaction_reference]
    #        end
    #      else
    #        @online_transaction_id = nil
    #      end
    #    end
    render :pdf => "application",:zoom => 0.90#,:show_as_html=>true
  end

  def registration_return
    @currency = currency
    @applicant = Applicant.find(params[:id])
    hostname = "#{request.protocol}#{request.host_with_port}"
    if params[:create_transaction].present?
    
      gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>params[:transaction_ref], :status=>0})
      gateway_record.update_attribute('status', true) if gateway_record.present?
      @active_gateway = gateway_record.present? ? gateway_record.gateway : 0
      if (@active_gateway.nil? or @active_gateway==0)
        flash[:notice] = "#{t('already_payed')}"
        redirect_to :action => "success" , :params => {:id => @applicant.print_token} and return
      else
        @custom_gateway = CustomGateway.find_by_id(@active_gateway)
      end
    
      gateway_response = Hash.new
      if params[:return_hash].present?
        return_value = params[:return_hash]
        @decrypted_hash = PaymentConfiguration.payment_decryption(return_value)
      end
      if @custom_gateway.present?
        @custom_gateway.gateway_parameters[:response_parameters].each_pair do|k,v|
          unless ["success_code","pending_code"].include?(k.to_s)
            gateway_response[k.to_sym] = params[:return_hash].present? ? @decrypted_hash[v.to_sym] : params[v.to_sym]
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
          flash[:notice] = "#{t('payment_success')} <br>  #{t('payment_reference')} : #{online_transaction_id}"
          if @applicant.email.present?
            begin
              Delayed::Job.enqueue(OnlinePayment::PaymentMail.new("Applicant",@applicant.email,@applicant.full_name,@custom_gateway.name,payment.gateway_response[:amount].to_f,online_transaction_id,payment.gateway_response,school_details,hostname))
            rescue Exception => e
              puts "Error------#{e.message}------#{e.backtrace.inspect}"
              return
            end
          end
        else
          flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{gateway_status.to_s == 'true' ? 'Transaction Amount mismatch' : payment.gateway_response[:reason_code]} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
        end
      else
        flash[:notice] = "#{t('already_payed')}"
      end
      redirect_to :action => "success" , :params => {:id => @applicant.print_token}
    end
  end

  def applicant_registration_report_csv
    @start_date = (params[:start_date]).to_date
    @end_date = (params[:end_date]).to_date
            
    filter_by_account, account_id = account_filter 
      
    if filter_by_account
      filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
      filter_values = [account_id]
      joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
    else        
      filter_conditions = joins = ""
      filter_values = []
    end
    
    @income_category = FinanceTransactionCategory.find_by_name('Applicant Registration')
    @transactions = @income_category.finance_transactions.all( :include => :transaction_ledger, 
      :joins => "INNER JOIN applicants on finance_transactions.payee_id = applicants.id #{joins} 
                      INNER JOIN registration_courses on registration_courses.id = applicants.registration_course_id",
      :select => "finance_transactions.*, registration_courses.course_id AS c_id, applicants.reg_no AS applicant_reg_no",
      :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
        @start_date, @end_date ] + filter_values).group_by(&:c_id)
    
    total = 0
    csv_string = FasterCSV.generate do |csv|
      csv << t('applicant_regi_label')
      csv << t('fees_collection')
      csv << [t('start_date'), format_date(@start_date),t('to'),format_date(@end_date)]
      csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
      csv << ""
      csv << ["", t('name'), t('amount'), t('transaction_date'), t('receipt_no')]
      @transactions.each do |course,income|
        csv << Course.find_by_id(course).full_name
        csv << ""
        income.each do |i|
          csv << ["","#{i.payee.full_name} (#{i.applicant_reg_no})",precision_label(i.amount),format_date(i.transaction_date),i.receipt_number]
          total+=i.amount.to_f
        end
      end
      csv << ""
      csv << [t('net_income'),"",precision_label(total)]
    end
    filename = "#{t('applicant_regi_label')}-#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end



  def load_lang
    if params[:lang]
      session[:register_lang] = params[:lang]
    else
      system_language = Configuration.get_config_value("Locale") || "en"
      session[:register_lang] = system_language
    end
    session[:language] = session[:register_lang]
    I18n.locale = "#{session[:register_lang]}-ch"
  end
  
  def set_translate_options
    CustomTranslation.translate_options ||= CustomTranslation.store_cache
  end
  
  def unasign_translate_options
    CustomTranslation.translate_options = nil
  end
  
  def generate_fee_receipt_pdf
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    finance_transactions = @applicant.finance_transaction.to_a
    #    finance_transactions = FinanceTransaction.find_all_by_id(params[:transaction_id], 
    #      :include => :finance_transaction_receipt_record)
    template_ids = []
    @transactions = finance_transactions.map do |ft| 
      receipt_data = ft.receipt_data
      template_ids << receipt_data.template_id = ft.fetch_template_id
      receipt_data
    end
    template_ids = template_ids.compact.uniq
    configs = ['PdfReceiptSignature', 'PdfReceiptSignatureName', 
      'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
    #    fetch_config_hash configs
    @config = Configuration.get_multiple_configs_as_hash configs
    
    @default_currency = Configuration.default_currency
    #    template_ids = finance_transactions.map {|x| x.fetch_template_id }.uniq.compact
    @data = {:templates => template_ids.present? ? FeeReceiptTemplate.find(template_ids).group_by(&:id) : {} }
    render :pdf => 'generate_fee_receipt_pdf',
      :template => "finance_extensions/receipts/generate_fee_receipt_pdf.erb",
      :margin =>{:top => 2, :bottom => 20, :left => 5, :right => 5},
      :header => {:html => { :content=> ''}},  :footer => {:html => {:content => ''}}, 
      :show_as_html => params.key?(:debug)
    #    @config = Configuration.get_multiple_configs_as_hash ['PdfReceiptSignature', 'PdfReceiptSignatureName', 'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
    #    @default_currency = Configuration.default_currency
    #    @currency = currency
    #    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    #    @financetransaction = @applicant.finance_transaction
    #    @registration_course = @applicant.registration_course
    #    @subject_amounts = @applicant.subject_amounts
    #    @application_fee = @applicant.amount.to_f
    #    if @subject_amounts.present?
    #      @application_fee = @subject_amounts[:application_fee]
    #      @elective_subject_amount = 0.to_f
    #      @total_fee = @application_fee + 0.to_f
    #      elective_subject_hash = @subject_amounts[:elective_subject_amounts]
    #      @elective_subject_amount = elective_subject_hash.values.sum.to_f
    #      active_batch_ids = @registration_course.course.batches.all(:conditions=>{:is_active=>true,:is_deleted=>false}).collect(&:id)
    #      @elective_subjects = Subject.find_all_by_code_and_batch_id(elective_subject_hash.keys,active_batch_ids).map(&:name).flatten.compact.uniq.join(', ')
    #      @normal_subject_amount = @subject_amounts[:normal_subject_amount].present? ? @subject_amounts[:normal_subject_amount] : 0.to_f
    #      @total_fee = @application_fee+@normal_subject_amount+@elective_subject_amount
    #    end
    #    @online_transaction_id = nil
    #    if FedenaPlugin.can_access_plugin?("fedena_pay")
    #      online_payment = Payment.find_by_payee_id_and_payee_type_and_status_and_amount(@applicant.id,'Applicant',true,@applicant.amount)
    #      if online_payment.present?
    #        @online_transaction_id = online_payment.gateway_response[:transaction_reference]
    #      end
    #    end
    #    render :pdf => 'generate_fee_receipt_pdf',:margin =>{:top=>2,:bottom=>20,:left=>5,:right=>5},:header => {:html => { :content=> ''}}, :footer => {:html => {:content => ''}}, :show_as_html => params.key?(:debug)
  end
  
  private

  def school_details
    name=Configuration.get_config_value('InstitutionName').present? ? "#{Configuration.get_config_value('InstitutionName')}," :""
    address=Configuration.get_config_value('InstitutionAddress').present? ? "#{Configuration.get_config_value('InstitutionAddress')}," :""
    Configuration.get_config_value('InstitutionPhoneNo').present?? phone="#{' Ph:'}#{Configuration.get_config_value('InstitutionPhoneNo')}" :""
    return (name+"#{' '}#{address}"+"#{phone}").chomp(',')
  end

end
