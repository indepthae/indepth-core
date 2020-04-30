class ItemCategoriesController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    @item_category = ItemCategory.new
    @item_categories = ItemCategory.paginate(:page => params[:page],:per_page => 10,:conditions => {:is_deleted => false})
  end

  def create
    @item_category = ItemCategory.new(params[:item_category])
    respond_to do |format|
      if @item_category.save
        flash[:notice] = "#{t('item_category_created')}"
        format.html { redirect_to(item_categories_path) }
        format.xml  { render :xml => @item_category, :status => :created, :location => @item_category }
      else
        @item_categories = ItemCategory.paginate(:page => params[:page],:per_page => 10 ,:conditions => {:is_deleted => false})
        format.html { render :action => "index" }
        format.xml  { render :xml => @item_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @item_category = ItemCategory.find(params[:id])
    @item_categories = ItemCategory.paginate(:all, :page => params[:page],:per_page => 10 ,:conditions => {:is_deleted => false})
  end

  def update
    @item_category = ItemCategory.find(params[:id])
    respond_to do |format|
      if @item_category.update_attributes(params[:item_category])
        flash[:notice] = "#{t('item_category_updated')}"
        format.html { redirect_to(item_categories_path) }
        format.xml  { head :ok }
      else
        @item_categories = ItemCategory.paginate(:all, :page => params[:page],:per_page => 10 ,:conditions => {:is_deleted => false})
        format.html { render :action => "index" }
        format.xml  { render :xml => @item_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @item_category = ItemCategory.find(params[:id])
    if @item_category.can_be_deleted?
      @item_category.update_attribute(:is_deleted,true)
      flash[:notice] = "#{t('item_category_deleted')}"
    else
      flash[:warn_notice]="<p> #{t('cannot_delete_category')} </p>"
    end
    respond_to do |format|
      format.html { redirect_to(item_categories_url) }
      format.xml  { head :ok }
    end
  end
  
  def show
    @item_category = ItemCategory.find(params[:id])
    @item_categories = ItemCategory.paginate(:all, :page => params[:page],:per_page => 10 ,:conditions => {:is_deleted => false})
  end
end