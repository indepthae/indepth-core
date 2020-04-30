class TallyExportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  in_place_edit_with_validation_for :tally_company, :company_name
  in_place_edit_with_validation_for :tally_account, :account_name
  in_place_edit_with_validation_for :tally_voucher_type, :voucher_name

  def index
    
  end

  def settings

  end

  def general_settings
    @config = TallyExportConfiguration.get_multiple_configs_as_hash ['TallyUrl', 'EnableLiveSync', 'LiveSyncStartDate']
    if request.post?
      configs = params[:tally_export_configuration]
      if configs[:enable_live_sync] == '1'
        configs[:live_sync_start_date] = I18n.l(Date.today, :format=>:default) if @config[:live_sync_start_date].blank?
      end
      TallyExportConfiguration.set_config_values(configs)
      @config = TallyExportConfiguration.get_multiple_configs_as_hash ['TallyUrl', 'EnableLiveSync', 'LiveSyncStartDate']
      flash[:notice] = "#{t('flash_msg8')}"
      flash.discard
      return
      flash[:notice] = "#{t('flash_msg8')}"
      flash.discard
      redirect_to :action => "general_settings"  and return
    end
  end

  def companies
    @companies = TallyCompany.all
    if request.post?
      @company=TallyCompany.new(params[:company])
      if @company.save
        flash[:notice] = "#{t('company_created_successfully')}"
        redirect_to :back
      end
    else
      @company=TallyCompany.new
    end
  end

  def delete_company
    company = TallyCompany.find_by_id params[:id]
    unless company.tally_ledgers.present?
      if company.destroy
        flash[:notice] = "#{t('company_deleted_successfully')}"
      end
    else
      flash[:notice] = "#{t('company_cannot_be_deleted')}"
    end
    redirect_to :action => 'companies'
  end

  def voucher_types
    @vouchers = TallyVoucherType.all
    if request.post?
      @voucher=TallyVoucherType.new(params[:voucher])
      if @voucher.save
        flash[:notice] = "#{t('voucher_type_created_successfully')}"
        redirect_to :back
      end
    else
      @voucher=TallyVoucherType.new
    end
  end

  def delete_voucher
    voucher = TallyVoucherType.find_by_id params[:id]
    unless voucher.tally_ledgers.present?
      if voucher.destroy
        flash[:notice] = "#{t('voucher_type_deleted_successfully')}"
      end
    else
      flash[:notice] = "#{t('voucher_type_cannot_be_deleted')}"
    end
    redirect_to :action => 'voucher_types'
  end

  def accounts
    @accounts = TallyAccount.all
    if request.post?
      @account = TallyAccount.new(params[:account])
      if @account.save
        flash[:notice] = "#{t('account_created_successfully')}"
        redirect_to :back
      end
    else
      @account = TallyAccount.new
    end
  end

  def delete_account
    account = TallyAccount.find_by_id params[:id]
    unless account.tally_ledgers.present?
      if account.destroy
        flash[:notice] = "#{t('account_deleted_successfully')}"
      end
    else
      flash[:notice] = "#{t('account_cannot_be_deleted')}"
    end
    redirect_to :action => 'accounts'
  end

  def create_ledger
    @tally_ledger = TallyLedger.new
    @companies = TallyCompany.all
    @vouchers = TallyVoucherType.all
    @accounts = TallyAccount.all
    @transaction_categories = FinanceTransactionCategory.all(:conditions => "tally_ledger_id IS NULL AND deleted = 0")
    if request.post?
      category_ids = params[:tally_ledger][:finance_transaction_category_ids]
      categories = FinanceTransactionCategory.all(:conditions => "id IN (#{category_ids.join(',')}) AND tally_ledger_id IS NULL AND deleted = 0") unless category_ids.blank?
      params[:tally_ledger].delete('finance_transaction_category_ids')
      @tally_ledger = TallyLedger.new(params[:tally_ledger])
      unless categories.nil?
        if @tally_ledger.save
          categories.each do |cat|
            cat.update_attributes(:tally_ledger_id => @tally_ledger.id)
          end
          @transaction_categories = FinanceTransactionCategory.all(:conditions => "tally_ledger_id IS NULL AND deleted = 0")
          flash[:notice] = "#{t('ledger_created_successfully')}"
          redirect_to :action=>:create_ledger
        end
      else
        @tally_ledger.errors.add(:category, "#{t('must_be_selected')}.")
        render :action=>:create_ledger
      end
    end
  end

  def edit_ledger
    @tally_ledger = TallyLedger.find_by_id(params[:id], :include=>[ :finance_transaction_categories ])
    @companies = TallyCompany.all
    @vouchers = TallyVoucherType.all
    @accounts = TallyAccount.all
    @transaction_categories = FinanceTransactionCategory.all(:conditions => "(tally_ledger_id = #{@tally_ledger.id} OR tally_ledger_id IS NULL) AND deleted = 0")
    if request.post?
      category_ids = params[:tally_ledger][:finance_transaction_category_ids]
      categories = FinanceTransactionCategory.all(:conditions => "id IN (#{category_ids.join(',')}) AND deleted = 0") unless category_ids.blank?
      params[:tally_ledger].delete('finance_transaction_category_ids')
      unless categories.nil?
        if @tally_ledger.update_attributes(params[:tally_ledger])
          @transaction_categories.each do |trans_cat|
            if categories.include?(trans_cat)
              trans_cat.update_attributes(:tally_ledger_id => @tally_ledger.id)
            else
              trans_cat.update_attributes(:tally_ledger_id => nil)
            end
          end
          flash[:notice] = "#{t('ledger_updated_successfully')}"
          
        else
          render :edit_ledger
        end
      else
        @tally_ledger.errors.add(:category, "#{t('must_be_selected')}.")
        render :edit_ledger
      end
      flash.discard
    end
  end

  def view_ledgers
    @ledgers = TallyLedger.all(:include => [:finance_transaction_categories])

  end

  def delete_ledger
    ledger = TallyLedger.find_by_id params[:id]

    transactions = ledger.finance_transaction_categories
    transactions.each do |trans|
      trans.update_attributes(:tally_ledger_id => nil)
    end
    if ledger.destroy
      flash[:notice] = "#{t('ledger_deleted_successfully')}"
    end
    redirect_to :action => 'view_ledgers'
  end

  def manual_sync
    if request.post?
      Delayed::Job.enqueue(TallyManualSyncJob.new(params[:manual_sync][:start_date], params[:manual_sync][:end_date] ))
      flash[:notice] = "#{t('manual_sync_scheduled_successfully')} <a href='#{scheduled_task_path(:job_object=>"TallyManualSyncJob",:job_type=>"1")}'>#{t('click_here')}</a> #{t('to_view_status')}"
    end
  end

  def bulk_export

  end

  def schedule
    @ledgers = TallyLedger.all
    if request.post?
      @errors = []
      unless params[:bulk_export][:ledger_ids].blank?
        Delayed::Job.enqueue(TallyBulkExportJob.new(params[:bulk_export][:start_date], params[:bulk_export][:end_date], params[:bulk_export][:ledger_ids].join(',')))
        flash[:notice] = "#{t('export_scheduled_successfully')} <a href='#{scheduled_task_path(:job_object=>"TallyBulkExportJob",:job_type=>"1")}'>#{t('click_here')}</a> #{t('to_view_status')}"
      else
        @errors << "#{t('please_select_any_ledger')}"
      end
    end
  end

  def downloads
    @files = TallyExportFile.all
  end

  def download
    export_file = TallyExportFile.find(params[:id])
    file_name = export_file.export_file.path
    export_file.update_attribute('download_no',"#{export_file.download_no.next}")
    send_file file_name, :type => 'text/xml'
  end

  def failed_syncs
    unless request.post?
      @logs = TallyExportLog.paginate(:page=> params[:page],:per_page=>5,:conditions => { :status => false }, :order=> "updated_at DESC", :joins => [:finance_transaction]) 
    else
      @date = params[:date]
      @logs = TallyExportLog.paginate(:page => params[:page], :per_page => 5, :conditions => ["tally_export_logs.status = ? AND tally_export_logs.updated_at >= ? AND tally_export_logs.updated_at < ?",false, @date.to_datetime, @date.to_datetime + 1.day], :order=> "updated_at DESC", :joins => [:finance_transaction])
    end
  end

end
