class SuppliersController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  # GET /suppliers
  # GET /suppliers.xml
  def index
    @suppliers = Supplier.active.paginate :page=>params[:page],:per_page => 20  

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @suppliers }
      format.js
    end
  end

  # GET /suppliers/1
  # GET /suppliers/1.xml
  def show
    @supplier = Supplier.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @supplier }
    end
  end

  # GET /suppliers/new
  # GET /suppliers/new.xml
  def new
    @supplier = Supplier.new
    @supplier_types = SupplierType.active

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @supplier }
    end
  end

  # GET /suppliers/1/edit
  def edit
    @supplier = Supplier.find(params[:id])
    @supplier_types = SupplierType.active
  end

  # POST /suppliers
  # POST /suppliers.xml
  def create
    @supplier = Supplier.new(params[:supplier])

    respond_to do |format|
      if @supplier.save
        flash[:notice] = 'Supplier was successfully created.'
        format.html { redirect_to(@supplier) }
        format.xml  { render :xml => @supplier, :status => :created, :location => @supplier }
        format.js
      else
        @supplier_types = SupplierType.active
        format.html { render :action => "new" }
        format.xml  { render :xml => @supplier.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /suppliers/1
  # PUT /suppliers/1.xml
  def update
    @supplier = Supplier.find(params[:id])

    respond_to do |format|
      if @supplier.update_attributes(params[:supplier])
        flash[:notice] = 'Supplier was successfully updated.'
        format.html { redirect_to(@supplier) }
        format.xml  { head :ok }
      else
        @supplier_types = SupplierType.active
        format.html { render :action => "edit" }
        format.xml  { render :xml => @supplier.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /suppliers/1
  # DELETE /suppliers/1.xml
  def destroy
    @supplier = Supplier.find(params[:id])
    if @supplier.can_be_deleted?
      @supplier.update_attributes(:is_deleted => true)
      flash[:notice] = 'Supplier was successfully deleted.'
    else
      flash[:warn_notice]="<p>Supplier is in use and can not be deleted</p>"
    end
    respond_to do |format|
      format.html { redirect_to(suppliers_url) }
      format.xml  { head :ok }
    end
  end

  def suppliers_pdf
    @suppliers = Supplier.active
        render :pdf => 'supplier_pdf'
  end
end
