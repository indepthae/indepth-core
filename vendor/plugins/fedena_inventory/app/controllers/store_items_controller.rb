class StoreItemsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :set_precision
  
  def index
    @stores = Store.active
    if request .xhr?
      if params[:search_store] == 'All'
        @store_items = StoreItem.active.paginate(:all, :page => params[:page],:per_page=>30,:include=>[:item_category],:order=>'item_categories.name,item_name',
          :conditions => ["item_name LIKE ?", "#{params[:query]}%"])
      else
        #@store_items = StoreItem.active.paginate(:all, :page => params[:page], :per_page=>30,:include=>:store,
         # :conditions => ["store_id = ? and item_name LIKE ? ", params[:search_store],"#{params[:query]}%" ] )
        @store_items = StoreItem.active.paginate(:all, :page => params[:page], :per_page=>30,:include=>[:store,:item_category],:order=>'item_categories.name,item_name',
          :conditions => ["store_id = ? and item_name LIKE ? ", params[:search_store],"#{params[:query]}%" ] )
      end
      render(:update) do |page|
        page.replace_html'error_and_items',:partial=>'search_ajax'
      end
    end
  end

  def new
    @store_item = StoreItem.new
    @stores = Store.active
    @item_categories = ItemCategory.find(:all, :conditions => {:is_deleted => false})

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @store_item }
    end
  end

  def edit
    @store_item = StoreItem.find(params[:id])
    @stores = Store.active
    @item_categories = ItemCategory.find(:all, :conditions => {:is_deleted => false})
  end

  def create
    @store_item = StoreItem.new(params[:store_item])
    @item_categories = ItemCategory.find(:all, :conditions => {:is_deleted => false})

    respond_to do |format|
      if @store_item.save
        flash[:notice] = 'Store Item was successfully created.'
        format.html { redirect_to(store_items_path) }
        format.xml  { render :xml => @store_item, :status => :created, :location => @store_item }
      else
        @stores = Store.active
        format.html { render :action => "new" }
        format.xml  { render :xml => @store_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @store_item = StoreItem.find(params[:id])
    @item_categories = ItemCategory.find(:all, :conditions => {:is_deleted => false})
    respond_to do |format|
      if @store_item.update_attributes(params[:store_item])
        flash[:notice] = 'Store Item was successfully updated.'
        format.html { redirect_to(store_items_path) }
        format.xml  { head :ok }
      else
        @stores = Store.active
        format.html { render :action => "edit" }
        format.xml  { render :xml => @store_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @store_item = StoreItem.find(params[:id])
    if @store_item.can_be_deleted?
      @store_item.update_attributes(:is_deleted => true)
      flash[:notice] = 'Store Item was successfully deleted.'
    else
      flash[:warn_notice]="<p>Store Item is in use and can not be deleted.</p>"
    end
    respond_to do |format|
      format.html { redirect_to(store_items_url) }
      format.xml  { head :ok }
    end
  end

  #  def search_ajax
  #    #    if params[:search_store] == 'All'
  #    #      @store_items = StoreItem.active.paginate(:all, :page => params[:page],
  #    #        :conditions => ["item_name LIKE ? ", "#{params[:query]}%" ])
  #    #    else
  #    #      @store_items = StoreItem.active.paginate(:all, :page => params[:page], :include=>:store,
  #    #        :conditions => ["stores.name LIKE ? and item_name LIKE ?  ", "#{params[:search_store]}%","#{params[:query]}%" ] )
  #    #    end
  #    #    render :partial => 'search_ajax'
  #  end

  def store_items_pdf 
    
    @stores = Store.active
    if params[:search_store] == 'All'
      @store_items = StoreItem.find(:all,:conditions => ["is_deleted=false and  item_name LIKE ? ", "#{params[:query]}%" ])
    else
      @store_items = StoreItem.find(:all,:include=>:store,:conditions => ["store_items.is_deleted=false and store_id LIKE ? and item_name LIKE ?  ",params[:search_store], "#{params[:query]}%" ] )
    end
     
    render :pdf => 'store_items_pdf',
      :margin => {    :top=> 30,
      :bottom => 10,
      :left=> 30,
      :right => 30}

  end
  
end

