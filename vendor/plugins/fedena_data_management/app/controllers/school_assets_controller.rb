class SchoolAssetsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    @school_assets = SchoolAsset.all
  end

  def new
    @school_assets=SchoolAsset.all
    @school_asset=SchoolAsset.new
    @asset_field=@school_asset.asset_fields.build
    #    @asset_field.asset_field_options.build
  end

  def create
    @school_asset=SchoolAsset.new(params[:school_asset])
    #    @asset_field=@school_asset.asset_fields.build
    if params[:add_asset_field]
      @school_asset.asset_fields.build
    elsif params[:remove_asset_field]
    else
      if @school_asset.save
        flash[:notice]="#{t('category_save')}"
        redirect_to school_assets_path and return
      end
    end
    render :action => 'new'
  end

  def show
    redirect_to school_assets_path
  end

  def edit
    @school_assets=SchoolAsset.all
    @school_asset=SchoolAsset.find params[:id]
    render :action => 'new'
  end

  def update
    @school_assets=SchoolAsset.all
    @school_asset=SchoolAsset.find params[:id]
    if params[:add_asset_field]
      @school_asset.update_attributes(params[:school_asset])
      @school_asset.asset_fields.build
    elsif params[:remove_asset_field]
      @school_asset.update_attributes(params[:school_asset])
    else
      if @school_asset.update_attributes(params[:school_asset])
        flash[:notice]="#{t('category_edit')}"
        redirect_to @school_asset and return
      end
    end
    @asset_fields=@school_asset.asset_fields.each{|dc| dc[:_destroy] = ""}
    render :action => 'new'
  end
  def destroy
    @school_asset=SchoolAsset.find params[:id]
    @school_asset.destroy
    flash[:notice]="#{t('category_delete')}"
    redirect_to :controller => :school_assets
  end

end
