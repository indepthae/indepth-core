class InstantFeesController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision
  include LinkPrivilege
  include  ApplicationHelper
  before_filter :load_tax_setting, :only => [
    :create_particular,
    :create_category_particular, 
    :edit_particular,
    :edit_particular_slab, 
    :handle_category, 
    :handle_category_for_guest,
    :list_particulars, 
    :new_category_particular, 
    :new_instant_fees, 
    :new_particular, 
    :update_particular, 
    :update_particular_slab
  ]

  check_request_fingerprint :delete_transaction_for_instant_fee, :create_instant_fee
  
  helper_method('link_to','link_to_remote','link_present')
  
  def index
  end

  def manage_fees
    @instant_fee_categories = InstantFeeCategory.current_active_financial_year.all(:conditions => {:is_deleted => false})
  end

  def new_category
    @new_instant_category = InstantFeeCategory.new
    respond_to do |format|
      format.js { render :action => 'new_category' }
    end
  end

  def create_category
    @new_instant_category = InstantFeeCategory.new(params[:instant_fee_category])
    if @new_instant_category.save
      @instant_fee_categories = InstantFeeCategory.current_active_financial_year.active
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'create_category' }
    end
  end

  def edit_category
    @instant_category = InstantFeeCategory.find(params[:id])
    @financial_year = FinancialYear.fetch_name @instant_category.financial_year_id
    respond_to do |format|
      format.js { render :action => 'edit_category' }
    end
  end

  def update_category
    @instant_category = InstantFeeCategory.find(params[:id])
    if @instant_category.update_attributes(params[:instant_fee_category])
      @instant_fee_categories = InstantFeeCategory.current_active_financial_year.active
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'update_category' }
    end
  end

  def delete_category
    @instant_category = InstantFeeCategory.find(params[:id])
    @error=false
    unless @instant_category.instant_fees.present?
      @instant_category.update_attributes(:is_deleted => true)
      @instant_category.instant_fee_particulars.each do |particular|
        particular.update_attributes(:is_deleted => true)
      end
    else
      @error=true;
    end
    @instant_fee_categories = InstantFeeCategory.current_active_financial_year.active
    respond_to do |format|
      format.js { render :action => 'delete_category' }
    end
  end


  def new_particular
    @new_instant_particular = InstantFeeParticular.new
    @master_particulars = MasterFeeParticular.core
    @tax_slabs = TaxSlab.all if @tax_enabled
    @instant_fee_categories = InstantFeeCategory.current_active_financial_year.active
    respond_to do |format|
      format.js { render :action => 'new_particular' }
    end
  end

  def new_category_particular
    @instant_category = InstantFeeCategory.find(params[:id], :conditions => {:is_deleted => false})
    @master_particulars = MasterFeeParticular.core
    @tax_slabs = TaxSlab.all if @tax_enabled
    @new_instant_particular = @instant_category.instant_fee_particulars.new
    respond_to do |format|
      format.js {render :action =>'new_category_particular'}
    end
  end

  def create_particular
    @instant_category = InstantFeeCategory.find(params[:instant_fee_particular][:instant_fee_category_id]) if params[:instant_fee_particular][:instant_fee_category_id].present?

    @new_instant_particular = @instant_category.present? ? @instant_category.instant_fee_particulars.new(params[:instant_fee_particular]) :
        InstantFeeParticular.new(params[:instant_fee_particular])
    if @new_instant_particular.save
      include_fee_particular_associations = @tax_enabled ? [:tax_slabs] : []
      @instant_fee_particulars = @instant_category.instant_fee_particulars.all(
        :conditions=> {:is_deleted => false}, :include => include_fee_particular_associations)
    else
      @error = true
    end

    respond_to do |format|
      format.js { render :action => 'create_particular' }
    end
  end

  def create_category_particular
    @instant_category = InstantFeeCategory.find(params[:id],:conditions => {:is_deleted => false})
    @new_instant_particular = @instant_category.instant_fee_particulars.new(params[:instant_fee_particular])
    if @new_instant_particular.save
      include_fee_particular_associations = @tax_enabled ? [:tax_slabs] : []
      @instant_fee_particulars = @instant_category.instant_fee_particulars.all(
        :conditions=> {:is_deleted=>false}, :include => include_fee_particular_associations)
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'create_particular' }
    end
  end

  def edit_particular
    include_fee_particular_associations = @tax_enabled ? [:tax_slabs, :master_fee_particular] : []
    @master_particulars = MasterFeeParticular.core
    @instant_particular = InstantFeeParticular.find(params[:id],
      :include => include_fee_particular_associations)
    @instant_fee_categories = InstantFeeCategory.current_active_financial_year.active
    @tax_slabs = TaxSlab.all if @tax_enabled
    respond_to do |format|
      format.js { render :action => 'edit_particular' }
    end
  end

  def edit_particular_slab    
    include_fee_particular_associations = @tax_enabled ? [:tax_slabs] : []
    @instant_particular = InstantFeeParticular.find(params[:id], 
      :include => include_fee_particular_associations)
    @tax_slabs = TaxSlab.all if @tax_enabled
  end
  
  def update_particular_slab
    @instant_fee_particular = InstantFeeParticular.find(params[:id])
    if @instant_fee_particular.apply_tax_slab(params[:instant_fee_particular][:tax_slab_id])
      include_fee_particular_associations = @tax_enabled ? [:tax_slabs] : []
      @instant_fee_particulars = @instant_fee_particular.instant_fee_category.
        instant_fee_particulars.all(:include => include_fee_particular_associations, 
        :conditions=> {:is_deleted=>false})
    else
      @tax_slabs = TaxSlab.all if @tax_enabled
    end
    respond_to do |format|
      format.js { render :action => 'update_particular_slab' }
    end
  end
  
  def update_particular
    @instant_category = InstantFeeCategory.find(params[:instant_fee_particular][:instant_fee_category_id])
    @instant_particular = InstantFeeParticular.find(params[:id])
    if @instant_particular.update_attributes(params[:instant_fee_particular])
      @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions=> {:is_deleted=>false})
    else
      @error = true
    end
    respond_to do |format|
      format.js { render :action => 'update_particular' }
    end
  end

  def delete_particular
    @instant_particular = InstantFeeParticular.find(params[:id])
    @instant_category = @instant_particular.instant_fee_category
    @instant_particular.update_attributes(:is_deleted => true)
    @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions=> {:is_deleted=>false})
    respond_to do |format|
      format.js { render :action => 'delete_particular' }
    end
  end

  def list_particulars
    @instant_fee_category = InstantFeeCategory.find(params[:id])
    include_fee_particular_associations = @tax_enabled ? [:tax_slabs, :master_fee_particular] : [:master_fee_particular]
    @instant_fee_particulars = @instant_fee_category.instant_fee_particulars.all(
      :conditions=> {:is_deleted => false}, :include => include_fee_particular_associations)
  end

  def new_instant_fees
    @tax_slab_hash = Hash.new 
    @tax_slabs = TaxSlab.all
    @tax_slabs.map do |slab|
      @tax_slab_hash.merge!({slab.id => {:name => slab.name, :rate => slab.rate.to_f}})
    end if @tax_enabled
  end

  def tsearch_logic # transport search fees structure
    @instant_fee_categories = InstantFeeCategory.active
    @option = params[:option]
    if params[:option] == "student"
      query = params[:query]
      unless query.length < 3
        @students_result = Student.first_name_or_last_name_or_admission_no_begins_with query
      else
        @students_result = Student.admission_no_begins_with query
      end if query.present?
    elsif params[:option] == "employee"
      query = params[:query]
      unless query.length < 3
        @employee_result = Employee.first_name_or_last_name_or_employee_number_begins_with query
      else
        @employee_result = Employee.employee_number_begins_with query
      end if query.present?
    end
    render :layout => false
  end

  def category_type
    if params[:employee_id].present?
      @employee_id = params[:employee_id]
    elsif params[:student_id].present?
      @student_id = params[:student_id]
    end
    @instant_fee_categories = InstantFeeCategory.active
    render :update do |page|
      # page.replace_html 'partial-content',:text => ''
      page.replace_html 'search_box_bg', :text => ''
      page.replace_html 'information', :text => ''
      page.replace_html 'select-category-type', :partial => 'select_category_type_for_user'
    end
  end

  def handle_category

    payee_id = @employee_id = params[:employee_id] if params[:employee_id].present?
    payee_id = @student_id = params[:student_id] if params[:student_id].present?


    # @paid_fees=FinanceTransaction.find_all_by_payee_id_and_title(payee_id, "Instant Fee")
    @master_particulars = MasterFeeParticular.core
    @master_discounts = MasterFeeDiscount.core
    @tax_slabs = TaxSlab.all if @tax_enabled
    @option = params[:user_type]
    @instant_fee_categories = InstantFeeCategory.active if @option == 'guest'
    @transaction_date = Date.today_with_timezone
    financial_year_check
    if params[:category_id] == "#{t('custom')}"
      render :update do |page|
        page.replace_html 'fee_window', :partial => 'make_fee'
        # page.replace_html 'fee_window',:partial => 'make_fee_from_custom_category'
      end
    else
      #      @tax_slabs = TaxSlab.all if @tax_enabled
      unless params[:category_id] ==""
        # unless InstantFeeCategory.has_unlinked_particulars?(params[:category_id])
          include_fee_particular_associations = @tax_enabled ? [:tax_slabs] : []
          @instant_category = InstantFeeCategory.find(params[:category_id])
          @instant_fee_particulars = @instant_category.instant_fee_particulars.all(
              :include => include_fee_particular_associations, :conditions => {:is_deleted => false})
          render :update do |page|
            page.replace_html 'enter_custom_category', :text => ''
            page.replace_html 'fee_window', :partial => 'make_fee'
            page << "enable_fee_payment(#{!@financial_year_enabled})"
          end
        # else
        #   render :update do |page|
        #     page.replace_html 'fee_window', :partial => 'notice_link_particulars'
        #   end
        # end
      else
        render :update do |page|
          page.replace_html 'enter_custom_category', :text => ''
          page.replace_html 'fee_window', :text => ''
        end
      end

    end
  end

  def validate_transaction_date
    @transaction_date = params[:transaction_date]
    financial_year_check
    render :update do |page|
      page.replace_html 'flash-msg', :partial => "finance_extensions/flash_notice"
      page << "enable_fee_payment(#{!@financial_year_enabled})"
    end
  end

  def handle_category_for_guest
    @tax_slabs = TaxSlab.all if @tax_enabled
    @master_particulars = MasterFeeParticular.core
    @master_discounts = MasterFeeDiscount.core
    if params[:category_id] == "Custom"
      #      @tax_slabs = TaxSlab.all if @tax_enabled
      render :update do |page|
        page.replace_html 'fee_window', :partial => 'make_fee_from_custom_category_for_guest'
      end
    else
      unless params[:category_id] ==""
        #        @tax_slabs = TaxSlab.all if @tax_enabled
        @instant_category = InstantFeeCategory.find(params[:category_id])
        @instant_fee_particulars = @instant_category.instant_fee_particulars.all(:conditions => {:is_deleted => false})
        render :update do |page|
          page.replace_html 'enter_custom_category', :text => ''
          page.replace_html 'fee_window', :partial => 'make_fee_for_guest'
        end
      else
        render :update do |page|
          page.replace_html 'enter_custom_category', :text => ''
          page.replace_html 'fee_window', :text => ''
        end
      end
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

  def create_instant_fee
    @instant_fee = InstantFee.new
    unless params[:custom_category_name].blank?
      @instant_fee.custom_category = params[:custom_category_name]
      @instant_fee.custom_description=params[:custom_category_description]
      unless params[:guest_payee].nil?
        @instant_fee.guest_payee = params[:guest_payee]
      else
        unless params[:student_id].nil?
          @student = Student.find(params[:student_id])
          @instant_fee.payee = @student
          @instant_fee.groupable = @student.batch
        end
        unless params[:employee_id].nil?
          @employee = Employee.find(params[:employee_id])
          @instant_fee.payee = @employee
          @instant_fee.groupable = @employee.employee_department
        end
      end
    else
      @instant_fee.instant_fee_category_id = params[:category_id]
      unless params[:guest_payee].nil?
        @instant_fee.guest_payee = params[:guest_payee]
      else
        unless params[:student_id].blank?
          @student = Student.find(params[:student_id])
          @instant_fee.payee = @student
          @instant_fee.groupable = @student.batch
        end
        unless params[:employee_id].blank?
          @employee = Employee.find(params[:employee_id])
          @instant_fee.payee = @employee
          @instant_fee.groupable = @employee.employee_department
        end
      end
    end
    unless params[:fees][:payment_mode].blank?
      # name=params[:name].reject{ |c| c.empty? } unless params[:name].nil?
      master_particular_ids_orig = params[:master_fee_particular_id] #.reject { |c| c.empty? }.map(&:to_i)
      master_particular_ids = params[:master_fee_particular_id] #.reject { |c| c.empty? }.map(&:to_i)
      master_discount_ids = params[:master_fee_discount_id] #.reject { |c| c.empty? }.map(&:to_i)
      # particular_ids = params[:particular_ids].present? ? params[:particular_ids].reject { |c| c.empty? } : []
      particular_ids = params[:particular_ids].present? ? params[:particular_ids] : []
      # particular_ids -= InstantFeeParticular.with_masters.with_ids(particular_ids) if particular_ids.present?
      master_ids = master_particular_ids.slice(particular_ids.length, master_particular_ids.length)

      total_paid = params[:total].map { |x| x.to_f }.sum
      total_amount = (params[:total_fees].to_f != total_paid.to_f) ? total_paid.to_f : params[:total_fees].to_f
      # if total_paid != params[:total_fees].to_f
      #   flash[:notice] = t('flash1')
      #   redirect_to :action => 'new_instant_fees'
      # else
      # if master_particular_ids.present?
      if particular_ids.present? or master_ids.present?
        ActiveRecord::Base.transaction do
          @instant_fee.tax_enabled = params[:tax_enabled]
          @instant_fee.tax_amount = 0
          @instant_fee.amount = total_amount #params[:total_fees]
          @instant_fee.pay_date = params[:transaction_date]

          if @instant_fee.save
            master_particulars = master_ids.present? ? MasterFeeParticular.find_all_by_id(master_ids).group_by(&:id) : {}
            i = 0
            @amounts = params[:amount]
            @discounts = params[:discount]
            @total_fees = params[:total]
            is_tax_enabled = (params[:tax_enabled].present? and params[:tax_enabled] == "true")
            if is_tax_enabled
              @tax_rates = params[:tax_rate]
              @tax_amounts = params[:tax_amount]
            end

            particular_ids.each do |particular|
              @instant_fee_details = @instant_fee.instant_fee_details.new
              @instant_fee_details.master_fee_particular_id = master_particular_ids[i] unless master_particular_ids[i].to_i.zero?
              @instant_fee_details.master_fee_discount_id = master_discount_ids[i] unless master_discount_ids[i].to_i.zero?
              if particular_ids[i].present?
                @instant_fee_details.instant_fee_particular_id = particular_ids[i]
                # else
                #   @instant_fee_details.custom_particular = master_particulars[particular].first.name
              end
              @instant_fee_details.amount = @amounts[i]
              @instant_fee_details.discount = @discounts[i]
              @instant_fee_details.net_amount = @total_fees[i]
              if is_tax_enabled
                @instant_fee_details.tax = @tax_rates[i]
                @instant_fee_details.tax_amount = @tax_amounts[i]
                @instant_fee.tax_amount += @tax_amounts[i].to_f
              end
              @instant_fee_details.save
              i = i + 1
              @flag=0
            end

            master_ids.each do |particular|
              # particular_ids.each do |particular|
              @instant_fee_details = @instant_fee.instant_fee_details.new
              @instant_fee_details.master_fee_particular_id = particular
              @instant_fee_details.master_fee_discount_id = master_discount_ids[i] unless master_discount_ids[i].to_i.zero?
              if particular_ids[i].present?
                @instant_fee_details.instant_fee_particular_id = particular_ids[i]
              else
                @instant_fee_details.custom_particular = master_particulars[particular.to_i].try(:first).try(:name)
              end
              @instant_fee_details.amount = @amounts[i]
              @instant_fee_details.discount = @discounts[i]
              @instant_fee_details.net_amount = @total_fees[i]
              if is_tax_enabled
                @instant_fee_details.tax = @tax_rates[i]
                @instant_fee_details.tax_amount = @tax_amounts[i]
                @instant_fee.tax_amount += @tax_amounts[i].to_f
              end
              @instant_fee_details.save
              i = i + 1
              @flag=0
            end

            @instant_fee.save if @instant_fee.tax_amount.to_f > 0
            unless @error
              category_type = FinanceTransactionCategory.find_by_name("InstantFee")
              @transaction = FinanceTransaction.new
              @transaction.title = "Instant Fee"
              @transaction.description = category_type.description
              @transaction.category_id = category_type.id
              @transaction.finance_fees_id = @instant_fee.id
              @transaction.amount = @instant_fee.amount
              if @instant_fee.tax_amount.to_f > 0
                @transaction.tax_amount = @instant_fee.tax_amount
                @transaction.tax_included = true
              end
              @transaction.payee = @instant_fee.payee
              @transaction.finance = @instant_fee
              @transaction.trans_type = 'particular_wise'
              @transaction.transaction_date = params[:transaction_date]
              @transaction.payment_mode = params[:fees][:payment_mode]
              @transaction.reference_no = params[:fees][:reference_no]
              @transaction.payment_note = params[:fees][:payment_note]
              unless params[:student_id].blank?
                @transaction.batch_id = @student.batch_id
              end
              #            @transaction.save
              @transaction.safely_create
              TaxPayment.update_all({:finance_transaction_id => @transaction.id},
                                    {:id => @instant_fee.tax_payment_ids}) if is_tax_enabled
              flash[:notice] = t('instant_fee_payed')
              redirect_to :action => "instant_fee_created_detail", :id => @instant_fee.id
            end
          else
            @error=true
          end
          if @error==true
            flash[:warn_notice] = t('flash2')
            redirect_to :action => 'new_instant_fees'
            raise ActiveRecord::Rollback
          end
        end
      else
        @error = true
        flash[:warn_notice] = t('flash2')
        redirect_to :action => 'new_instant_fees'
      end
      # end
      # particular_ids = params[:particular_ids].reject{ |c| c.empty? } unless params[:particular_ids].nil?

    else
      flash[:warn_notice] = t('flash3')
      redirect_to :action => 'new_instant_fees'
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

  def report
    if validate_date
      
      filter_by_account, account_id = account_filter 
      joins = " INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                 LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      filter_conditions = "(fa.id IS NULL OR fa.is_deleted = false) "
      if filter_by_account
        filter_conditions += " AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      @target_action = 'report'
      @instant_fee_transaction_type = FinanceTransactionCategory.find_by_name("InstantFee")
      @instant_fee_transactions_by_custom = FinanceTransaction.find(:all,
        :order=>'created_at desc',
        :include => [:transaction_ledger, {:finance => :payee}],
        :joins => "INNER JOIN instant_fees ON instant_fees.id=finance_id
               LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id = instant_fee_category_id #{joins}",
        :conditions => ["finance_type='InstantFee' AND instant_fees.instant_fee_category_id is NULL and 
                                 (finance_transactions.transaction_date BETWEEN ? AND ?) AND #{filter_conditions}",
          @start_date, @end_date] + filter_values)
      
      @instant_fee_transactions_with_category = @transactions=FinanceTransaction.find(:all,
        :order=>'finance_transactions.created_at desc',
        :include => :transaction_ledger,
        :joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id #{joins} 
                      LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",
        :select=>"finance_transactions.*,instant_fees.instant_fee_category_id, 
                        instant_fee_categories.name AS category_name",
        :conditions=> ["finance_type='InstantFee' AND instant_fees.instant_fee_category_id IS NOT NULL and 
                              finance_transactions.transaction_date BETWEEN ? AND ? AND #{filter_conditions}",
          @start_date, @end_date] + filter_values).group_by(&:instant_fee_category_id)
      
      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial=>"report"
        end
      end
    else
      render_date_error_partial
    end
  end


  def instant_fee_report_csv
    if date_format_check
      
      filter_by_account, account_id = account_filter
      joins = " INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                 LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      filter_conditions = "(fa.id IS NULL OR fa.is_deleted = false) "
      if filter_by_account
        filter_conditions += " AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      @instant_fee_transaction_type = FinanceTransactionCategory.find_by_name("InstantFee")
      @instant_fee_transactions_by_custom = FinanceTransaction.find(:all, :order => 'created_at desc',
        :joins => "INNER JOIN instant_fees ON instant_fees.id = finance_id 
               LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id = instant_fee_category_id #{joins}",
        :include => [:transaction_receipt, {:finance => :payee}],
        :conditions => ["finance_type = 'InstantFee' AND instant_fees.instant_fee_category_id is NULL AND
                         (finance_transactions.transaction_date BETWEEN ? AND ?) AND #{filter_conditions}",
          @start_date, @end_date] + filter_values)
      
      @instant_fee_transactions_with_category = @transactions = FinanceTransaction.find(:all,
        :order => 'finance_transactions.created_at desc', :include => :transaction_receipt,
        #        :include => [:transaction_ledger, {:finance => :instant_fee_category}],
        :joins => "INNER JOIN instant_fees ON instant_fees.id=finance_id 
               LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id #{joins}",
        :select => "finance_transactions.*, instant_fees.instant_fee_category_id, 
                          instant_fee_categories.name AS category_name",
        :conditions => ["finance_type='InstantFee' AND instant_fees.instant_fee_category_id IS NOT NULL AND
                         (finance_transactions.transaction_date BETWEEN ? AND ?) AND #{filter_conditions}",
          @start_date, @end_date] + filter_values).group_by(&:instant_fee_category_id)
      
      csv_string=FasterCSV.generate do |csv|
        csv << t('instant_fees_transaction_report')
        csv << [t('start_date'),format_date(@start_date)]
        csv << [t('end_date'),format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << ["",t('payee'),t('date_text'),t('reciept'),t('amount')]
        total=0
        @instant_fee_transactions_with_category.each do |category,transactions|
          csv << transactions.first.try(:category_name)
          transactions.each do |transaction|
            row = []
            row << ""
            row << transaction.finance.payee_name
            row << format_date(transaction.transaction_date,:long)
            row << transaction.receipt_number
            row << precision_label(transaction.amount)
            total += transaction.amount.to_f
            csv << row
          end
        end
        row = []
        unless @instant_fee_transactions_by_custom.empty?
          csv << t('custom')
          csv << ""
          @instant_fee_transactions_by_custom.each do |transaction|
            row << ""
            row << transaction.finance.payee_name
            row << format_date(transaction.transaction_date,:long)
            row << transaction.receipt_number
            row << transaction.amount
            total += transaction.amount.to_f
            csv << row
          end
        end
        csv << ""
        csv << [t('net_income'),"","","",total]
      end
      filename = "#{t('instant_fees_transaction_report')} #{@start_date}  #{t('to')}  #{@end_date}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end

  def instant_fee_created_detail
    @instant_fee = InstantFee.find_by_id(params[:id], :conditions => "(fa.id IS NULL OR fa.is_deleted = false)",
                      :joins => "INNER JOIN finance_transactions ft ON ft.finance_id = instant_fees.id AND ft.finance_type = 'InstantFee'
                                 INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id")
    if @instant_fee.present?
      @student = Student.find_by_id(@instant_fee.payee_id)
      @instant_fee_details = @instant_fee.instant_fee_details.all
    else
      flash[:notice] = t("flash_msg5")
      redirect_to :controller => 'user', :action => "dashboard"
    end
  end

  def print_reciept
    @instant_fee = InstantFee.find(params[:id])
    @instant_fee_details = @instant_fee.instant_fee_details.all
    render :pdf =>'instant_fee_reciept', :show_as_html=>params[:d].present?
  end

  def report_detail
    if date_format_check
      @instant_fee = InstantFee.find_by_id(params[:id], :conditions => "(fa.id IS NULL OR fa.is_deleted = false)",
                      :joins => "INNER JOIN finance_transactions ft ON ft.finance_id = instant_fees.id AND ft.finance_type = 'InstantFee'
                                 INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id")
      if @instant_fee.present?
        @instant_fee_details = @instant_fee.instant_fee_details.all
        @tax_payments = @instant_fee.tax_payments if @instant_fee.tax_enabled?
      else
        flash[:notice] = t("flash_msg5")
        redirect_to :controller => 'user', :action => "dashboard"
      end
    end
  end

  def instant_fee_report_detail_csv
    if date_format_check
      @instant_fee = InstantFee.find_by_id(params[:id], :conditions => "(fa.id IS NULL OR fa.is_deleted = false)",
                      :joins => "INNER JOIN finance_transactions ft ON ft.finance_id = instant_fees.id AND ft.finance_type = 'InstantFee'
                                 INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id")
      if @instant_fee.present?
        @instant_fee_details = @instant_fee.instant_fee_details.all
        tax_payments = @instant_fee.tax_payments if @instant_fee.tax_enabled?
        tax_enabled = @instant_fee.tax_enabled? and tax_payments.present?
        csv_string = FasterCSV.generate do |csv|
          csv << t('instant_fees_transaction_report')
          csv << [t('start_date'), @start_date]
          csv << [t('end_date'), @end_date]
          csv << ""
          csv << [t('reciept'), @instant_fee.finance_transaction.receipt_number]
          csv << [t('date_text'), format_date(@instant_fee.pay_date, :format => :long)]
          csv << [t('category'), @instant_fee.category_name]
          csv << [t('category_description'), @instant_fee.category_description]
          csv << [t('payee'), shorten_string(@instant_fee.payee_name, 20)]
          csv << [t('payment_mode'), @instant_fee.finance_transaction.payment_mode]
          csv << [t('payment_notes'), @instant_fee.finance_transaction.payment_note]
          csv << ""
          csv << (tax_enabled ? [t('particular'), t('amount'), "#{t('discount')} (%)", "#{t('tax_text')} (%)", t('total')] :
              [t('particular'), t('amount'), "#{t('discount')} (%)", t('total')])
          total_amount = 0
          total_net_amount = 0
          @instant_fee_details.each do |d|
            amt = precision_label(d.amount)
            disc = precision_label(d.discount)
            tax = precision_label(d.tax) if tax_enabled
            net_amt = precision_label(d.net_amount)
            csv << (tax_enabled ? [d.particular_name, amt, disc, tax, net_amt] :
                [d.particular_name, amt, disc, net_amt])
            total_amount += amt.to_f unless d.amount.nil?
            total_net_amount += net_amt.to_f unless d.net_amount.nil?
          end
          csv <<[t('total'), precision_label(total_amount), '', precision_label(total_net_amount)]
        end
        filename = "#{t('instant_fees_transaction_report')} #{@start_date}  #{t('to')}  #{@end_date}.csv"
        send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
      else
        flash[:notice] = t("flash_msg5")
        redirect_to :controller => "user", :action => "dashboard"
      end
    end
  end

  def delete_transaction_for_instant_fee
    @financetransaction=FinanceTransaction.find(params[:id])
    @financetransaction.cancel_reason = params[:reason]
    if @financetransaction
      @financetransaction.destroy
      @financetransaction.finance.destroy
    end
    #@category=InstantFeeCategory.find(params[:category_id])
    @category=params[:category_id]
    #@category=nil if params[:category_id]=='Custom'
    @start_date=params[:s_date]
    @end_date=params[:e_date]
    unless @category=='Custom'
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],
        :order=>'transaction_date desc', :include => :transaction_ledger,
        :joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id 
                      INNER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",
        :conditions=>["finance_type='InstantFee' AND instant_fees.instant_fee_category_id=? AND 
                               finance_transactions.transaction_date >= ? and finance_transactions.transaction_date < ?",
          params[:category_id],@start_date,@end_date.to_date+1.day])
    else
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],
        :order=>'transaction_date desc',:include => :transaction_ledger,
        :joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id 
                      LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",
        :conditions=>["finance_type='InstantFee' AND instant_fees.instant_fee_category_id is NULL AND 
                               finance_transactions.transaction_date >= ? and finance_transactions.transaction_date < ?",
          @start_date,@end_date.to_date+1.day])
    end
    render :update do |page|
      page.replace_html 'show_transactions',:partial => 'show_transactions'
    end
  end
  def show_instant_fee_transactions
    @instant_fee_categories = InstantFeeCategory.all(:conditions => {:is_deleted => false})
    #@transactions=FinanceTransaction.find(:all,:order => 'created_at desc',:conditions=>['finance_type=?',"InstantFee"]).paginate( :page => params[:page], :per_page => 20)
  end
  def list_instant_fee_transactions
    @category = params[:category_id]
    @page = params[:page]

    unless @category == 'Custom'
      @transactions = FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],
        :order=>'transaction_date desc',:include => :transaction_ledger,
        :joins => "INNER JOIN instant_fees ON instant_fees.id=finance_id
              LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id
                   INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        :conditions=>["finance_type=? AND instant_fees.instant_fee_category_id=? AND (fa.id IS NULL OR fa.is_deleted = false)
                       AND finance_transactions.transaction_date >= ? and finance_transactions.transaction_date < ?",
          'InstantFee', @category, Date.today, Date.today + 1.day])

    else
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],
        :order => 'transaction_date desc',:include => :transaction_ledger,
        :joins => "INNER JOIN instant_fees ON instant_fees.id=finance_id
              LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id
                   INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        :conditions => ["finance_type='InstantFee' AND instant_fees.instant_fee_category_id is NULL AND
                         (fa.id IS NULL OR fa.is_deleted = false) AND finance_transactions.transaction_date >= ? and
                         finance_transactions.transaction_date < ?", Date.today,Date.today+1.day])
    end
    render :update do |page|
      page.replace_html 'show_transactions',:partial => 'show_transactions'
    end
  end
  def instant_fee_transaction_filter_by_date
    @category=params[:category_id]
    #@category=nil if params[:category_id]=='Custom'
    @start_date=params[:s_date]
    @end_date=params[:e_date]
    unless @category=='Custom'
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],        
        :order=>'transaction_date desc',:include => :transaction_ledger,
        :joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id 
                 INNER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id
                 INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        :conditions=>["#{active_account_conditions} AND finance_type='InstantFee' AND instant_fees.instant_fee_category_id=? AND
                       finance_transactions.transaction_date >= ? and finance_transactions.transaction_date < ?",
          params[:category_id],@start_date,@end_date.to_date+1.day])
    else
      @transactions=FinanceTransaction.paginate(:per_page=>10,:page=>params[:page],        
        :order=>'transaction_date desc',:include => :transaction_ledger,
        :joins=>"INNER JOIN instant_fees ON instant_fees.id=finance_id
                 INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
            LEFT OUTER JOIN instant_fee_categories ON instant_fee_categories.id=instant_fee_category_id",
        :conditions=>["#{active_account_conditions} AND finance_type='InstantFee' AND instant_fees.instant_fee_category_id is NULL AND
                       finance_transactions.transaction_date >= ? and finance_transactions.transaction_date < ?",
          @start_date,@end_date.to_date+1.day])
    end
    render :update do |page|
      page.replace_html 'show_transactions',:partial => 'show_transactions'
    end
  end
  
  private

  def load_tax_setting
    @tax_enabled = Configuration.get_config_value('EnableFinanceTax').to_i == 1
  end  

end
