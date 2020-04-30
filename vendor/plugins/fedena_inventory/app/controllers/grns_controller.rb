class GrnsController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision
  
  def index
    @grns = Grn.active.paginate :page => params[:page],:per_page => 20

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grns }
    end
  end

  def show
    @grn = Grn.active.find(params[:id])
    @user = @grn.purchase_order.indent.user unless @grn.purchase_order.indent.nil?
    @total =0
    @grn.grn_items.each do |i|
      @total  += ( i.total_amount)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @grn }
    end
  end

  def new
    @supplier=[]
    @grn = Grn.new
    @purchase_orders = PurchaseOrder.active.select{|po| po.po_status == "Issued"}
    @last_grn = Grn.last.grn_no unless Grn.last.nil?
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @grn }
    end
  end
  
  def create
    @grn = Grn.new(params[:grn])
    @supplier=[]
    respond_to do |format|
      if @grn.save
        flash[:notice] = "GRN successfully created "
        format.html { redirect_to(@grn) }
        format.xml  { render :xml => @grn, :status => :created, :location => @grn }
      else
        @purchase_orders = PurchaseOrder.active.select{|po| po.po_status == "Issued"}
        @last_grn = Grn.last.grn_no unless Grn.last.nil?
        format.html { render :action => "new" }
        format.xml  { render :xml => @grn.errors, :status => :unprocessable_entity }
      end
    end

  end

  def grn_pdf
    @grn = Grn.find(params[:id])
    @user = @grn.purchase_order.indent.user unless @grn.purchase_order.indent.nil?
    @total =0
    @grn.grn_items.each do |i|
      @total  += ( i.total_amount)
    end
    render :pdf=>'grn_pdf'
  end

  def update_po
    unless params[:po_id].to_i==0
      @po  = PurchaseOrder.active.find_by_id(params[:po_id])
      @grn = Grn.new
      @store_items = @po.store.store_items.active
      @po.purchase_items.each do |po|
        @grn.grn_items.build(:store_item_id => po.store_item_id,:quantity => po.quantity, :unit_price => po.price,:tax => po.tax, :discount => po.discount)
      end

      render :update do |page|
        page.replace_html 'update_po_item',:partial => 'grn_item_fields',:locals => {:f =>  ActionView::Helpers::FormBuilder.new(:grn,@grn,@template,{},{})}
      end
    else
      render :update do |page|
        page.replace_html 'update_po_item',:text=> ""
      end
    end
  end

  def report
    if validate_date
      
      filter_by_account, account_id = account_filter false
      
      if filter_by_account
        filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id"
      else        
        filter_conditions = joins = ""
        filter_values = []
      end
      
      @target_action = "report"
      @stores = Store.find(:all,
        :joins => "INNER JOIN purchase_orders po ON po.store_id=stores.id 
                        INNER JOIN grns ON grns.purchase_order_id=po.id 
                        INNER JOIN finance_transactions ft ON ft.id=grns.finance_transaction_id #{joins}",
        :conditions => ["(ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          @start_date, @end_date] + filter_values,
        :group => "stores.id", :select => "SUM(ft.amount) AS amount, stores.name AS store_name,
                          stores.id AS store_id")
      
      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial => "report"
        end
      end
    else
      render_date_error_partial
    end
  end
  
  def store_report_csv
    if date_format_check
      
      filter_by_account, account_id = account_filter false
      
      if filter_by_account
        filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id"
      else        
        filter_conditions = joins = ""
        filter_values = []
      end
      
      stores = Store.all(
        :joins => "INNER JOIN purchase_orders po ON po.store_id=stores.id 
                        INNER JOIN grns ON grns.purchase_order_id=po.id 
                        INNER JOIN finance_transactions ft ON ft.id=grns.finance_transaction_id #{joins}",
        :conditions => ["(ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          @start_date, @end_date] + filter_values, :group => "stores.id",
        :select => "sum(ft.amount) as amount,stores.name as store_name,stores.id as store_id")
      
      csv_string = FasterCSV.generate do |csv|
        csv << t('inventory_transaction_report')
        csv << [t('start_date'),format_date(@start_date)]
        csv << [t('end_date'),format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << [t('store'),t('amount')]
        total = 0
        stores.each do |t|
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
  
  def list_grn
    if validate_date
      
      filter_by_account, account_id = account_filter false
      
      if filter_by_account
        filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id"
      else        
        filter_conditions = joins = ""
        filter_values = []
      end
      
      @target_action = "list_grn"
      @store = Store.find(params[:id])
      @grand_total = Grn.find(:first, :select => "SUM(ft.amount) AS amount",
        :joins => "INNER JOIN finance_transactions ft on ft.id=grns.finance_transaction_id 
                        INNER JOIN purchase_orders po on po.id=grns.purchase_order_id #{joins}",
        :conditions => ["po.store_id = ? AND (ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}", 
          @start_date, @end_date, params[:id]] + filter_values).amount
      
      @grns = Grn.find(:all,
        :joins => "INNER JOIN finance_transactions ft on ft.id = grns.finance_transaction_id 
                        INNER JOIN purchase_orders po on po.id = grns.purchase_order_id #{joins}",
        :conditions => ["po.store_id = ? AND (ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          params[:id], @start_date, @end_date] + filter_values, :group => "grns.id", 
        :select => "SUM(ft.amount) AS amount, grns.*, po.store_id AS store_id")
      
      if request.xhr?
        render(:update) do|page|
          page.replace_html "fee_report_div", :partial=>"list_grn_partial"
        end
      end
    else
      render_date_error_partial
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
  
  def list_grn_csv
    if date_format_check
      
      filter_by_account, account_id = account_filter false
      
      if filter_by_account
        filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id"
      else        
        filter_conditions = joins = ""
        filter_values = []
      end
      
      @store = Store.find(params[:id])
      grns = Grn.all(
        :joins => "INNER JOIN finance_transactions ft on ft.id=grns.finance_transaction_id 
                        INNER JOIN purchase_orders po on po.id=grns.purchase_order_id",
        :conditions => ["po.store_id = ? AND (ft.transaction_date BETWEEN ? AND ?) #{filter_conditions}", 
          params[:id], @start_date, @end_date] + filter_values,
        :group => "grns.id",
        :select => "SUM(ft.amount) AS amount, grns.*, po.store_id AS store_id")
      
      csv_string = FasterCSV.generate do |csv|
        csv << t('inventory_transaction_report')
        csv << ["store",@store.name]
        csv << [t('start_date'), format_date(@start_date)]
        csv << [t('end_date'), format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << [t('grn_no'), t('invoice_no'), t('date_text'), t('amount')]
        total = 0
        grns.each do |t|
          row = []
          row << t.grn_no
          row << t.invoice_no
          row << format_date(t.grn_date, :format => :long_date)
          row << precision_label(t.amount)
          total += t.amount.to_f
          csv << row
        end
        csv << ""
        csv << [t('net_income'), precision_label(total)]
      end
      filename = "#{t('inventory_transaction_report')}-#{@store.name}  #{format_date(@start_date)}  #{t('to')}  #{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end

  end


  def report_detail
    if validate_date
      
      filter_by_account, account_id = account_filter false
      
      if filter_by_account
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        joins = :finance_transaction_receipt_record
      else        
        filter_conditions = joins = ""
        filter_values = []
      end
      
      @grn_report = Grn.find(params[:id])
      @store = Store.find(params[:store_id],:select=>"id as store_id")
      inventory = FinanceTransactionCategory.find_by_name('Inventory').id
      @inventory_transactions = FinanceTransaction.find(:all, :joins => joins,
        :conditions => ["(transaction_date BETWEEN ? AND ?) AND category_id = ? #{filter_conditions}", 
          @start_date, @end_date, inventory] + filter_values)
      @user = @grn_report.purchase_order.indent.user unless @grn_report.purchase_order.indent.nil?
      @total = 0
      @grn_report.grn_items.each do |i|
        @total  += i.total_amount
      end
    else
      render_date_error_partial
    end
  end

  #  def destroy
  #    @grn = Grn.active.find(params[:id])
  #    if @grn.can_be_deleted?
  #      if @grn.update_attributes(:is_deleted => true)
  #        flash[:notice] = 'GRN was successfully deleted.'
  #      else
  #        flash[:warn_notice]="<p>GRN is in use and can not be deleted</p>"
  #      end
  #    else
  #      flash[:warn_notice]="<p>GRN is in use and can not be deleted</p>"
  #    end
  #    respond_to do |format|
  #      format.html { redirect_to(grns_url) }
  #      format.xml  { head :ok }
  #    end
  #  end
end

