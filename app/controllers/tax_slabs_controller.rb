class TaxSlabsController < ApplicationController
  
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  before_filter :load_tax_setting
  
  
  check_request_fingerprint :create, :update
  
  def index
    @tax_slabs = TaxSlab.all(:include => [:tax_assignments, :collectible_tax_slabs])
  end
  
  def new
    @tax_slab = TaxSlab.new
    render_form
  end
  
  def create
    @tax_slab = TaxSlab.new(params[:tax_slab])
    if @tax_slab.save
      flash[:notice] = "#{t('tax_slabs.flash1')}"
      render :update do |page|
        page.redirect_to(tax_slabs_path)
      end
    else
      render_form
    end
  end
  
  def edit
    @tax_slab = TaxSlab.find(params[:id], :include => [:tax_assignments, :collectible_tax_slabs])
    @tax_slab.has_assignments?
    render_form    
  end
  
  def update
    @tax_slab = TaxSlab.find(params[:id])
    @tax_slab.has_assignments?
    if @tax_slab.update_attributes(params[:tax_slab])
      flash[:notice] = "#{t('tax_slabs.flash2')}"
      render :update do |page|
        page.redirect_to(tax_slabs_path)
      end
    else
      render_form
    end
  end
  
  def destroy
    @tax_slab = TaxSlab.find(params[:id])
    @tax_slab.has_assignments?
    if @tax_slab.destroy
      flash[:notice] = "#{t('tax_slabs.flash3')}"
#      redirect_to tax_slabs_path      
    else
      flash[:notice] = "#{t('tax_slabs.flash4')}"
      # 
    end
    render :js=>"window.location='#{tax_slabs_path}'"
  end
  
  private
  
  def render_form
    respond_to do |format|
      format.js { render :action => :new }
    end
  end
  
  def load_tax_setting
    @tax_enabled = Configuration.get_config_value('EnableFinanceTax').to_i
    unless @tax_enabled
      flash[:notice] = "#{t('not_permitted')}"
      redirect_to :controller => "user", :action => "dashboard"  and return      
    end
  end
end
