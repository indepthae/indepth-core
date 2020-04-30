class HostelFeeController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation
  require 'authorize_net'
  helper :authorize_net
  before_filter :login_required
  before_filter :set_precision
  filter_access_to :all
  filter_access_to :student_profile_fee_details, :attribute_check => true, :load_method => lambda {  params[:student_type] == 'Student' ? Student.find(params[:id]) : ArchivedStudent.find(params[:id]) }
  filter_access_to :student_fee_receipt_pdf, :attribute_check => true, :load_method => lambda { HostelFee.find params[:id] }
  protect_from_forgery :except => [:student_profile_fee_details]
  before_filter :load_tax_setting, :only => [:hostel_fee_collection_new, :hostel_fee_collection_create,
    :student_wise_fee_collection_new]
  check_request_fingerprint :delete_hostel_fee_transaction

  # renders form for new hostel fee collection
  def hostel_fee_collection_new
    @hostel_fee_collection = HostelFeeCollection.new
    @batches = Batch.active.reject { |b| !b.room_allocations_present }
    @tax_slabs = TaxSlab.all if @tax_enabled
    @start_date, @end_date = FinancialYear.fetch_current_range
  end

  def send_reminder(hostel_fee_collection, recipients)
    body = "#{t('hostel_text')} #{t('fee_collection_date_for')} <b> #{hostel_fee_collection.name} </b> #{t('has_been_published')} #{t('by')} <b>#{current_user.full_name}</b>, #{t('start_date')} : #{format_date(hostel_fee_collection.start_date)}  #{t('due_date')} :  #{format_date(hostel_fee_collection.due_date)} "
    links = {:target => 'view_fees', :target_param => 'student_id'}
    inform(recipients, body, 'Finance', links)
  end

  # record new hostel fee collection
  def hostel_fee_collection_create
    @hostel_fee_collection = HostelFeeCollection.new
    @batches = Batch.active.reject { |b| !b.room_allocations_present }
    @tax_slabs = TaxSlab.all if @tax_enabled
    if request.post?
      @batch = params[:hostel_fee_collection][:batch_id]
      parameter=params[:hostel_fee_collection]
      parameter.delete("batch_ids")
      @hostel_fee_collection = HostelFeeCollection.new(parameter)
      @hostel_fee_collection.valid?
      @hostel_fee_collection.errors.add_to_base("#{t('no_batch_selected')}") if @batch.nil?
      if @hostel_fee_collection.errors.empty?
        Delayed::Job.enqueue(DelayedHostelFeeCollectionJob.new(current_user, @batch, params[:hostel_fee_collection]))
        flash[:notice]="Collection is in queue. <a href='/scheduled_jobs/HostelFeeCollection/1'>Click Here</a> to view the scheduled job."
        redirect_to :action => 'hostel_fee_collection_view'
      else
        render :action => 'hostel_fee_collection_new'
      end
    else
      render :action => 'hostel_fee_collection_new'
    end
  end

  def hostel_fee_collection_view
    @batches = Batch.active.all(:include => :course)
  end

  def batchwise_collection_dates
    unless params[:batch_id]==""
      #       @hostel_fee_collection = HostelFeeCollection.find(:all, :select => 'distinct hostel_fee_collections.*', :joins => {:hostel_fees => :student}, :conditions => "hostel_fees.batch_id = #{params[:batch_id]} and hostel_fee_collections.is_deleted = false and hostel_fees.is_active=true", :include => {:batch => :course})
      @hostel_fee_collection = HostelFeeCollection.current_active_financial_year.all(
        :joins => " #{active_account_joins(true, 'hostel_fee_collections')}
                        INNER JOIN hostel_fees ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id",
        :conditions => ["hostel_fees.batch_id = ? AND hostel_fees.is_active = true AND hostel_fee_collections.is_deleted = false AND
                             #{active_account_conditions(true, 'hostel_fee_collections')}", params[:batch_id]],
        :group => :id, :select => "hostel_fee_collections.*,hostel_fees.batch_id as hostel_batch_id")
      render(:update) do |page|
        page.replace_html 'flash', :text => ""
        page.replace_html "financial_year_details", :partial => "finance/financial_year_info"
        page.replace_html "fee-collection-edit", :partial => "fee_collection_edit"
      end
    else
      render(:update) do |page|
        page.replace_html 'flash', :text => ""
        page.replace_html "financial_year_details", :partial => "finance/financial_year_info"
        page.replace_html "fee-collection-edit", :text => ""
      end
    end
  end

  # renders batch-wise hostel fee collection payment page
  def hostel_fee_pay
    @batches = Batch.active.all(:include => :course)
    @hostel_fee_collection = []

    render "hostel_fee/fees_payment/hostel_fee_pay"
  end

  def hostel_fee_collection_edit
    @batch_id=params[:batch_id]
    @hostel_fee_collection = HostelFeeCollection.find params[:id]
  end

  def update_hostel_fee_collection_date
    hostel_fee_collection = HostelFeeCollection.find params[:id]
    render :update do |page|
      if params[:hostel_fee_collection][:due_date].to_date >= params[:hostel_fee_collection][:start_date].to_date
        if hostel_fee_collection.update_attributes(params[:hostel_fee_collection])
          hostel_fee_collection.event.update_attributes(:start_date => hostel_fee_collection.due_date.to_datetime, :end_date => hostel_fee_collection.due_date.to_datetime)
          page.replace_html 'form-errors', :text => ''
          page << "Modalbox.hide();"
          page.replace_html 'flash', :text => "<p class='flash-msg'>#{t('hostel_fee.hostel_flash12')} </p>"
          # @hostel_fee_collection = HostelFeeCollection.all(:joins => :hostel_fees, :conditions => {:hostel_fees => {:batch_id => params[:batch_id], :is_active => true}, :is_deleted => false, }, :group => :id, :select => "hostel_fee_collections.*,hostel_fees.batch_id as hostel_batch_id")
          @hostel_fee_collection = HostelFeeCollection.current_active_financial_year.all(:joins => :hostel_fees,
            :conditions => ["hostel_fees.batch_id = ? AND hostel_fees.is_active = true AND is_deleted = false",
              params[:batch_id]], :group => :id,
            :select => "hostel_fee_collections.*,hostel_fees.batch_id as hostel_batch_id")
          page.replace_html 'fee-collection-edit', :partial => 'fee_collection_edit', :object => @hostel_fee_collection
        else
          page.replace_html 'flash', :text => ""
          page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => hostel_fee_collection
          page.visual_effect(:highlight, 'form-errors')
        end
      else
        page.replace_html 'form-errors', :text => "<div id='error-box'><ul><li>#{t('hostel_fee.hostel_flash13')}</li></ul></div>"
        flash[:notice]=""
      end
    end
  end

  def update_fee_collection_dates
    # @hostel_fee_collection = HostelFeeCollection.find_all_by_batch_id(params[:batch_id],:conditions=>{:is_deleted => false})
    @hostel_fee_collection=HostelFeeCollection.find(:all,
      :select => "distinct hostel_fee_collections.*",
      :joins => " #{active_account_joins(true, 'hostel_fee_collections')}
                 INNER JOIN hostel_fees ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id",
      :conditions => "hostel_fees.batch_id='#{params[:batch_id]}' AND
                      hostel_fees.is_active=1 AND hostel_fee_collections.is_deleted=false AND
                      #{active_account_conditions(true, 'hostel_fee_collections')}")
    render :update do |page|
      page.replace_html "hostel_fee_collection_dates", :partial => 'hostel_fee_collection_dates'
    end
  end

  # fetches and renders hostel fee collection details for respective batch and
  # one of first student with hostel fee under selected hostel fee collection
  def hostel_fee_collection_details
    flash[:notice] = nil
    flash[:warn_notice] = nil
    @target_action = 'hostel_fee_collection_details'
    fine = params[:fees].present? ? params[:fees][:fine_amount].to_f : nil
    @date = HostelFeeCollection.find_by_id(params[:date], :joins => " #{active_account_joins(true, 'hostel_fee_collections')}",
      :select => "hostel_fee_collections.*, IFNULL(fa.is_deleted, false) AS is_account_deleted")
    
    if @date.present? and @date.is_account_deleted?
      render :update do |page|
        flash[:notice] = t('flash_msg5')
        page.redirect_to :controller => "user", :action => "dashboard"
      end
    else
      @batch = Batch.find(params[:batch_id])
      additional_conditions = params[:defaulters].present? ? " AND hostel_fees.balance <> 0" : ""
      additional_conditions += " AND #{active_account_conditions(true, 'hfc')}"

      @students = @date.present? ? Student.find(:all,
        :joins => "INNER JOIN hostel_fees ON hostel_fees.student_id = students.id
                 INNER JOIN hostel_fee_collections hfc ON hfc.id = hostel_fees.hostel_fee_collection_id
                   #{active_account_joins(true, 'hfc')}",
        :conditions => ["hostel_fees.hostel_fee_collection_id='#{@date.id}' AND
                      hostel_fees.is_active=1 AND hostel_fees.batch_id=? #{additional_conditions}", @batch.id],
        :order => "id ASC") : [] #unless params[:defaulters].present?
      # @students = Student.find(:all, :joins => :hostel_fees,
      #   :conditions => "hostel_fees.hostel_fee_collection_id='#{@date.id}' and
      #                   hostel_fees.is_active=1 and hostel_fees.batch_id='#{@batch.id}' and
      #                   hostel_fees.balance!=0", :order => "id ASC") if params[:defaulters].present?

      if params[:student].present?
        @student = Student.find(params[:student])
      else
        @student = @students.first
      end

      # calculating advance fee used
      @advance_fee_used = @date.finance_transaction.all(:conditions => {:payee_id => @student.id}).sum(&:wallet_amount).to_f

      unless @student.nil?
        @prev_student=@students.select { |student| student.id<@student.id }.last||@students.last
        @next_student=@students.select { |student| student.id>@student.id }.first||@students.first
        @hostel_fee = HostelFee.find_by_student_id_and_hostel_fee_collection_id(@student.id, @date.id)
        @tax_slab = @date.collection_tax_slabs.try(:last) if @date.tax_enabled
        if fine
          @hostel_fee.has_fine=true
          @attribute_set= Proc.new { {:readonly => true, :tooltip => "remove fine for partial payment"} }
          @hostel_fee.finance_transactions_with_fine.new(:fine_included => true, :fine_amount => fine)
          @hostel_fee.balance = @hostel_fee.balance.to_f+fine
        end
        @finance_transaction=@hostel_fee.finance_transactions_with_fine.first
        @transaction_date = @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today_with_timezone
        financial_year_check
        
        render :update do |page|
          page.replace_html "fees_detail", :partial => 'hostel_fee/fees_payment/fees_submission_form'
        end
      else
        render :update do |page|
          msg = @date.present? ? (params[:defaulters].present? ? t('no_fees_to_pay') : t('no_fee_defaulters')) : t('flash_msg5')
          page.replace_html "fees_detail", :text => "<p class = 'flash-msg'> #{msg}</p>"
        end
      end
    end
  end


  def hostel_fee_defaulters
    @batches = Batch.all(
      :joins => "INNER JOIN students ON students.batch_id = batches.id
                   INNER JOIN hostel_fees ON hostel_fees.student_id = students.id
                   INNER JOIN hostel_fee_collections ON hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id
                    #{active_account_joins(true, 'hostel_fee_collections')}",
      :conditions => ["#{active_account_conditions(true, 'hostel_fee_collections')} AND batches.is_deleted=? and
                         batches.is_active=? and hostel_fee_collections.is_deleted=? and hostel_fee_collections.due_date < ? and
                         hostel_fees.rent > ? and hostel_fees.balance > 0", false, true, false, Date.today, 0.0],
      :group => "batches.id")
    @hostel_fee_collection = []

    render "hostel_fee/fees_payment/hostel_fee_defaulters"
  end

  def update_fee_collection_defaulters_dates
    @hostel_fee_collection = HostelFeeCollection.all(
      :conditions => ["#{active_account_conditions(true, 'hostel_fee_collections')} AND hostel_fees.batch_id=? and
        hostel_fee_collections.is_deleted=? and hostel_fees.balance > 0 and hostel_fee_collections.due_date < ? and
        hostel_fees.rent > ?", params[:batch_id], false, Date.today, 0.0],
      :group => "hostel_fee_collections.id",
      :joins => "#{active_account_joins(true, 'hostel_fee_collections')}
                 INNER JOIN hostel_fees
                         ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id and hostel_fees.is_active = 1"
    )

    render :update do |page|
      page.replace_html "hostel_fee_collection_dates", :partial => 'hostel_fee_collection_defaulters_dates'
    end
  end

  def hostel_fee_collection_defaulters_details
    @target_action='hostel_fee_collection_defaulters_details'
    fine = params[:fees].present? ? params[:fees][:fine_amount].to_f : nil
    @date=HostelFeeCollection.find(params[:date])
    @batch=Batch.find(params[:batch_id])
    @students=Student.find(:all, :joins => :hostel_fees, :conditions => "hostel_fees.hostel_fee_collection_id='#{@date.id}' and hostel_fees.is_active=1 and hostel_fees.batch_id='#{@batch.id}'", :order => "id ASC")
    if params[:student].present?
      @student=Student.find(params[:student])
    else
      @student=@students.first
    end
    # calculating advance fee used
    @advance_fee_used = @date.finance_transaction.all(:conditions => {:payee_id => @student.id}).sum(&:wallet_amount).to_f
    @prev_student=@students.select { |student| student.id<@student.id }.last||@students.last
    @next_student=@students.select { |student| student.id>@student.id }.first||@students.first
    @hostel_fee = HostelFee.find_by_student_id_and_hostel_fee_collection_id(@student.id, @date.id)
    if fine
      @hostel_fee.has_fine=true
      @hostel_fee.balance = @hostel_fee.balance.to_f+fine
    end
    @finance_transaction=@hostel_fee.finance_transactions_with_fine.first
    @payment_date = params[:payment_date] ? Date.parse(params[:payment_date]) : Date.today_with_timezone
    flash[:notice]=nil
    render :update do |page|
      page.replace_html "fees_detail", :partial => 'fees_submission_form'
    end
  end

  def pay_defaulters_fees
    category_id = FinanceTransactionCategory.find_by_name("Hostel").id
    @pay = HostelFee.find params[:id]
    transaction = FinanceTransaction.new
    transaction.title = @pay.hostel_fee_collection.name
    transaction.category_id = category_id
    transaction.finance = @pay
    transaction.amount = @pay.rent
    transaction.payee = @pay.student
    transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date

    #    if transaction.save
    #      @pay.update_attribute(:finance_transaction_id, transaction.id)
    #    end
    @hostel_fee = HostelFee.find_all_by_hostel_fee_collection_id(@pay.hostel_fee_collection_id, :conditions => ["balance > 0"])
    @hostel_fee.reject! { |x| x.student.nil? }
    render :update do |page|
      page.replace_html "hostel_fee_collection_details", :partial => 'hostel_fee_collection_defaulters_details'
      page.replace_html "pay_msg", :text => "<p class='flash-msg'> #{t('fees_paid')} </p>"
    end
  end

  def search_ajax
    #if params[:query].length >= 3
    #@usnconfig = Configuration.find_by_config_key('EnableUsn')

    #    if @usnconfig.config_value == '1'
    #      @students = Student.usn_no_or_first_name_or_middle_name_or_last_name_or_admission_no_begins_with params[:query].split unless params[:query].empty?
    #      @students.reject! {|s| RoomAllocation.find_all_by_student_id(s.id, :conditions=>["is_vacated is false"]).empty?}
    #    else
    ###########
    #     if params[:query].length > 0
    #      @students = Student.first_name_or_middle_name_or_last_name_or_admission_no_begins_with params[:query].split unless params[:query].empty?
    #      @students.reject! {|s| RoomAllocation.find_all_by_student_id(s.id, :conditions=>["is_vacated is false"]).empty?}
    ##    end
    #    render :partial => "search_ajax"
    #    end
    ############
    if params[:query].length>= 3
      @students = Student.find(:all,
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) and is_vacated is false",
          "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}"], :joins => [:room_allocations],
        :order => "batch_id asc,first_name asc", :include => [:batch => :course]).uniq unless params[:query] == ''
    else
      @students = Student.find(:all,
        :conditions => ["first_name = ? OR middle_name = ? OR last_name = ?
                            OR admission_no = ? OR (concat(first_name, \" \", last_name) = ? ) and is_vacated is false",
          "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}"], :joins => [:room_allocations],
        :order => "batch_id asc,first_name asc", :include => [:batch => :course]).uniq unless params[:query] == ''
    end
    render :partial => "search_ajax"
  end

  def student_hostel_fee
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

    @hostel_fee_collection = HostelFeeCollection.find_by_id(params[:collection_id])
    @dates = HostelFeeCollection.find(:all,
      :joins => " LEFT JOIN fee_accounts fa On fa.id = hostel_fee_collections.fee_account_id
                 INNER JOIN hostel_fees
                         ON hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id",
      :conditions => "hostel_fees.student_id = #{@student.id} and
                      hostel_fee_collections.is_deleted = 0 and 
                      hostel_fees.is_active=1 AND (fa.id IS NULL OR fa.is_deleted = false)")

    render "hostel_fee/fees_payment/student_hostel_fee"
  end

  def fees_submission_student
    flash[:notice] = nil
    flash[:warn_notice] = nil
    @fine = params[:fees][:fine] if params[:fees].present?
    @target_action = 'fees_submission_student'
    @transaction_date = @payment_date = (Date.parse(params[:payment_date] || params[:transaction_date]) rescue Date.today_with_timezone)
    financial_year_check
    if params[:payer_type].present?
      @payer_type=params[:payer_type]
      if params[:payer_type]=='Archived Student'
        @student = ArchivedStudent.find_by_former_id(params[:student])
        unless @student.present?
          flash[:notice] = "#{t('finance.no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
        @student.id=@student.former_id
      else
        @student = Student.find_by_id(params[:student])
        unless @student.present?
          flash[:notice] = "#{t('finance.no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
      end
    else
      @student = Student.find_by_id(params[:student])
    end

    @date = HostelFeeCollection.find(params[:date])
    @tax_slab = @date.collection_tax_slabs.try(:last) if @date.tax_enabled
    @hostel_fee = HostelFee.find_by_student_id_and_hostel_fee_collection_id(@student.id, @date.id)
    @finance_transaction = @hostel_fee.finance_transaction

    render :update do |page|
      page.replace_html "flash", :partial => 'finance_extensions/flash_notice'
      page.replace_html "hostel_fee_collection_details",
        :partial => "hostel_fee/fees_payment/fees_details"
    end
  end

  def select_payment_mode
    if params[:payment_mode]=="Others"
      render :update do |page|
        page.replace_html "payment_mode", :partial => "select_payment_mode"
      end
    else
      render :update do |page|
        page.replace_html "payment_mode", :text => ""
      end
    end
  end

  def hostel_fee_collection_pay
    @hostel_fee = HostelFee.find_by_id(params[:fees][:finance_id], :select => "hostel_fees.*, IFNULL(fa.is_deleted, false) AS is_account_deleted",
      :joins => "INNER JOIN hostel_fee_collections hfc ON hfc.id = hostel_fees.hostel_fee_collection_id
                                #{active_account_joins(true, 'hfc')}",
      :conditions => "#{active_account_conditions(true, 'hfc')}")
    if @hostel_fee.present? and @hostel_fee.is_account_deleted?
      render :update do |page|
        flash[:notice] = t('flash_msg5')
        page.redirect_to :controller => "user", :action => "dashboard"
      end
    else
      @date=@hostel_fee.hostel_fee_collection      
      @tax_slab = @date.collection_tax_slabs.try(:last) if @date.tax_enabled
      @target_action = params[:target_action]
      @student = Student.find(params[:student])
      @batch=@student.batch
      @students=Student.find(:all, :joins => :hostel_fees,
        :conditions => "hostel_fees.hostel_fee_collection_id='#{@hostel_fee.hostel_fee_collection_id}' and
                              hostel_fees.is_active=1 and students.batch_id='#{@student.batch_id}'")
      @prev_student=@students.select { |student| student.id<@student.id }.last||@students.last
      @next_student=@students.select { |student| student.id>@student.id }.first||@students.first
      error_flash_proc = ""
      @transaction_date = params[:transaction_date].to_date
      financial_year_check
      unless params[:fees][:payment_mode].blank?
        FinanceTransaction.transaction do
          @transaction= FinanceTransaction.new(params[:fees])
          @transaction.title = @hostel_fee.hostel_fee_collection.name
          @transaction.category_id = FinanceTransactionCategory.find_by_name('Hostel').id
          @transaction.finance = @hostel_fee
          @transaction.transaction_date = params[:transaction_date]
          @transaction.payee = @hostel_fee.student
          @transaction.wallet_amount_applied = params[:wallet_amount_applied]
          @transaction.wallet_amount = params[:wallet_amount]
          @transaction.save
        end
        if @transaction.errors.empty?
          #        @transaction.update_attributes(:finance_transaction_id => transaction.id)
          error_flash_proc = Proc.new { {:text => "<p class='flash-msg'>#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{@transaction.id})'>#{t('print_receipt')}</a></p>"} }
          # flash[:warning]="#{t('finance.flash14')}. <a href ='http://#{request.host_with_port}/finance/generate_fee_receipt_pdf?student_id=#{@student.id}&transaction_id=#{transaction.id}' target='_blank'>#{t('print_receipt')}</a>"
          flash[:warn_notice]=nil
        else
          error_flash_proc = Proc.new { {:partial => 'render_errors', :locals => {:object => 'transaction'}} }
        end
        @finance_transaction = @hostel_fee.finance_transaction
        # calculating advance fee used
        @advance_fee_used = @date.finance_transaction.all(:conditions => {:payee_id => @hostel_fee.student.id}).sum(&:wallet_amount).to_f
      else
        flash[:notice]=nil
        flash[:warn_notice]="#{t('select_one_payment_mode')}"
      end
      render :update do |page|
        page.replace_html 'fees_details', :partial => 'hostel_fee/fees_payment/fees_details'
        page.replace_html 'flash', error_flash_proc.present? ? error_flash_proc.call : ""
      end
    end

  end

  def student_fee_receipt_pdf
    @transaction = HostelFee.find params[:id]
    @finance_transaction = @transaction.finance_transaction
    @fine = @finance_transaction.fine_amount if @finance_transaction.fine_included
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      response = @finance_transaction.try(:payment).try(:gateway_response)
      @online_transaction_id = response.nil? ? nil : response[:transaction_id]
      @online_transaction_id ||= response.nil? ? nil : response[:x_trans_id]
      @online_transaction_id ||= response.nil? ? nil : response[:transaction_reference]
    end
    render :pdf => 'hostel_fee_receipt'
  end

  def delete_fee_collection_date
    hostel_fee_collection = HostelFeeCollection.find(params[:id], :include => :hostel_fees)
    hostel_fees = hostel_fee_collection.hostel_fees
    batch_wise_hostel_fee_count = hostel_fee_collection.hostel_fees.all(:group => "batch_id").count
    if hostel_fees.present? && !hostel_fee_collection.has_paid_fees_in_this_batch?(params[:batch_id])
      if batch_wise_hostel_fee_count<=1
        #remove hostel_fee collection and corresponding user_events
        hostel_fee_collection.event.user_events.delete_all
        hostel_fee_collection.hostel_fees.delete_all
        hostel_fee_collection.soft_delete
      else
        student_ids = hostel_fee_collection.hostel_fees.find_all_by_batch_id(params[:batch_id]).collect { |x| x.student.user_id unless x.student.nil? }
        # To remove batch event
        batch_event = BatchEvent.find_by_event_id_and_batch_id(hostel_fee_collection.event.id, params[:batch_id])
        batch_event.destroy if batch_event.present?
        # to remove hostel fees
        HostelFee.destroy_all("hostel_fee_collection_id = '#{params[:id]}' and batch_id = '#{params[:batch_id]}'")
        # to remove corresponding user events
        UserEvent.destroy_all("user_id  in ( #{student_ids.join(',')} ) and event_id = #{hostel_fee_collection.event.id}")
      end
      render :update do |page|
        page.replace_html 'flash', :text => "<p class='flash-msg'>#{t('hostel_fee.deleted_successfully')} </p>"
        @hostel_fee_collection = HostelFeeCollection.current_active_financial_year.all(
          :joins => :hostel_fees, :conditions => {:hostel_fees => {:batch_id => params[:batch_id], :is_active => true},
            :is_deleted => false, }, :group => :id,
          :select => "hostel_fee_collections.*,hostel_fees.batch_id as hostel_batch_id")
        page.replace_html 'fee-collection-edit', :partial => 'fee_collection_edit', :object => @hostel_fee_collection
      end
    else
      render :update do |page|
        page.replace_html 'flash', :text => "<div id='errorExplanation' class='errorExplanation'><p>#{t('hostel_fee.cant_delete_collection_date_with_transactions')}</p</div>"
        @hostel_fee_collection = HostelFeeCollection.all(:joins => :hostel_fees, :conditions => {:hostel_fees => {:batch_id => params[:batch_id], :is_active => true}, :is_deleted => false, }, :group => :id, :select => "hostel_fee_collections.*,hostel_fees.batch_id as hostel_batch_id")
        page.replace_html 'fee-collection-edit', :partial => 'fee_collection_edit', :object => @hostel_fee_collection
      end
    end
  end

  def show_date_filter
    month_date
    @target_action=params[:target_action]
    if request.xhr?
      render(:update) do |page|
        page.replace_html "date_filter", :partial => "filter_dates"
      end
    end
  end

  def hostel_fees_report
    if validate_date

      filter_by_account, account_id = account_filter

      # if filter_by_account
      #   filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
      #   filter_values = [account_id]
      #   ft_joins = {:finance_transactions => :finance_transaction_receipt_record }
      # else
      #   filter_conditions = ""
      #   filter_values = []
      #   ft_joins = :finance_transactions
      # end

      ft_joins = "INNER JOIN hostel_fees ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                  INNER JOIN finance_transactions ft ON ft.finance_id=hostel_fees.id AND ft.finance_type = 'HostelFee'
                   LEFT JOIN fee_accounts fa ON fa.id = hostel_fee_collections.fee_account_id"
      if filter_by_account
        filter_conditions = "AND hostel_fee_collections.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_conditions += " AND fa.is_deleted = false" if account_id.present?
        filter_values = [account_id]
        # filter_select = ", fa.fee_account_id AS account_id" if account_id.present?
      else
        # joins += "LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
        #             LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
        filter_values = []
        filter_conditions = " AND (fa.id IS NULL or fa.is_deleted = false) "
        # filter_select = ""
      end

      @target_action = "hostel_fees_report"
      @start_date = params[:start_date]
      @end_date = params[:end_date]

      # hostel_id = FinanceTransactionCategory.find_by_name('Hostel').id

      @grand_total = HostelFeeCollection.all(:select => "ft.amount", :joins => ft_joins,
        :conditions => ["(ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          @start_date, @end_date] + filter_values).map { |x| x.amount.to_f }.sum

      @collections = HostelFeeCollection.paginate(:per_page => 10, :page => params[:page],
        :joins => ft_joins, :group => "hostel_fee_collections.id",
        :conditions => ["(ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          @start_date, @end_date] + filter_values,
        :select => "SUM(ft.amount) AS amount,
                   IF(hostel_fee_collections.tax_enabled, IFNULL(SUM(ft.tax_amount),0), '-') AS tax_amount,
                   hostel_fee_collections.tax_enabled, hostel_fee_collections.id AS collection_id,
                   hostel_fee_collections.name AS collection_name")

      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "hostel_fees_report"
        end
      end
    else
      render_date_error_partial
    end
  end

  def hostel_fees_report_csv
    if validate_date
      filter_by_account, account_id = account_filter

      ft_joins = "INNER JOIN hostel_fees ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                  INNER JOIN finance_transactions ft ON ft.finance_id=hostel_fees.id AND ft.finance_type = 'HostelFee'
                   LEFT JOIN fee_accounts fa ON fa.id = hostel_fee_collections.fee_account_id"
      if filter_by_account
        filter_conditions = "AND hostel_fee_collections.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_conditions += " AND fa.is_deleted = false" if account_id.present?
        filter_values = [account_id]
        # filter_select = ", fa.fee_account_id AS account_id" if account_id.present?
      else
        # joins += "LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
        #             LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
        filter_values = []
        filter_conditions = " AND (fa.id IS NULL or fa.is_deleted = false) "
        # filter_select = ""
      end

      hostel_id = FinanceTransactionCategory.find_by_name('Hostel').id

      collections = HostelFeeCollection.all(:joins => ft_joins, #{:hostel_fees => ft_joins},
        :group => "hostel_fee_collections.id",
        :conditions => ["(ft.transaction_date BETWEEN ? AND ?) AND ft.category_id = ? #{filter_conditions}",
          @start_date, @end_date, hostel_id] + filter_values,
        :select => "SUM(ft.amount) AS amount, IF(hostel_fee_collections.tax_enabled, IFNULL(SUM(ft.tax_amount),0),
                    '-') AS tax_amount, hostel_fee_collections.tax_enabled, hostel_fee_collections.id AS collection_id,
                    hostel_fee_collections.name AS collection_name")

      tax_enabled_present = collections.map(&:tax_enabled).uniq.include?(true)
      csv_string = FasterCSV.generate do |csv|
        csv << t('hostel_fee_collection')
        csv << [t('start_date'), format_date(@start_date)]
        csv << [t('end_date'), format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << (tax_enabled_present ? [t('collection'), t('tax_text'), t('amount')] :
            [t('collection'), t('amount')])
        total = 0
        collections.each do |collection|
          row = []
          row << collection.collection_name
          if tax_enabled_present
            row << (collection.tax_amount != '-' ? precision_label(collection.tax_amount) : '-')
          end
          row << precision_label(collection.amount)
          total += collection.amount.to_f
          csv << row
        end
        csv << ""
        csv << [t('net_income'), precision_label(total)]
      end

      filename = "#{t('hostel_fees')}-#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end

  def course_wise_hostel_fee_collection
    if validate_date
      filter_by_account, account_id = account_filter

      @collection = HostelFeeCollection.find_by_id(params[:id],
        :joins => "LEFT JOIN fee_accounts fa ON fa.id = hostel_fee_collections.fee_account_id",
        :conditions => "fa.id IS NULL OR fa.is_deleted = false")
      unless @collection.present?
        flash[:notice] = t('flash_msg5')
        if request.xhr?
          render :update do |page|
            page.redirect_to :controller => "user", :action => "dashboard"
          end
        else
          redirect_to :controller => "user", :action => "dashboard"
        end
      else
        if filter_by_account
          filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
          ft_joins = {:finance_transactions => :finance_transaction_receipt_record}
        else
          filter_conditions = ""
          filter_values = []
          ft_joins = :finance_transactions
        end

        @target_action = "course_wise_hostel_fee_collection"
        @grand_total = HostelFee.all(:select => "amount", :joins => ft_joins,
          :conditions => ["hostel_fees.hostel_fee_collection_id = ? AND
                                  (finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
            params[:id], @start_date, @end_date] + filter_values).map { |x| x.amount.to_f }.sum
        @batches = HostelFee.paginate(:per_page => 1, :page => params[:page],
          :joins => [ft_joins, :batch], :group => "hostel_fees.batch_id",
          :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                  hostel_fees.hostel_fee_collection_id = ? #{filter_conditions}", @start_date,
            @end_date, params[:id]] + filter_values,
          :select => "SUM(finance_transactions.amount) AS amount, batches.name AS batch_name,
                          batches.course_id AS course_id, hostel_fees.batch_id AS batch_id")
        @courses = @batches.group_by(&:course_id)
        if request.xhr?
          render(:update) do |page|
            page.replace_html "fee_report_div", :partial => "course_wise_hostel_fee_collection"
          end
        end
      end

    else
      render_date_error_partial
    end
  end

  def course_wise_hostel_fee_collection_csv
    if validate_date

      joins = " LEFT JOIN fee_accounts fa ON fa.id = hostel_fee_collections.fee_account_id"

      @collection = HostelFeeCollection.find_by_id(params[:id], :joins => joins,
        :conditions => "fa.id IS NULL OR fa.is_deleted is false")

      if @collection.present?

        filter_by_account, account_id = account_filter

        if filter_by_account
          filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
          ft_joins = {:finance_transactions => :finance_transaction_receipt_record}
        else
          filter_conditions = ""
          filter_values = []
          ft_joins = :finance_transactions
        end
        courses = HostelFee.all(:joins => [ft_joins, :batch], :group => "hostel_fees.batch_id",
          :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ? ) AND
                                  hostel_fees.hostel_fee_collection_id = ? #{filter_conditions}", @start_date,
            @end_date, params[:id]] + filter_values,
          :select => "SUM(finance_transactions.amount) AS amount, batches.name AS batch_name,
                          batches.course_id AS course_id, hostel_fees.batch_id AS batch_id").group_by(&:course_id)

        csv_string = FasterCSV.generate do |csv|
          csv << t('hostel_fee_collection')
          csv << [t('start_date'), format_date(@start_date)]
          csv << [t('end_date'), format_date(@end_date)]
          csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
          csv << ""
          csv << [t('course'), "", t('amount')]
          total = 0
          courses.each do |course, batches|
            csv << Course.find(course).course_name
            batches.each do |b|
              row = []
              row << ""
              row << b.batch_name
              row<< precision_label(b.amount)
              total += b.amount.to_f
              csv << row
            end
          end
          csv << ""
          csv << [t('net_income'), "", precision_label(total)]
        end
        filename = "#{t('hostel_fees')}-#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
        send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
      else
        flash[:notice] = t("flash_msg5")
        redirect_to :controller => "user", :action => "dashboard"
      end
    else
      render_date_error_partial
    end
  end

  def batch_hostel_fees_report
    if validate_date

      @fee_collection = HostelFeeCollection.find_by_id(params[:id], :joins => "#{active_account_joins(true, 'hostel_fee_collections')}",
        :conditions => "fa.id IS NULL OR fa.is_deleted = false")

      if @fee_collection.present?

        filter_by_account, account_id = account_filter

        if filter_by_account
          filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
          ft_joins = {:finance_transactions => :finance_transaction_receipt_record}
          joins = "INNER JOIN finance_transaction_receipt_records
                                 ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
        else
          joins = filter_conditions = ""
          filter_values = []
          ft_joins = :finance_transactions
        end
        @target_action = "batch_hostel_fees_report"
        @batch = Batch.find(params[:batch_id])
        hostel_id = FinanceTransactionCategory.find_by_name('Hostel').id
        @grand_total = HostelFee.all(:select => "amount", :joins => ft_joins,
          :conditions => ["hostel_fees.batch_id = ? AND hostel_fees.hostel_fee_collection_id = ? AND
                                 (finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                 finance_transactions.category_id = ? AND
                                 finance_transactions.finance_type='HostelFee' #{filter_conditions}",
            params[:batch_id], params[:id], @start_date, @end_date, hostel_id] + filter_values).
          map { |x| x.amount.to_f }.sum

        @transactions = FinanceTransaction.paginate(:per_page => 10, :page => params[:page],
          :joins => "INNER JOIN hostel_fee_finance_transactions hfft
                                    ON hfft.finance_transaction_id=finance_transactions.id
                        INNER JOIN hostel_fees tf
                                     ON tf.id=hfft.hostel_fee_id #{joins}",
          :include => :transaction_receipt,
          :conditions => ["tf.batch_id = ? AND tf.hostel_fee_collection_id = ? AND
                                 (finance_transactions.transaction_date BETWEEN ? AND ? ) AND
                                 finance_transactions.category_id = ? AND
                                 finance_transactions.finance_type='HostelFee' #{filter_conditions}", params[:batch_id],
            params[:id], @start_date, @end_date, hostel_id] + filter_values)

        if request.xhr?
          render(:update) do |page|
            page.replace_html "fee_report_div", :partial => "batch_hostel_fees_report"
          end
        end
      else
        flash[:notice] = t("flash_msg5")
        if request.xhr?
          render :update do |page|
            page.redirecto_to :controller => "user", :action => "dashboard"
          end
        else
          redirect_to :controller => "user", :action => "dashboard"
        end
      end
    else
      render_date_error_partial
    end
  end

  def batch_hostel_fees_report_csv
    if date_format_check
      fee_collection = HostelFeeCollection.find_by_id(params[:id], :joins => "#{active_account_joins(true, 'hostel_fee_collections')}",
        :conditions => "fa.id IS NULL OR fa.is_deleted = false")

      if fee_collection.present?
        filter_by_account, account_id = account_filter

        if filter_by_account
          filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
          joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
        else
          joins = filter_conditions = ""
          filter_values = []
        end

        batch = Batch.find(params[:batch_id])
        hostel_id = FinanceTransactionCategory.find_by_name('Hostel').id
        transactions = FinanceTransaction.all(
          :joins => "INNER JOIN hostel_fee_finance_transactions hfft
                                    ON hfft.finance_transaction_id=finance_transactions.id
                        INNER JOIN hostel_fees tf
                                     ON tf.id = hfft.hostel_fee_id #{joins}",
          :include => :transaction_receipt,
          :conditions => ["tf.batch_id = ? AND tf.hostel_fee_collection_id = ? AND
                                 (finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                 finance_transactions.category_id = ? AND
                                 finance_transactions.finance_type = 'HostelFee' #{filter_conditions}", params[:batch_id],
            params[:id], @start_date, @end_date, hostel_id] + filter_values)

        csv_string = FasterCSV.generate do |csv|
          csv << t('hostel_fee_collection')
          csv << [t('fee_collection'), fee_collection.name]
          csv << [t('batch'), batch.full_name]
          csv << [t('start_date'), format_date(@start_date)]
          csv << [t('end_date'), format_date(@end_date)]
          csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
          csv << ""
          csv << [t('student_name'), t('amount'), t('receipt_no'), t('date_text'), t('payment_mode'), t('payment_notes')]
          total = 0
          transactions.each do |t|
            row = []
            row << t.hosteller.full_name
            row << precision_label(t.amount)
            row << t.receipt_number
            row << format_date(t.created_at, :format => :short_date)
            row << t.payment_mode
            if t.reference_no.present?
              row << "#{t.payment_note}-#{t.reference_no}"
            else
              row << t.payment_note
            end
            total += t.amount.to_f
            csv << row
          end
          csv << [t('net_income'), precision_label(total)]
        end
        filename = "#{t('hostel_fees')}-#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
        send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
      else
        flash[:notice] = t('flash_msg5')
        redirect_to :controller => "user", :action => "dashboard"
      end
    end
  end

  def student_profile_fee_details
    @student_type = params[:student_type]
    @student = Student.find(params[:id]) if @student_type == 'Student'
    @student = ArchivedStudent.find(params[:id]) if @student_type == 'ArchivedStudent'
    student_id = @student_type == 'Student' ? @student.id : @student.former_id
    @hostel_fee = HostelFee.find_by_hostel_fee_collection_id_and_student_id(params[:id2], student_id)
    @amount = @hostel_fee.rent
    @fee_collection = HostelFeeCollection.find(params[:id2])
    # calculating advance fees used
    @advance_fee_used = @fee_collection.finance_transaction.all(:conditions => {:payee_id => student_id}).sum(&:wallet_amount).to_f if @fee_collection.present?
    if @hostel_fee.tax_enabled?
      @tax_slab = @fee_collection.collection_tax_slabs.try(:last)
    end
    @paid_fees = @hostel_fee.finance_transactions(:include => :transaction_ledger)
    @transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    financial_year_check
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      if ((PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_hostel_fee_enabled?))
        if params[:create_transaction].present?
          gateway_record = GatewayRequest.find(:first, :conditions => {:transaction_reference => params[:transaction_ref], :status => 0})
          gateway_record.update_attribute('status', true) if gateway_record.present?
          @active_gateway = gateway_record.present? ? gateway_record.gateway : 0
        else
          @active_gateway = PaymentConfiguration.first_active_gateway
        end
        @custom_gateway = (@active_gateway.nil? or @active_gateway==0) ? false : CustomGateway.find(@active_gateway)
        @partial_payment_enabled = PaymentConfiguration.is_partial_payment_enabled?
      end
      hostname = "#{request.protocol}#{request.host_with_port}"
      if params[:create_transaction].present? and @custom_gateway != false
        gateway_response = Hash.new
        if params[:return_hash].present?
          return_value = params[:return_hash]
          @decrypted_hash = PaymentConfiguration.payment_decryption(return_value)
        end
        if @custom_gateway.present?
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
        amount_to_pay = precision_label(@hostel_fee.balance.to_f).to_f
        amount_from_gateway = 0
        amount_from_gateway = ((@custom_gateway.present? and params[:wallet_amount_applied].present?) ? (gateway_response[:amount] + params[:wallet_amount].to_f) : gateway_response[:amount])
        wrong_amount = false
        if amount_from_gateway.to_f != amount_to_pay
          wrong_amount = true unless PaymentConfiguration.is_partial_payment_enabled?
        end
        payment = SingleFeePayment.new(:payee => @student, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway, :is_pending=>@pending_status)
        if payment.save
          finance_payment = FinancePayment.create(:payment_id => payment.id, :fee_payment => @hostel_fee, :fee_collection => @hostel_fee.hostel_fee_collection)
          unless wrong_amount
            tr_status = ""
            tr_ref = ""
            reason = ""
            #payment = SingleFeePayment.new(:payee => @student, :gateway_response => gateway_response, :status => @gateway_status, :amount => gateway_response[:amount].to_f, :gateway => @active_gateway)

            if !@hostel_fee.is_paid?
              amount_from_gateway =((@custom_gateway.present? and params[:wallet_amount_applied].present?) ? (gateway_response[:amount] + params[:wallet_amount].to_f) : gateway_response[:amount])
              if amount_from_gateway.to_f > 0.0 and payment.status
                logger = Logger.new("#{RAILS_ROOT}/log/payment_processor_error.log")
                pay_status = false
                begin
                  retries ||= 0
                  pay_status = true
                  transaction = FinanceTransaction.new
                  transaction.title = @hostel_fee.hostel_fee_collection.name
                  transaction.category_id = FinanceTransactionCategory.find_by_name('Hostel').id
                  transaction.finance = @hostel_fee
                  transaction.amount = amount_from_gateway.to_f
                  transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
                  transaction.payment_mode = "Online Payment"
                  transaction.reference_no = gateway_response[:transaction_reference]
                  transaction.payee = @hostel_fee.student
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
                  #finance_payment =  FinancePayment.create(:payment_id=>payment.id,:fee_payment => transaction.finance,:fee_collection => transaction.finance.hostel_fee_collection)
                  #              @fee.update_attributes(:finance_transaction_id => transaction.id)
                  finance_payment.update_attributes(:finance_transaction_id => transaction.id)
                  #              online_transaction_id = payment.gateway_response[:transaction_id]
                  #              online_transaction_id ||= payment.gateway_response[:x_trans_id]
                  #              online_transaction_id ||= payment.gateway_response[:payment_reference]
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
                      Delayed::Job.enqueue(OnlinePayment::PaymentMail.new(finance_payment.fee_collection.name, user.email, user.full_name, @custom_gateway.name, FedenaPrecision.set_and_modify_precision(payment.amount), online_transaction_id, payment.gateway_response, user.school_details, hostname))
                    rescue Exception => e
                      puts "Error------#{e.message}------#{e.backtrace.inspect}"
                      return
                    end
                  end
                else
                  status = Payment.payment_status_mapping[:failed]
                  payment.update_attributes(:status_description => status)
                  flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
                  tr_status = "failure"
                  tr_ref = payment.gateway_response[:transaction_reference]
                  reason = payment.gateway_response[:reason_code]
                end
              else
                status = Payment.payment_status_mapping[:failed]
                payment.update_attributes(:status_description => status)
                flash[:notice] = "#{t('payment_failed')} <br> #{t('reason')} : #{payment.gateway_response[:reason_code] || 'N/A'} <br> #{t('transaction_id')} : #{payment.gateway_response[:transaction_reference] || 'N/A'}"
                tr_status = "failure"
                tr_ref = payment.gateway_response[:transaction_reference]
                reason = payment.gateway_response[:reason_code]
              end
            else
              flash[:notice] = "#{t('already_paid')}"
              tr_status = "failure"
              tr_ref = payment.gateway_response[:transaction_reference]
              reason = "#{t('already_paid')}"
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
          redirect_to :controller => "payment_settings", :action => "complete_payment",
            :student_id => @student.id, :fee_collection_id => @fee_collection.id,
            :collection_type => "hostel", :transaction_status => tr_status,
            :reason => reason, :transaction_id => tr_ref
        else
          redirect_to :controller => 'hostel_fee', :action => 'student_profile_fee_details',
            :id => params[:id], :id2 => params[:id2]
        end
      else
        check_if_mobile_user

        if @ret == true
          @page_title = t('fees_text')
          render 'hostel_fee/mobile_fee_details', :layout => 'mobile'
        else
          render 'hostel_fee/fees_payment/student_profile_fee_details'
        end
      end
    else
      check_if_mobile_user

      if @ret == true
        @page_title = t('fees_text')
        render 'hostel_fee/mobile_fee_details', :layout => 'mobile'
      else
        render 'hostel_fee/fees_payment/student_profile_fee_details'
      end
    end
  end

  def delete_hostel_fee_transaction
    @target_action=params[:target_action]
    @financetransaction = FinanceTransaction.find_by_id(params[:id], :conditions => "#{active_account_conditions(true, 'hfc')}",
      :joins => "INNER JOIN hostel_fees hf ON hf.id = finance_transactions.finance_id AND finance_transactions.finance_type = 'HostelFee'
               INNER JOIN hostel_fee_collections hfc ON hfc.id = hf.hostel_fee_collection_id
               #{active_account_joins(true, 'hfc')}  ")
    unless @financetransaction.present?
      render :update do |page|
        flash[:notice] = "#{t('flash_msg5')}"
        page.redirect_to :controller => "user", :action => "dashboard"
      end
    else
      @financetransaction.cancel_reason = params[:reason]
      @student=@financetransaction.payee
      @hostel_fee=@financetransaction.finance
      @date=@hostel_fee.hostel_fee_collection
      @tax_slab = @date.collection_tax_slabs.try(:last) if @date.tax_enabled?
      if FedenaPlugin.can_access_plugin?("fedena_pay")
        finance_payment = @financetransaction.finance_payment
        unless finance_payment.nil?
          status = Payment.payment_status_mapping[:reverted]
          finance_payment.payment.update_attributes(:status_description => status)
        end
      end

      ActiveRecord::Base.transaction do
        if @financetransaction
          transaction_ledger = @financetransaction.transaction_ledger
          if transaction_ledger.transaction_mode == 'SINGLE'
            transaction_ledger.mark_cancelled(params[:reason])
            @hostel_fee.reload
            flash.now[:notice]= (transaction_ledger.status == 'CANCELLED' ? "#{t('finance.flash18')}" :
                "#{t('finance.flash32')}")
          else
            #          raise ActiveRecord::Rollback unless @financetransaction.destroy
            unless @financetransaction.destroy
              raise ActiveRecord::Rollback
              flash.now[:notice]="#{t('finance.flash32')}"
            else
              flash.now[:notice]="#{t('finance.flash18')}"
            end
          end
        end
      end
      
      # calculating advance fee used
      @advance_fee_used = @date.finance_transaction.all(:conditions => {:payee_id => @student.id}).sum(&:wallet_amount).to_f
      
      @transaction_date = Date.today_with_timezone
      financial_year_check
      render :update do |page|
        page << "remove_popup_box()" if request.xhr?
        page.replace_html "fees_details", :partial => "hostel_fee/fees_payment/fees_details"
        page.replace_html "flash", :text => flash[:notice].present? ? "<p class='flash-msg'>#{flash[:notice]}</p>" : ""
      end
      #    render :js=> "new Ajax.Request('/hostel_fee/hostel_fee_collection_defaulters_details', {method: 'get',parameters: {student: #{@student.id},batch_id:#{@student.batch_id},date:#{@date.id}}});"

    end

  end

  def student_wise_fee_collection_new
    error=false
    HostelFeeCollection.transaction do
      @tax_slabs = TaxSlab.all if @tax_enabled
      invoice_enabled = (Configuration.get_config_value('EnableInvoiceNumber').to_i == 1)
      @hostel_fee_collection = HostelFeeCollection.new(params[:hostel_fee_collection])
      @hostel_fee_collection.invoice_enabled = invoice_enabled
      if request.post?
        hostel_fee_collection_params = params[:hostel_fee_collection].dup
        hostel_fee_collection_params[:invoice_enabled] = invoice_enabled
        if @tax_enabled
          @tax_slab = TaxSlab.find_by_id(params[:hostel_fee_collection][:tax_slab_id])
          @tax_multiplier = @tax_slab.rate.to_f * 0.01 if @tax_slab.present?
        end
        if @tax_slab.present? or invoice_enabled
          hostel_fee_collection_params[:hostel_fees_attributes].each_pair do |key, fee_param|
            if @tax_slab.present?
              tax = fee_param["rent"].to_i * @tax_multiplier
              fee_param["tax_enabled"] = @hostel_fee_collection.tax_enabled
              fee_param["tax_amount"] = tax
            end
            fee_param["invoice_number_enabled"] = @hostel_fee_collection.invoice_enabled
            hostel_fee_collection_params[:hostel_fees_attributes][key] = fee_param
          end
        end

        @hostel_fee_collection = HostelFeeCollection.new(hostel_fee_collection_params)
        # setting account id
        master_particular = MasterFeeParticular.find_by_particular_type 'HostelFee'
        transaction_category = FinanceTransactionCategory.find_by_name 'Hostel'
        account = transaction_category.get_multi_config[:account]
        account_id = (account.is_a?(Fixnum) ? account : (account.is_a?(FeeAccount) ? account.try(:id) : nil))
        @hostel_fee_collection.fee_account_id = account_id
        @hostel_fee_collection.master_fee_particular_id = master_particular.id if master_particular.present?
        if @hostel_fee_collection.save

          @hostel_fee_collection.collectible_tax_slabs.build({:tax_slab_id => @tax_slab.id,
              :collectible_entity_id => @hostel_fee_collection.id,
              :collectible_entity_type => 'HostelFeeCollection'}) if @tax_slab.present?

          @hostel_fee_collection.hostel_fees.each do |hostel_fee|
            hostel_fee.tax_collections.build({:taxable_entity_type => "HostelFeeCollection",
                :taxable_entity_id => @hostel_fee_collection.id, :slab_id => @tax_slab.id,
                :tax_amount => hostel_fee.rent * @tax_multiplier})
          end if @tax_slab.present?
          @hostel_fee_collection.save

          event=Event.new(:title => "#{t('hostel_fee_text')}", :description => "#{t('fee_name')}: #{@hostel_fee_collection.name}", :start_date => @hostel_fee_collection.due_date.to_s, :end_date => @hostel_fee_collection.due_date.to_s, :is_due => true, :origin => @hostel_fee_collection, :user_events_attributes => params["event"])
          error=true unless event.save
          recipients=[]
          params[:event].each { |k, v| recipients<<v["user_id"] }
          send_reminder(@hostel_fee_collection, recipients)
        else
          error=true
        end

        if error
          render :update do |page|
            page.replace_html 'financial_year_details', :partial => 'finance/financial_year_info'
            page.replace_html "collection-details", :partial => 'student_wise_fee_collection_new'
          end
          raise ActiveRecord::Rollback

        else
          flash[:notice]="#{t('collection_date_has_been_created')}"
          render :update do |page|
            page.redirect_to :action => 'collection_creation_and_assign'
          end
        end
      else
        @start_date, @end_date = FinancialYear.fetch_current_range
        render :update do |page|
          page.replace_html 'financial_year_details', :partial => 'finance/financial_year_info'
          page.replace_html "collection-details", :partial => 'student_wise_fee_collection_new'
        end
      end
    end
  end

  def search_student
    students= Student.active.find(:all, :joins => [{:room_allocations => :room_detail}], :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and room_allocations.is_vacated=false", "%#{params[:query]}%", "%#{params[:query]}%"]).uniq
    suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - "+s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s+"(#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.name}-#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.type})" : s.full_name+"(#{s.admission_no})"+" - "+s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s+"(#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.name}-#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.type})" }

    student_datas=students.map { |st| "{'id': #{st.id}, 'rent' : #{st.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent},'user_id':#{st.user_id},'batch_id':#{st.batch_id}}" }
    if students.present?
      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => student_datas}
    else
      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
    end
  end

  def allocate_or_deallocate_fee_collection
    error=false
    @batches = Batch.active
    if request.post?
      HostelFee.transaction do
        fy_id = params[:fees_list][:financial_year_id]
        fy_id = params[:fees_list][:financial_year_id].to_i == 0 ? nil : fy_id

        error = current_financial_year_id.to_i != fy_id.to_i
        unless error
          params[:fees_list][:collection_ids].present? ? colln_ids_new=params[:fees_list][:collection_ids].map(&:to_i) : colln_ids_new=[0]
          student = Student.find(params[:fees_list][:receiver_id])
          batch = Batch.find(params[:fees_list][:batch_id])
          all_unpaid_collections = HostelFeeCollection.for_financial_year(fy_id).all(
            :conditions => ["finance_transaction_id is null and hf.batch_id = ? and student_id = ?", batch.id, student.id],
            :joins => " #{active_account_joins(true, 'hostel_fee_collections')}
                         INNER JOIN hostel_fees hf ON hf.hostel_fee_collection_id = hostel_fee_collections.id")
          all_col_ids = all_unpaid_collections.map(&:id)
          active_fee_ids = colln_ids_new & all_col_ids
          inactive_fee_ids = all_col_ids - active_fee_ids

          HostelFee.update_all({:is_active => false}, ["student_id = ? and batch_id = ? and hostel_fee_collection_id in (?)",
              student.id, batch.id, inactive_fee_ids]) if inactive_fee_ids.present?
          HostelFee.update_all({:is_active => true}, ["student_id = ? and batch_id = ? and hostel_fee_collection_id in (?)",
              student.id, batch.id, active_fee_ids]) if active_fee_ids.present?

          HostelFee.update_collection_report({:fees_to_remove => (inactive_fee_ids).uniq,
              :fees_to_insert => active_fee_ids, :student_id=> student.id})

          student.send(:attributes=, params[:new_collection_ids])
          student.save(false)
          user_events=UserEvent.create(params[:user_events].values) if params[:user_events].present?
        end

        if (error)
          render :update do |page|
            page.replace_html 'flash-div', :text => "<div id='error-box'><ul><li>#{t('fees_text')} #{t('hostel_fee.allocation')} #{t('failed')}</li></ul></div>"
          end
          raise ActiveRecord::Rollback
        else
          render :update do |page|
            page.replace_html 'flash-div', :text => "<p class='flash-msg'>#{t('fee_collections_are_updated_to_the_student_successfully')} </p>"
          end
        end
      end
    end
  end

  def list_students_by_batch
    @students = Student.find(:all, :select => 'distinct students.*',
      :joins => "INNER JOIN hostel_fees ON hostel_fees.student_id = students.id
                                        INNER JOIN hostel_fee_collections ON hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id
                                        #{active_account_joins(true, 'hostel_fee_collections')}",
      :conditions => "students.batch_id='#{params[:batch_id]}' AND hostel_fee_collections.is_deleted=false AND
                                             hostel_fees.balance > 0 AND #{active_account_conditions(true, 'hostel_fee_collections')}",
      :order => 'first_name ASC')
    @batch = Batch.find(params[:batch_id])
    unless @students.blank?
      @student = @students.first
      fy_id = current_financial_year_id
      @fee_collection_dates=HostelFeeCollection.find(:all, :select => "distinct hostel_fee_collections.*,hostel_fees.is_active as assigned",
        :joins => "INNER JOIN `hostel_fees` ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                           #{active_account_joins(true, 'hostel_fee_collections')}",
        :conditions => ["hostel_fees.student_id='#{@student.id}' and hostel_fee_collections.is_deleted=false and
                                 hostel_fees.finance_transaction_id is NULL AND #{active_account_conditions(true, 'hostel_fee_collections')} AND 
                                 (financial_year_id #{fy_id.present? ? '=' : 'IS'} ?)", fy_id])
    end
    render :update do |page|
      page.replace_html 'receivers', :partial => 'students_collections_list'
      page.replace_html 'financial_year_details', :partial => 'finance/financial_year_info'
      page << "update_select_all()"
    end
  end

  def list_fees_for_student
    @student = Student.find_by_id(params[:receiver])
    @batch = Batch.find_by_id(params[:batch_id])
    fy_id = current_financial_year_id
    @fee_collection_dates=HostelFeeCollection.find(:all,
      :select => "distinct hostel_fee_collections.*,hostel_fees.is_active as assigned",
      :joins => "INNER JOIN `hostel_fees` ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                          #{active_account_joins(true, 'hostel_fee_collections')}",
      :conditions => ["hostel_fees.student_id='#{@student.id}' and hostel_fee_collections.is_deleted=false and
                                hostel_fees.finance_transaction_id is NULL AND #{active_account_conditions(true, 'hostel_fee_collections')} AND
                                hostel_fees.finance_transaction_id is NULL AND (financial_year_id #{fy_id.present? ? '=' : 'IS'} ?)", fy_id])
    render :update do |page|
      page.replace_html 'fees_list', :partial => 'fees_list'
      page.replace_html 'financial_year_details', :partial => 'finance/financial_year_info'
    end
  end

  def list_fee_collections_for_student
    @student=Student.find(params[:receiver_id])
    params[:collection_ids].present? ? colln_ids=params[:collection_ids] : colln_ids=[0]
    fee_collections= HostelFeeCollection.find(:all, :include => :event, :select => "distinct hostel_fee_collections.*", :joins => :hostel_fees, :conditions => ["(name LIKE ?) and hostel_fee_collections.id not in (?) and  (hostel_fee_collections.batch_id is null or hostel_fee_collections.batch_id='#{params[:batch_id]}')", "%#{params[:query]}%", colln_ids])
    data_values=fee_collections.map { |f| "{'id':#{f.id}, 'event_id' : #{f.event.id}}" }
    render :json => {'query' => params["query"], 'suggestions' => fee_collections.collect { |fc| fc.name.length+fc.start_date.to_s.length > 20 ? fc.name[0..(18-fc.start_date.to_s.length)]+".. "+" - "+fc.start_date.to_s : fc.name+" - "+fc.start_date.to_s }, 'data' => data_values}
  end

  def collection_creation_and_assign
    @batches =Batch.find(:all,
      :select => "distinct `batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
      :joins => "INNER JOIN students on students.batch_id=batches.id
                 INNER JOIN room_allocations on students.id=room_allocations.student_id 
                 INNER JOIN `courses` ON `courses`.id = `batches`.course_id",
      :conditions => "batches.is_active=1 and batches.is_deleted=0", :order => "course_full_name",
      :include => :course)
    @dates=[]
  end


  def update_fees_collections
    @dates = HostelFeeCollection.current_active_financial_year.all(:select => "distinct hostel_fee_collections.*",
      :joins => "#{active_account_joins(true, 'hostel_fee_collections')}
                                                 INNER JOIN `hostel_fees` ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id 
                                                 INNER JOIN students on students.id=hostel_fees.student_id",
      :conditions => "students.batch_id='#{params[:batch_id]}' and hostel_fee_collections.is_deleted=false AND
                                                      #{active_account_conditions(true, 'hostel_fee_collections')}")
    render :update do |page|
      page.replace_html 'fees_collection_dates', :partial => 'fees_collection_dates'
    end
  end

  def render_collection_assign_form
    @hostel_fee_collection=HostelFeeCollection.find(params[:id])
    render :update do |page|
      page.replace_html 'students_selection', :partial => 'students_selection'
    end
  end


  def list_students_for_collection
    @collection=HostelFeeCollection.find(params[:date_id], :include => :hostel_fees)
    student_ids=@collection.hostel_fees.collect(&:student_id)
    student_ids=student_ids.join(',')

    students= Student.active.find(:all, :joins => [:room_allocations => :room_detail], :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and students.id not in (#{student_ids}) and batch_id='#{params[:batch_id]}' ", "%#{params[:query]}%", "%#{params[:query]}%"]).uniq
    suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - "+s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s+"(#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.name}-#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.type})" : s.full_name+"(#{s.admission_no})"+" - "+s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s+"(#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.name}-#{s.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.hostel.type})" }
    receivers=students.map { |st| "{'receiver': 'Student','id': #{st.id}, 'rent' : #{st.room_allocations.find(:first, :conditions => "is_vacated=false").room_detail.rent.to_s},'user_id':#{st.user_id},'batch_id':#{st.batch_id}}" }
    if receivers.present?
      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => receivers}
    else
      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
    end
  end

  def collection_assign_students
    @hostel_fee_collection=HostelFeeCollection.find(params[:hostel_fee_collection][:id])
    event=@hostel_fee_collection.event
    student_fees = params[:hostel_fee_collection][:hostel_fees_attributes].values
    if @hostel_fee_collection.tax_enabled
      tax_slab = @hostel_fee_collection.collection_tax_slabs.try(:last)
      tax_multiplier = tax_slab.rate.to_f * 0.01 if tax_slab.present?
      tax_collection_hsh = {
        :taxable_entity_id => @hostel_fee_collection.id,
        :taxable_entity_type => 'HostelFeeCollection',
        :taxable_fee_type => 'HostelFee'
      } if tax_slab.present?
      student_fees.each_with_index do |student_fee, i|
        student_fee["invoice_number_enabled"] = @hostel_fee_collection.invoice_enabled
        if tax_slab.present?
          tax = student_fee["rent"].to_f * tax_multiplier
          student_fee_tax = tax_collection_hsh.dup.merge({:tax_amount => tax, :slab_id => tax_slab.id})
          student_fee["tax_amount"] = tax
          student_fee["tax_enabled"] = @hostel_fee_collection.tax_enabled
          student_fee['tax_collections_attributes'] = [student_fee_tax]
          student_fees[i] = student_fee
        end
      end
    end
    @hostel_fee_collection.update_attributes(:hostel_fees_attributes => student_fees)
    if (params[:event].present?)
      recipients=[]
      user_events=event.user_events.create(params[:event].values) if event
      params[:event].each { |k, v| recipients<<v["user_id"] }
      send_reminder(@hostel_fee_collection, recipients)
    end
    flash[:notice]="#{t('collection_date_has_been_created')}"
    redirect_to :action => 'collection_creation_and_assign'
  end

  def choose_collection_and_assign
    @batches =Batch.find(:all, :select => "distinct batches.*",
      :joins => "INNER JOIN students on students.batch_id=batches.id
                      INNER JOIN room_allocations on students.id=room_allocations.student_id",
      :conditions => "batches.is_active=1 and batches.is_deleted=0")
    @dates=[]
    render :update do |page|
      page.replace_html "collection-details", :partial => 'choose_collection_and_assign'
    end
  end

  def generate_fee_receipt_pdf
    @finance_transaction= FinanceTransaction.find(params[:transaction_id])
    @hostel_fee=@finance_transaction.finance
    @payee= @finance_transaction.payee
    render :pdf => 'generate_fee_receipt_pdf', :template => 'hostel_fee/generate_fee_receipt_pdf.erb', :margin => {:top => 10, :bottom => 30, :left => 15, :right => 15}, :header => {:html => {:content => ''}}, :show_as_html => params.key?(:debug)
  end

  private

  def load_tax_setting
    @tax_enabled = Configuration.get_config_value('EnableFinanceTax').to_i == 1
  end

  def check_if_mobile_user
    user_agents=["android", "ipod", "opera mini", "opera mobi", "blackberry", "palm", "hiptop", "avantgo", "plucker", "xiino", "blazer", "elaine", "windows ce; ppc;", "windows ce; smartphone;", "windows ce; iemobile", "up.browser", "up.link", "mmp", "symbian", "smartphone", "midp", "wap", "vodafone", "o2", "pocket", "kindle", "mobile", "pda", "psp", "treo"]
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
end
