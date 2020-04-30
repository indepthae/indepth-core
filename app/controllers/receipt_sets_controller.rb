class ReceiptSetsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  require 'lib/override_errors'
  helper OverrideErrors
  
  #  before_filter :load_tax_setting    
  check_request_fingerprint :create, :update
  
  def index
    ## TO DO :: add pagination
    @receipt_sets = ReceiptNumberSet.all(
      :include => [:transaction_receipts, :finance_category_receipt_sets],
      :order => "name")
  end
  
  def new
    @receipt_set = ReceiptNumberSet.new
    render_form
  end
  
  def create
    @receipt_set = ReceiptNumberSet.new(params[:receipt_number_set])
    if @receipt_set.save
      flash[:notice] = "#{t('receipt_sets.flash1')}"
      #      render :update do |page|
      #        page.redirect_to(receipt_sets_path)
      #      end
      page_redirect receipt_sets_path
    else
      render_form
    end
  end
  
  def edit
    @receipt_set = ReceiptNumberSet.find(params[:id])
    render_form
  end
  
  def update
    @receipt_set = ReceiptNumberSet.find(params[:id])
    unless @receipt_set.has_assignments?
      if @receipt_set.update_attributes(params[:receipt_number_set])
        flash[:notice] = "#{t('receipt_sets.flash2')}"
        page_redirect receipt_sets_path
      else
        render_form
      end
    else
      flash[:notice] = "#{t('receipt_sets.flash8')}"
      page_redirect receipt_sets_path
    end
  end
  
  def destroy
    @receipt_set = ReceiptNumberSet.find(params[:id])
    #    @tax_slab.has_assignments?
    if @receipt_set.destroy
      flash[:notice] = "#{t('receipt_sets.flash3')}"
      #      redirect_to tax_slabs_path      
    else
      flash[:notice] = "#{t('receipt_sets.flash4')}"
      # 
    end
    page_redirect receipt_sets_path
    #    render :update do |page|
    #      page.redirect_to(receipt_sets_path)
    #    end
    #    render :js=>"window.location='#{tax_slabs_path}'"
  end
  
  private
  
  def page_redirect redirect_path
    render :update do |page|
      page.redirect_to(redirect_path)
    end
  end
  
  def render_form
    respond_to do |format|
      format.js { render :action => :new }
    end
  end
  
end
