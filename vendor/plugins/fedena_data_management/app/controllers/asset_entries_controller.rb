class AssetEntriesController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  before_filter :find_school_asset,:except=>:school_assets_pdf

  def index
    @asset_field=@school_asset.asset_field_names.keys.first
    @asset_entries=@school_asset.asset_entries
  end

  def assets_pdf
    @asset_field=@school_asset.asset_field_names.keys.first
    @asset_entries=@school_asset.asset_entries
    render :pdf =>  'assets_pdf'#,:show_as_html=>true
  end


  def school_assets_pdf
    @school_assets = SchoolAsset.all
    render :pdf =>  'school_assets_pdf'
  end
  
  def new
    @asset_entry=AssetEntry.new(:school_asset_id=>@school_asset.id)
  end

  def create
    @asset_entry=AssetEntry.new(:school_asset_id=>@school_asset.id)
    if params[:asset_entry].present?
      if @asset_entry.update_dynamic_attributes(params[:asset_entry])
        flash[:notice]="#{t('data_save')}"
        redirect_to school_asset_asset_entries_path(:school_asset_id=>@school_asset.id)
      end
    else
      @asset_entry.errors.add_to_base(:atleast_one_asset_has_to_be_selected)
      render :action=>'new'
    end
  end

  def edit
    @asset_entry=AssetEntry.find(params[:id])
    render :action => 'new'
  end

  def update
   
    @asset_entry=AssetEntry.find(params[:id])
    if params[:asset_entry].present?
      if @asset_entry.update_dynamic_attributes(params[:asset_entry])
        flash[:notice]="#{t('data_edit')}"
        redirect_to school_asset_asset_entries_path(:school_asset_id=>@school_asset.id)
      end
    else
      @asset_entry.errors.add_to_base(:atleast_one_asset_has_to_be_selected)
      render :action=>'new'
    end
  end

  def show
    @asset_entry=AssetEntry.find(params[:id])
    @asset_fields=@school_asset.asset_field_names.keys
  end
  def destroy
    @asset_entry=AssetEntry.find(params[:id])
    @asset_entry.delete
    flash[:notice]="#{t('data_delete')}"
    redirect_to school_asset_asset_entries_path(:school_asset_id=>@school_asset.id)
  end

  def find_school_asset
    @school_asset=SchoolAsset.find(params[:school_asset_id], :include=>[:asset_fields,:asset_entries])
  end
end
