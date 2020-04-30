class AdvancePaymentFeesController < ApplicationController

  filter_access_to :all
  before_filter :check_permission
  before_filter :first_rule, :only => [:category_by_students, :fee_head_by_student,
    :list_online_fee_head_form, :category_wise_transaction_by_student,
    :wallet_particular_report_by_collection, :wallet_deduction_transaction_report, :wallet_transactions_by_student, 
    :payment_history, :category_wise_collections
  ]
  before_filter :find_configuration_values, :only => [:advance_payment_by_student, :advance_fees_index,
    :list_online_fee_head_form, :initialize_advance_payment, :making_payment, :advance_fee_students]
  before_filter :set_precision
  include ReceiptPrinterHelper
  skip_before_filter :verify_authenticity_token
  helper_method(:get_stylesheet_for_current_receipt_template, :get_stylesheet_for_receipt_template,
    :get_current_receipt_partial, :get_partial_for_current_receipt_template, :get_receipt_partial, :has_tax?,
    :has_previously_paid_fees?, :has_particulars?, :has_discount?, :has_fine?, :has_due?, :has_roll_number?)

  check_request_fingerprint :submit_fees

  # find the configuration values for advance fees payment
  def find_configuration_values
    @advance_fee_config = Configuration.advance_fee_payment_enabled?
    @enable_online_payment = PaymentConfiguration.find_by_config_key("enabled_online_payment").try(:config_value) || "true"
    @active_gateways = PaymentConfiguration.config_value("fedena_gateway")
  end

  def first_rule
    @student = Student.find_by_id(params[:student_id])
  end

  def check_permission
    @advance_fee_payment = Configuration.find_by_config_key_and_config_value("AdvanceFeePaymentForStudent", true)
    if @advance_fee_payment.present?
      return true
    else
      flash[:notice] = "#{t('flash_msg2')} , #{t('flash_msg4')}"
      redirect_to :controller=>:user ,:action=>:dashboard
    end
  end

  def advance_fees_index

  end

  # advance fee categories list and edit
  def advance_fee_categories_list
    @advance_fee_categories = AdvanceFeeCategory.all(:conditions =>
        ['advance_fee_categories.financial_year_id = ? AND advance_fee_categories.is_deleted = false AND advance_fee_categories.is_enabled = true',
        FinancialYear.current_financial_year[:id]]).paginate(:per_page => 10, :page => params[:page])
    if request.post?
      render :update do |page|
        page.replace_html 'category_list', :partial => "category_list"
      end
    end
  end

  # edit advance fee category
  def edit_advance_fee_category
    @advance_fee_category = AdvanceFeeCategory.find_by_id(params[:id])
    @a_f_c_batches = @advance_fee_category.advance_fee_category_batches
    @batches = Batch.active
    render :update do |page|
      page.replace_html 'modal-box', :partial => 'edit_advance_fee_category'
      page << "Modalbox.show($('modal-box'), {title: ''});"
    end
  end

  # updating advance fee category
  def update_advance_fee_category
    advance_fee_category = AdvanceFeeCategory.find_by_id(params[:id])
    advance_fee_category.update_attributes(params[:advance_fee_category].except(:batches))
    advance_fee_category.validate_category_batches(params[:batches])
    flash[:notice] = t('advance_fee_category_updated_text')
    render :update do |page|
      page << "Modalbox.hide($('modal-box'), {title: ''});"
      page.redirect_to :controller => "advance_payment_fees", :action =>"advance_fee_categories_list"
    end
  end

  # delete advance fee category
  def delete_advance_fee_category
    advance_fee_category = AdvanceFeeCategory.find_by_id(params[:id])
    advance_fee_category.update_attributes(:is_deleted => true, :is_enabled => false)
    flash[:notice] = t('advance_fee_category_deleted_text')
    redirect_to :cotroller => "advance_payment_fees", :action => "advance_fee_categories_list"
  end

  # new advance fee category
  def advance_fees_category_new
    @advance_fee_category = AdvanceFeeCategory.new
    @current_financial_year = FinancialYear.current_financial_year
    @batches = Batch.active
    respond_to do |format|
      format.js { render :action => 'advance_fees_category_new' }
    end
  end

  def show_category_detail_fields
    @academic_year = AcademicYear.find_by_id(params[:academic_year_id])
    @current_financial_year = FinancialYear.find_by_id(FinancialYear.current_financial_year_id)
    @advance_fee_category = AdvanceFeeCategory.new
    @batches = Batch.find_all_by_is_active_and_academic_year_id(true, @academic_year.id)
    render :update do |page|
      page.replace_html 'category-sec', :partial => "year_wise_batch_list" if params[:academic_year_id].present?
      page.replace_html 'category-sec', :text => "" if params[:academic_year_id] == ""
    end
  end

  # def wallet_report

  # end

  # create the advance fees category
  def advance_fees_category_create
    if request.post?
      if params[:batches].present?
        @advance_fee_category = AdvanceFeeCategory.new(params[:advance_fee_category])
        unless @advance_fee_category.save
          @error_list = true
        else
          AdvanceFeeCategoryBatch.create_category_batches(@advance_fee_category.id, params[:batches])
        end
      else
        @error_list = true
        @advance_fee_category = AdvanceFeeCategory.new(params[:advance_fee_category])
        @advance_fee_category.valid?
        @batch_error = true
      end
      if @error_list.nil?
        flash[:notice] = t('advance_fee_category_created')
        render :update do |page|
          page << "Modalbox.hide($('modal-box'), {title: ''});"
          page.redirect_to :controller => "advance_payment_fees", :action =>"advance_fee_categories_list"
        end
      else
        respond_to do |format|
          format.js { render :action => 'advance_fees_category_create' }
        end
      end
    end
  end

  # show advance fee category batches
  def show_advance_fees_category_batches
    @advance_fee_category = AdvanceFeeCategory.find_by_id(params[:id])
    if @advance_fee_category.present?
      @batches=Batch.active.find(:all, :joins => [{:advance_fee_category_batches => :advance_fee_category}, :advance_fee_categories],
        :conditions => "advance_fee_categories.id = #{@advance_fee_category.id}", :order => "courses.code ASC").uniq
    end
    render :update do |page|
      page << "build_modal_box({'title' : '#{t('batch_list')}', 'popup_class' : 'show_batches_popup'})"
      page.replace_html 'popup_content', :partial => 'list_category_batch'
    end
  end

  # advance fee collection index
  def advance_fees_collection_index
    @batches = Batch.active
  end

  # list all students in the selected batch
  def list_students_by_batch
    if params[:batch_id].present?
      @batch = Batch.find_by_id(params[:batch_id])
      @students = @batch.students
      render :update do |page|
        page.replace_html "fee_collections", :partial => 'students_list'
        page.replace_html 'flash-div', :text => ""
        page.replace_html "financial_year_details", :partial => 'finance/financial_year_info'
      end
    else
      render :update do |page|
        page.replace_html "fee_collections", :plane => ""
        page.replace_html "fee_head_section_main", :plane => ""
        page.replace_html 'flash-div', :text => ""
        page.replace_html "financial_year_details", :partial => 'finance/financial_year_info'
      end
    end
  end

  # payment fee head by student
  def fee_head_by_student
    if params[:student_id].present?
      @search_query = params[:query]
      unless @student.nil?
        @advance_fee_categories = AdvanceFeeCategory.all(:joins => [:advance_fee_category_batches], :conditions =>
            ['advance_fee_categories.financial_year_id = ? AND advance_fee_category_batches.batch_id = ? AND advance_fee_category_batches.is_active = ? AND advance_fee_categories.is_deleted = false AND advance_fee_categories.is_enabled = true',
            FinancialYear.current_financial_year[:id], @student.batch_id, true])
      end
      @paid_fees_collections = fetch_paid_collections.paginate(:page => params[:page], :per_page => 10)
      @advance_fees_collection = AdvanceFeeCollection.new()
      render :update do |page|
        page.replace_html 'flash-div', :text => ""
        page.replace_html "fee_head_section_main", :partial => "fee_head_by_student"
      end
    else
      render :update do |page|
        page.replace_html 'flash-div', :text => ""
        page.replace_html "fee_head_section_main", :plane => ""
      end
    end
  end

  # selecting payment mode for transactions
  def select_payment_mode
    @payment_mode = params[:payment_mode]
    render :update do |page|
      page.replace_html "payment_mode_details", :partial => "advance_payment_fees/advance_fees_forms/select_payment_modes"
    end
  end

  # submitting the fees
  def submit_fees
    @advance_fee_collection = AdvanceFeeCollection.new(params[:advance_fees_collection])
    @student = @advance_fee_collection.student
    c_sql = "AND advance_fee_categories.online_payment_enabled = true" if (@current_user.student? or @current_user.parent?)
    @advance_fee_categories = AdvanceFeeCategory.all(:joins => [:advance_fee_category_batches], :conditions =>
        ["advance_fee_categories.financial_year_id = ? AND advance_fee_category_batches.batch_id = ? AND advance_fee_category_batches.is_active = ? AND advance_fee_categories.is_deleted = false #{c_sql}",
        FinancialYear.current_financial_year[:id], @student.batch_id, true])
    if @advance_fee_collection.save
      @advance_fee_collection.create_the_transaction_data
      @paid_fees_collections = fetch_paid_collections.paginate(:page => params[:page], :per_page => 10)
      render :update do |page|
        page.replace_html 'flash-div', :text=>"<p class='flash-msg'>#{t('transaction_created')}</p>"
        page.replace_html "fee_head_section_main", :partial => "fee_head_by_student"
      end
    elsif @advance_fee_collection.errors.present?
      render :update do |page|
        flash[:notice] = t('transaction_faild')
        page.redirect_to :action => "advance_fees_collection_index"
      end
    end
  end
  
  # advance fee student profile page
  def advance_fee_students
    if params[:student_type] == 'former'
      @student = ArchivedStudent.find_by_former_id(params[:id].to_i) 
    else
      @student = Student.find_by_id(params[:id])
    end
    student_id = @student.class.name == 'Student' ? @student.id : @student.former_id
    @batches = @student.all_batches.reverse
    @advance_fee_config = Configuration.advance_fee_payment_enabled?
    @enable_online_payment = PaymentConfiguration.find_by_config_key("enabled_online_payment").try(:config_value) || "false"
    @active_gateways = PaymentConfiguration.config_value("fedena_gateway")
    @advance_fee_category_collections = AdvanceFeeCollection.all(:joins => [[:advance_fee_category_collections => [:advance_fee_category]]], :conditions => {:student_id => student_id, 
        :advance_fee_categories => {:financial_year_id => FinancialYear.current_financial_year[:id]}}, 
      :select => "advance_fee_categories.name as category_name, SUM(advance_fee_category_collections.fees_paid) as amount, advance_fee_collections.batch_id as batch_id, max(advance_fee_collections.date_of_advance_fee_payment) as last_paid_date", 
      :group => "advance_fee_category_collections.advance_fee_category_id")
  end


  def payment_history
    @paid_fees_collections = fetch_paid_collections.paginate(:page => params[:page], :per_page => 10)
    render :update do |page|
      page.replace_html 'payment_history', :partial => 'payment_history_head'
    end
  end

  # advance fee payment by student
  def advance_payment_by_student
    @student = Student.find_by_id(params[:id])
    @paid_fees_collections = fetch_paid_collections.paginate(:page => params[:page], :per_page => 10)
    @advance_fee_categories = AdvanceFeeCategory.all(:joins => [:advance_fee_category_batches], :conditions =>
        ['advance_fee_categories.financial_year_id = ? AND advance_fee_category_batches.batch_id = ? AND advance_fee_category_batches.is_active = ? AND advance_fee_categories.is_deleted = false AND advance_fee_categories.is_enabled = true AND advance_fee_categories.online_payment_enabled = true',
        FinancialYear.current_financial_year[:id], @student.batch_id, true])
    @advance_fee_collection = AdvanceFeeCollection.new
    @available_gateways = CustomGateway.available_gateways
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway") || []
  end

  # initializing online payment
  def initialize_advance_payment
    @student = Student.find(params[:advance_fees_collection][:student_id])
    @transaction_date = Date.today_with_timezone
    if (FedenaPlugin.can_access_plugin?("fedena_pay") and @enable_online_payment and
          PaymentConfiguration.op_enabled?)
      student_new_advance_payment = making_payment_request
      @amount_total = params[:advance_fees_collection][:fees_paid]
      if student_new_advance_payment.save
        @active_gateways = PaymentConfiguration.config_value("fedena_gateway")
        @active_gateway = PaymentConfiguration.first_active_gateway
        @payment_id = student_new_advance_payment.id
        render :layout => false
      else
        redirect_to :back
      end
    else
      flash[:notice] = t('online_payment_is_currently_disabled')
      redirect_to :controller => "user",:action => "dashboard"
    end
  end

  # changing gateways
  def change_gateway_options
    @active_gateway = params[:g_id]
    @payment_id = params[:payment_id]
    render :update do |page|
      page.replace_html 'proceed_button',:partial => "proceed_button"
    end
  end

  # online payment process
  def making_payment
    enable_all_fee = PaymentConfiguration.find_by_config_key("enabled_pay_all").try(:config_value) || "true"
    if (FedenaPlugin.can_access_plugin?("fedena_pay") and PaymentConfiguration.config_value("enabled_fees").present? and
          PaymentConfiguration.op_enabled? and enable_all_fee == "true")
      @student_payment = PaymentRequest.find_by_id(params[:payment_id])
      gateway = params[:gateway_id]
      @custom_gateway = CustomGateway.find(gateway)
      if PaymentConfiguration.is_encrypted(@custom_gateway)==true
        hash_for_user_payment = user_payment_hash
        @encrypted_hash = PaymentConfiguration.payment_encryption(gateway,hash_for_user_payment,"all")
      end
      render :layout => false
    else
      flash[:notice] = t('online_payment_is_currently_disabled')
      redirect_to :controller => "user",:action => "dashboard"
    end
  end

  # start the online transactions
  def start_transaction
    if params[:create_transaction].present?
      gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>params[:transaction_ref], :status=>0})
      if gateway_record.present?
        gateway_record.update_attribute('status', true)
        active_gateway = gateway_record.gateway
        hostname = "#{request.protocol}#{request.host_with_port}"
        advance_fees_transaction = AdvanceFeePayment.create_advance_fees_transactions(params,hostname,nil,active_gateway)
        if advance_fees_transaction.status
          flash[:notice] = "#{t('payment_success')} <br>  #{t('payment_reference')} : #{advance_fees_transaction.gateway_response[:transaction_reference]}"
        else
          flash[:notice] = "#{t('payment_failed')} <br>  #{t('reason')} : #{advance_fees_transaction.gateway_response[:reason_code]}"
        end
      else
        flash[:notice] = t('flash_msg3')
      end
    else
      flash[:notice] = t('payment_failed')
    end
    redirect_to :action => "advance_payment_by_student", :id => params[:id]
  end


  def advance_fees_receipt_pdf
    @advance_fee_collections = AdvanceFeeCollection.find_all_by_id(params[:advance_fee_collection_id])
    template_ids = []
    @transactions = @advance_fee_collections.map do |aft|
      receipt_data = aft.receipt_data
      template_ids << receipt_data.template_id = aft.fetch_template_id
      receipt_data
    end
    if template_ids.present?
      template_ids = template_ids.compact.uniq
      @data = {:templates => template_ids.present? ? FeeReceiptTemplate.find(template_ids).group_by(&:id) : {} }
    end
    render :pdf => "generate_fee_receipt_pdf", :with => @advance_fee_collection,
      :template => '/finance_extensions/receipts/generate_fee_receipt_pdf.erb',
      :margin =>{:top => 2, :bottom => 20, :left => 5, :right => 5},
      :header => {:html => { :content=> ''}},
      :footer => {:html => {:content => ''}},
      :show_as_html => params.key?(:debug)
  end

  # generting pdf receipt
  def generate_fee_receipt
    @advance_fee_collection = AdvanceFeeCollection.find_by_id(params[:advance_fee_collection_id])
    @transactions = @advance_fee_collection.receipt_data
    @data = {:templates => @transactions.template_id.present? ? FeeReceiptTemplate.all(@transactions.template_id).group_by(&:id) : {} }
    render :layout => "print"
  end

  # generating fees receipt pdf
  def online_fees_receipt_pdf
    @student = Student.find_by_id(params[:id])
    @batch = @student.batch
    c_sql = "AND advance_fee_categories.online_payment_enabled = true" if (@current_user.student? or @current_user.parent?)
    @advance_fee_categories = @student.batch.advance_fee_categories.all(:conditions =>
        ["advance_fee_categories.financial_year_id = ? AND advance_fee_categories.is_deleted = false AND advance_fee_categories.is_enabled = true
                                                                              #{c_sql}",
        FinancialYear.current_financial_year[:id]])
    @student_fee_collections = AdvanceFeeCollection.all(:joins => [:advance_fee_category_collections => [:advance_fee_category, [:advance_fee_collection => [:student => [:batch => [:course]]]]]], 
      :conditions => ['students.id = ?', @student.id], 
      :select => 'advance_fee_collections.fees_paid  as amount, advance_fee_collections.date_of_advance_fee_payment as date_of_payment,students.id as student_id, advance_fee_collections.receipt_data,
      advance_fee_collections.payment_mode as payment_mode,advance_fee_collections.payment_note as payment_note, advance_fee_collections.user_id', 
      :group => "advance_fee_collections.id")
    render :pdf => 'online_fee_receipt_pdf',
      :margin => {:left => 15, :right => 15},
      :show_as_html => params.key?(:debug)
  end

  # revert wallet transactions
  def delete_advance_fee_payment_transaction
    cancelled_transaction_data = OpenStruct.new
    advance_fee_collection = AdvanceFeeCollection.find(params[:adfc_id])
    @student = advance_fee_collection.student
    @advance_fees_collection = AdvanceFeeCollection.new()
    advance_fee_category_collections = advance_fee_collection.advance_fee_category_collections
    @advance_fee_categories = @student.batch.advance_fee_categories.all(:conditions =>
        ['advance_fee_categories.financial_year_id = ? AND advance_fee_categories.is_deleted = false AND advance_fee_categories.is_enabled = true',
        FinancialYear.current_financial_year[:id]])
    adfcc_ids = advance_fee_category_collections.collect(&:id)
    @paid_fees_collections = fetch_paid_collections.paginate(:page => params[:page], :per_page => 10)
    if @student.advance_fee_wallet.amount >= advance_fee_collection.fees_paid
      transaction_status = advance_fee_collection.create_cancelled_transaction_data(advance_fee_collection, params[:reason])
      advance_fee_category_collections = AdvanceFeeCategoryCollection.delete_transactions(adfcc_ids)
      if transaction_status
        if advance_fee_collection.destroy
          @paid_fees_collections = fetch_paid_collections.paginate(:page => params[:page], :per_page => 10)
          render (:update) do |page|
            page.replace_html 'flash-div', :text=>"<p class='flash-msg'>#{t('successfully_reverted')}</p>"
            page.replace_html "fee_head_section_main", :partial => 'fee_head_by_student'
          end
        end
      else
        render(:update) do |page|
          page.replace_html 'flash-div', :text=>"<p class='flash-msg'>#{t('revert_transaction_faild')}</p>"
          page.replace_html "fee_head_section_main", :partial => 'fee_head_by_student'
        end
      end
    else 
      render(:update) do |page|
        page.replace_html 'flash-div', :text=>"<p class='flash-msg'>#{t('insufficient_balance_wallet_text')}</p>"
        page.replace_html "fee_head_section_main", :partial => 'fee_head_by_student'
      end
    end
  end

  # wallet transactions report index
  def report_index
    @current_academic_year = AcademicYear.first(:conditions => {:is_active => true })
    @batches = Batch.all(:joins => [:course], :conditions => {:is_active => true, :is_deleted => false}, :order => "courses.course_name ASC")
  end

  def search_students
    students= Student.active.find(:all, :conditions=>["(first_name LIKE ? OR last_name LIKE ? OR admission_no LIKE ?)", "%#{params[:query]}%","%#{params[:query]}%","%#{params[:query]}%"])
    render :json=>{'query'=>params["query"],'suggestions'=>students.collect{|s| s.full_name+'('+s.admission_no+')'},'data'=>students.collect(&:id)  }
  end

  # listing all student wallet details
  def list_student_wallet_details
    if params[:student_id].present?
      @student = Student.find_by_id(params[:student_id])
      @course = @student.batch.course
    elsif params[:batch_id].present?
      @batch = Batch.find_by_id(params[:batch_id])
      @students = @batch.students
    end
    render :update do |page|
      page.replace_html 'wallet_report_section', :partial => "wallet_report_list"
    end
  end

  # generating wallet transactions report by student
  def wallet_transactions_by_student
    transactions = AdvanceFeeCategoryCollection.all(:joins => [:advance_fee_category, :advance_fee_collection], 
      :conditions => {:advance_fee_collections => {:student_id => @student.id}}, 
      :select => "sum(advance_fee_category_collections.fees_paid) as amount, advance_fee_categories.name as category_name, advance_fee_collections.student_id as student, advance_fee_categories.id as advance_fee_category_id", 
      :group => "advance_fee_categories.id")
    @wallet_credit_transactions = transactions.paginate(:page => params[:page_1], :per_page => 10)
    @wallet_debit_transactions = @student.advance_fee_deductions.paginate(:page => params[:page_2], :per_page => 10)
    render :update do |page|
      page.replace_html 'wallet_report_section', :partial => "wallet_transactions"
    end
  end

  # category wise transactions report by perticular student
  def category_wise_transaction_by_student
    @advance_fee_category = AdvanceFeeCategory.find_by_id(params[:category_id])
    @advance_fee_collections = @advance_fee_category.advance_fee_category_collections.all(:joins => [:advance_fee_collection],
      :conditions => {:advance_fee_collections => {:student_id => @student.id}})
    @collections_total_amount = 0
    @advance_fee_collections.each do |collection|
      @collections_total_amount += collection.fees_paid
    end
    render :update do |page|
      page.replace_html 'wallet_report_section', :partial => "wallet_report"
    end
  end

  # wallet deduction transactions report
  def wallet_deduction_transaction_report
    @student = Student.find_by_id(params[:student_id])
    @advance_fee_deduction = @student.advance_fee_deductions.find_by_id(params[:transaction_id])
    @finance_transaction = @advance_fee_deduction.finance_transaction
    render :update do |page|
      page.replace_html 'wallet_report_section', :partial => "fianance_transaction_report_on_wallet"
    end
  end

  # generating transaction report pdf
  def transaction_pdf
    if params[:course_id].present?
      @course = Course.find_by_id(params[:course_id])
      @students  = @course.students
    elsif params[:batch_id].present?
      @batch = Batch.find_by_id(params[:batch_id])
      @students  = @batch.students
    end
    render :pdf => 'transaction_pdf'
    # , :show_as_html => params[:d].present?
  end

  # generating wallet credit transactions report
  def wallet_credit_transaction_report
    fetch_accounts
    @target_action = "wallet_credit_transaction_report"
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @account_id = params[:fee_account_id]
    transactions = AdvanceFeeCollection.fetch_wallet_credit_transaction_details(@start_date, @end_date, @account_id)
    @advance_fee_categories = transactions.paginate(:page => params[:page], :per_page => 10)
    if request.xhr?
      render :update do |page|
        page.replace_html 'wallet_monthly_income_report_section', :partial => 'monthly_wallet_income_report_category_wise'
      end
    end
  end

  # generating wallet debit transactions report
  def wallet_debit_transaction_report
    @target_action = "wallet_debit_transaction_report"
    @batch_details = Hash.new
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @batch_details = AdvanceFeeCollection.fetch_wallet_expense_transaction_course_wise(@start_date, @end_date)
    course_ids = []
    @batch_details.each do |x|
      course_ids << x["course_id"]
    end
    @courses = course_ids.uniq
  end

  # generating course wise monthly report
  def course_wise_monthly_report
    fetch_accounts
    @target_action = "course_wise_monthly_report"
    @advance_fee_category = AdvanceFeeCategory.find_by_id(params[:category_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @course_details = Hash.new
    @account_id = params[:fee_account_id]
    @course_details = @advance_fee_category.fetch_batches_by_collection(@start_date, @end_date, @advance_fee_category.id, @account_id)
    @a = []
    @course_details.each do |x|
      @a << x["course_id"]
    end
    @a.uniq
    render :update do |page|
      page.replace_html 'wallet_monthly_income_report_section', :partial => "monthly_students_wallet_report_by_course"
    end
  end

  # generating batch wise wallet income transactions report
  def batch_wise_monthly_income_report
    fetch_accounts
    @target_action = "batch_wise_monthly_income_report"
    @advance_fee_category = AdvanceFeeCategory.find_by_id(params[:category_id])
    @batch = Batch.find_by_id(params[:batch_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @account_id = params[:fee_account_id]
    transactions = AdvanceFeeCollection.batch_wise_monthly_income_report(@start_date, @end_date, @advance_fee_category.id, @batch.id, @account_id)
    @student_fee_collections_by_batch = transactions.paginate(:page => params[:page], :per_page => 10)
    render :update do |page|
      page.replace_html 'wallet_monthly_income_report_section', :partial => "monthly_students_wallet_report_by_batch"
    end
  end

  # fetch category wise collection report
  def category_wise_collections
    fetch_accounts
    @target_action = "category_wise_collections"
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @account_id = params[:fee_account_id]
    @advance_fee_category = AdvanceFeeCategory.find(params[:category_id])
    transactions = AdvanceFeeCollection.category_wise_collection_report(@start_date, @end_date, @advance_fee_category.id, @student.id, @student.batch.id, @account_id)
    @advance_fee_collections = transactions.paginate(:page => params[:page], :per_page => 10)
    render :update do |page|
      page.replace_html 'wallet_monthly_income_report_section', :partial => "category_wise_collections"
    end
  end

  # generating batch wise wallet expense transactions report
  def batch_wise_monthly_expense_report
    @target_action = "batch_wise_monthly_expense_report"
    @batch = Batch.find_by_id(params[:batch_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @student_fee_collections_by_batch = FinanceTransaction.fetch_batch_wise_expense_report_wallet(@batch, @start_date, @end_date, params[:page])
    render :update do |page|
      page.replace_html 'wallet_monthly_expense_report_section', :partial => "monthly_wallet_exepese_report_batch_wise"
    end
  end

  # gateway warning message for zero amount
  def check_amount_to_pay
    render :update do |page|
      page.replace_html 'gateway_error', :text => "<p>#{t('gateway_error_text')}</p>"
    end
  end

  private

  # fetch accounts details
  def fetch_accounts
    @accounts_enabled = (Configuration.get_config_value("MultiFeeAccountEnabled").to_i == 1)
    @accounts = @accounts_enabled ? FeeAccount.all : []
  end

  # fetch paid collections
  def fetch_paid_collections
    @student.advance_fee_collections.all(:joins => [[:advance_fee_category_collections => [:advance_fee_category]]],
      :conditions => {:advance_fee_categories => {:financial_year_id => FinancialYear.current_financial_year[:id]}},
      :order => "advance_fee_collections.created_at desc", :group => :id)
  end

  # making online payment request
  def making_payment_request
    student_payment = PaymentRequest.new(
   		:user_id => @student.try(:user_id),
   		:transaction_parameters => wrapp_parameter
    )
  end

  # wrapping parameters for online payment initialization
  def wrapp_parameter
    {:advance_fees_collection => params[:advance_fees_collection]}
  end

end
