class FeeAccountsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  before_filter :validate_if_enabled, :only => [:manage]

  require 'lib/override_errors'
  helper OverrideErrors

  check_request_fingerprint :create, :update

  # fee accounts dashboard
  # list active fee accounts; create/edit/delete fee accounts
  def index
    ## TO DO :: add pagination
    @fee_accounts = FeeAccount.all(:order => "name")
  end

  # render form for creating new fee account
  def new
    @fee_account = FeeAccount.new
    render_form
  end

  # create a fee account
  def create
    @fee_account = FeeAccount.new(params[:fee_account])
    if @fee_account.save
      flash[:notice] = "#{t('fee_accounts.flash1')}"
      render :update do |page|
        page.redirect_to(fee_accounts_path)
      end
    else
      render_form
    end
  end

  # edit a fee account
  def edit
    @fee_account = FeeAccount.find(params[:id])
    render_form
  end

  # update a fee account
  def update
    @fee_account = FeeAccount.find(params[:id])
    #    @fee_account.has_assignments?
    if @fee_account.update_attributes(params[:fee_account])
      flash[:notice] = "#{t('fee_accounts.flash2')}"
      render :update do |page|
        page.redirect_to(fee_accounts_path)
      end
    else
      render_form
    end
  end

  # delete a fee account
  def destroy
    @fee_account = FeeAccount.find(params[:id])
    #    @tax_slab.has_assignments?
    if @fee_account.destroy
      flash[:notice] = "#{t('fee_accounts.flash3')}"
      #      redirect_to tax_slabs_path      
    else
      flash[:notice] = "#{t('fee_accounts.flash4')}"
      # 
    end
    render :update do |page|
      page.redirect_to(fee_accounts_path)
    end
  end

  # list fee accounts to manage (activate / deactivate)
  # Activate / Deactivate a fee account
  def manage
    if request.post?
      status = FeeAccount.manage(params[:id], params[:op])

      render :update do |page|
        if status == 'error'
          flash[:notice] = t('not_permitted')
          page.redirect_to({:controller => "user", :action => "dashboard"})
        else
          flash[:notice] = status ? t('fee_accounts.flash9_' + params[:op]) : t('fee_accounts.flash8_' + params[:op])
          page.redirect_to(manage_fee_accounts_path)
        end
      end
    else
      @fee_accounts = FeeAccount.all_accounts
    end
  end

  private

  # verifies if manage operation is permitted for fee account
  def validate_if_enabled
    unless FeeAccount.is_deletion_enabled
      flash[:notice] = t('not_permitted')
      if request.get?
        redirect_to :controller => "user", :action => "dashboard"
      else
        render :update do |page|
          page.redirect_to({:controller => "user", :action => "dashboard"})
        end
      end
    end
  end

  def render_form
    respond_to do |format|
      format.js { render :action => :new }
    end
  end
end
