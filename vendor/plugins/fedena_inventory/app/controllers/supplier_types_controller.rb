class SupplierTypesController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  # GET /supplier_types
  # GET /supplier_types.xml
  def index
    @supplier_type = SupplierType.new
    @supplier_types = SupplierType.active

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @supplier_types }
    end
  end
  
  # GET /supplier_types/new
  # GET /supplier_types/new.xml
  def new
    @supplier_type = SupplierType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @supplier_type }
    end
  end

  # GET /supplier_types/1/edit
  def edit
    @supplier_type = SupplierType.find(params[:id])
  end

  # POST /supplier_types
  # POST /supplier_types.xml
  def create
    @supplier_type = SupplierType.new(params[:supplier_type])

    respond_to do |format|
      if @supplier_type.save
        flash[:notice] = 'Supplier Type was successfully created.'
        format.html { redirect_to(supplier_types_path) }
        format.xml  { render :xml => @supplier_type, :status => :created, :location => @supplier_type }
      else
        @supplier_types = SupplierType.active
        format.html { render :action => "index" }
        format.xml  { render :xml => @supplier_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /supplier_types/1
  # PUT /supplier_types/1.xml
  def update
    @supplier_type = SupplierType.find(params[:id])

    respond_to do |format|
      if @supplier_type.update_attributes(params[:supplier_type])
        flash[:notice] = 'Supplier Type was successfully updated.'
        format.html { redirect_to(supplier_types_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @supplier_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /supplier_types/1
  # DELETE /supplier_types/1.xml
  def destroy
    @supplier_type = SupplierType.find(params[:id])
    if @supplier_type.can_be_deleted?
      @supplier_type.update_attributes(:is_deleted => true)
      flash[:notice] = 'Supplier Type was successfully deleted.'
    else
      flash[:warn_notice]="<p>Supplier Type is in use and cannnot be deleted.</p>"
    end
    respond_to do |format|
      format.html { redirect_to(supplier_types_url) }
      format.xml  { head :ok }
    end
  end
end
