class PurchaseOrdersController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision


  def index
    @purchase_orders = PurchaseOrder.active.paginate :page=>params[:page],:include=>[:store], :conditions => ["(purchase_orders.po_no LIKE ? OR stores.name LIKE ?) AND (purchase_orders.po_status LIKE ?)","#{params[:po_no_or_store_like]}%","#{params[:po_no_or_store_like]}%","#{params[:po_status_like]}%"],:per_page => 20
  end

  def show
    @purchase_order = PurchaseOrder.active.find(params[:id])
    @total =0
    @purchase_order.purchase_items.each do |i|
      @total  +=  i.total_amount
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @purchase_order }
    end
  end

  def raised_grns
    @purchase_order = PurchaseOrder.active.find(params[:id])
    @grns = @purchase_order.grns.active.paginate :page => params[:page],:per_page => 20
    
    render :template => "grns/index"
  end

  def new
    @purchase_order = PurchaseOrder.new
    @last_purchase_order = PurchaseOrder.last.po_no unless PurchaseOrder.last.nil?
    @supplier = Array.new
    @stores = Store.active
    @supplier_types = SupplierType.active
    @suppliers = Array.new
    @indents = Indent.active
    @purchase_item = @purchase_order.purchase_items.build
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @purchase_order }
    end
  end


  def edit
    @purchase_order = PurchaseOrder.find(params[:id])
    @stores = Store.active
    @supplier_types = SupplierType.active
    @suppliers = Supplier.active
    @indents = Indent.active
  end

  def create
    @purchase_order = PurchaseOrder.new(params[:purchase_order])
    respond_to do |format|
      if @purchase_order.save
        flash[:notice] = 'Purchase Order was successfully created.'
        format.html { redirect_to(@purchase_order) }
        format.xml  { render :xml => @purchase_order, :status => :created, :location => @purchase_order }
      else
        @supplier = Array.new
        @stores = Store.active
        @supplier_types = SupplierType.active
        @suppliers = Array.new
        @indents = Indent.active
        @purchase_items = @purchase_order.purchase_items.select{|pi| pi._destroy == false}
        format.html { render :action => "new" }
        format.xml  { render :xml => @purchase_order.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @purchase_order = PurchaseOrder.find(params[:id])
    @supplier = []
    respond_to do |format|
      if @purchase_order.update_attributes(params[:purchase_order])
        flash[:notice] = 'Purchase Order was successfully updated.'
        format.html { redirect_to(@purchase_order) }
        format.xml  { head :ok }
      else
        @stores = Store.active
        @supplier_types = SupplierType.active
        @suppliers = Supplier.active
        @indents = Indent.active
        format.html { render :action => "edit" }
        format.xml  { render :xml => @purchase_order.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_item
    @i =  params[:i]
    @store_item = StoreItem.find_by_id params[:item_id]
    @price = @store_item ? @store_item.unit_price : 0
    @tax = @store_item ? @store_item.tax : 0
  end

  def destroy
    @purchase_order = PurchaseOrder.find(params[:id])
    if @purchase_order.can_be_deleted?
      @purchase_order.purchase_items.map{|ii| ii.update_attributes(:is_deleted => true)}
      @purchase_order.update_attributes(:is_deleted => true)
      flash[:notice] = 'Purchase Order was successfully deleted.'
    else
      flash[:warn_notice]="<p>Purchase Order is in use and can not be deleted</p>"
    end
    respond_to do |format|
      format.html { redirect_to(purchase_orders_url) }
      format.xml  { head :ok }
    end
  end


  def po_pdf
    @purchase_order = PurchaseOrder.find(params[:id])
    @total =0
    @purchase_order.purchase_items.each do |i|
      @total  += i.total_amount
    end
    render :pdf=>'purchase_order_pdf'
  end


  def update_supplier
    render(:update) do |page|
      if params[:supplier_type_id].present?
        @suppliers = Supplier.find(:all,:conditions=>"supplier_type_id=#{params[:supplier_type_id]}" )
      else
        @suppliers = Array.new
      end
      page.replace_html 'update_supplier', :partial=>'update_supplier'
    end
  end

  def update_storeitem
    @store =  Store.find params[:item_id]
    @store_items = @store.store_items.active
  end

  def update_store
    @indent = Indent.active.find(params[:indent_id])
    @stores = @indent.store.to_a
  end

  def acceptance
    @supplier = []
    @purchase_order = PurchaseOrder.find(params[:id])
    @stores = Store.active
    @store_items_load = @purchase_order.store.store_items.active
    @store_items = StoreItem.active
    if request.post?
      if @purchase_order.update_attributes(params[:purchase_order])
        flash[:notice] = 'Purchase Order was successfully updated .'
        redirect_to purchase_orders_path
      else
        render :acceptance
      end
    end
  end
end




