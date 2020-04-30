class StoreCategoriesController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  # GET /store_categories
  # GET /store_categories.xml
  def index
    @store_category = StoreCategory.new
    @store_categories = StoreCategory.active

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @store_categories }
    end
  end


  # GET /store_categories/new
  # GET /store_categories/new.xml
  def new
    @store_category = StoreCategory.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @store_category }
    end
  end

  # GET /store_categories/1/edit
  def edit
    @store_category = StoreCategory.find(params[:id])
    @store_categories = StoreCategory.active
    respond_to do |format|
      format.html { render :action => "index"}
    end
  end

  # POST /store_categories
  # POST /store_categories.xml
  def create
    @store_category = StoreCategory.new(params[:store_category])

    respond_to do |format|
      if @store_category.save
        flash[:notice] = 'Store Category was successfully created.'
        format.html { redirect_to(store_categories_path) }
        format.xml  { render :xml => @store_category, :status => :created, :location => @store_category }
      else
        @store_categories = StoreCategory.active
        format.html { render :action => "index" }
        format.xml  { render :xml => @store_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /store_categories/1
  # PUT /store_categories/1.xml
  def update
    @store_category = StoreCategory.find(params[:id])

    respond_to do |format|
      if @store_category.update_attributes(params[:store_category])
        flash[:notice] = 'Store Category was successfully updated.'
        format.html { redirect_to(store_categories_path) }
        format.xml  { head :ok }
      else
        @store_categories = StoreCategory.active
        
        format.html { render :action => "index" }
        format.xml  { render :xml => @store_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /store_categories/1
  # DELETE /store_categories/1.xml
  def destroy
    @store_category = StoreCategory.find(params[:id])
    if @store_category.can_be_deleted?
      @store_category.update_attributes(:is_deleted => true)
      flash[:notice] = 'Store Category was successfully deleted.'
    else
      flash[:warn_notice]="<p>Store Category is in use and cannot be deleted</p>"
    end
    respond_to do |format|
      format.html { redirect_to(store_categories_url) }
      format.xml  { head :ok }
    end
  end
end


