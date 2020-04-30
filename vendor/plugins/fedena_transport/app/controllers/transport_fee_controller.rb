class TransportFeeController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation
  require 'authorize_net'
  helper :authorize_net
  before_filter :login_required
  filter_access_to :all
  filter_access_to :student_profile_fee_details, :attribute_check => true, :load_method => lambda { params[:student_type] == 'Student' ? Student.find(params[:id]) : ArchivedStudent.find(params[:id]) }
  filter_access_to :transport_fee_receipt_pdf, :attribute_check => true, :load_method => lambda { FinanceTransaction.find params[:id] }
  before_filter :set_precision
  protect_from_forgery :except => [:student_profile_fee_details]
  before_filter :load_tax_setting, :only => [:transport_fee_collection_new, :transport_fee_collection_create,
    :collection_assign_students, :receiver_wise_collection_new, :receiver_wise_fee_collection_creation, :collection_creation_and_assign]
  before_filter :academic_year_id, :only => [:allocate_or_deallocate_fee_collection, :search_student, :list_students_by_batch, :list_employees_by_department, :list_students_for_collection, :choose_collection_and_assign]
  #fingerprint filter
  check_request_fingerprint :transport_fee_collection_create, :transport_fee_collection_pay, :delete_transport_transaction

  def index

  end

  def transport_fee_collection_new
    @fee_categories = FinanceFeeCategory.find(:all, :conditions => ["is_master = '#{1}' and is_deleted = '#{false}'"])
    @transport_fee_collection = TransportFeeCollection.new
    @batches = Batch.active
    #    @batches.reject! { |x| x.transports.blank? }
    @tax_slabs = TaxSlab.all if @tax_enabled
    @fines=Fine.active
    @start_date, @end_date = FinancialYear.fetch_current_range
  end

  def fine_list
    if params[:id].present?
      @fine=Fine.find(params[:id])
      @fine_rules=@fine.fine_rules.order_in_fine_days
      render :update do |page|
        page.replace_html "fine_list", :partial => "list_fines"
      end
    else
      render :update do |page|
        page.replace_html "fine_list", :text => ""
      end
    end
  end

  def send_reminder(transport_fee_collection, recipients)
    #
    #    subject = "#{t('fees_submission_date')}"
    #    Delayed::Job.enqueue(DelayedReminderJob.new(:sender_id => current_user.id,
    #        :recipient_ids => recipients,
    #        :subject => subject,
    #        :body => body))
    body = "#{t('transport_text')} #{t('fee_collection_date_for')} <b> #{transport_fee_collection.name} </b> #{t('has_been_published')} #{t('by')} <b>#{current_user.full_name}</b>, #{t('start_date')} : #{format_date(transport_fee_collection.start_date)}  #{t('due_date')} :  #{format_date(transport_fee_collection.due_date)} "
    links = {:target=>'view_fees',:target_param=>'student_id'}
    inform(recipients,body,'Finance',links)
  end

  def transport_fee_collection_create
    @transport_fee_collection = TransportFeeCollection.new
    @batches = Batch.active
    @batches.reject! { |x| x.transports.blank? }
    @tax_slabs = TaxSlab.all if @tax_enabled
    @fines = Fine.active
    if request.post?
      unless params[:transport_fee_collection].nil?
        @include_employee = params[:transport_fee_collection][:employee]
        @batchs = params[:transport_fee_collection][:batch_ids]
        parameters= params[:transport_fee_collection]
        parameters.delete("batch_ids")
        parameters.delete("employee")
        @transport_fee_collection=TransportFeeCollection.new(parameters)
        @transport_fee_collection.valid?
        @transport_fee_collection.errors.add_to_base("#{t('please_select_a_batch_or_emp')}") if (@batchs.blank? and @include_employee.blank?)
        if @transport_fee_collection.errors.empty?
          Delayed::Job.enqueue(DelayedTransportFeeCollectionJob.new(current_user, @batchs, @include_employee, params[:transport_fee_collection]))
          flash[:notice]="Collection is in queue. <a href='/scheduled_jobs/TransportFeeCollection/1'>Click Here</a> to view the scheduled job."
          redirect_to :action => 'transport_fee_collection_view'
        else
          render :action => 'transport_fee_collection_new'
        end
      end
    else
      render :action => 'transport_fee_collection_new'
    end
  end

  def transport_fee_collection_view
    #@transport_fee_collection = ''
    #@batches = Batch.active
    @transport_fee_collection = TransportFeeCollection.current_active_financial_year.paginate(
      :select => "distinct transport_fee_collections.*", :joins => [:transport_fees],
      :conditions => "transport_fees.receiver_type='Employee' and is_deleted=false",
      :per_page => 20, :page => params[:page])
  end

  def transport_fee_collection_date_edit
    @transport_fee_collection = TransportFeeCollection.find params[:id]
  end

  def transport_fee_collection_date_update
    @transport_fee_collection = TransportFeeCollection.find params[:id]
    render :update do |page|
      if @transport_fee_collection.update_attributes(params[:fee_collection])
        @user_type=params[:user_type]
        @transport_fee_collection.event.update_attributes(:start_date => @transport_fee_collection.due_date.to_datetime, :end_date => @transport_fee_collection.due_date.to_datetime)
        if @user_type=='employee'
          #         @transport_fee_collection = TransportFeeCollection.find(:all, :conditions=>'batch_id IS NULL')
          @transport_fee_collection = TransportFeeCollection.
            current_active_financial_year.paginate(:all,
            :select => "distinct transport_fee_collections.*",
            :joins => "INNER JOIN transport_fees
                               ON transport_fees.transport_fee_collection_id = transport_fee_collections.id AND transport_fees.receiver_type='Employee'",
            :conditions => ["transport_fees.is_active=true"],
            :per_page => 20, :page => params[:page])
          # @transport_fee_collection = TransportFeeCollection.paginate(:select => "distinct transport_fee_collections.*", :joins => [:transport_fees], :conditions => "transport_fees.receiver_type='Employee' and is_deleted=false and transport_fees.is_active=true", :per_page => 20, :page => params[:page])
          page << "Modalbox.hide()" unless params[:page]

          @user_type = 'employee'
          page.replace_html 'fee_collection_list', :partial => 'fee_collection_list'
          page.replace_html 'flash-box', :text => "<p class='flash-msg'>#{t('transport_fee.flash1')}</p>"
          page.replace_html 'batch_list', :text => ''
        elsif @user_type=='student'
          #         @transport_fee_collection = TransportFeeCollection.find_all_by_batch_id(params[:batch_id])
          @transport_fee_collection = TransportFeeCollection.current_active_financial_year.paginate(:all,
            :select => "distinct transport_fee_collections.*",
            :joins => "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id = transport_fee_collections.id
                        INNER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'",
            :conditions => "students.batch_id= #{params[:batch_id]} and transport_fees.is_active=true",
            :per_page => 20, :page => params[:page])

          @user_type = 'student'
          @batches = Batch.active
          page << "Modalbox.hide()" unless params[:page]
          #          page.replace_html 'batch_list', :partial=>'students_batch_list'
          page.replace_html 'fee_collection_list', :partial => 'fee_collection_list'
          page.replace_html 'flash-box', :text => "<p class='flash-msg'>#{t('transport_fee.flash1')}</p>"
        else
          page.replace_html 'batch_list', :text => ''
          page.replace_html 'fee_collection_list', :text => ''
        end
        #        page << "Modalbox.hide()"
      else
        @errors = true
        page.replace_html 'form-errors', :partial => 'transport_fee/errors', :object => @transport_fee_collection
        page.visual_effect(:highlight, 'form-errors')
      end

    end

  end

  def transport_fee_collection_edit
    @transport_fee_collection = TransportFee.find params[:id]
    @batches = Batch.active
    @selected_batches = [1]
  end

  def transport_fee_collection_update
    @transport_fee_collection = TransportFee.find params[:id]
    flash[:notice]="#{t('flash2')}" if @transport_fee_collection.update_attributes(params[:fee_collection]) if request.post?
    @transport_fee_collection_details = TransportFee.find_all_by_name(@transport_fee_collection.name)
  end

  def transport_fee_collection_delete
    @transport_fee_collection = TransportFee.find params[:id]
    @transport_fee_collection.destroy
    flash[:notice] = "#{t('flash3')}"
    redirect_to :controller => 'transport_fee', :action => 'transport_fee_collection_view'
  end

  def transport_fee_pay

    @transport_fee_collection_details = TransportFee.find params[:id]
    category_id = FinanceTransactionCategory.find_by_name("Transport").id
    transaction = FinanceTransaction.new
    transaction.title = @transport_fee_collection_details.transport_fee_collection.name
    transaction.category_id = category_id
    transaction.amount = @transport_fee_collection_details.bus_fare
    transaction.amount += params[:fine].to_f unless params[:fine].nil?
    transaction.fine_included = true unless params[:fine].nil?
    transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    transaction.payee = @transport_fee_collection_details.receiver
    transaction.finance = @transport_fee_collection_details
    unless transaction.save
      #      @transport_fee_collection_details.update_attribute(:transaction_id, transaction.id)
      render :text => transaction.errors.full_messages and return
    end
    @collection_id = params[:collection_id]
    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:collection_id])
    #    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(@transport_fee_collection_details.transport_fee_collection_id)
    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:collection_id], params[:id]) unless params[:id].nil?
    @user ||= @transport_fee.first
    @next_user = @user.next_user
    @prev_user = @user.previous_user
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
    render :update do |page|
      page.replace_html 'transport_fee_collection_details', :partial => 'transport_fee_collection_details'
    end
  end

  def transport_fee_defaulters_view
    @transport_fee_collection = ''
    @batches = Batch.all(
      :joins => {
        :students => {
          :transport_fees => :transport_fee_collection
        }
      },
      :conditions => ["batches.is_deleted=? and batches.is_active=? and transport_fee_collections.is_deleted=? and transport_fee_collections.due_date < ? and transport_fees.balance > ? and transport_fees.receiver_type='Student' and transport_fees.is_active = ? ", false, true, false, Date.today, 0, true], :group => "batches.id")
    render "transport_fee/fees_payment/transport_fee_defaulters_view"
  end

  def transport_fee_defaulters_details
    @transport_fee_details = TransportFeeCollection.find_all_by_name(params[:name])
    @transport_defaulters = @transport_fee_details.reject { |u| !u.transaction_id.nil? }
    render :update do |page|
      page.replace_html 'transport_fee_defaulters_details', :partial => 'transport_fee_defaulters_details'
    end
  end

  def transport_defaulters_fee_pay
    @transport_fee_defaulters_details = TransportFee.find params[:id]
    category_id = FinanceTransactionCategory.find_by_name("Transport").id
    transaction = FinanceTransaction.new
    transaction.title = @transport_fee_defaulters_details.transport_fee_collection.name
    transaction.category_id = category_id
    transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    transaction.amount = @transport_fee_defaulters_details.bus_fare
    transaction.amount += params[:fine].to_f unless params[:fine].nil?
    transaction.fine_included = true unless params[:fine].nil?
    transaction.payee = @transport_fee_defaulters_details.receiver
    transaction.finance = @transport_fee_defaulters_details
    #    if transaction.save
    #      @transport_fee_defaulters_details.update_attribute(:transaction_id, transaction.id)
    #    end
    @transport_defaulters = TransportFee.find_all_by_transport_fee_collection_id(@transport_fee_defaulters_details.transport_fee_collection_id)
    @transport_defaulters = @transport_defaulters.reject { |u| !u.transaction_id.nil? }
    @collection_id = params[:collection_id]
    @transport_fee_collection= TransportFeeCollection.find_by_id(params[:collection_id])
    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:collection_id])
    #@transport_fee = @transport_fee.reject{|u| !u.transaction_id.nil? }
    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:collection_id], params[:id]) unless params[:id].nil?
    @user ||= @transport_fee_collection.transport_fees.first(:conditions => ["transaction_id is null"])
    @next_user = @user.next_default_user unless @user.nil?
    @prev_user = @user.previous_default_user unless @user.nil?
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id) unless @user.nil?
    render :update do |page|
      page.replace_html 'defaulters_transport_fee_collection_details', :partial => 'defaulters_transport_fee_collection_details'
    end
  end

  def tsearch_logic # transport search fees structure
    @option = params[:option]
    if params[:option] == "student"
      if params[:query].length>= 3
        @students_result = Student.find(:all,
          :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
            "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
            "#{params[:query]}", "#{params[:query]}"],
          :order => "batch_id asc,first_name asc") unless params[:query] == ''
        @students_result.reject! { |s| s.transport_fees.empty? }
      else
        @students_result = Student.find(:all,
          :conditions => ["admission_no = ? ", params[:query]],
          :order => "batch_id asc,first_name asc") unless params[:query] == ''
        @students_result.reject! { |s| s.transport_fees.empty? }
      end if params[:query].present?
    else

      if params[:query].length>= 3
        @employee_result = Employee.find(:all,
          :conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                       OR employee_number = ? OR (concat(first_name, \" \", last_name) LIKE ? ))",
            "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
            "#{params[:query]}", "#{params[:query]}"],
          :order => "employee_department_id asc,first_name asc") unless params[:query] == ''
        @employee_result.reject! { |s| s.transport_fees.empty? }
      else
        @employee_result = Employee.find(:all,
          :conditions => ["(employee_number = ? )", "#{params[:query]}"],
          :order => "employee_department_id asc,first_name asc") unless params[:query] == ''
        @employee_result.reject! { |s| s.transport_fees.empty? }
      end if params[:query].present?
    end
    render :layout => false
  end

  def fees_student_dates
    if params[:payer_type].present?
      @payer_type=params[:payer_type]
      if params[:payer_type]=='Archived Student'
        @student = ArchivedStudent.find_by_former_id(params[:id])
        unless @student.present?
          flash[:notice] = "#{t('finance.no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
        @student.id=@student.former_id
      else
        @student = Student.find_by_id(params[:id])
        unless @student.present?
          flash[:notice] = "#{t('finance.no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
      end
    else
      @student = Student.find_by_id(params[:id])
      unless @student.present?
        flash[:notice] = "#{t('finance.no_payer')}"
        redirect_to :controller => 'user', :action => 'dashboard' and return
      end
    end
    @transport_fee_collection = TransportFeeCollection.find_by_id(params[:collection_id],
      :joins => "#{active_account_joins(true, 'transport_fee_collections')}",
      :conditions => "#{active_account_conditions(true, 'transport_fee_collections')}")
    @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today_with_timezone
    @transport_fees = TransportFee.active.all(
      :joins => "INNER JOIN transport_fee_collections tfc ON tfc.id = transport_fees.transport_fee_collection_id
                    LEFT JOIN fee_accounts fa ON fa.id = tfc.fee_account_id",
      :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND receiver_type='Student' and
                         receiver_id = #{@student.id} and bus_fare IS NOT NULL"])
    @dates = @transport_fees.map { |t| t.transport_fee_collection }
    @dates.compact!
    financial_year_check
    render "transport_fee/fees_payment/fees_student_dates"
  end

  def fees_employee_dates
    if params[:payer_type].present?
      @payer_type=params[:payer_type]
      if params[:payer_type] == 'Archived Employee'
        @employee = ArchivedEmployee.find_by_former_id(params[:id])
        unless @employee.present?
          flash[:notice] = "#{t('finance.no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
        @employee.id=@employee.former_id
      else
        @employee = Employee.find_by_id(params[:id])
        unless @employee.present?
          flash[:notice] = "#{t('finance.no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
      end
    else
      @employee = Employee.find_by_id(params[:id])
      unless @employee.present?
        flash[:notice] = "#{t('finance.no_payer')}"
        redirect_to :controller => 'user', :action => 'dashboard' and return
      end
    end

    @transport_fee_collection = TransportFeeCollection.find_by_id(params[:collection_id],
      :joins => "#{active_account_joins(true, 'transport_fee_collections')}",
      :conditions => "#{active_account_conditions(true, 'transport_fee_collections')}")
    @transport_fees = TransportFee.active.all(:conditions => ["receiver_type='Employee' and receiver_id = #{@employee.id} and
                     bus_fare IS NOT NULL AND #{active_account_conditions(true, 'tfc')}"],
      :joins => "INNER JOIN transport_fee_collections tfc ON tfc.id = transport_fees.transport_fee_collection_id
                  #{active_account_joins(true, 'tfc')}")
    @dates = @transport_fees.map { |t| t.transport_fee_collection }
    @dates.compact!

    render "transport_fee/fees_payment/fees_employee_dates"
  end

  def fees_submission_student
    @user = params[:id]

    if params[:payer_type].present?
      @payer_type=params[:payer_type]
      if params[:payer_type]=='Archived Student'
        @student = ArchivedStudent.find_by_former_id(params[:student])

        unless @student.present?
          flash[:notice] = "#{t('no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end

        @student.id=@student.former_id
      else
        @student = Student.find_by_id(params[:student])

        unless @student.present?
          flash[:notice] = "#{t('no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
      end
    else
      @student = Student.find_by_id(params[:student])

      unless @student.present?
        flash[:notice] = "#{t('finance.no_payer')}"
        redirect_to :controller => 'user', :action => 'dashboard' and return
      end
    end

    @fine = params[:fees][:fine] if params[:fees].present?

    unless params[:date].blank?
      @transport_fee = TransportFee.find_by_receiver_id_and_transport_fee_collection_id(
        params[:student], params[:date], :include => {:finance_transactions => :transaction_ledger},
        :conditions => "receiver_type = 'Student'")
      @date = @transport_fee.transport_fee_collection
      
      # calculating advance fee used
      @advance_fee_used = @date.finance_transaction.all(:conditions => {:payee_id => @student.id}).sum(&:wallet_amount).to_f
      
      @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
      @transaction = FinanceTransaction.find(@transport_fee.transaction_id) unless @transport_fee.transaction_id.nil?
      @batch = @student.batch
      discount_details

      @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today
      financial_year_check
      fine_details

      render :update do |page|
        page << "remove_popup_box()" if params[:hide_popup].present? and params[:hide_popup].to_i == 1
        page.replace_html "fees_details", :partial => "transport_fee/fees_payment/fees_details"
        page.replace_html "flash", :text => flash[:notice].present? ? "<p class='flash-msg'>#{flash[:notice]}</p>" : ""
      end
    else
      render :update do |page|
        page.replace_html "fees_details", :text => ""
        page.replace_html "flash", :text => ""
      end
    end
  end

  def update_fine_ajax
    if request.post?
      @date = @transport_fee_collection = TransportFeeCollection.find(params[:fine][:date])
      @transport_fee = TransportFee.find(params[:fine][:transport_fee])
      @student = Student.find(params[:fine][:student])
    else
      render :update do |page|
        page.replace_html 'modal-box', :partial => 'fine_submission'
        page << "Modalbox.show($('modal-box'), {title: ''});"

      end
    end

  end

  def fees_submission_employee

    @fine = params[:fees][:fine] if params[:fees].present?
    @user = params[:id]

    if params[:payer_type].present?
      @payer_type=params[:payer_type]
      if params[:payer_type]=='Archived Employee'
        @employee = ArchivedEmployee.find_by_former_id(params[:employee])
        unless @employee.present?
          flash[:notice] = "#{t('no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
        @employee.id=@employee.former_id
      else
        @employee = Employee.find_by_id(params[:employee])
        unless @employee.present?
          flash[:notice] = "#{t('no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
      end
    else
      @employee = Employee.find_by_id(params[:employee])
      @employee_id = @employee.id if @employee.present?
      unless @employee.present?
        flash[:notice] = "#{t('finance.no_payer')}"
        redirect_to :controller => 'user', :action => 'dashboard' and return
      end
    end

    unless params[:date].blank?
      @transport_fee = TransportFee.find_by_receiver_id_and_transport_fee_collection_id(params[:employee],
        params[:date], :include => {:finance_transactions => :transaction_ledger},
        :conditions => "receiver_type = 'Employee'")
      @transport_fee.reload
      @date = @transport_fee.transport_fee_collection
      @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
      @is_fine_waiver = params[:is_fine_waiver].present? ? params[:is_fine_waiver] : @transport_fee.is_fine_waiver ? true : false
      transport_fee_balance = @transport_fee.balance
      transport_fee_is_paid = @transport_fee.is_paid
      update_transport_fine_amount(@is_fine_waiver,@transport_fee)
      discount_details
      @transaction_date = @payment_date = params[:transaction_date] ? Date.parse(params[:transaction_date]) : Date.today_with_timezone
      calculate_auto_fine_for_waiver_tracker if params[:is_fine_waiver].present? && params[:is_fine_waiver] && transport_fee_balance <= 0 && !transport_fee_is_paid
      financial_year_check
      fine_details
      
      render :update do |page|
        page << "remove_popup_box()" if @hide_popup
        page.replace_html "fee_submission", :partial => "transport_fee/fees_payment/fees_details"
      end
    else
      render :update do |page|
        page.replace_html "fees_details", :text => ""
      end
    end

  end

  def create_instant_discount
    @master_discounts = MasterFeeDiscount.core
    if request.get?
      @master_discounts = MasterFeeDiscount.core
      @discount_post_symbol = "%"
      @transport_fee = TransportFee.find(params[:id])
      @transport_fee.receiver_type == "Employee" ? @apply_waiver = false : @apply_waiver = true
      @transport_fee_discount = TransportFeeDiscount.new
      respond_to do |format|
        format.js { render :action => 'create_instant_discount' }
      end

    else
      @discount_post_symbol = params[:transport_fee_discount].present? ?
        (params[:transport_fee_discount][:is_amount] == "true" ? currency : "%") : "%"
      @transport_fee_discount = TransportFeeDiscount.new(params[:transport_fee_discount])
      @transport_fee = TransportFee.find(params[:transport_fee_discount][:transport_fee_id],
        :include => {:finance_transactions => :transaction_ledger})
      @transport_fee.receiver_type == "Employee" ? @apply_waiver = false : @apply_waiver = true
      waiver_check = params[:transport_fee_discount][:waiver_check]
      ActiveRecord::Base.transaction do
        if @transport_fee_discount.save
          @transport_fee.receiver_type == "Student" ? @student  = @transport_fee.receiver : @employee = @transport_fee.receiver
          @date = @transport_fee.transport_fee_collection
          @transport_fee.update_tax_on_discount(@date)
          @transport_fee.reload
          @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
          discount_details
          @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today_with_timezone
          financial_year_check
          fine_details
          if waiver_check == "1"
            @transport_fee_discount.update_discounts_on_creation_or_deletion(@transport_fee,"create")
            transaction = TransportFeeDiscount.create_transaction_for_waiver_discount(@transport_fee)
            if transaction.present?
              @transport_fee_discount.reload
              @transport_fee_discount.finance_transaction_id = transaction.id.to_i
              @transport_fee_discount.send(:update_without_callbacks)
              @transport_fee_discount.reload
              @transport_fee.reload
              flash[:warning] = "#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"
            else
              flash[:notice] = "#{t('fee_payment_failed')}"
              raise ActiveRecord::Rollback
            end
            @transport_fee.update_tax_on_discount(@date)
            @transport_fee.update_balance_fine_amount(@date)
            @transport_fee.reload
          end
          @transport_fee_discount.update_discounts_on_creation_or_deletion(@transport_fee,"create")
          @transport_fee.reload
          @transport_fee_discounts.reload
          @discount_amount = @transport_fee.total_discount_amount
          render :update do |page|
            page.replace_html "fees_details", :partial => "transport_fee/fees_payment/fees_details"
            page << "Modalbox.hide();"
          end
        else
          raise ActiveRecord::Rollback
          @master_discounts = MasterFeeDiscount.core
          respond_to do |format|
            format.js { render :action => 'create_instant_discount' }
          end
        end
      end
    end
  end

  def delete_instant_discount

    @transport_fee = TransportFee.find(params[:transport_fee],
      :include => {:finance_transactions => :transaction_ledger})
    @transport_fee_discount = TransportFeeDiscount.find(params[:transport_fee_discount])
    @date = @transport_fee.transport_fee_collection
    #    @transport_fee_discount.update_discounts_on_creation_or_deletion(@transport_fee,"delete")
    if @transport_fee_discount.destroy
      #      @transport_fee.reload
      #      @transport_fee.update_tax_on_discount(@date)
      @transport_fee.reload
      @transport_fee.receiver_type == "Student" ? @student  = @transport_fee.receiver : @employee = @transport_fee.receiver
      @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
      discount_details
      @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today_with_timezone
      financial_year_check
      fine_details
      render :update do |page|
        page.replace_html "fees_details", :partial => "transport_fee/fees_payment/fees_details"
      end
    end

  end

  def update_fee_collection_dates
    @transport_fee_collections=TransportFeeCollection.all(
      :joins => "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id=transport_fee_collections.id and
                                              transport_fees.groupable_type='Batch'
                  LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id",
      :conditions => ["transport_fees.groupable_id=? and transport_fee_collections.is_deleted=? and
                       transport_fees.bus_fare > ? and transport_fees.is_active = ? AND
                       #{active_account_conditions(true, 'transport_fee_collections')}",
        params[:batch_id], false, 0.0, true], :group => "transport_fee_collections.id")
    render :update do |page|
      page.replace_html 'fees_collection_dates', :partial => 'transport_fee_collection_dates'
    end
  end

  def select_payment_mode
    if  params[:payment_mode]=="Others"
      render :update do |page|
        page.replace_html "payment_mode", :partial => "select_payment_mode"
      end
    else
      render :update do |page|
        page.replace_html "payment_mode", :text => ""
      end
    end
  end

  def transport_fee_collection_pay
    @transport_fee = TransportFee.find(params[:fees][:finance_id])
    @date = @transport_fee.transport_fee_collection
    @tax_slab = @date.collection_tax_slabs.try(:last)
    fine_waiver = params[:fees].present? && params[:fees][:fine_waiver].present? ? params[:fees][:fine_waiver] : @transport_fee.is_fine_waiver? ? true :false
    if params[:receiver_type]=='Student'
      @student = Student.find(params[:receiver_id])
      @batch=@student.batch
      @students=Student.find(:all,
        :joins=>"inner join transport_fees tf on tf.receiver_id=students.id and tf.receiver_type='Student'",
        :conditions => "tf.transport_fee_collection_id='#{@date.id}' and tf.is_active=1 and
                                 students.batch_id='#{@batch.id}'",:order=>"id ASC")
      @prev_student=@students.select{|student| student.id<@student.id}.last||@students.last
      @next_student=@students.select{|student| student.id>@student.id}.first||@students.first
    end
    @employee_id = params[:receiver_id] if params[:receiver_type] == "Employee"
    category_id = FinanceTransactionCategory.find_by_name("Transport").id
    error_flash_proc = ""
    @transaction_date = params[:transaction_date]
    financial_year_check
    if @financial_year_enabled
      unless params[:fees][:payment_mode].blank?
        FinanceTransaction.transaction do
          @transaction= FinanceTransaction.new(params[:fees])
          @transaction.title = @transport_fee.transport_fee_collection.name
          @transaction.category_id = category_id
          @transaction.transaction_date = params[:transaction_date]
          @transaction.payee = @transport_fee.receiver
          @transaction.wallet_amount_applied = params[:wallet_amount_applied]
          @transaction.wallet_amount = params[:wallet_amount]
          @transaction.save
        end
        if @transaction.errors.empty?
          user_event = UserEvent.first(:conditions => ["user_id = ? AND event_id = ?",@transport_fee.receiver.user_id,@date.event.id])
          user_event.destroy if user_event.present?
          #        @transport_fee.update_attributes(:transaction_id => @transaction.id)
          error_flash_proc = Proc.new{{:text=>"<p class='flash-msg'>#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{@transaction.id})'>#{t('print_receipt')}</a></p>"}}
          # flash[:warning]="#{t('finance.flash14')}. <a href ='http://#{request.host_with_port}/finance/generate_fee_receipt_pdf?transaction_id=#{@transaction.id}' target='_blank'>#{t('print_receipt')}</a>"
          flash[:warn_notice]=nil
        else
          flash[:warning] =nil
          error_flash_proc=Proc.new{{:partial => 'render_errors',:locals=>{:object=>'transaction'}}}
        end
      else
        flash[:notice]=nil
        flash[:warn_notice]="#{t('select_one_payment_mode')}"
      end
    end

    @transport_fee.reload
    @date = @transport_fee.transport_fee_collection
    
    # calculating advance fee used
    @advance_fee_used = @student.present? ? (@date.finance_transaction.all(:conditions => {:payee_id => @student.id}).sum(&:wallet_amount).to_f) : 0.00
    
    @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
    discount_details
    @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today
    fine_details

    financial_year_check
    render :update do |page|
      page.replace_html 'fees_details', :partial => 'transport_fee/fees_payment/fees_details'
      page.replace_html 'flash',  error_flash_proc.present? ? error_flash_proc.call : ""
      # page.replace_html 'flash-msg', :text=>"<p class='flash-msg'>#{flash[:warning]}</p>"
    end
  end

  def transport_fee_collection_details
    @date = TransportFeeCollection.find(params[:date])
    @batch = Batch.find(params[:batch_id]) if params[:batch_id].present?
    @fine = params[:fees][:fine] if params[:fees].present?
    @students = Student.find(:all,
      :joins => "INNER JOIN transport_fees tf
                         ON tf.receiver_id = students.id and tf.receiver_type='Student'",
      :conditions => "tf.transport_fee_collection_id='#{@date.id}' and
                      tf.is_active=1 and tf.groupable_type='Batch' and
                      tf.groupable_id='#{@batch.id}'",
      :order => "id ASC")
    if params[:student].present?
      @student = Student.find(params[:student])
    else
      @student = @students.first
    end
    
    # calculating advance fee used
    @advance_fee_used = @date.finance_transaction.all(:conditions => {:payee_id => @student.id}).sum(&:wallet_amount).to_f

    if @student.present?

      @prev_student = @students.select { |student| student.id<@student.id }.last||@students.last
      @next_student = @students.select { |student| student.id>@student.id }.first||@students.first
      @transport_fee = TransportFee.active.find_by_receiver_id_and_transport_fee_collection_id(
        @student.id, @date.id, :conditions => "receiver_type = 'Student'",
        :include => {:finance_transactions => :transaction_ledger})
      @fine_waiver_val = params[:is_fine_waiver].present? ? params[:is_fine_waiver] : false
      transport_fee_balance = @transport_fee.balance
      transport_fee_is_paid = @transport_fee.is_paid
      update_transport_fine_amount(@fine_waiver_val,@transport_fee)
      @transport_fee_collection = @transport_fee.transport_fee_collection
      @tax_slab = @transport_fee_collection.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled
      @transaction = FinanceTransaction.find_by_id(@transport_fee.transaction_id) unless @transport_fee.
        transaction_id.nil?

      discount_details

      @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today_with_timezone
      calculate_auto_fine_for_waiver_tracker if params[:is_fine_waiver].present? && params[:is_fine_waiver] && transport_fee_balance <= 0 && !transport_fee_is_paid
      fine_details
      flash.clear

      financial_year_check
    else
      flash.now[:notice] = t('student_documents.student_not_found')
    end
    
    render :update do |page|
      if params[:is_fine_waiver].present? && params[:is_fine_waiver]
        page.replace_html 'fees_details', :partial => 'transport_fee/fees_payment/fees_details'
      else
        page.replace_html "fees_detail", {:partial => @student.present? ? "transport_fee/fees_payment/fees_submission_form" : "flash_notice"}
      end
    end

  end

  #  def transport_fee_collection_details
  #    @collection_id = params[:collection_id]
  #    @transport_fee_collection= TransportFeeCollection.find_by_id(params[:collection_id])
  #    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:collection_id])
  #    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:collection_id], params[:id]) unless params[:id].nil?
  #    @user ||= @transport_fee_collection.transport_fees.first
  #    @next_user = @user.next_user unless @user.nil?
  #    @prev_user = @user.previous_user unless @user.nil?
  #    @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
  #    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id) unless @user.nil?
  #    render :update do |page|
  #      page.replace_html 'transport_fee_collection_details', :partial => 'transport_fee_collection_details'
  #    end
  #  end

  def update_fine_ajax
    @collection_id = params[:fine][:transport_fee_collection]
    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:fine][:transport_fee_collection])
    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:fine][:transport_fee_collection], params[:fine][:_id]) unless params[:fine][:_id].nil?
    @user ||= @transport_fee.first
    @next_user = @user.next_user
    @prev_user = @user.previous_user
    @fine = (params[:fine][:fee])
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
    render :update do |page|
      page.replace_html 'transport_fee_collection_details', :partial => 'transport_fee_collection_details'
    end
  end

  def update_student_fine_ajax
    @collection_id = params[:fine][:transport_fee_collection]
    @transport_fee = TransportFee.find_by_transport_fee_collection_id_and_receiver_id_and_receiver_type(params[:fine][:transport_fee_collection], params[:fine][:_id], 'Student') unless params[:fine][:_id].nil?
    @transport_fee_collection= TransportFeeCollection.find_by_id(@transport_fee.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@transport_fee.transaction_id)
    render :update do |page|
      unless params[:fine][:fee].to_f < 0
        @fine = params[:fine][:fee]
        @student = Student.find(params[:fine][:_id])
        page.replace_html 'fee_submission', :partial => 'transport_fee/fees_payment/fees_submission_form',
          :with => @student
        page.replace_html 'flash', :text => ""
      else
        @student = Student.find(params[:fine][:_id])
        page.replace_html 'fee_submission', :partial => 'transport_fee/fees_payment/fees_submission_form'
        page.replace_html 'flash', :text => "<p class='flash-msg'>#{t('fine_cannot_be_negative')}</p>"
      end
    end
  end


  #  def employee_transport_fee_collection
  #    @transport_fee_collection =TransportFeeCollection.employee
  #  end
  #
  #  def employee_transport_fee_collection_details
  #    @collection_id = params[:collection_id]
  #    @transport_fee_collection= TransportFeeCollection.find_by_id(params[:collection_id])
  #    @transport_fee = TransportFee.find_all_by_transport_fee_collection_id(params[:collection_id])
  #    @user = TransportFee.find_by_transport_fee_collection_id_and_id(params[:collection_id], params[:id]) unless params[:id].nil?
  #    @user ||= @transport_fee_collection.transport_fees.first
  #    unless @user.nil?
  #      @next_user = @user.next_user
  #      @prev_user = @user.previous_user
  #      @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
  #      @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
  #    end
  #    render :update do |page|
  #      page.replace_html 'transport_fee_collection_details', :partial => 'employee_transport_fee_collection_details'
  #    end
  #  end

  def update_employee_fine_ajax
    @collection_id = params[:fine][:transport_fee_collection]
    @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:fine][:transport_fee_collection])
    @user = TransportFee.active.find_by_transport_fee_collection_id_and_id(params[:fine][:transport_fee_collection], params[:fine][:_id]) unless params[:fine][:_id].nil?
    @user ||= @transport_fee.first
    @next_user = @user.next_user
    @prev_user = @user.previous_user
    @fine = (params[:fine][:fee])
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
    render :update do |page|
      page.replace_html 'transport_fee_collection_details', :partial => 'employee_transport_fee_collection_details'
    end
  end

  def update_employee_fine_ajax2
    @collection_id = params[:date]
    @transport_fee = TransportFee.active.find_by_transport_fee_collection_id_and_receiver_id_and_receiver_type(params[:date], params[:emp_id], 'Employee') unless params[:emp_id].nil?
    @transport_fee_collection= TransportFeeCollection.find_by_id(@transport_fee.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@transport_fee.transaction_id)
    render :update do |page|
      unless params[:fees][:fine].to_f < 0
        @fine = params[:fees][:fine].to_f
        @employee = Employee.find(params[:emp_id])
        page.replace_html 'fees_details', :partial => 'transport_fee/fees_payment/fees_details'
        page.replace_html 'flash', :text => ""
      else
        @employee = Employee.find(params[:emp_id])
        page.replace_html 'fees_details', :partial => 'transport_fee/fees_payment/fees_details'
        page.replace_html 'flash', :text => "<p class='flash-msg'>#{t('fine_cannot_be_negative')}</p>"
      end
    end
  end

  def defaulters_update_fee_collection_dates
    @transport_fee_collection = TransportFeeCollection.all(
      :joins => "INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id
                  #{active_account_joins(true, 'transport_fee_collections')}",
      :conditions => ["transport_fees.groupable_id = ? AND transport_fee_collections.is_deleted = ? AND
                       transport_fee_collections.due_date < '#{Date.today}' AND transport_fees.balance > ? AND
                       transport_fees.is_active = ? AND transport_fees.groupable_type = ? AND
                       #{active_account_conditions(true, 'transport_fee_collections')}",
        params[:batch_id],false,0.0,true,'Batch'],
      :group => "transport_fee_collections.id")

    render :update do |page|
      page.replace_html 'fees_collection_dates', :partial => 'defaulters_transport_fee_collection_dates'
    end
  end

  def defaulters_transport_fee_collection_details
    @collection_id = params[:collection_id]
    @transport_fee = TransportFee.active.find(:all, :select => "distinct transport_fees.*",
      :joins => "INNER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'
                  #{active_account_joins(true, 'transport_fee_collections')}",
      :conditions => "transport_fees.transport_fee_collection_id='#{params[:collection_id]}' AND
                      students.batch_id='#{params[:batch_id]}' AND transport_fees.balance > 0 AND
                      transport_fees.groupable_type = 'Batch' AND
                      #{active_account_conditions(true, 'transport_fee_collections')}").
      sort_by { |s| s.receiver.full_name.downcase unless s.receiver.nil? }
    # @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:collection_id], :conditions => 'transaction_id IS NULL')
    # @transport_fee.reject! { |x| x.receiver.nil? }
    #   @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
    #  @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id) unless @user.nil?
    render :update do |page|
      page.replace_html 'fee_submission', :partial => 'students_list'
    end
  end

  def fees_submission_defaulter_student
    @fine=params[:fees][:fine] if params[:fees].present?
    @user = params[:id]
    @student = Student.find(params[:student])
    @batch=@student.batch
    @date=TransportFeeCollection.find(params[:date],
      :conditions => "#{active_account_conditions(true, 'transport_fee_collections')}",
      :joins => "#{active_account_joins(true, 'transport_fee_collections')}")
    if @date.present?
      @transport_fee = TransportFee.active.find_by_receiver_id_and_transport_fee_collection_id(@student.id, @date.id,
        :conditions => "receiver_type = 'Student'")
      @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
      @transport_fee_collection = @transport_fee.transport_fee_collection
      discount_details
      @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today_with_timezone
      fine_details
      flash.clear
    else
      flash.now[:notice] = t('flash_msg5')
    end
    # calculating advance fee used
    @advance_fee_used = @date.finance_transaction.all(:conditions => {:payee_id => @student.id}).sum(&:wallet_amount).to_f
    
    financial_year_check
    render :update do |page|
      if @date.present?
        page.replace_html "fee_submission", :partial => "transport_fee/fees_payment/fees_details"
      else
        page.replace_html "fee_submission", :text => ""
      end
    end
  end

  def update_defaulters_fine_ajax
    @collection_id = params[:fine][:transport_fee_cofind_all_by_transport_fee_collection_idllection]
    @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:fine][:transport_fee_collection])
    @user = TransportFee.active.find_by_transport_fee_collection_id_and_id(params[:fine][:transport_fee_collection], params[:fine][:_id]) unless params[:fine][:_id].nil?
    @user ||= @transport_fee.first
    @next_user = @user.next_user unless @user.nil?
    @prev_user = @user.previous_user unless @user.nil?
    @fine = (params[:fine][:fee])
    @transport_fee_collection= TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id)
    render :update do |page|
      page.replace_html 'defaulters_transport_fee_collection_details', :partial => 'defaulters_transport_fee_collection_details'
    end
  end

  def employee_defaulters_transport_fee_collection
    @transport_fee_collection =TransportFeeCollection.employee

    render "transport_fee/fees_payment/employee_defaulters_transport_fee_collection"
  end

  def employee_defaulters_transport_fee_collection_details
    @collection_id = params[:collection_id]
    @transport_fee_collection = TransportFeeCollection.find_by_id(params[:collection_id],
      :conditions => "#{active_account_conditions(true, 'transport_fee_collections')}",
      :joins => "#{active_account_joins(true, 'transport_fee_collections')}")
    if @transport_fee_collection.present?
      @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:collection_id],
        :conditions => "balance > 0  AND receiver_type = 'Employee'")
      @transport_fee.reject! { |x| x.receiver.nil? }
      @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
      @transport_fee_collection = TransportFeeCollection.find_by_id(@user.transport_fee_collection_id) unless @user.nil?
    else
      flash.now[:notice] = t('flash_msg5')
    end

    render :update do |page|
      page.replace_html 'flash', :text => (flash.now[:notice].present? ? "<p class='flash-msg'>#{flash[:notice]}</p>" : "")
      if @transport_fee_collection.present?
        page.replace_html 'fee_submission', :partial => 'students_list'
      else
        page.replace_html 'fee_submission', :text => ""
      end
    end
  end

  def update_employee_defaulters_fine_ajax
    @collection_id = params[:fine][:transport_fee_collection]
    @transport_fee = TransportFee.active.find_all_by_transport_fee_collection_id(params[:fine][:transport_fee_collection])
    @user = TransportFee.active.find_by_transport_fee_collection_id_and_id(params[:fine][:transport_fee_collection],
      params[:fine][:_id]) unless params[:fine][:_id].nil?
    @user ||= @transport_fee_collection.transport_fees.first(:conditions => ["transaction_id is null"])
    @next_user = @user.next_default_user unless @user.nil?
    @prev_user = @user.previous_default_user unless @user.nil?
    @transaction = FinanceTransaction.find_by_id(@user.transaction_id) unless @user.nil?
    @fine = (params[:fine][:fee])
    @transport_fee_collection = TransportFeeCollection.find_by_id(@user.transport_fee_collection_id)
    render :update do |page|
      page.replace_html 'defaulters_transport_fee_collection_details',
        :partial => 'employee_defaulters_transport_fee_collection_details'
    end
  end

  def show_date_filter
    month_date
    @target_action=params[:target_action]
    if request.xhr?
      render(:update) do|page|
        page.replace_html "date_filter", :partial=>"filter_dates"
      end
    end
  end

  def transport_fee_receipt_pdf
    @transaction = FinanceTransaction.find params[:id]
    @transport_fee = @transaction.finance
    @fee_collection = @transport_fee.transport_fee_collection
    @user = @transport_fee.receiver
    @bus_fare = @transaction.fine_included ? ((@transaction.amount.to_f) - (@transaction.fine_amount.to_f)) : @transaction.amount.to_f
    @currency = currency
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      response = @transaction.try(:payment).try(:gateway_response)
      @online_transaction_id = response.nil? ? nil : response[:transaction_id]
      @online_transaction_id ||= response.nil? ? nil : response[:x_trans_id]
      @online_transaction_id ||= response.nil? ? nil : response[:transaction_reference]
    end
    render :pdf => 'transport_fee_receipt', :layout => 'pdf'
  end


  def delete_fee_collection_date

    @user_type=params[:user_type]
    fee_collection = TransportFeeCollection.find(params[:id],:include=>:transport_fees)
    @transport_fees = fee_collection.transport_fees.active
    transport_fees_count = fee_collection.transport_fees.active.all(:group=>"groupable_type,groupable_id").size
    is_paid=@user_type == 'student' ? fee_collection.has_paid_fees_in_batch?(params[:batch_id]) : fee_collection.has_paid_fees_by_employee?
    if @transport_fees.present? && !is_paid
      if transport_fees_count == 1
        event=fee_collection.event
        event.destroy
        fee_collection.destroy
      else
        if @user_type == 'student'
          user_ids = @transport_fees.find_all_by_groupable_id_and_groupable_type(params[:batch_id],'Batch').collect{|x| x.receiver.user_id unless x.receiver.nil?}
          TransportFee.destroy_all("groupable_type='Batch' and groupable_id='#{params[:batch_id]}' and transport_fee_collection_id=#{params[:id]}")
          TransportFeeCollectionAssignment.destroy_all("transport_fee_collection_id='#{params[:id]}' and assignee_type = 'Batch' and assignee_id= '#{params[:batch_id]}'")
        else
          user_ids = @transport_fees.find_all_by_groupable_type('EmployeeDepartment').collect{|x| x.receiver.user_id unless x.receiver.nil?}
          TransportFee.destroy_all("groupable_type='EmployeeDepartment' and transport_fee_collection_id=#{params[:id]}")
          TransportFeeCollectionAssignment.destroy_all("transport_fee_collection_id='#{params[:id]}' and assignee_type = 'EmployeeDepartment'")
        end
        user_ids.delete(nil) #remove nil value - when student get archived
        #Remove user events
        UserEvent.destroy_all("user_id  in ( #{user_ids.join(',')} ) and event_id=#{fee_collection.event.id}")

      end
      flash[:notice]="#{t('flash4')}"
    else
      @error_text=true
      render :update do |page|
        flash[:error]=t('transport_fee.flash5')
        page.redirect_to :action => 'transport_fee_collection_view'
      end
    end

  end


  def update_user_ajax #TODO
    if params[:user_type] == 'employee'
      #@transport_fee_collection = TransportFeeCollection.find(:all, :conditions=>'batch_id IS NULL').paginate(:page => params[:page],:per_page => 30)
      fy_id = current_financial_year_id
      @transport_fee_collection = TransportFeeCollection.current_active_financial_year.paginate(:select => "distinct transport_fee_collections.*",
        :joins => "INNER JOIN transport_fees
                             ON transport_fees.transport_fee_collection_id = transport_fee_collections.id AND
                                transport_fees.groupable_type='EmployeeDepartment'
                      #{active_account_joins(true, 'transport_fee_collections')}",
        :conditions => "transport_fees.receiver_type = 'Employee' AND transport_fee_collections.is_deleted = false AND
                          transport_fees.is_active = true AND
                          #{active_account_conditions(true, 'transport_fee_collections')}",
        :per_page => 20, :page => params[:page])
      @user_type = 'employee'
      render :update do |page|
        page.replace_html 'fee_collection_list', :partial => 'fee_collection_list'
        page.replace_html 'batch_list', :text => ''
      end
    elsif params[:user_type] == 'student'
      @user_type = 'student'
      @batches = Batch.active
      render :update do |page|
        page.replace_html 'batch_list', :partial => 'students_batch_list'
        page.replace_html 'fee_collection_list', :text => ''
      end
    else
      render :update do |page|
        page.replace_html 'batch_list', :text => ''
        page.replace_html 'fee_collection_list', :text => ''
      end
    end
  end

  def update_batch_list_ajax
    @transport_fee_collection = TransportFeeCollection.current_active_financial_year.paginate(:all, :select => "distinct transport_fee_collections.*",
      :joins => "INNER JOIN transport_fees
                         ON transport_fees.transport_fee_collection_id = transport_fee_collections.id AND
                            transport_fees.groupable_type='Batch'
                  #{active_account_joins(true, 'transport_fee_collections')}",
      :conditions => "transport_fees.groupable_id= #{params[:batch_id]} AND transport_fees.is_active = true AND
                      #{active_account_conditions(true, 'transport_fee_collections')}",
      :per_page => 20, :page => params[:page])
    @user_type = 'student'
    render :update do |page|
      page.replace_html 'fee_collection_list', :partial => 'fee_collection_list'
    end
  end

  def update_fine_on_payment_date_change_ajax
    #    @student = Student.find_by_id(params[:student]) if params[:student].present?
    unless params[:date].blank?
      if params[:student].present?
        @student = Student.find_by_id(params[:student])
        @transport_fee = TransportFee.find_by_receiver_id_and_transport_fee_collection_id(
          params[:student], params[:date], :include => {:finance_transactions => :transaction_ledger},
          :conditions => "receiver_type = 'Student'")
      else
        @employee = Employee.find_by_id(params[:employee])
        @transport_fee = TransportFee.find_by_receiver_id_and_transport_fee_collection_id(
          params[:employee], params[:date], :include => {:finance_transactions => :transaction_ledger},
          :conditions => "receiver_type = 'Employee'")
      end
      @batch = @student.present? ? @student.batch : nil
      @date = @transport_fee.transport_fee_collection
      @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
      @transaction = FinanceTransaction.find(@transport_fee.transaction_id) unless @transport_fee.transaction_id.nil?
      discount_details
      @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today
      financial_year_check
      fine_details
    end
    render :update do |page|
      page.replace_html "fees_details", :partial => "transport_fee/fees_payment/fees_details"
    end
  end

  def transport_fees_report
    if validate_date

      filter_by_account, account_id = account_filter

      ft_joins = "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id = transport_fee_collections.id
                  INNER JOIN finance_transactions ft ON ft.finance_id=transport_fees.id AND ft.finance_type = 'TransportFee'
                   LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id"
      if filter_by_account
        filter_conditions = "AND transport_fee_collections.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_conditions += " AND fa.is_deleted = false" if account_id.present?
        filter_values = [account_id]
      else
        filter_values = []
        filter_conditions = " AND (fa.id IS NULL or fa.is_deleted = false) "
      end

      @target_action = "transport_fees_report"
      @start_date = @start_date.to_s
      @end_date = @end_date.to_s

      @transport_fee_collections = TransportFeeCollection.paginate(:per_page => 10,
        :page => params[:page], :joins => ft_joins, #{:transport_fees => ft_joins},
        :group => "transport_fee_collections.id",
        :conditions => ["(ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}", @start_date, @end_date] + filter_values,
        :select => "SUM(ft.amount) AS amount, IF(transport_fee_collections.tax_enabled, IFNULL(SUM(ft.tax_amount),0),
                    '-') AS tax_amount, transport_fee_collections.tax_enabled, transport_fee_collections.id,
                    transport_fee_collections.name AS collection_name, IFNULL((SUM(ft.fine_amount)),0) as total_fine")

      @ftd_hash = Hash.new
      @transport_fee_collections.each{ |tfc| @ftd_hash[tfc.id] = tfc.total_amount_and_discount(@start_date, @end_date) }

      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial=>"transport_fees_report"
        end
      end
    else
      render_date_error_partial
    end
  end

  def transport_fees_report_csv
    if date_format_check

      filter_by_account, account_id = account_filter

      ft_joins = "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id = transport_fee_collections.id
                  INNER JOIN finance_transactions ft ON ft.finance_id=transport_fees.id AND ft.finance_type = 'TransportFee'
                   LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id"
      if filter_by_account
        filter_conditions = "AND transport_fee_collections.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_conditions += " AND fa.is_deleted = false" if account_id.present?
        filter_values = [account_id]
      else
        filter_values = []
        filter_conditions = " AND (fa.id IS NULL or fa.is_deleted = false) "
      end

      collections = TransportFeeCollection.all(:joins => ft_joins, :group => "transport_fee_collections.id",
        :conditions => ["(ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}", @start_date, @end_date] + filter_values,
        :select => "SUM(ft.amount) AS amount, IF(transport_fee_collections.tax_enabled, IFNULL(SUM(ft.tax_amount),0),
                    '-') AS tax_amount, transport_fee_collections.tax_enabled, transport_fee_collections.id,
                    transport_fee_collections.name AS collection_name, IFNULL((SUM(ft.fine_amount)),0) as total_fine")

      tax_enabled_present = collections.map(&:tax_enabled).uniq.include?(true)
      ftd_hash = Hash.new
      collections.each{ |tfc| ftd_hash[tfc.id] = tfc.total_amount_and_discount(@start_date, @end_date) }
      csv_string = FasterCSV.generate do |csv|
        csv << t('transport_fee_collections')
        csv << [t('start_date'),format_date(@start_date)]
        csv << [t('end_date'),format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << (tax_enabled_present ? [t('collection'), t('total_discount'), t('tax_text'), t('total_fine_amount'), t('amount')] :
            [t('collection'), t('total_discount'), t('total_fine_amount'), t('amount')])
        total = 0
        collections.each do |collection|
          row = []
          row << collection.collection_name
          row << precision_label(ftd_hash[collection.id]["discount"])
          if tax_enabled_present
            row << (collection.tax_amount != '-' ? precision_label(collection.tax_amount) : '-')
          end
          row << precision_label(collection.total_fine)
          row << precision_label(collection.amount.to_f + ftd_hash[collection.id]["discount"].to_f)
          total += collection.amount.to_f
          csv << row
        end
        csv << ""
        csv << [t('net_income'),precision_label(total)]
      end
      filename = "#{t('transport_fee_collections')}-#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end



  #
  #  def transport_student_course_wise_collection_report
  #    if date_format_check
  #      @fee_collection = FinanceFeeCollection.find(params[:id])
  #      @target_action = "course_wise_collection_report"
  #      @course_ids=@fee_collection.batches.all(:include=>:course).group_by(&:course_id)
  #      if request.xhr?
  #        render(:update) do|page|
  #          page.replace_html "fee_report_div", :partial=>"fees_report"
  #        end
  #      end
  #    end
  #  end
  #
  #
  def category_wise_collection_report
    if validate_date

      joins = "LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id"
      @collection = TransportFeeCollection.find_by_id(params[:id], :joins => joins,
        :conditions => "fa.id IS NULL OR fa.is_deleted = false")
      if @collection.present?
        filter_by_account, account_id = account_filter

        if filter_by_account
          filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
          joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
          ft_joins = :finance_transaction_receipt_record
        else
          filter_conditions = joins = ""
          ft_joins = ""
          filter_values = []
        end

        @target_action = "category_wise_collection_report"
        @grand_total = @collection.finance_transaction.all(:select => "amount",
          :joins => ft_joins, :conditions => ["(transaction_date BETWEEN ? AND ?) #{filter_conditions}",
            @start_date, @end_date] + filter_values).map {|x| x.amount.to_f }.sum

        @courses = TransportFee.all(
          :joins => "INNER JOIN transport_fee_finance_transactions ON transport_fees.id = transport_fee_finance_transactions.transport_fee_id
                        INNER JOIN finance_transactions ON finance_transactions.id = transport_fee_finance_transactions.finance_transaction_id
                        INNER JOIN batches on batches.id = transport_fees.groupable_id #{joins}",
          :group => "transport_fees.groupable_id",
          :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ?) AND transport_fees.transport_fee_collection_id = ? AND
                                 transport_fees.groupable_type = 'Batch' #{filter_conditions}", @start_date,
            @end_date, params[:id]] + filter_values,
          :select => "SUM(finance_transactions.amount) AS amount, batches.name AS batch_name, batches.course_id AS course_id,
                          transport_fees.groupable_id AS batch_id").group_by(&:course_id)

        @departments = TransportFee.find(:all,
          :joins => "INNER JOIN transport_fee_finance_transactions ON transport_fees.id = transport_fee_finance_transactions.transport_fee_id
                        INNER JOIN finance_transactions ON finance_transactions.id = transport_fee_finance_transactions.finance_transaction_id
                        INNER JOIN employee_departments on employee_departments.id=transport_fees.groupable_id #{joins}",
          :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                 transport_fees.groupable_type = 'EmployeeDepartment' AND
                                 transport_fees.transport_fee_collection_id = ? #{filter_conditions}",
            @start_date, @end_date, params[:id]] + filter_values,
          :group => "transport_fees.groupable_id",
          :select => "employee_departments.name AS dep_name, SUM(finance_transactions.amount) AS amount,
                          transport_fees.groupable_id AS dep_id")

        if request.xhr?
          render(:update) do|page|
            page.replace_html "fee_report_div", :partial => "department_wise_transport_collection_report_partial"
          end
        end
      else
        flash[:notice] = t('flash_msg5')
        if request.xhr?
          render :update do |page|
            page.redirect_to :controller => "user", :action => "dashboard"
          end
        else
          redirect_to :controller => "user", :action => "dashboard"
        end
      end
    else
      render_date_error_partial
    end
  end

  def transport_employee_department_wise_collection_report_csv
    if date_format_check
      joins = "LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id"
      @collection = TransportFeeCollection.find_by_id(params[:id], :joins => joins,
        :conditions => "fa.id IS NULL OR fa.is_deleted = false")

      if @collection.present?
        filter_by_account, account_id = account_filter

        if filter_by_account
          filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
          joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id"
        else
          filter_conditions = joins = ""
          filter_values = []
        end

        @courses = TransportFee.all(
          :joins => "INNER JOIN transport_fee_finance_transactions ON (transport_fees.id = transport_fee_finance_transactions.transport_fee_id)
                        INNER JOIN finance_transactions ft ON (ft.id = transport_fee_finance_transactions.finance_transaction_id)
                        INNER JOIN batches on batches.id = transport_fees.groupable_id #{joins}",
          :group => "transport_fees.groupable_id",
          :conditions => ["(ft.transaction_date BETWEEN ? AND ?) AND
                                 transport_fees.transport_fee_collection_id = ? AND
                                 transport_fees.groupable_type='Batch' #{filter_conditions}",
            @start_date, @end_date, params[:id]] + filter_values,
          :select => "SUM(ft.amount) AS amount, batches.name AS batch_name, batches.course_id AS course_id,
                          transport_fees.groupable_id AS batch_id").group_by(&:course_id)

        @departments = TransportFee.find(:all,
          :joins => "INNER JOIN transport_fee_finance_transactions ON (transport_fees.id = transport_fee_finance_transactions.transport_fee_id)
                        INNER JOIN finance_transactions ft ON (ft.id = transport_fee_finance_transactions.finance_transaction_id)
                        INNER JOIN employee_departments ON employee_departments.id = transport_fees.groupable_id #{joins}",
          :conditions => ["(ft.transaction_date BETWEEN ? AND ?) AND
                                 transport_fees.transport_fee_collection_id = ? AND
                                 transport_fees.groupable_type = 'EmployeeDepartment' #{filter_conditions}",
            @start_date, @end_date, params[:id]] + filter_values, :group => "transport_fees.groupable_id",
          :select => "employee_departments.name AS dep_name, SUM(ft.amount) AS amount,
                          transport_fees.groupable_id AS dep_id")

        csv_string = FasterCSV.generate do |csv|
          csv << t('transport_fee_collections')
          csv << [t('start_date'), format_date(@start_date)]
          csv << [t('end_date'), format_date(@end_date)]
          csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
          net_total = 0
          unless @departments.empty?
            total = 0
            csv << ""
            csv << t('employees')
            csv << ["",t('department'),t('amount')]
            @departments.each do |dep|
              row = []
              row << ["",""]
              row << dep.dep_name
              row << precision_label(dep.amount)
              total += dep.amount.to_f
              csv << row
            end
            net_total += total
            csv << [t('total'),"",precision_label(total)]
            csv << ""
          end
        end
        filename = "#{t('transport_fee_collection')}-#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
        send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
      else
        flash[:notice] = t("flash_msg5")
        redirect_to :controller => "user", :action => "dashboard"
      end
    end
  end

  def batch_transport_fees_report
    if date_format_check
      @start_date=@start_date.to_s
      @end_date=@end_date.to_s
      @fee_collection = TransportFeeCollection.find(params[:id])
      @batch = @fee_collection.batch
      transport_id = FinanceTransactionCategory.find_by_name('Transport').id
      @transaction =[]
      @fee_collection.finance_transaction.all(:include => :transaction_ledger).each { |f| @transaction<<f if (f.transaction_date.to_s >= @start_date and f.transaction_date.to_s <= @end_date) }
    end
  end

  def employee_transport_fees_report
    if validate_date

      joins = "LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id"
      @fee_collection = TransportFeeCollection.find_by_id(params[:id], :joins => joins,
        :conditions => "fa.id IS NULL OR fa.is_deleted = false")

      if @fee_collection.present?
        filter_by_account, account_id = account_filter

        if filter_by_account
          filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
          joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
          ft_joins = {:finance_transactions => :finance_transaction_receipt_record}
        else
          filter_conditions = ""
          joins = ""
          ft_joins = :finance_transactions
          filter_values = []
        end

        @start_date = @start_date.to_s
        @end_date = @end_date.to_s
        transport_id = FinanceTransactionCategory.find_by_name('Transport').id
        @target_action = 'employee_transport_fees_report'
        if params[:type] == 'employee'
          @category = EmployeeDepartment.find(params[:dep_id])
          @grand_total = TransportFee.all(:select => "amount", :joins => ft_joins,
            :conditions => ["transport_fees.groupable_id = ? AND
                                   transport_fees.groupable_type = 'EmployeeDepartment' AND
                                   transport_fees.transport_fee_collection_id = ? AND
                                   (finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                   finance_transactions.category_id = ? AND
                                   finance_transactions.finance_type = 'TransportFee'", params[:dep_id], params[:id],
              @start_date, @end_date, transport_id] + filter_values).map {|x| x.amount.to_f }.sum

          @transactions = FinanceTransaction.paginate(:per_page => 10,:page => params[:page],
            :include => [:transaction_receipt, {:finance => :receiver}],
            :joins => "INNER JOIN transport_fee_finance_transactions tfft on tfft.finance_transaction_id = finance_transactions.id
                          INNER JOIN transport_fees tf on tf.id=tfft.transport_fee_id #{joins}",
            :conditions => ["tf.groupable_id = ? AND tf.groupable_type='EmployeeDepartment' and
                                   tf.transport_fee_collection_id = ? AND
                                   (finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                   finance_transactions.category_id = ? AND
                                   finance_transactions.finance_type = 'TransportFee' #{filter_conditions}",
              params[:dep_id], params[:id], @start_date, @end_date, transport_id] + filter_values)
        else
          @category = Batch.find(params[:batch_id])
          @grand_total = TransportFee.all(:select => "amount", :joins => ft_joins,
            :conditions => ["transport_fees.groupable_id = ? AND  transport_fees.groupable_type='Batch' and
                                   transport_fees.transport_fee_collection_id = ? AND
                                   (finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                   finance_transactions.category_id = ? AND
                                   finance_transactions.finance_type='TransportFee' #{filter_conditions}",
              params[:batch_id], params[:id], @start_date, @end_date, transport_id] + filter_values).
            map {|x| x.amount.to_f }.sum

          @transactions = FinanceTransaction.paginate(:per_page => 10,:page => params[:page],
            :include => [:transaction_receipt, {:finance => :receiver}],
            :joins => "INNER JOIN transport_fee_finance_transactions tfft on tfft.finance_transaction_id=finance_transactions.id
                          INNER JOIN transport_fees tf on tf.id=tfft.transport_fee_id #{joins}",
            :conditions=>["tf.groupable_id = ? AND tf.groupable_type='Batch' AND
                                 tf.transport_fee_collection_id = ? AND
                                 (finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                 finance_transactions.category_id = ? AND
                                 finance_transactions.finance_type = 'TransportFee' #{filter_conditions}",
              params[:batch_id], params[:id], @start_date, @end_date, transport_id] + filter_values)
        end

        if request.xhr?
          render(:update) do|page|
            page.replace_html "fee_report_div", :partial => "transport_fees_transactions"
          end
        end
      else
        flash[:notice] = t("flash_msg5")
        if request.xhr?
          render :update do |page|
            page.redirect_to :controller => "user", :action => "dashboard"
          end
        else
          redirect_to :controller => "user", :action => "dashboard"
        end
      end

    else
      render_date_error_partial
    end
  end

  def employee_transport_fees_report_csv
    if date_format_check
      joins = "LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id"
      @fee_collection = TransportFeeCollection.find_by_id(params[:id], :joins => joins,
        :conditions => "fa.id IS NULL OR fa.is_deleted = false")
      if @fee_collection.present?
        filter_by_account, account_id = account_filter

        if filter_by_account
          filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
          joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
          #        ft_joins = {:finance_transactions => :finance_transaction_receipt_record}
        else
          filter_conditions = ""
          joins = ""
          #        ft_joins = :finance_transactions
          filter_values = []
        end

        transport_id = FinanceTransactionCategory.find_by_name('Transport').id
        if params[:type] == 'employee'
          @category = EmployeeDepartment.find(params[:dep_id])
          @transactions = FinanceTransaction.all(:include => :transaction_receipt,
            :joins => "INNER JOIN transport_fee_finance_transactions tfft on tfft.finance_transaction_id=finance_transactions.id
                          INNER JOIN transport_fees tf on tf.id=tfft.transport_fee_id #{joins}",
            :conditions => ["tf.groupable_id = ? AND tf.groupable_type = 'EmployeeDepartment' AND
                                   tf.transport_fee_collection_id = ? AND
                                   (finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                   finance_transactions.category_id = ? AND
                                   finance_transactions.finance_type = 'TransportFee' #{filter_conditions}",
              params[:dep_id], params[:id], @start_date, @end_date, transport_id] + filter_values)
        else
          @category = Batch.find(params[:batch_id])
          @transactions = FinanceTransaction.all(:include => :transaction_receipt,
            :joins => "INNER JOIN transport_fee_finance_transactions tfft on tfft.finance_transaction_id=finance_transactions.id
                          INNER JOIN transport_fees tf on tf.id=tfft.transport_fee_id #{joins}",
            :conditions => ["tf.groupable_id = ? AND tf.groupable_type='Batch' AND
                                   tf.transport_fee_collection_id = ? AND
                                   (finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                   finance_transactions.category_id = ? AND
                                   finance_transactions.finance_type = 'TransportFee' #{filter_conditions}",
              params[:batch_id], params[:id], @start_date, @end_date, transport_id] + filter_values)
        end

        csv_string = FasterCSV.generate do |csv|
          csv << t('transport_fee_collections')
          csv << [t('start_date'),format_date(@start_date)]
          csv << [t('end_date'),format_date(@end_date)]
          if params[:type] == "employee"
            csv << [t('department'),@category.name]
          else
            csv << [t('batch'),@category.name]
          end
          csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
          csv  << ""
          row = []
          if params[:type]=='employee'
            row << [t('employee_name')]
          else
            row << [t('student_name')]
          end
          row << t('amount')
          row << t('receipt_no')
          row << t('date_text')
          row << t('payment_mode')
          row << t('payment_notes')
          csv << row
          total = 0
          @transactions.each do |t|
            row = []
            if params[:type]=='student'
              row << "#{t.transport_student_with_out_batch_name.full_name} (#{t.transport_student_with_out_batch_name.admission_no})"
            else
              row << "#{t.transport_employee.full_name}(#{t.transport_employee.employee_number})"
            end
            row << precision_label(t.amount)
            row << t.receipt_number
            row << format_date(t.created_at,:format=>:short_date)
            row << t.payment_mode
            row << t.payment_note
            total += t.amount.to_f
            csv << row
          end
          csv << ""
          csv << [t('net_income'),precision_label(total)]
        end
        filename = "#{t('transport_fee_collection')}-#{@fee_collection.name}#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
        send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
      else
        flash[:notice] = t("flash_msg5")
        if request.xhr?
          render :update do |page|
            page.redirect_to :controller => "user", :action => "dashboard"
          end
        else
          redirect_to :controller => "user", :action => "dashboard"
        end
      end
    end
  end

  def student_profile_fee_details
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if ((PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_transport_fee_enabled?))
        if params[:create_transaction].present?
          gateway_record = GatewayRequest.find(:first, :conditions=>{:transaction_reference=>params[:transaction_ref], :status=>0})
          gateway_record.update_attribute('status', true) if gateway_record.present?
          @active_gateway = gateway_record.present? ? gateway_record.gateway : 0
        else
          @active_gateway = PaymentConfiguration.first_active_gateway
        end
        @custom_gateway = (@active_gateway.nil? or @active_gateway==0) ? false : CustomGateway.find(@active_gateway)
        @partial_payment_enabled = PaymentConfiguration.is_partial_payment_enabled?
      end
    end
    @fine_detail_flag = true
    hostname = "#{request.protocol}#{request.host_with_port}"

    @student_type = params[:student_type]
    @student=Student.find(params[:id]) if @student_type == 'Student'
    @student = ArchivedStudent.find(params[:id]) if @student_type == 'ArchivedStudent'
    student_id = @student_type == 'Student' ? @student.id : @student.former_id
    
    @transport_fee= TransportFee.find_by_transport_fee_collection_id_and_receiver_id(params[:id2], student_id)
    @fee_collection = TransportFeeCollection.find(params[:id2])
    
    # calculating advance fees used
    @advance_fee_used = @fee_collection.finance_transaction.all(:conditions => {:payee_id => student_id}).sum(&:wallet_amount).to_f if @fee_collection.present?
    
    @date = @fee_collection
    @amount = @transport_fee.bus_fare
    @paid_fees = @transport_fee.finance_transactions(:include => :transaction_ledger)
    @receiver_profile = true
    @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today_with_timezone
    financial_year_check
    discount_details
    days=(Date.today_with_timezone-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    @fine_amount=0
    @paid_fine=0
    bal= (@transport_fee.bus_fare-@discount_amount).to_f
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      if Configuration.is_fine_settings_enabled? && @transport_fee.balance_fine.present? && @transport_fee.balance <= 0
        @fine_amount = @transport_fee.balance_fine
      elsif @fine_rule.present?
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100
        @fine_amount=@fine_amount-@transport_fee.finance_transactions.find(:all,
          :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
      end
    end
    #    if @transport_fee.tax_enabled?
    #      @tax_collections = @transport_fee.tax_collections.all(:include => :tax_slab)
    #      @total_tax = @tax_collections.map(&:tax_amount).sum.to_f
    #      #      @tax_slabs = @tax_collections.map {|tax_col| tax_col.tax_slab }.uniq
    #      @tax_collections = @tax_collections.group_by {|x| x.tax_slab }
    #    end
    @tax_slab = @date.collection_tax_slabs.try(:last) if @transport_fee.tax_enabled?
    if params[:create_transaction].present? and @custom_gateway != false
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
      amount_to_pay = precision_label(@transport_fee.balance.to_f).to_f
      amount_to_pay += precision_label(@fine_amount).to_f if @fine_amount.present?
      amount_from_gateway = 0
      amount_from_gateway = ((@custom_gateway.present? and params[:wallet_amount_applied].present?) ? (gateway_response[:amount] + params[:wallet_amount].to_f) : gateway_response[:amount])
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
            amount_from_gateway = ((@custom_gateway.present? and params[:wallet_amount_applied].present?) ? (gateway_response[:amount] + params[:wallet_amount].to_f) : gateway_response[:amount])
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
                transaction.wallet_amount_applied = params[:wallet_amount_applied] if params[:wallet_amount_applied].present?
                transaction.wallet_amount = params[:wallet_amount] if params[:wallet_amount].present?
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
                flash[:notice] = "#{t('payment_success')} <br>  #{t('payment_reference')} : #{online_transaction_id}"
                tr_status = "success"
                tr_ref = online_transaction_id
                reason = payment.gateway_response[:reason_code]
                if current_user.parent?
                  user = current_user
                else
                  user = @student.user
                end
                if @student.is_email_enabled && user.email.present?
                  begin
                    Delayed::Job.enqueue(OnlinePayment::PaymentMail.new(finance_payment.fee_collection.name, user.email, user.full_name, @custom_gateway.name, FedenaPrecision.set_and_modify_precision(payment.gateway_response[:amount]), online_transaction_id, payment.gateway_response, user.school_details, hostname))
                  rescue Exception => e
                    puts "Error------#{e.message}------#{e.backtrace.inspect}"
                    return
                  end
                end

              else
                status = SingleFeePayment.payment_status_mapping[:failed]
                payment.update_attributes(:status_description => status)
                flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
                tr_status = "failure"
                tr_ref = payment.gateway_response[:transaction_reference]
                reason = payment.gateway_response[:reason_code]
              end

            else
              status = SingleFeePayment.payment_status_mapping[:failed]
              payment.update_attributes(:status_description => status)
              flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
              tr_status = "failure"
              tr_ref = payment.gateway_response[:transaction_reference]
              reason = payment.gateway_response[:reason_code]
            end

          else
            flash[:notice] = "#{t('flash_payed')}"
            tr_status = "failure"
            tr_ref = payment.gateway_response[:transaction_reference]
            reason = "#{t('flash_payed')}"
          end
        else
          reason = payment.status == false ? payment.gateway_response[:reason_code] : "#{t('partial_payment_disabled')}"
          flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{reason}"
          tr_status = "failure"
          tr_ref = payment.gateway_response[:transaction_reference]
        end
      else
        flash[:notice] = "#{t('flash_payed')}"
        tr_status = "failure"
        tr_ref = payment.gateway_response[:transaction_reference]
        reason = "#{t('flash_payed')}"
      end
      if session[:mobile] == true
        redirect_to :controller => "payment_settings", :action => "complete_payment", :student_id => @student.id,
          :fee_collection_id => @fee_collection.id, :collection_type => "transport", :transaction_status => tr_status,
          :reason => reason, :transaction_id=>tr_ref
      else
        redirect_to :controller => 'transport_fee', :action => 'student_profile_fee_details', :id => params[:id], :id2 => params[:id2]
      end
    else
      check_if_mobile_user
      if @ret==true
        @page_title=t('fees_text')
        render 'transport_fee/mobile_fee_details', :layout=>"mobile"
      else
        render 'transport_fee/fees_payment/student_profile_fee_details'
      end
    end
  end

  def delete_transport_transaction

    @financetransaction=FinanceTransaction.find(params[:transaction_id])
    @transport_fee= @financetransaction.finance
    # the following query (till end of transaction block) is to delete the waiver discount in transport fee discount
    transport_fee_discounts = @transport_fee.transport_fee_discounts
    transport_fee_discount_record = transport_fee_discounts.detect{|x| x.finance_transaction_id.present?} if transport_fee_discounts.present?
    tfd_id = transport_fee_discount_record.id
    transaction_id = params[:transaction_id]
    @transport_fee.reload
    if @transport_fee.tax_enabled
      @transport_fee_collection = @transport_fee.transport_fee_collection
      @tax_slab = @transport_fee_collection.collection_tax_slabs.try(:last)
    end
    @date=@transport_fee.transport_fee_collection
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      finance_payment = @financetransaction.finance_payment
      unless  finance_payment.nil?
        status = Payment.payment_status_mapping[:reverted]
        finance_payment.payment.update_attributes(:status_description => status)
      end
    end

    ActiveRecord::Base.transaction do
      if @financetransaction
        @financetransaction.cancel_reason = params[:reason]
        transaction_ledger = @financetransaction.transaction_ledger
        if transaction_ledger.transaction_mode == 'SINGLE'
          transaction_ledger.mark_cancelled(params[:reason])
          @transport_fee.reload
          UserEvent.create(:event_id=>@transport_fee.transport_fee_collection.event.id,:user_id=>@transport_fee.receiver.user_id)
        else
          if @financetransaction.destroy
            flash[:notice]="#{t('finance.flash18')}"
            @transport_fee.reload
            UserEvent.create(:event_id=>@transport_fee.transport_fee_collection.event.id,:user_id=>@transport_fee.receiver.user_id)
          else
            raise ActiveRecord::Rollback
            flash[:notice]="#{t('finance.flash32')}"
          end
        end
      end
    end
    if transport_fee_discount_record.present?
      if transport_fee_discount_record.finance_transaction_id.to_i == transaction_id.to_i
        ActiveRecord::Base.transaction do
          transport_fee_discount = TransportFeeDiscount.find(tfd_id)
          transport_fee_discount.destroy if transport_fee_discount.present?
          DiscountParticularLog.create(:amount => transport_fee_discount_record.discount, :is_amount => transport_fee_discount_record.is_amount,
            :receiver_type => "FeeDiscount", :finance_fee_id => @transport_fee.id, :user_id => current_user.id,
            :name => transport_fee_discount_record.name)
          @transport_fee.reload
          #        FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
        end
      end
    end

    if @transport_fee.receiver_type=="Employee"
      redirect_to :action => 'fees_submission_employee', :employee => params[:id], :date => params[:date], :hide_popup => 1
    else
      redirect_to :action => 'fees_submission_student', :student => params[:id], :date => params[:date], :hide_popup => 1
      #      render :js=> "new Ajax.Request('/transport_fee/transport_fee_collection_details', {method: 'get',parameters: {student: #{@transport_fee.receiver_id},batch_id:#{@transport_fee.receiver.batch_id},date:#{@transport_fee.transport_fee_collection_id}}});"
    end
    #    render :update do |page|
    #          page.replace_html 'payments_details',:text => ''
    #        end
  end

  def receiver_wise_collection_new
    @transport_fee_collection = TransportFeeCollection.new
    @tax_slabs = TaxSlab.all if @tax_enabled
    render :update do |page|
      page.replace_html "collection-details", :partial => 'receiver_wise_collection_new'
    end
    # @batches =Batch.find(:all,:select=>"distinct batches.*",:joins=>"INNER JOIN students on students.batch_id=batches.id INNER JOIN transports on students.id=transports.receiver_id and transports.receiver_type='Student'",:conditions=>"batches.is_active=1 and batches.is_deleted=0")
  end


  def collection_creation_and_assign
    #    @batches =Batch.find(:all, :select => "distinct batches.*", :joins => "INNER JOIN students on students.batch_id=batches.id INNER JOIN transports on students.id=transports.receiver_id and transports.receiver_type='Student'", :conditions => "batches.is_active=1 and batches.is_deleted=0")
    #    @dates=[]
    @transport_fee_collection = TransportFeeCollection.new
    @tax_slabs = TaxSlab.all if @tax_enabled
    @fines = Fine.active
  end

  def search_student
    students= Student.active.all(:joins => "INNER JOIN transports ON transports.receiver_id = students.id AND
transports.receiver_type = 'Student'", :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and
transports.bus_fare != 0 and transports.academic_year_id = ?", "%#{params[:query]}%", "%#{params[:query]}%", @academic_year_id], :include => :transport).uniq
    employees= Employee.find(:all, :joins => "INNER JOIN transports ON transports.receiver_id = employees.id AND
transports.receiver_type = 'Employee'", :conditions => ["(employee_number LIKE ? OR first_name LIKE ?) and
transports.bus_fare != 0 and transports.academic_year_id = ?", "%#{params[:query]}%", "%#{params[:query]}%", @academic_year_id], :include => :transport).uniq
    students_suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - "+s.transport.bus_fare.to_s : s.full_name+"(#{s.admission_no})"+" - "+s.transport.bus_fare.to_s }
    employees_suggestions=employees.collect { |e| e.full_name.length+e.employee_number.length > 20 ? e.full_name[0..(18-e.employee_number.length)]+".. "+"(#{e.employee_number})"+" - "+e.transport.bus_fare.to_s : e.full_name+"(#{e.employee_number})"+" - "+e.transport.bus_fare.to_s }
    suggestions=students_suggestions+employees_suggestions
    receivers=students.map { |st| "{'receiver': 'Student','id': #{st.id}, 'bus_fare' : #{st.transport.bus_fare},'user_id':#{st.user_id},'groupable_id':#{st.batch_id},'groupable_type':'Batch'}" }+employees.map { |emp| "{'receiver': 'Employee','id': #{emp.id}, 'bus_fare' : #{emp.transport.bus_fare},'user_id':#{emp.user_id},'groupable_id':#{emp.employee_department_id},'groupable_type':'EmployeeDepartment'}" }
    if receivers.present?
      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => receivers}
    else
      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
    end
  end

  def receiver_wise_fee_collection_creation
    error=false
    # fy_id = current_financial_year_id
    @fines = Fine.active
    @tax_slabs = TaxSlab.all if @tax_enabled
    TransportFeeCollection.transaction do
      if params[:receiver].present?
        invoice_enabled = (Configuration.get_config_value('EnableInvoiceNumber').to_i == 1)
        recipients=[]
        @transport_fee_collection=TransportFeeCollection.new(params[:transport_fee_collection])
        @transport_fee_collection.invoice_enabled = invoice_enabled
        @tax_slab = TaxSlab.find_by_id(params[:transport_fee_collection][:tax_slab_id]) if @tax_enabled
        # fetching account id
        transaction_category = FinanceTransactionCategory.find_by_name 'Transport'
        account = transaction_category.get_multi_config[:account]
        account_id = (account.is_a?(Fixnum) ? account : (account.is_a?(FeeAccount) ? account.try(:id) : nil))
        # setting account id
        @transport_fee_collection.fee_account_id = account_id
        # @transport_fee_collection.financial_year_id = fy_id
        if @transport_fee_collection.save
          if @tax_slab.present?
            @transport_fee_collection.collectible_tax_slabs.build({:tax_slab_id => @tax_slab.id,
                :collectible_entity_id => @transport_fee_collection,
                :collectible_entity_type => 'TransportFeeCollection'})

            tax_multiplier = @tax_slab.rate.to_f * 0.01
          end

          groupable={}
          params[:receiver].each do |key, values|
            values.each do |k, v|
              groupable[v[:groupable_id]] = v[:groupable_type]
              v[:invoice_number_enabled] = @transport_fee_collection.invoice_enabled
              v[:tax_enabled] = @transport_fee_collection.tax_enabled
              v[:tax_amount] = v[:bus_fare].to_f * tax_multiplier if @tax_slab.present?
              @transport_fee=@transport_fee_collection.transport_fees.build(v)
              @transport_fee.tax_collections.build({:tax_amount => v[:tax_amount],
                  :slab_id => @tax_slab.id,
                  :taxable_entity_type => "TransportFeeCollection",
                  :taxable_entity_id => @transport_fee_collection}) if @tax_slab.present?
            end
          end
          collection_assignment_hsh = {:transport_fee_collection_id => @transport_fee_collection.id}
          groupable.each do |key, value|
            # link batch with transport
            TransportFeeCollectionAssignment.create(collection_assignment_hsh.merge({
                  :assignee_type => value, :assignee_id => key}))
          end
          @transport_fee_collection.save

          event=Event.new(:title => "#{t('transport_fee_text')}", :description => "#{t('fee_name')}: #{@transport_fee_collection.name}", :start_date => @transport_fee_collection.due_date.to_s, :end_date => @transport_fee_collection.due_date.to_s, :is_due => true, :origin => @transport_fee_collection)
          params[:event].each { |i, j| j.each { |k, v| event.user_events.build(v) } }
          error=true unless event.save
          params[:event].each { |i, j| j.each { |k, v| recipients<<v[:user_id] } }
          send_reminder(@transport_fee_collection, recipients)
        else
          error=true
        end
      else
        error=true
        @transport_fee_collection=TransportFeeCollection.new(params[:transport_fee_collection])
      end

      if error
        render :update do |page|
          page.replace_html "collection-details", :partial => 'receiver_wise_collection_new'
        end
        raise ActiveRecord::Rollback

      else
        flash[:notice]="#{t('collection_date_has_been_created')}"
        render :update do |page|
          page.redirect_to :action => 'collection_creation_and_assign'
        end
      end

    end
  end

  def allocate_or_deallocate_fee_collection
    @recepient = params[:recepient]
    if @recepient == 'employees'
      receiver_type = 'Employee'
      @employee_departments = EmployeeDepartment.active
    else
      receiver_type = 'Student'
      @batches = Batch.active
    end
    if request.post?
      error=false
      batch = Batch.find_by_id(params[:batch_id]) if params[:batch_id].present? and receiver_type=='Student'
      transport_entry = Transport.in_academic_year(@academic_year_id).find_by_receiver_id_and_receiver_type(params[:fees_list][:receiver_id], receiver_type)
      TransportFee.transaction do
        params[:fees_list][:collection_ids].present? ? colln_ids= params[:fees_list][:collection_ids].map(&:to_i) : colln_ids = [0]
        receiver = receiver_type.constantize.find(params[:fees_list][:receiver_id])

        #find inactive bus fees
        if transport_entry.present? and transport_entry.auto_update_fare
          active_collections = TransportFee.find(:all, :select=> "transport_fee_collection_id",
            :conditions=>["receiver_id='#{receiver.id}' and receiver_type='#{receiver_type}' and is_active=false"]).
            map{|tf| tf.transport_fee_collection_id.to_s}

          amount_ids = (params[:fees_list][:collection_ids]) & active_collections

          TransportFee.update_all({:bus_fare=>transport_entry.bus_fare.to_f,
              :balance=> transport_entry.bus_fare.to_f}, ["receiver_id='#{receiver.id}' and
                  receiver_type='#{receiver_type}' and transport_fee_collection_id in (?)", amount_ids])
        end

        ids_with_transactions = TransportFee.find(:all,
          :conditions=>['transaction_id is not null and receiver_id=? and receiver_type=? and is_active=?',
            receiver.id, receiver_type, true]).map{|tf| tf.transport_fee_collection_id.to_i}
        colln_ids = (colln_ids + ids_with_transactions).uniq
        colln_ids -= [0] if (colln_ids.present? and ids_with_transactions.present?)
        if receiver_type == "Student"
          TransportFee.update_all({:groupable_id => receiver.batch.id }, ["receiver_id='#{receiver.id}' and 
-                                               receiver_type='#{receiver_type}' and is_active = false and
                                                transport_fee_collection_id in (?)", colln_ids])
          TransportFee.update_all(["is_active = true"], ["receiver_id='#{receiver.id}' and 
-                                               receiver_type='#{receiver_type}' and groupable_id = '#{receiver.batch.id}' and 
                                                transport_fee_collection_id in (?)", colln_ids])
          active_tf_ids = TransportFee.all(:conditions => ["receiver_id='#{receiver.id}' and
                                               receiver_type='#{receiver_type}' and groupable_id=#{receiver.batch.id} and
                                               transport_fee_collection_id in (?)", colln_ids]).map(&:id)
          existing_tfc_ids = TransportFee.find(:all,:conditions => ["receiver_id=? and groupable_id=? and
                     receiver_type='Student' and groupable_type='Batch'",receiver.id,receiver.batch.id]).
            map(&:transport_fee_collection_id)
          t_fees = TransportFee.find(:all, :conditions => ["receiver_id='#{receiver.id}' and
                        receiver_type='#{receiver_type}' and transport_fee_collection_id not in (?)", colln_ids])
          @disabled_fee_ids = t_fees.present? ? TransportFeeDiscount.all(
            :conditions => "transport_fee_id IN (#{t_fees.map(&:id).join(',')}) AND
                                    multi_fee_discount_id IS NOT NULL",
            :select => "transport_fee_id").map {|x| x.transport_fee_id.to_i } : []
          inactive_ids = []
          transport_fee_to_destroy = []
          transport_fee_id_to_destroy = []
          t_fees.each do |tf|
            if batch.id == tf.groupable_id
              inactive_ids << tf.id unless @disabled_fee_ids.include?(tf.id)
              #              tf.is_active = false
              #              tf.save unless @disabled_fee_ids.include?(tf.id)
            else
              unless @disabled_fee_ids.include?(tf.id)
                if tf.is_active
                  transport_fee_to_destroy << tf
                  transport_fee_id_to_destroy << tf.id
                end
              end
              #              tf.destroy unless @disabled_fee_ids.include?(tf.id)
            end
          end
          TransportFee.update_all("is_active=false",["id in (?)",inactive_ids])  if inactive_ids.present?
          TransportFee.update_all("is_active=false",["id in (?)",transport_fee_id_to_destroy])  if transport_fee_id_to_destroy.present?
          Delayed::Job.enqueue(DelayedManageFeeCollectionJob.new(transport_fee_to_destroy)) if transport_fee_to_destroy.present?
          TransportFee.update_collection_report({:fees_to_remove => (inactive_ids + transport_fee_id_to_destroy).uniq,
              :fees_to_insert => active_tf_ids})
        else
          TransportFee.update_all("is_active=false", ["receiver_id='#{receiver.id}' and
                            receiver_type='#{receiver_type}' and transport_fee_collection_id not in (?)", colln_ids])
          TransportFee.update_all(["is_active=true"], ["receiver_id='#{receiver.id}' and
                                  receiver_type='#{receiver_type}' and transport_fee_collection_id in (?)", colln_ids])
          existing_tfc_ids = TransportFee.find(:all,:conditions => ["receiver_id=? and groupable_id=? and
                                         receiver_type='Employee' and groupable_type='EmployeeDepartment'",
              receiver.id,receiver.employee_department.id]).map(&:transport_fee_collection_id)
        end
        new_colln_ids = colln_ids - existing_tfc_ids
        if new_colln_ids.present? and new_colln_ids != [0]
          @transport_fee_collections = TransportFeeCollection.find(new_colln_ids)
          if @transport_fee_collections.present?
            if receiver_type == "Student"
              transport = receiver.transport
              @transport_fee_collections.each do |tfc|
                if transport.bus_fare != 0
                  @transport_fee = TransportFee.new(:receiver => receiver, :bus_fare => transport.bus_fare,
                    :transport_fee_collection_id => tfc.id,:groupable=>receiver.batch,
                    :invoice_number_enabled => tfc.invoice_enabled)
                  @transport_fee.tax_enabled_on_creation(tfc)
                  @transport_fee.save
                end
              end
            else
              employee_transport = Transport.in_academic_year(@academic_year_id).find_by_receiver_id(receiver.id,
                :conditions => ["receiver_type = 'Employee'"])
              @transport_fee_collections.each do |tfc|
                if employee_transport.bus_fare != 0
                  @transport_fee = TransportFee.new(:receiver => receiver,
                    :bus_fare => employee_transport.bus_fare,
                    :transport_fee_collection_id => tfc.id,
                    :groupable=>receiver.employee_department)
                  @transport_fee.tax_enabled_on_creation(tfc)
                  @transport_fee.save
                end
              end
            end
          end
        end

        receiver.send(:attributes=, params[:new_collection_ids])
        receiver.save(false)
        user_events = UserEvent.create(params[:user_events].values) if params[:user_events].present?

        if (error)
          render :update do |page|
            page.replace_html 'flash-div', :text => "<div id='error-box'><ul><li>#{t('fees_text')} #{t('transport_fee.allocation')} #{t('failed')}</li></ul></div>"
          end
          raise ActiveRecord::Rollback
        else
          render :update do |page|
            page.replace_html 'flash-div', :text => "<p class='flash-msg'>#{receiver_type=='Student' ?
            t('fee_collections_are_updated_to_the_student_successfully') :
            t('transport_fee.fee_collections_are_updated_to_the_employee_successfully')} </p>"
          end
        end
      end
    end
  end

  def list_students_by_batch
    @receivers = Student.find_all_by_batch_id(params[:batch_id], :select => 'distinct students.*',
      :joins => "INNER JOIN transports ON transports.receiver_id = students.id AND transports.receiver_type = 'Student'", :order => 'first_name ASC')
    @batch = Batch.find_by_id(params[:batch_id])
    unless @receivers.blank?
      @receiver = @receivers.first
      receiver_fee_collections("Student")
    end
    render :partial => 'receivers_list'
  end

  def list_employees_by_department
    @receivers = Employee.find(:all, :select => 'distinct employees.*',
      :joins => "INNER JOIN transports ON transports.receiver_id = employees.id AND transports.receiver_type = 'Employee'",
      :conditions => "employees.employee_department_id='#{params[:department_id]}'", :order => 'first_name ASC')
    unless @receivers.blank?
      @receiver = @receivers.first
      receiver_fee_collections("Employee")
    end
    render :partial => 'receivers_list'
  end

  def list_fees_for_student
    @receiver = Student.find_by_id(params[:receiver])
    @batch = Batch.find_by_id(params[:batch_id])
    receiver_fee_collections("Student")
    render :update do |page|
      page.replace_html 'fees_list', :partial => 'fees_list'
      page.replace_html 'financial_year_details', :partial => 'finance/financial_year_info'
    end
  end

  def list_fees_for_employee
    @receiver = Employee.find_by_id(params[:receiver])
    receiver_fee_collections("Employee")
    render :update do |page|
      page.replace_html 'fees_list', :partial => 'fees_list'
      page.replace_html 'financial_year_details', :partial => 'finance/financial_year_info'
    end
  end

  def list_students_for_collection
    @collection=TransportFeeCollection.find(params[:date_id], :include => :transport_fees)
    student_ids=@collection.transport_fees.all(:conditions => {:receiver_type => 'Student'}).collect(&:receiver_id)
    student_ids=student_ids.join(',')

    students = Student.active.find(:all, :joins => "INNER JOIN transports ON transports.receiver_id = students.id AND transports.receiver_type = 'Student'",
      :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and students.id not in (#{student_ids}) and
                                 batch_id='#{params[:batch_id]}' and transports.bus_fare != 0", "%#{params[:query]}%",
        "%#{params[:query]}%"]).uniq
    suggestions = students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - "+s.transport.bus_fare.to_s : s.full_name+"(#{s.admission_no})"+" - "+s.transport.bus_fare.to_s }
    receivers = students.map { |st| "{'receiver': 'Student','id': #{st.id}, 'bus_fare' : #{st.transport.bus_fare},'user_id':#{st.user_id},'groupable_id':#{st.batch_id},'groupable_type':'Batch'}" }
    if receivers.present?
      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => receivers}
    else
      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
    end
  end

  def render_collection_assign_form
    @transport_fee_collection=TransportFeeCollection.find(params[:id])
    render :update do |page|
      page.replace_html 'students_selection', :partial => 'students_selection'
    end
  end


  def list_fee_collections_for_employees
    @receiver=Employee.find(params[:receiver_id])
    params[:collection_ids].present? ? colln_ids=params[:collection_ids] : colln_ids=[0]
    fee_collections= TransportFeeCollection.find(:all, :include => :event,
      :select => "distinct transport_fee_collections.*", :joins => :transport_fees,
      :conditions => ["(name LIKE ?) and transport_fee_collections.id not in (?) and  (transport_fee_collections.batch_id is null)",
        "%#{params[:query]}%", colln_ids])
    data_values=fee_collections.map { |f| "{'id':#{f.id}, 'event_id' : #{f.event.id}}" }
    render :json => {'query' => params["query"], 'suggestions' => fee_collections.collect { |fc| fc.name.length+fc.start_date.to_s.length > 20 ? fc.name[0..(18-fc.start_date.to_s.length)]+".. "+" - "+fc.start_date.to_s : fc.name+" - "+fc.start_date.to_s }, 'data' => data_values}
  end

  def choose_collection_and_assign
    @batches =Batch.find(:all, :select => "distinct batches.*", :joins => "INNER JOIN students on students.batch_id=batches.id INNER JOIN transports on students.id=transports.receiver_id and transports.receiver_type='Student'", :conditions => "batches.is_active=1 and batches.is_deleted=0")
    @dates=[]
    render :update do |page|
      page.replace_html "collection-details", :partial => 'choose_collection_and_assign'
    end
  end


  def update_fees_collections
    @dates=TransportFeeCollection.all(:select=>"DISTINCT transport_fee_collections.*",
      :joins=>"INNER JOIN transport_fees tf on tf.transport_fee_collection_id=transport_fee_collections.id
                    INNER JOIN students on students.id=tf.receiver_id and tf.receiver_type='Student'",
      :conditions=>["students.batch_id=?",params[:batch_id]])
    render :update do |page|
      page.replace_html 'fees_collection_dates', :partial => 'fees_collection_dates'
    end
  end

  def collection_assign_students
    @transport_fee_collection=TransportFeeCollection.find(params[:transport_fee_collection][:id])
    event=@transport_fee_collection.event
    student_fees = params[:receiver][:Student].values
    if @transport_fee_collection.tax_enabled
      tax_slab = @transport_fee_collection.collection_tax_slabs.try(:last)
      tax_multiplier = tax_slab.rate.to_f * 0.01 if tax_slab.present?
      tax_collection_hsh = {
        :taxable_entity_id => @transport_fee_collection.id,
        :taxable_entity_type => 'TransportFeeCollection',
        :taxable_fee_type => 'TransportFee'
      } if tax_slab.present?
      student_fees.each_with_index do |student_fee, i|
        student_fee["invoice_number_enabled"] = @transport_fee_collection.invoice_enabled
        if tax_slab.present?
          tax = student_fee["bus_fare"].to_f * tax_multiplier
          student_fee_tax = tax_collection_hsh.dup.merge({ :tax_amount => tax, :slab_id => tax_slab.id })
          student_fee["tax_amount"] = tax
          student_fee["tax_enabled"] = @transport_fee_collection.tax_enabled
          student_fee['tax_collections_attributes'] = [student_fee_tax]
          student_fees[i] = student_fee
        end
      end
    end
    @transport_fee_collection.update_attributes(:transport_fees_attributes => student_fees)

    recipients=[]
    if (params[:event].present? and params[:event][:Student].present?)
      params[:event][:Student].each { |k, v| recipients<<v["user_id"] }
      send_reminder(@transport_fee_collection, recipients)
      user_events=event.user_events.create(params[:event][:Student].values) if event
    end
    flash[:notice]="#{t('collection_date_has_been_created')}"
    redirect_to :action => 'collection_creation_and_assign'
  end

  def show_employee_departments

    @employee_departments=EmployeeDepartment.active.sort_by { |e| e.name.downcase }

    render :update do |page|
      page.replace_html 'batch_or_department', :partial => 'departments'
    end

  end

  def show_student_batches
    @batches = Batch.active

    render :update do |page|
      page.replace_html 'batch_or_department', :partial => 'batches'
    end
  end

  def pay_batch_wise
    @batches = Batch.active.all(:include => :course)
    @transport_fee_collections = []

    render "transport_fee/fees_payment/pay_batch_wise"
  end

  def transport_fee_search

  end

  def fetch_waiver_amount_transport_fee
    waiver_check = params[:id]
    collections = params[:collection]
    balance =100
    balance = TransportFeeDiscount.fetch_waiver_balance(collections)
    waiver_amount = balance.to_f
    render :json => {'attributes' => waiver_amount.to_f}
  end

  private

  def load_tax_setting
    @tax_enabled = Configuration.get_config_value('EnableFinanceTax').to_i == 1
  end

  def check_if_mobile_user
    user_agents=["android","ipod","opera mini","opera mobi","blackberry","palm","hiptop","avantgo","plucker", "xiino","blazer","elaine", "windows ce; ppc;", "windows ce; smartphone;","windows ce; iemobile", "up.browser","up.link","mmp","symbian","smartphone", "midp","wap","vodafone","o2","pocket","kindle", "mobile","pda","psp","treo"]
    @ret=false
    if FedenaPlugin.can_access_plugin?("fedena_mobile")
      user_agents.each do |ua|
        if request.env["HTTP_USER_AGENT"].downcase=~ /#{ua}/i
          @ret=true
          return
        end
      end
    end
  end

  def receiver_fee_collections(receiver_type)
    unless receiver_type == "Student"
      groupable = @receiver.employee_department
      @fee_collection_dates = groupable.transport_fee_collections.current_active_financial_year.all(
        :joins => "LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id",
        :conditions => "#{active_account_conditions(true, 'transport_fee_collections')}")
    else
      groupable = @receiver.batch
      current_fee_collection_dates = groupable.transport_fee_collections.current_active_financial_year.all(
        :joins => "LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id",
        :conditions => "#{active_account_conditions(true, 'transport_fee_collections')}")

      previous_fee_collection_dates = TransportFeeCollection.current_active_financial_year.all(
        :joins => "INNER JOIN transport_fees ON transport_fees.transport_fee_collection_id = transport_fee_collections.id
                    LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id",
        :conditions => ["transport_fees.receiver_id = ? AND transport_fees.receiver_type = ? AND transport_fees.groupable_id <> ?
                        AND transport_fees.groupable_type = ? AND transport_fees.is_paid = false and transport_fees.is_active = true
                        AND transport_fees.transaction_id IS NULL AND
                        #{active_account_conditions(true, 'transport_fee_collections')}",
          @receiver.id,'Student',groupable.id,'Batch'])
      @fee_collection_dates = current_fee_collection_dates + previous_fee_collection_dates
      @fee_collection_dates = @fee_collection_dates.uniq
    end
    transport_fees = TransportFee.find(:all,
      :include => {:transport_fee_discounts => :transport_transaction_discount},
      :conditions => ["receiver_id=? and receiver_type=? and transport_fee_collection_id in (?)",@receiver.id,
        receiver_type, @fee_collection_dates.collect(&:id)],
      :group => "transport_fees.transport_fee_collection_id",
      :select => "transport_fees.id AS fee_id, transport_fee_collection_id, transport_fees.id,
                        IF(FIND_IN_SET(0,group_concat(transport_fees.is_active)) > 0,0,1) AS collection_active,
                        IF(group_concat(transport_fees.transaction_id),true,false) AS transaction_id_present")
    @disabled_fee_ids = transport_fees.present? ? TransportFeeDiscount.all(
      :conditions => "transport_fee_id IN (#{transport_fees.map(&:fee_id).join(',')}) AND
                              multi_fee_discount_id IS NOT NULL",
      :select => "transport_fee_id").map {|x| x.transport_fee_id.to_i } : []
    @transport_fees = transport_fees.group_by{|x| x.transport_fee_collection_id }
  end

  def discount_details

    @transport_fee_discounts = @transport_fee.transport_fee_discounts
    @discount_amount = @transport_fee.total_discount_amount

  end

  def fine_details

    days=(@payment_date-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    @fine_amount=0
    @paid_fine=0
    bal= (@transport_fee.bus_fare-@discount_amount).to_f
    if days > 0 and auto_fine and !@transport_fee.is_fine_waiver
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      if Configuration.is_fine_settings_enabled? && @transport_fee.balance_fine.present? && @transport_fee.balance <= 0 && @transport_fee.is_paid == false
        @fine_amount = precision_label(@transport_fee.balance_fine).to_f
      elsif @fine_rule
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100
        @fine_amount=precision_label(@fine_amount).to_f-precision_label(@transport_fee.finance_transactions.find(:all,
            :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)).to_f

      end
    end

  end

  def update_transport_fine_amount(fine_waiver_flag, transport_fee)
    if fine_waiver_flag && transport_fee.balance <= 0 && !transport_fee.is_paid
      @transport_fee.update_attributes(:is_fine_waiver=>fine_waiver_flag, :is_paid=>true)
    end
  end
  
  def calculate_auto_fine_for_waiver_tracker    
    days=(@payment_date-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    fine_amount=0
    bal= (@transport_fee.bus_fare-@discount_amount).to_f
    if days > 0 and auto_fine and !@transport_fee.is_fine_waiver
      fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      if Configuration.is_fine_settings_enabled? && @transport_fee.balance_fine.present? && @transport_fee.balance <= 0 && @transport_fee.is_paid == false
        fine_amount = precision_label(@transport_fee.balance_fine).to_f
      elsif fine_rule
        fine_amount =fine_rule.is_amount ? fine_rule.fine_amount : (bal*fine_rule.fine_amount)/100
        fine_amount=precision_label(fine_amount).to_f-precision_label(@transport_fee.finance_transactions.find(:all,
            :conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)).to_f

      end
    end
    finance_type = "TransportFee"
    @transport_fee.track_fine_calculation(finance_type, fine_amount, @financefee.id)
  end

end
