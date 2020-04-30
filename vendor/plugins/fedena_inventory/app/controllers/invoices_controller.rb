class InvoicesController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation
  before_filter :login_required
  filter_access_to :all, :except => [:edit, :update, :destroy]
  filter_access_to [:edit, :update, :destroy], :attribute_check=>true
  check_request_fingerprint :create

  def index
    @selected_store = (Invoice.last.nil? ? nil : Invoice.last.store.id) || (Store.first.present? ? Store.first.id : "")
  end
  
  def new
    @error = false
    @invoice = Invoice.new
    @stores = Store.find(:all, :joins => :store_items, :conditions => ["store_items.sellable = ? AND stores.is_deleted = ? AND store_items.is_deleted = ?",1, false,false]).uniq
    @sales_user_details = @invoice.sales_user_details.build
    @sold_items = @invoice.sold_items.build
    @discounts = @invoice.discounts.build
    @additional_charges = @invoice.additional_charges.build
    @selected_store = params[:selected_store] || (Store.first.present? ? Store.first.id : nil)
    if @selected_store.present?
      @invoice_no = generate_invoice_no(params[:selected_store])
    else
      flash[:notice] = "No store present"
      redirect_to :action=>:index
    end
  end

  def find_invoice_prefix
    invoice_no = generate_invoice_no(params[:id])
    render :json => {'invoice_no' => invoice_no }
  end

  def edit
    @invoice = Invoice.find(params[:id])
    @stores = Store.find(:all, :joins => :store_items, :conditions => ["store_items.sellable = ? AND stores.is_deleted = ? AND store_items.is_deleted = ?",1, false,false]).uniq
    @discounts = @invoice.discounts.build if @invoice.discounts.empty?
    @additional_charges = @invoice.additional_charges.build if @invoice.additional_charges.empty?
    @username = @invoice.sales_user_details.first.user.username if @invoice.sales_user_details.first.user.present?
  end

  def update
    @invoice = Invoice.find(params[:id])
    if @invoice.update_attributes(params[:invoice])
      if @invoice.is_paid
        payee = @invoice.sales_user_details.first.user
        status=true
        begin
          retries ||= 0
          status = true
          transaction = FinanceTransaction.new
          transaction.title = @invoice.invoice_no
          transaction.category = FinanceTransactionCategory.find_by_name("SalesInventory")
          transaction.finance = @invoice
          transaction.payee = payee
          transaction.transaction_date = @invoice.date
          transaction.amount = params[:invoice][:grandtotal]
          transaction.save
        rescue ActiveRecord::StatementInvalid => er            
          status = false
          retry if (retries += 1) < 2
        rescue Exception => e
          status = false
        end
        unless status
          @invoice.update_attribute('is_paid', false)
        end
      end
      flash[:notice] = "#{t('invoice_update_successfuly')}. <a href ='http://#{request.host_with_port}/invoices/invoice_pdf/#{@invoice.id}' target='_blank'>Print</a>"
      redirect_to :action => "index"
    else
      @stores = Store.find(:all, :joins => :store_items, :conditions => ["store_items.sellable = ? AND stores.is_deleted = ? AND store_items.is_deleted = ?",1, false,false]).uniq
      @discounts = @invoice.discounts.build if @invoice.discounts.empty?
      @additional_charges = @invoice.additional_charges.build if @invoice.additional_charges.empty?
      render :action => "edit", :id => @invoice.id
    end
  end
  
  def create
    @invoice = Invoice.new(params[:invoice])
    @stores = Store.find(:all, :joins => :store_items, :conditions => ["store_items.sellable = ? AND stores.is_deleted = ? AND store_items.is_deleted = ?",1, false,false]).uniq
    @selected_store = params[:invoice][:store_id].to_i || (Store.first.present? ? Store.first.id : "")
    @error = false
    if @invoice.save      
      if @invoice.is_paid
        payee = @invoice.sales_user_details.first.user
        status=true
        begin
          retries ||= 0
          status = true
          transaction = FinanceTransaction.new
          transaction.title = @invoice.invoice_no
          transaction.category = FinanceTransactionCategory.find_by_name("SalesInventory")
          transaction.finance = @invoice
          transaction.payee = payee
          transaction.transaction_date = @invoice.date
          transaction.amount = params[:invoice][:grandtotal]
          transaction.save
        rescue ActiveRecord::StatementInvalid => er            
          status = false
          retry if (retries += 1) < 2
        rescue Exception => e
          status = false
        end
        unless status
          @invoice.update_attribute('is_paid', false)
        end
      end      
      flash[:notice] = "Invoice #{@invoice.invoice_no} created successfully. <a href ='http://#{request.host_with_port}/invoices/invoice_pdf/#{@invoice.id}' target='_blank'>Print</a>"
      render(:update) do|page|
        page.redirect_to :action => "new", :selected_store => params[:invoice][:store_id]
      end
      #flash[:notice] = "Invoice #{@invoice.invoice_no} created successfully. <a href ='http://#{request.host_with_port}/invoices/invoice_pdf/#{@invoice.id}' target='_blank'>Print</a>"
      #redirect_to :action => "new", :selected_store => params[:invoice][:store_id]
    else
      @error = true
      @discounts = @invoice.discounts.build if @invoice.discounts.empty?
      @additional_charges = @invoice.additional_charges.build if @invoice.additional_charges.empty?
      #render :action => 'new', :selected_store => params[:invoice][:store_id]
      render(:update) do|page|
        page.replace_html "error", :partial=>"error_messages"
        page << ("j(window).scrollTop(0,0);")                
      end
    end
  end

  def show
    @item=StoreItem.find(params[:item_id]) if params[:item_id].present?
    @invoice = Invoice.find_by_id(params[:id], :conditions => "fa.id IS NULL OR fa.is_deleted = false",
      :joins => "LEFT JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
                           LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                            LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id")
    @currency = Configuration.find_by_config_key("CurrencyType").config_value
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    unless @invoice.present?
      flash[:notice] = t("flash_msg5")
      redirect_to :controller => 'user', :action => "dashboard"
    end
  end
  
  def destroy
    @invoice = Invoice.find(params[:id])
    @invoice.destroy
    flash[:notice] = "#{t('invoice_deleted_successfully')}"
    respond_to do |format|
      format.html { redirect_to(invoices_url) }
      format.xml  { head :ok }
    end
  end

  def search_code
    item_code = StoreItem.find(:all, :conditions=>[" is_deleted = ? AND code LIKE ? AND store_id = ? AND sellable = ?", false,"%#{params[:query]}%","#{params[:store_id]}", 1])
    render :json=>{'query'=>params["query"],'suggestions'=>item_code.collect{|c| c.code},'data'=>item_code.collect(&:id)  }
  end

  def search_store_item
    unless params[:id].nil?
      store_item = StoreItem.find(params[:id])
      store_item_name = store_item.item_name
      unit_price = store_item.unit_price
      render :json=> {'item_name' => store_item_name, 'unit_price' => unit_price, 'code' => store_item.code}
    else
      store_item = if params[:po].present?
        StoreItem.find(:all, :conditions=>[" is_deleted = ? AND item_name LIKE ? AND store_id = ?",false, "%#{params[:query]}%","#{params[:store_id]}"])
      else
        StoreItem.find(:all, :conditions=>[" is_deleted = ? AND item_name LIKE ? AND store_id = ? AND sellable = ?",false, "%#{params[:query]}%","#{params[:store_id]}", 1]) 
      end  
      render :json=> {'query'=>params["query"],'suggestions'=>store_item.collect{|c| c.item_name},'data'=>store_item.collect(&:id)}
    end
  end

  def search_username
    user = User.active.find(:all, :conditions=>["username LIKE ?", "%#{params[:query]}%"])
    render :json=>{'query'=>params["query"],'suggestions'=>user.collect{|c| c.username},'data'=>user.collect(&:id)  }
  end

  
  
  def search_user_details
    user = User.find(params[:id])
    first_name = user.first_name
    address = ""
    if user.employee?
      emp = Employee.find_by_user_id(user.id)
      address += emp.home_address_line1 + "\n" unless emp.home_address_line1.nil?
      address += emp.home_address_line2 + "\n" unless emp.home_address_line2.nil?
      address += emp.home_city+ "\n" unless emp.home_city.nil?
      address += emp.home_state + "\n"unless emp.home_state.nil?
      #address += emp.home_country unless emp.home_country_id.nil?
      address += emp.home_pin_code + "\n"unless emp.home_pin_code.nil?
    elsif user.student?
      stud = Student.find_by_user_id(user.id)
      address += stud.address_line1 + "\n" unless stud.address_line1.nil?
      address += stud.address_line2 + "\n" unless stud.address_line2.nil?
      address += stud.city + "\n" unless stud.city.nil?
      address += stud.state + "\n" unless stud.state.nil?
      address += stud.pin_code + "\n" unless stud.pin_code.nil?
      #address += stud.country + "\n" unless stud.country_id.nil?
    end
    render :json => {'name' => first_name, 'address' => address, :user_id => user.id}
  end

  def update_invoice
    @currency = Configuration.find_by_config_key("CurrencyType").config_value
    @invoices = Invoice.paginate(:page => params[:page],:per_page => 10,
      :joins => "LEFT JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
                 LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                 LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND invoice_no LIKE ? AND store_id = ? ",
        "#{params[:query]}%", params[:id] ], :order => "id desc")
    render(:update) do|page|
      page.replace_html 'update_invoice', :partial=>'list_invoices'
    end
  end

  def invoice_pdf
    @invoice = Invoice.find_by_id(params[:id], :conditions => "fa.id IS NULL OR fa.is_deleted = false",
      :joins => "LEFT JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
                           LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                           LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id")
    if @invoice.present?
      @store_name = @invoice.store.name
      @user = @invoice.sales_user_details.first.user
      @currency = Configuration.find_by_config_key("CurrencyType").config_value
      if @invoice.is_paid
        transaction = @invoice.finance_transaction
        unless transaction.nil?
          @transaction_date = transaction.transaction_date
          @amount = transaction.amount
          @reciept_no = transaction.receipt_number
          # render :pdf => 'invoice_pdf', :show_as_html => false
          @transaction_hash = transaction.receipt_data
          @transaction_hash.template_id = transaction.fetch_template_id
          template_id = @transaction_hash.template_id
        end
      end
      @data = {:templates => template_id.present? ? FeeReceiptTemplate.find(template_id).to_a.group_by(&:id) : {} }

      render :pdf => 'invoice_pdf', :template => "invoices/invoice_new_pdf.erb",
        :margin =>{:top=>2,:bottom=>20,:left=>5,:right=>5}, :header => {:html => { :content=> ''}},
        :footer => {:html => {:content => ''}},  :show_as_html => params.key?(:debug)
    else
      flash[:notice] = t("flash_msg5")
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def find_item_name
    @store_item = StoreItem.find(params[:id])
    render :json => {:item_name => @store_item.item_name}
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

  def report
    if validate_date
      
      filter_by_account, account_id = account_filter

      ft_joins = "INNER JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
                  INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                  INNER JOIN stores ON stores.id = invoices.store_id"
      filter_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "
      if filter_by_account
        filter_conditions += " AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      @target_action = "report"
      
      inventory = FinanceTransactionCategory.find_by_name('SalesInventory').id
      @store_sales = Invoice.find(:all, :joins => ft_joins, :group => :store_id,
        :conditions => ["ft.category_id = ? AND (ft.transaction_date BETWEEN ? AND ? ) AND ft.finance_type='Invoice'
                         AND #{filter_conditions}", inventory, @start_date, @end_date] + filter_values,
        :select => "stores.name AS store_name, SUM(ft.amount) AS amount, invoices.store_id AS store_id")
      
      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial=>"report"
        end
      end
    else
      render_date_error_partial
    end

  end
  
  def report_csv
    if date_format_check
      
      filter_by_account, account_id = account_filter
      ft_joins = "INNER JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
                  INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                  INNER JOIN stores ON stores.id = invoices.store_id"
      filter_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "
      if filter_by_account
        filter_conditions += " AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      inventory = FinanceTransactionCategory.find_by_name('SalesInventory').id
      store_sales = Invoice.all(:joins => ft_joins, :group => :store_id,
        :conditions =>["ft.category_id = ? AND (ft.transaction_date BETWEEN ? AND ?) AND ft.finance_type = 'Invoice'
                        AND #{filter_conditions}", inventory, @start_date, @end_date] + filter_values,
        :select => "stores.name AS store_name, SUM(ft.amount) AS amount, invoices.store_id AS store_id")
      
      csv_string = FasterCSV.generate do |csv|
        csv << t('inventory_transaction_report')
        csv << [t('start_date'),format_date(@start_date)]
        csv << [t('end_date'),format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << [t('store'),t('amount')]
        total = 0
        store_sales.each do |t|
          row = []
          row << t.store_name
          row << precision_label(t.amount)
          total += t.amount.to_f
          csv << row
        end
        csv << ""
        csv << [t('net_income'),precision_label(total)]
      end
      filename = "#{t('inventory_transaction_report')}-#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end
  
  def sold_items_report
    if validate_date
      
      filter_by_account, account_id = account_filter
      ft_joins_1 = "INNER JOIN invoices ON invoices.id = sold_items.invoice_id
                  INNER JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'"
      ft_joins_2 = " INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                  INNER JOIN stores ON stores.id = invoices.store_id"
      ft_joins_3 = " INNER JOIN invoices ON invoices.id = invoice_id
                    INNER JOIN finance_transactions ft ON ft.finance_id = invoice_id AND ft.finance_type = 'Invoice'"

      ft_joins = ft_joins_1 + ft_joins_2

      filter_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "
      
      if filter_by_account
        filter_conditions += " AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      @target_action = "sold_items_report"
      @grand_total = SoldItem.all(:select => "rate", :joins => ft_joins,
        :conditions => ["invoices.store_id= ? AND (invoices.date BETWEEN ? AND ?) AND 
                                 invoices.is_paid = true AND #{filter_conditions}",
          params[:id], @start_date, @end_date] + filter_values).map {|x| x.rate.to_f }.sum
      @store_items = StoreItem.paginate(:page => params[:page], :per_page=>10,
        :joins =>  "INNER JOIN sold_items ON sold_items.store_item_id = store_items.id #{ft_joins}",
        :group => "sold_items.store_item_id",
        :conditions => ["store_items.store_id = ? AND (invoices.date BETWEEN ? AND ?) AND invoices.is_paid= true AND
                         #{filter_conditions}", params[:id], @start_date, @end_date] + filter_values,
        :select => "item_name, sold_items.store_item_id AS item_id, SUM(sold_items.rate) AS amount,
                    store_items.store_id AS store_id")

      #@additional_charges = Invoice.find_all_by_store_id_and_is_paid(params[:id],true).map{|s| s.additional_charges}.flatten.map{|s| s.amount.to_f}.sum      
      @additional_charges = AdditionalCharge.all(:joins => ft_joins_3 + ft_joins_2,
        :conditions => ["invoices.store_id = ? AND (invoices.date BETWEEN ? AND ?) AND invoices.is_paid = true AND #{filter_conditions} ",
          params[:id], @start_date, @end_date] + filter_values).flatten.map{|s| s.amount.to_f}.sum                      
      #@discounts = Invoice.find_all_by_store_id_and_is_paid(params[:id],true).map{|s| s.discounts}.flatten.map{|s| s.amount.to_f}.sum
      @discounts = Discount.all(:joins => ft_joins_3 + ft_joins_2,
        :conditions => ["invoices.store_id = ? AND (invoices.date BETWEEN ? AND ?) AND invoices.is_paid = true AND #{filter_conditions} ",
          params[:id], @start_date, @end_date] + filter_values).flatten.map{|s| s.amount.to_f}.sum      
      #@invoices = Invoice.find_all_by_store_id_and_is_paid(params[:id],true)
      @invoices = Invoice.all(:conditions => ["invoices.date BETWEEN ? AND ? AND invoices.store_id = ? AND invoices.is_paid = ?", @start_date, @end_date,params[:id],true])      
      @tax_sum_1 = []
      @tax_sum_2 = []
      @invoices.each do |invoice|        
        @invoice_add_charges = 0
        if invoice.additional_charges.present?
          @invoice_add_charges = invoice.additional_charges.map{|add_c| add_c.amount.to_f}.compact.sum
          @invoice_add_charges = @invoice_add_charges.present? ? @invoice_add_charges : 0 
        end
        @invoice_discounts = 0
        if invoice.discounts.present?
          @invoice_discounts = invoice.discounts.map{|dis_c| dis_c.amount.to_f}.compact.sum
          @invoice_discounts = @invoice_discounts.present? ? @invoice_discounts : 0
        end
        @item_tax = invoice.tax.to_f
        @sold_item_sum = invoice.sold_items.map{|sold_items| sold_items.rate.to_f}.sum
        @sold_item_sum = @sold_item_sum.present? ? @sold_item_sum : 0
        if invoice.tax_mode == 1          
          @tax = ((@sold_item_sum.to_f - @invoice_discounts.to_f + @invoice_add_charges.to_f) *  @item_tax)/100          
          @tax_sum_1 << @tax.to_f
        else          
          @tax = (@sold_item_sum *  @item_tax)/100          
          @tax_sum_2 << @tax.to_f          
        end        
      end      
      @tax_sum_1 = @tax_sum_1.present? ? @tax_sum_1.sum : 0
      @tax_sum_2 = @tax_sum_2.present? ? @tax_sum_2.sum : 0
      @total_tax_sum = @tax_sum_1 + @tax_sum_2      
      @final_grand_total = (@grand_total + @additional_charges) - @discounts + @total_tax_sum      

      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial => "sold_items_report_partial"
        end
      else
        unless @store_items.present?
          flash[:notice] = t('flash_msg5')
          redirect_to :controller => "user", :action => "dashboard"
        end
      end
    else
      render_date_error_partial
    end
  end
  
  def sold_items_report_csv
    if date_format_check
      
      filter_by_account, account_id = account_filter

      ft_joins_1 = "INNER JOIN invoices ON invoices.id = sold_items.invoice_id
                  INNER JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'"
      ft_joins_2 = " INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                  INNER JOIN stores ON stores.id = invoices.store_id"
      ft_joins_3 = " INNER JOIN invoices ON invoices.id = invoice_id
                    INNER JOIN finance_transactions ft ON ft.finance_id = invoice_id AND ft.finance_type = 'Invoice'"

      ft_joins = ft_joins_1 + ft_joins_2


      filter_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "

      if filter_by_account
        filter_conditions += " AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      store_items = StoreItem.paginate( :page => params[:page],:per_page=>10,
        :joins =>  "INNER JOIN sold_items ON sold_items.store_item_id = store_items.id #{ft_joins}",
        :conditions => ["store_items.store_id = ? AND (invoices.date BETWEEN ? AND ?) AND invoices.is_paid= true AND
                         #{filter_conditions}", params[:id], @start_date, @end_date] + filter_values,
        :group => "sold_items.store_item_id",
        :select => "item_name,sold_items.store_item_id as item_id,sum(sold_items.rate) as amount,store_items.store_id as store_id"
      )

      #@additional_charges = Invoice.find_all_by_store_id_and_is_paid(params[:id],true).map{|s| s.additional_charges}.flatten.map{|s| s.amount.to_f}.sum
      @additional_charges = AdditionalCharge.all(:joins => ft_joins_3 + ft_joins_2,
        :conditions => ["invoices.store_id = ? AND (invoices.date BETWEEN ? AND ?) AND invoices.is_paid = true AND #{filter_conditions} ",
          params[:id], @start_date, @end_date] + filter_values).flatten.map{|s| s.amount.to_f}.sum
      #@discounts = Invoice.find_all_by_store_id_and_is_paid(params[:id],true).map{|s| s.discounts}.flatten.map{|s| s.amount.to_f}.sum
      @discounts = Discount.all(:joins => ft_joins_3 + ft_joins_2,
        :conditions => ["invoices.store_id = ? AND (invoices.date BETWEEN ? AND ?) AND invoices.is_paid = true AND #{filter_conditions} ",
          params[:id], @start_date, @end_date] + filter_values).flatten.map{|s| s.amount.to_f}.sum
      #@invoices = Invoice.find_all_by_store_id_and_is_paid(params[:id],true)
      @invoices = Invoice.all(:conditions => ["invoices.date BETWEEN ? AND ? AND invoices.store_id = ? AND invoices.is_paid = ?", @start_date, @end_date,params[:id],true])
      @tax_sum_1 = []
      @tax_sum_2 = []
      @invoices.each do |invoice|        
        @invoice_add_charges = 0
        if invoice.additional_charges.present?
          @invoice_add_charges = invoice.additional_charges.map{|add_c| add_c.amount.to_f}.compact.sum
          @invoice_add_charges = @invoice_add_charges.present? ? @invoice_add_charges : 0 
        end
        @invoice_discounts = 0
        if invoice.discounts.present?
          @invoice_discounts = invoice.discounts.map{|dis_c| dis_c.amount.to_f}.compact.sum
          @invoice_discounts = @invoice_discounts.present? ? @invoice_discounts : 0
        end
        @item_tax = invoice.tax.to_f
        @sold_item_sum = invoice.sold_items.map{|sold_items| sold_items.rate.to_f}.sum
        @sold_item_sum = @sold_item_sum.present? ? @sold_item_sum : 0
        if invoice.tax_mode == 1          
          @tax = ((@sold_item_sum.to_f - @invoice_discounts.to_f + @invoice_add_charges.to_f) *  @item_tax)/100          
          @tax_sum_1 << @tax.to_f          
        else          
          @tax = (@sold_item_sum *  @item_tax)/100          
          @tax_sum_2 << @tax.to_f         
        end        
      end
      @tax_sum_1 = @tax_sum_1.present? ? @tax_sum_1.sum : 0
      @tax_sum_2 = @tax_sum_2.present? ? @tax_sum_2.sum : 0
      @total_tax_sum = @tax_sum_1 + @tax_sum_2 

      csv_string=FasterCSV.generate do |csv|
        csv << [t('inventory_transaction_report'),t('store_items')]
        csv << [t('start_date'),format_date(@start_date)]
        csv << [t('end_date'),format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << [t('item'),t('amount')]
        total=0
        store_items.each do |t|
          row=[]
          row << t.item_name
          row << precision_label(t.amount)
          total+=t.amount.to_f
          csv << row
        end
        @final_grand_total = (total + @additional_charges) - @discounts + @total_tax_sum
        csv << ""
        csv << [t('additional_charges'),precision_label(@additional_charges.to_f)]
        csv << [t('discount'),precision_label(@discounts.to_f)]
        csv << [t('tax'),precision_label(@total_tax_sum.to_f)]
        csv << [t('net_income'),precision_label(@final_grand_total.to_f)]
      end
      filename = "#{t('inventory_transaction_report')}-#{format_date(@start_date)} #{t('to')} #{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end


  def sold_item_transactions
    if validate_date
      
      filter_by_account, account_id = account_filter
      ft_joins = "INNER JOIN sold_items ON sold_items.invoice_id = invoices.id
                  INNER JOIN store_items ON store_items.id = sold_items.store_item_id
                  INNER JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
                  INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                  INNER JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                  LEFT JOIN discounts on discounts.invoice_id = invoices.id
                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      filter_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "
      if filter_by_account
        filter_conditions += " AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end
      
      @target_action = "sold_item_transactions"
      @item = StoreItem.find(params[:id])
      @inventory_transactions = Invoice.paginate(:page => params[:page], :per_page => 10,
        :joins => ft_joins, :conditions => ["invoices.is_paid = ? AND (invoices.date BETWEEN ? AND ?) AND
                                             sold_items.store_item_id = ? AND #{filter_conditions}",
          true, @start_date, @end_date, params[:id]] + filter_values,
        :group => "invoices.id",
        :select => "invoices.invoice_no, SUM(sold_items.rate - discounts.amount) as rate, ft.finance_type, date,
                    CONCAT(IFNULL(tr.receipt_sequence,''), tr.receipt_number) AS receipt_no, invoices.id as invoice_id")
      #      SoldItem.paginate(:page => params[:page],:per_page=>10,:joins=>"INNER JOIN finance_transactions on finance_transactions.finance_id=sold_items.invoice_id",:conditions=>"sold_items.store_item_id=#{params[:id]} and finance_transactions.category_id =#{inventory} and finance_transactions.transaction_date >= '#{@start_date}' and finance_transactions.transaction_date <= '#{@end_date}' and  finance_transactions.finance_type='Invoice'",:select=>"finance_transactions.*")
      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial => "sold_item_transactions_partial"
        end
      end
    else
      render_date_error_partial
    end
  end
  
  def sold_item_transactions_csv
    if date_format_check
      
      filter_by_account, account_id = account_filter
      ft_joins = "INNER JOIN sold_items ON sold_items.invoice_id = invoices.id
                  INNER JOIN store_items ON store_items.id = sold_items.store_item_id
                  INNER JOIN finance_transactions ft ON ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
                  INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                  INNER JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      filter_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "
      if filter_by_account
        filter_conditions += " AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end

      @item = StoreItem.find(params[:id])
      @inventory_transactions = Invoice.all(:joins => ft_joins,
        :conditions => ["invoices.is_paid = ? AND (invoices.date BETWEEN ? AND ?) AND sold_items.store_item_id = ? AND
                         #{filter_conditions}", true, @start_date, @end_date, params[:id]] + filter_values,
        :group => "invoices.id",
        :select => "invoices.invoice_no,sold_items.rate, ft.finance_type,date,
                    CONCAT(IFNULL(tr.receipt_sequence,''), tr.receipt_number) AS receipt_no, invoices.id as invoice_id"
      ) 
      total = 0
      csv_string = FasterCSV.generate do |csv|
        csv << [t('inventory_transaction_report'),t('store_items')]
        csv << [t('start_date'),format_date(@start_date)]
        csv << [t('end_date'),format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << [t('description'),t('date_text'),t('receipt_no'),t('amount')]
        @inventory_transactions.each do |t|
          row=[]
          row << t.finance_type
          row << t.format_date(t.date,:format=>:long_date)
          row << t.receipt_no
          row << precision_label(t.rate)
          total += t.rate.to_f
          csv << row
        end
        csv << ""
        csv << [t('net_income'),"","",precision_label(total)]
      end
      filename = "#{t('inventory_transaction_report')}-#{@start_date} #{t('to')} #{@end_date}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end 
  end
  private

  def generate_invoice_no(store_id)
    prefix = Store.find(store_id).invoice_prefix || "INV"
    last_invoice = Invoice.last(:conditions=> ["store_id = ? and invoice_no LIKE (?)",store_id,"#{prefix}%"])
    unless last_invoice.nil?
      invoice_suffix = last_invoice.invoice_no.scan(/\d+/).first
      invoice_suffix = invoice_suffix.next unless invoice_suffix.nil?
    end
    suffix = invoice_suffix || "001"
    return prefix + suffix
  end
end




