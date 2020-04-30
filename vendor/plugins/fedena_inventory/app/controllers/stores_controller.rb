class StoresController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  # GET /stores
  # GET /stores.xml
  def index
    @store = Store.new
    @stores = Store.active
    @store_categories = StoreCategory.active
    @store_types = StoreType.active

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @stores }
    end
  end

  # GET /stores/new
  # GET /stores/new.xml
  def new
    @store = Store.new
    @store_categories = StoreCategory.active
    @store_types = StoreType.active


    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @store }
    end
  end

  # GET /stores/1/edit
  def edit
    @store = Store.find(params[:id])
    @store_categories = StoreCategory.active
    @store_types = StoreType.active
    @stores = Store.active

    respond_to do |format|
      format.html { render :action => "index"}
    end
  end

  # POST /stores
  # POST /stores.xml
  def create
    @store = Store.new(params[:store])

    respond_to do |format|
      if @store.save
        flash[:notice] = 'Store was successfully created.'
        format.html { redirect_to(stores_path) }
        format.xml  { render :xml => @store, :status => :created, :location => @store }
      else
        @store_categories = StoreCategory.active
        @store_types = StoreType.active
        @stores = Store.active
        format.html { render :action => "index" }
        format.xml  { render :xml => @store.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /stores/1
  # PUT /stores/1.xml
  def update
    @store = Store.find(params[:id])

    respond_to do |format|
      if @store.update_attributes(params[:store])
        flash[:notice] = 'Store was successfully updated.'
        format.html { redirect_to(stores_path) }
        format.xml  { head :ok }
      else
        @store_categories = StoreCategory.active
        @store_types = StoreType.active
        @stores = Store.active
        format.html { render :action => "index" }
        format.xml  { render :xml => @store.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /stores/1
  # DELETE /stores/1.xml
  def destroy
    @store = Store.find(params[:id])
    if @store.can_be_deleted?
      @store.update_attributes(:is_deleted => true)
      flash[:notice] = 'Store was successfully deleted.'
    else
      flash[:warn_notice]="<p>Store is in use and can not be deleted.</p>"
    end
    respond_to do |format|
      format.html { redirect_to(stores_url) }
      format.xml  { head :ok }
    end
  end

  def stores_pdf
    @stores = Store.active
    @data = Store.store_data(params)

    render :pdf => 'stores_pdf',
      :margin => {    :top=> 30,
      :bottom => 10,
      :left=> 30,
      :right => 30}
    
  end
end
