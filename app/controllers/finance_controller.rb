#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License

class FinanceController < ApplicationController
  lock_with_feature :hr_enhancement, :only => [:employee_payslip_approve, :employee_payslip_reject, :payslip_revert_transaction, :view_monthly_payslip, :view_monthly_payslip_pdf, :view_employee_payslip]
  lock_with_feature :finance_multi_receipt_data_updation

  before_filter :login_required, :configuration_settings_for_finance
  before_filter :protect_access_by_other_students, :only => [:fee_receipts, :generate_fee_receipt_pdf]
  before_filter :set_precision
  before_filter :load_tax_setting, :only => [:index, :tax_index, :tax_settings, :fees_particulars_new,
    :fees_particulars_create, :master_category_particulars, :master_category_particulars_edit,
    :master_category_particulars_update, :fees_particulars_new2, :fees_particulars_create2,
    :master_category_particulars_delete, :master_particular_tax_slab_update, :finance_reports,
    :fees_receipt_preview]
  before_filter :invoice_number_enabled?, :only => [:generate_fee_receipt, :generate_fee_receipt_pdf, :fees_receipt_preview]
  before_filter :fetch_multiple_configs, :only => [:master_category_new, :master_category_create]
  filter_access_to :all
  filter_access_to [:view_monthly_payslip], :attribute_check => true, :load_method => lambda { cur_user = current_user; cur_user.finance_flag = !params[:hr].present?; cur_user }
  filter_access_to [:student_fee_receipt_pdf, :pay_all_fees_receipt_pdf], :attribute_check => true, :load_method => lambda { Student.find(params[:id]) }
  include LinkPrivilege
  include FeeReceiptMod
  include ReceiptPrinterHelper
  # include FinanceHelper
  helper_method :previous_payments
  helper_method('link_to', 'link_to_remote', 'link_present')
  helper_method(:get_stylesheet_for_current_receipt_template, :get_stylesheet_for_receipt_template, :get_current_receipt_partial, :get_partial_for_current_receipt_template, :receipt_path, :get_receipt_partial, :precision_label_with_currency,
    :has_fine?, :has_discount?, :has_tax?, :has_previously_paid_fees?, :has_roll_number?, :particular_has_discount, :particular_has_previous_payments,
    :current_receipt_template_preview_url, :reference_no_label, :clean_output, :has_due?, :has_due_date?, :has_particulars?)
  filter_access_to :refund_student_view, :refund_student_view_pdf, :attribute_check => true , :load_method => lambda { params[:student_type] == 'Student' ? Student.find(params[:id]) : ArchivedStudent.find_by_former_id(params[:id]) }
  check_request_fingerprint :donation, :expense_create, :income_create, :create_liability, :create_asset, :category_create, :fees_particulars_create,
    :pay_fees_defaulters, :fees_particulars_create2, :additional_fees_create, :add_particulars_create, :fee_collection_update, :fees_submission_save,
    :batch_wise_discount_create, :category_wise_fee_discount_create, :student_wise_fee_discount_create, :create_refund, :fees_refund_student,
    :add_additional_details_for_donation, :update_ajax, :employee_payslip_approve, :payslip_revert_transaction,
    :delete_transaction_for_student, :delete_transaction_for_particular_wise_fee_pay, :delete_transaction_fees_defaulters,
    :delete_transaction_by_batch

  # finance module dashboard
  def index
    @hr = Configuration.find_by_config_value("HR")
    @advance_fee_payment = Configuration.find_by_config_key("AdvanceFeePaymentForStudent")
  end

  # finance tax module dashboard
  def tax_index

  end

  # fees index
  def fees_index
    @advance_fee_payment = Configuration.find_by_config_key("AdvanceFeePaymentForStudent")
  end

  # manage tax settings
  def tax_settings
    @config = Configuration.get_multiple_configs_as_hash ['FinanceTaxName', 'FinanceTaxIdentificationLabel', 'FinanceTaxIdentificationNumber']
    if request.post?
      @ret_value=Configuration.set_config_values(params[:configuration])
      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action => "tax_settings" and return
    end
  end

  # receive / collection donation
  def donation
    @donation = FinanceDonation.new(params[:donation])
    @donation_additional_details = DonationAdditionalDetail.find_all_by_finance_donation_id(@donation.id)
    @additional_fields = DonationAdditionalField.find(:all, :conditions => "status = true", :order => "priority ASC")
    if request.post? && @donation.valid?
      @error=false
      mandatory_fields = DonationAdditionalField.find(:all, :conditions => {:is_mandatory => true, :status => true})
      mandatory_fields.each do |m|
        unless params[:donation_additional_details][m.id.to_s.to_sym].present?
          @donation.errors.add_to_base("#{m.name} must contain atleast one selected option.")
          @error=true
        else
          if params[:donation_additional_details][m.id.to_s.to_sym][:additional_info]==""
            @donation.errors.add_to_base("#{m.name} cannot be blank.")
            @error=true
          end
        end
      end
      unless @error==true
        @donation.save
        additional_field_ids_posted = []
        additional_field_ids = @additional_fields.map(&:id)
        if params[:donation_additional_details].present?
          params[:donation_additional_details].each_pair do |k, v|
            addl_info = v['additional_info']
            additional_field_ids_posted << k.to_i
            addl_field = DonationAdditionalField.find_by_id(k)
            if addl_field.input_type == "has_many"
              addl_info = addl_info.join(", ")
            end
            prev_record = DonationAdditionalDetail.find_by_finance_donation_id_and_additional_field_id(params[:id], k)
            unless prev_record.nil?
              unless addl_info.present?
                prev_record.destroy
              else
                prev_record.update_attributes(:additional_info => addl_info)
              end
            else
              addl_detail = DonationAdditionalDetail.new(:finance_donation_id => @donation.id,
                :additional_field_id => k, :additional_info => addl_info)
              addl_detail.save if addl_detail.valid?
            end
          end
        end
        if additional_field_ids.present?
          DonationAdditionalDetail.find_all_by_finance_donation_id_and_additional_field_id(params[:id], (additional_field_ids - additional_field_ids_posted)).each do |additional_info|
            additional_info.destroy unless additional_info.donation_additional_field.is_mandatory == true
          end
        end
        flash[:notice] = "#{t('flash1')}"
        redirect_to :action => 'donation_receipt', :id => @donation.id
      end
    end
  end

  # view donation transaction receipt
  def donation_receipt
    @donation = FinanceDonation.find_by_id(params[:id], :include => {:transaction => :transaction_ledger},
      :joins => "INNER JOIN finance_transactions ft ON ft.finance_type = 'FinanceDonation' AND ft.finance_id = finance_donations.id
                   INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => "#{active_account_conditions(true, 'ftrr')}")
    if @donation.present?
      @additional_details = @donation.donation_additional_details.find(:all,:include => [:donation_additional_field],
        :conditions => ["donation_additional_fields.status = true"],:order => "donation_additional_fields.priority ASC")
      @additional_fields_count = DonationAdditionalField.count(:conditions => "status = true")
    else
      flash[:notice] = t('flash_msg5')
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  #  def donation_edit
  #    @donation = FinanceDonation.find(params[:id])
  #    @transaction = FinanceTransaction.find(@donation.transaction_id)
  #    @donation_additional_details = DonationAdditionalDetail.find_all_by_finance_donation_id(@donation.id)
  #    @additional_fields = DonationAdditionalField.find(:all, :conditions=> "status = true", :order=>"priority ASC")
  #    if request.post?
  #      @donation.attributes=params[:donation]
  #      if @donation.valid?
  #        @error=false
  #        mandatory_fields = DonationAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :status=>true})
  #        mandatory_fields.each do|m|
  #          unless params[:donation_additional_details][m.id.to_s.to_sym].present?
  #            @donation.errors.add_to_base("#{m.name} must contain atleast one selected option.")
  #            @error=true
  #          else
  #            if params[:donation_additional_details][m.id.to_s.to_sym][:additional_info]==""
  #              @donation.errors.add_to_base("#{m.name} cannot be blank.")
  #              @error=true
  #            end
  #          end
  #        end
  #        unless @error==true
  #          @donation.save
  #          additional_field_ids_posted = []
  #          additional_field_ids = @additional_fields.map(&:id)
  #          if params[:donation_additional_details].present?
  #            params[:donation_additional_details].each_pair do |k, v|
  #              addl_info = v['additional_info']
  #              additional_field_ids_posted << k.to_i
  #              addl_field = DonationAdditionalField.find_by_id(k)
  #              if addl_field.input_type == "has_many"
  #                addl_info = addl_info.join(", ")
  #              end
  #              prev_record = DonationAdditionalDetail.find_by_finance_donation_id_and_additional_field_id(params[:id], k)
  #              unless prev_record.nil?
  #                unless addl_info.present?
  #                  prev_record.destroy
  #                else
  #                  prev_record.update_attributes(:additional_info => addl_info)
  #                end
  #              else
  #                addl_detail = DonationAdditionalDetail.new(:finance_donation_id => @donation.id,
  #                  :additional_field_id => k,:additional_info => addl_info)
  #                addl_detail.save if addl_detail.valid?
  #              end
  #            end
  #          end
  #          if additional_field_ids.present?
  #            DonationAdditionalDetail.find_all_by_finance_donation_id_and_additional_field_id(params[:id],(additional_field_ids - additional_field_ids_posted)).each do |additional_info|
  #              additional_info.destroy unless additional_info.donation_additional_field.is_mandatory == true
  #            end
  #          end
  #          donor = "#{t('flash15')} #{params[:donation][:donor]}"
  #          FinanceTransaction.update(@transaction.id, :description => params[:donation][:description], :title => donor, :amount => params[:donation][:amount], :transaction_date => @donation.transaction_date)
  #          redirect_to :action => 'donations'
  #          flash[:notice] = "#{t('flash16')}"
  #        end
  #      end
  #    end
  #  end

  # delete donation transaction
  def donation_delete
    @donation = FinanceDonation.find(params[:id])
    @transaction = FinanceTransaction.find(@donation.transaction_id)
    @transaction.cancel_reason = params[:reason]
    if @transaction.destroy
      redirect_to :action => 'donations'
      flash[:notice] = "#{t('flash25')}"
    end
  end

  # download donation transaction receipt
  def donation_receipt_pdf
    # @donation = FinanceDonation.find(params[:id], :include => {:transaction=>:transaction_ledger})
    @donation = FinanceDonation.find_by_id(params[:id], :include => {:transaction => :transaction_ledger},
      :joins => "INNER JOIN finance_transactions ft ON ft.finance_type = 'FinanceDonation' AND ft.finance_id = finance_donations.id
                 INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => "#{active_account_conditions(true, 'ftrr')}")

    if @donation.present?
      @additional_details = @donation.donation_additional_details.find(:all,:include => [:donation_additional_field],
        :conditions => ["donation_additional_fields.status = true"],:order => "donation_additional_fields.priority ASC")
      @additional_fields_count = DonationAdditionalField.count(:conditions => "status = true")
      @currency_type = currency
      transaction_rec = @donation.transaction
      @transaction_hash = transaction_rec.receipt_data
      @transaction_hash.template_id = transaction_rec.fetch_template_id
      template_id = @transaction_hash.template_id
      #    configs = ['PdfReceiptSignature', 'PdfReceiptSignatureName',
      #      'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
      #    fetch_config_hash configs

      #    @default_currency = Configuration.default_currency
      #    template_ids = finance_transactions.map {|x| x.fetch_template_id }.uniq.compact
      @data = {:templates => template_id.present? ? FeeReceiptTemplate.find(template_id).to_a.group_by(&:id) : {} }

      render :pdf => 'donation_receipt_pdf', :template => "finance/donation_receipt_new_pdf.erb",
        :margin =>{:top=>2,:bottom=>20,:left=>5,:right=>5}, :header => {:html => { :content=> ''}},
        :footer => {:html => {:content => ''}},  :show_as_html => params.key?(:debug)
    else
      flash[:notice] = t("flash_msg5")
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  # def donors
  #   @donations = FinanceDonation.find(:all, :order => 'transaction_date desc')
  # end
  # lists all donations by pagination
  def donations
    @donations=FinanceDonation.paginate(
      :joins => "INNER JOIN finance_transactions ft ON ft.finance_type = 'FinanceDonation' AND ft.finance_id = finance_donations.id
                 INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                  LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["finance_donations.transaction_date BETWEEN ? AND ? AND #{active_account_conditions(true, 'ftrr')}",
        1.month.ago.beginning_of_day, Date.today.end_of_day],
      # :conditions => {:transaction_date => 1.month.ago.beginning_of_day..Date.today.end_of_day},
      :per_page => 20, :page => params[:page], :order => 'created_at ASC')
  end

  # not in use
  def donors_list

    conditions = []
    joins = "INNER JOIN finance_transactions ft ON ft.finance_id = finance_donations.id AND ft.finance_type = 'FinanceDonation'
             INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
              LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
    conditions << "(fa.id IS NULL OR fa.is_deleted = false) AND finance_donations.transaction_date BETWEEN ? AND ?"
    unless params[:donors_list].nil?
      conditions << [params[:donors_list][:from].to_date.beginning_of_day]
      conditions << [params[:donors_list][:to].to_date.end_of_day]
    else
      conditions << [1.month.ago.beginning_of_day]
      conditions << [Date.today_with_timezone.end_of_day]
    end

    @donations = FinanceDonation.paginate(:conditions => conditions, :joins => joins, :per_page => 20,
      :page => params[:page], :order => 'created_at ASC')
    if request.xhr?
      render :update do |page|
        page.replace_html "donors_list", :partial => "donors_list"
      end
    end
  end

  def change_field_priority_for_donation
    @additional_field = DonationAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = DonationAdditionalField.find(:all, :conditions => {:status => true}, :order => "priority ASC").map { |b| b.priority.to_i }
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = DonationAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = DonationAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority => prev_field.priority)
    prev_field.update_attributes(:priority => priority.to_i)
    @additional_field = DonationAdditionalField.new
    @additional_details = DonationAdditionalField.find(:all, :conditions => {:status => true}, :order => "priority ASC")
    @inactive_additional_details = DonationAdditionalField.find(:all, :conditions => {:status => false}, :order => "priority ASC")
    render(:update) do |page|
      page.replace_html "category-list", :partial => "additional_fields_for_donation"
    end
  end

  # add custom expense transaction
  def expense_create
    @finance_transaction = FinanceTransaction.new
    @categories = FinanceTransactionCategory.expense_categories
    if @categories.empty?
      flash[:notice] = "#{t('flash2')}"
    end
    if request.post?
      @finance_transaction = FinanceTransaction.new(params[:finance_transaction])
      if @finance_transaction.save
        flash[:notice] = "#{t('flash3')}"
        redirect_to :action => "expense_create"
      else
        render :action => "expense_create"
      end
    end
  end

  # view list of custom expense transactions
  def expense_list

  end

  # view list of custom expense transactions based on date range
  def expense_list_update
    if params[:start_date].present? and params[:end_date].present?
      if (params[:start_date].to_date > params[:end_date].to_date)
        flash[:warn_notice] = "#{t('flash17')}"
        redirect_to :action => 'expense_list'
      end

      @start_date = (params[:start_date]).to_date
      @end_date = (params[:end_date]).to_date
      @expenses = FinanceTransaction.expenses(@start_date, @end_date)
    else
      redirect_to :action => 'expense_list'
    end
  end

  # get pdf of list of custom expense transactions
  def expense_list_pdf
    if date_format_check
      @currency_type = currency
      @expenses = FinanceTransaction.expenses(@start_date, @end_date)
      render :pdf => 'expense_list_pdf', :show_as_html => params[:d].present?
    end
  end

  # add custom income transaction
  def income_create
    @finance_transaction = FinanceTransaction.new()
    @categories = FinanceTransactionCategory.income_categories
    if @categories.empty?
      flash[:notice] = "#{t('flash5')}"
    end
    if request.post?
      @finance_transaction = FinanceTransaction.new(params[:finance_transaction])
      #      if @finance_transaction.save
      if @finance_transaction.safely_create
        flash[:notice] = "#{t('flash6')}"
        redirect_to :action => "income_create"
      else
        render :action => "income_create"
      end
    end
  end

  # not in use
  def monthly_income

  end

  # view transaction report
  def monthly_report
    @accounts_enabled = (Configuration.get_config_value 'MultiFeeAccountEnabled').to_i == 1
    @accounts = FeeAccount.find(:all) if @accounts_enabled
    #    @target_action = "update_monthly_report"
  end

  # view list of custom income transactions
  def income_list
  end

  # destroy a transaction
  def delete_transaction
    @transaction = FinanceTransaction.find_by_id(params[:id])
    @transaction.cancel_reason = params[:reason]
    income = @transaction.category.is_income?
    if income
      auto_transactions = FinanceTransaction.find_all_by_master_transaction_id(params[:id])
      auto_transactions.each { |a| a.destroy } unless auto_transactions.nil?
    end
    @transaction.destroy
    flash.now[:notice]="#{t('flash18')}"
    if income
      redirect_to :action => 'income_list'
    else
      redirect_to :action => 'expense_list'
    end
  end

  # view list of income transactions filtered by date range
  def income_list_update
    if params[:start_date].present? and params[:end_date].present?
      @start_date = (params[:start_date]).to_date
      @end_date = (params[:end_date]).to_date
      @incomes = FinanceTransaction.incomes(@start_date, @end_date)
    else
      redirect_to :action => 'income_list'
    end
  end

  # view list of custom expenses for a date range (link from transaction report page)
  def expense_details
    if date_format_check
      filter_by_account, account_id = account_filter false

      if filter_by_account
        ft_joins = "" #[:finance_transaction_receipt_record]
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        ft_joins = filter_values = []
        filter_conditions = ""
      end

      @expense_category = FinanceTransactionCategory.find(params[:id])

      if @expense_category.name == 'Refund'
        ft_joins = "INNER JOIN fee_refunds fr ON fr.finance_transaction_id = finance_transactions.id
                    INNER JOIN finance_fees ff ON ff.id = fr.finance_fee_id
                    INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
                     LEFT JOIN fee_accounts fa On fa.id = ffc.fee_account_id"
        cond = "(fa.id IS NULL OR fa.is_deleted = false) AND "
      else
        cond = ""
      end

      @grand_total = @expense_category.finance_transactions.all(:select => "finance_transactions.amount",
        :joins => ft_joins, :conditions => ["#{cond} transaction_date BETWEEN ? AND ? #{filter_conditions}",
          @start_date, @end_date] + filter_values).map { |x| x.amount.to_f }.sum

      @expense = @expense_category.finance_transactions.all(:joins => ft_joins, :conditions =>
          ["#{cond} transaction_date BETWEEN ? AND ? #{filter_conditions}", @start_date, @end_date] + filter_values)
    end
  end

  # get pdf of custom expenses for a date range (link from transaction report page)
  def expense_details_pdf
    if date_format_check
      @expense_category = FinanceTransactionCategory.find(params[:id])
      @expense = @expense_category.finance_transactions.find(:all, :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
      render :pdf => 'expense_details_pdf', :show_as_html => params[:d].present?, :page_width => '800'
    end
  end

  # view list of custom income transactions for a date range (link from transaction report page)
  def income_details
    if date_format_check
      if params[:id].present?
        @income_category = FinanceTransactionCategory.find(params[:id])
      end
      @incomes = @income_category.finance_transactions.all(:include => :transaction_receipt,
        :joins => "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND transaction_date BETWEEN '#{@start_date}' AND
                         '#{@end_date}'"])
    end
  end

  # get pdf of custom income transactions for a date range (link from incomes list page)
  def income_list_pdf
    if date_format_check
      @currency_type = currency
      @incomes = FinanceTransaction.incomes(@start_date, @end_date)
      render :pdf => 'income_list_pdf', :zoom => 0.68, :page_width => '800', :margin => {:left => '20', :right => '20'}, :show_as_html => params[:d].present?
    end
  end

  # get pdf of custom income transactions (link from transaction report page)
  def income_details_pdf
    if date_format_check
      @income_category = FinanceTransactionCategory.find(params[:id])
      @incomes = @income_category.finance_transactions.find(:all, :include => :transaction_ledger,
        :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'"])
      render :pdf => 'income_details_pdf'
    end
  end

  # view / manage FinanceTransactionCategory
  def categories
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false}, :order => 'name asc')
    @categories = @categories.select { |x| x.accessible? }
    @category_ids = @categories.map { |cat| cat.id if FinanceTransaction.find_by_category_id(cat.id).present? }.compact
    @multi_config = FinanceTransactionCategory.get_multi_configuration
    @fee_category_present = FinanceFeeCategory.first
    #    @fixed_categories = @categories.reject { |c| !c.is_fixed }
    #    @other_categories = @categories.reject { |c| c.is_fixed }
  end

  # render form to create a custom finance transaction category
  def category_new
    @finance_transaction_category = FinanceTransactionCategory.new
  end

  # records a custom finance transaction category
  def category_create
    @finance_category = FinanceTransactionCategory.new(params[:finance_category])
    @multi_config = FinanceTransactionCategory.get_multi_configuration
    render :update do |page|
      @finance_category.validate_category_name # restrict category reserved names
      if @finance_category.save
        @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false}, :order => 'name asc')
        @category_ids = @categories.map { |cat| cat.id if FinanceTransaction.find_by_category_id(cat.id).present? }.compact
        @fixed_categories = @categories.reject { |c| !c.is_fixed }
        @other_categories = @categories.reject { |c| c.is_fixed }
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'category-list', :partial => 'category_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg35')}</p>"

      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_category
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  # delete a custom finance transaction category
  def category_delete
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @finance_category.update_attributes(:deleted => true)
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false}, :order => 'name asc')
    @category_ids = @categories.map { |cat| cat.id if FinanceTransaction.find_by_category_id(cat.id).present? }.compact
    @fixed_categories = @categories.reject { |c| !c.is_fixed }
    @other_categories = @categories.reject { |c| c.is_fixed }
    @multi_config = FinanceTransactionCategory.get_multi_configuration
  end

  # render form to edit a custom finance transaction category
  def category_edit
    @finance_category = FinanceTransactionCategory.find(params[:id])
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false})
    @category_ids = @categories.map { |cat| cat.id if FinanceTransaction.find_by_category_id(cat.id).present? }.compact
  end

  # update a custom finance transaction category
  def category_update
    @finance_category = FinanceTransactionCategory.find(params[:id])
    unless @finance_category.update_attributes(params[:finance_category])
      @errors=true
    end
    @categories = FinanceTransactionCategory.all(:conditions => {:deleted => false}, :order => 'name asc')
    @category_ids = @categories.map { |cat| cat.id if FinanceTransaction.find_by_category_id(cat.id).present? }.compact
    @fixed_categories = @categories.reject { |c| !c.is_fixed }
    @other_categories = @categories.reject { |c| c.is_fixed }
    @multi_config = FinanceTransactionCategory.get_multi_configuration
  end

  def show_date_filter
    month_date
    @target_action = params[:target_action]
    if request.xhr?
      render(:update) do |page|
        page.replace_html "date_filter", :partial => "filter_dates"
      end
    end
  end

  def show_compare_date_filter
    month_date
    @target_action=params[:target_action]
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
    @start_date2 = params[:start_date2].to_date
    @end_date2 = params[:end_date2].to_date
    if request.xhr?
      render(:update) do |page|
        page.replace_html "date_filter", :partial => "date_filter_for_compare"
      end
    end
  end

  #transaction-----------------------
  # fetches data and renders transaction report as per selected filters
  def update_monthly_report
    unless request.get?
      if validate_date
        graph_data = ""
        fixed_category_name
        @error_flag=false
        @hr = Configuration.find_by_config_value("HR")

        filter_by_account, account_id = account_filter
        joins = "INNER JOIN finance_transactions ON finance_transactions.category_id = finance_transaction_categories.id "
        ft_joins = "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id=finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
        ft_joins_2 = "LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id=finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
        if filter_by_account
          joins += "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                     LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
          # {:finance_transactions => :finance_transaction_receipt_record}
          # ft_joins = [:finance_transaction_receipt_record]
          filter_conditions = "AND ftrr.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_conditions += " AND fa.is_deleted = false" if account_id.present?
          filter_values = [account_id]
          filter_select = ", ftrr.fee_account_id AS account_id"
        else
          joins += "LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
          filter_values = []
          filter_conditions = " AND (fa.id IS NULL or fa.is_deleted = false) "
          filter_select = ""
        end
        @refund_transaction_category = FinanceTransactionCategory.find_by_name('Refund')
        @fixed_cat_ids << @refund_transaction_category.id if @refund_transaction_category.present?
        other_cat_ids = @fixed_cat_ids.join(',')
        @other_transaction_categories = FinanceTransactionCategory.find(:all,
          :select => "finance_transaction_categories.* #{filter_select}",
          :conditions => ["finance_transactions.transaction_date >= '#{@start_date}' and
                                 finance_transactions.transaction_date <= '#{@end_date}' and
                                 finance_transaction_categories.id NOT IN (#{other_cat_ids})
          #{filter_conditions}"] + filter_values,
          :group => "finance_transactions.category_id", :joins => joins)

        fees_id = FinanceTransaction.get_transaction_category("Fee")
        @transactions_fees = FinanceTransaction.all(
          :select => "finance_transactions.amount #{filter_select}",
          :conditions => ["transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}' and
                                 category_id ='#{fees_id}' #{filter_conditions}"] + filter_values,
          :joins => ft_joins).map {|x| x.amount.to_f }.sum
        graph_data += "&fees=#{@transactions_fees.to_f}"
        @salary = ((filter_by_account and account_id.present?) ? [] : FinanceTransaction.all(
            :select => "finance_transactions.amount", :conditions => ["title = 'Monthly Salary' AND
                      (transaction_date BETWEEN '#{@start_date}' AND '#{@end_date}')"]).map {|x| x.amount.to_f }).sum
        graph_data += "&salary=#{@salary.to_f}"
        @donations_total = FinanceTransaction.donations_triggers(@start_date, @end_date,
          {:conditions => filter_conditions, :values => filter_values, :joins => ft_joins, :select => filter_select})
        graph_data += "&donation=#{@donations_total.to_f}"
        @refund = FinanceTransaction.get_refund_total_amount(@refund_transaction_category, @start_date, @end_date)
        graph_data += "&refund=#{@refund.to_f}"

        # advance fee transaction report
        dy_condition_c = 'AND advance_fee_transaction_receipt_records.fee_account_id is null' if account_id.nil?
        dy_condition_c = "AND advance_fee_transaction_receipt_records.fee_account_id = #{account_id}" if (!account_id.nil? and account_id != false)
        dy_condition_c =  nil if account_id == false
        @wallet_collections = AdvanceFeeCollection.find(:all, :joins => [:advance_fee_transaction_receipt_record],
          :conditions => ["date_of_advance_fee_payment between ? AND ? #{(dy_condition_c unless dy_condition_c.nil?)}", @start_date, @end_date.end_of_day ])
        
        @wallet_collection_amount = 0
        @wallet_collections.each do |collection|
          @wallet_collection_amount += collection.fees_paid
        end
        
        @wallet_deductions = AdvanceFeeDeduction.find(:all, :joins => [:finance_transaction], 
          :conditions => ["deduction_date between ? and ?", @start_date, @end_date.end_of_day ])
        @wallet_deduction_amount = 0
        @wallet_deductions.each do |deduction|
          @wallet_deduction_amount += deduction.amount
        end

        @category_transaction_totals = {}

        plugin_categories = FedenaPlugin::FINANCE_CATEGORY.collect do |p_c|
          p_c[:category_name] if can_access_request? "#{p_c[:destination][:action]}".to_sym, "#{p_c[:destination][:controller]}".to_sym
        end.compact

        @plugin_amount = FinanceTransaction.find(:all,
          :joins => "INNER JOIN finance_transaction_categories ftc ON ftc.id = finance_transactions.category_id #{ft_joins_2}",
          :conditions => ["transaction_date >= '#{@start_date}' AND transaction_date <= '#{@end_date}' AND
                           ftc.name IN (?) #{filter_conditions}", plugin_categories] + filter_values, :group => "ftc.name",
          :select => "SUM(finance_transactions.amount) AS amount, ftc.is_income AS is_income,
                         ftc.name AS pl_name #{filter_select}").group_by(&:pl_name)
        plugin_categories.each do |category|
          if @plugin_amount[category.camelize].present?
            amount = @plugin_amount[category.camelize].first.amount.to_f
            graph_data += "&ICATEGORY#{category.underscore.gsub(/\s+/, '_')+'_fees'}=#{amount}" if @plugin_amount[category.camelize].present? && amount > 0
          end
        end
        @other_transaction_category_amount = {}
        @other_transaction_categories.each do |cat|
          amt = @other_transaction_category_amount[cat.id] = cat.is_income ? cat.total_income(@start_date, @end_date) :
            cat.total_expense(@start_date, @end_date)
          graph_data += "&#{cat.is_income ? 'IO':'EO'}CATEGORY#{cat.name}=#{amt.to_f}"
        end
        @target_action = "update_monthly_report"

        @graph = open_flash_chart_object(1200, 500, "graph_for_update_monthly_report?start_date=#{@start_date}&end_date=#{@end_date}&fee_account_id=#{@account_id}#{graph_data}")

        if request.xhr?
          render(:update) do |page|
            page.replace_html "fee_report_div", :partial => "update_monthly_report_partial"
          end
        end
      else
        if request.xhr?
          render_date_error_partial
        else
          flash[:warn_notice] = "error"
          redirect_to :action => :monthly_report
        end
      end
    else
      #      flash[:warn_notice] = "error"
      redirect_to :action => :monthly_report
    end
  end

  # transaction pdf
  def transaction_pdf
    @data_hash = FinanceTransaction.fetch_finance_transaction_data(params)
    render :pdf => 'transaction_pdf', :show_as_html => params[:d].present?
  end

  # list salary department information as per filters ( link from transaction report page)
  def salary_department
    if validate_date

      filter_by_account, account_id = account_filter false

      if filter_by_account
        joins = "INNER JOIN finance_transaction_receipt_records
                         ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_conditions = joins = ""
        filter_values = []
      end

      @target_action = "salary_department"
      archived_employee_salary = FinanceTransaction.all(
        :select => "SUM(finance_transactions.amount) AS amount,employee_departments.id, employee_departments.name",
        :conditions => ["title = 'Monthly Salary' AND (transaction_date BETWEEN ? AND ?)
                                  #{filter_conditions}", @start_date, @end_date] + filter_values,
        :joins => "INNER JOIN archived_employees
                                     ON archived_employees.former_id = finance_transactions.payee_id
                        INNER JOIN employee_departments
                                     ON employee_departments.id = archived_employees.employee_department_id
                        #{joins}",
        :group => "employee_departments.id", :order => "employee_departments.name").group_by(&:id)

      employee_salary = FinanceTransaction.all(
        :select => "sum(finance_transactions.amount) as amount,employee_departments.id,employee_departments.name",
        :conditions => ["title = 'Monthly Salary' AND (transaction_date BETWEEN ? AND ?)
                                  #{filter_conditions}", @start_date, @end_date] + filter_values,
        :joins => "INNER JOIN employees on employees.id = finance_transactions.payee_id
               LEFT OUTER JOIN employee_departments ON employee_departments.id = employees.employee_department_id
                       #{joins}",
        :group => "employee_departments.id", :order => "employee_departments.name").group_by(&:id)

      @departments = EmployeeDepartment.ordered(:select => "id, name")

      @departments.each do |d|
        total = 0.0
        total += archived_employee_salary[d.id].nil? ? 0 : archived_employee_salary[d.id][0].amount.to_f
        total += employee_salary[d.id].nil? ? 0 : employee_salary[d.id][0].amount.to_f
        d['amount'] = total
      end
      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "salary_department_partial"
        end
      end
    else
      render_date_error_partial
    end
  end

  # list salary information as per filters ( link via transaction report page)
  def salary_employee
    if validate_date

      filter_by_account, account_id = account_filter false

      if filter_by_account
        joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_conditions = joins = ""
        filter_values = []
      end

      #TODO optimize query
      @target_action = "salary_employee"
      values = []
      archived_employees = "SELECT amount, archived_employees.employee_number employee_num,
                                                      CONCAT(archived_employees.first_name, ' ', archived_employees.middle_name,
                                                                    ' ', archived_employees.last_name) AS employee_name,
                                                      archived_employees.id AS employee_id, finance_transactions.id,
                                                      DATE_FORMAT(finance_transactions.transaction_date, '%M %Y') AS month_date,
                                                      finance_transactions.transaction_date, payslips_date_ranges.start_date,
                                                      payslips_date_ranges.end_date, payroll_groups.payment_period,
                                                      employee_payslips.id as payslip_id
                                            FROM `finance_transactions`
                                    INNER JOIN archived_employees on archived_employees.former_id= finance_transactions.payee_id
                                    INNER JOIN employee_payslips ON employee_payslips.finance_transaction_id = finance_transactions.id
                                    INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id
                                    INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id #{joins}
                                          WHERE (finance_transactions.title = 'Monthly Salary' AND
                                                        archived_employees.employee_department_id = ? AND
                                                        finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}"
      values += [params[:id], @start_date, @end_date] + filter_values

      employees = "SELECT amount,employees.employee_number as employee_number,
                                        concat(employees.first_name,' ',employees.middle_name,' ',employees.last_name) as employee_name,
                                        employees.id as employee_id ,finance_transactions.id,
                                        DATE_FORMAT(finance_transactions.transaction_date, '%M %Y') AS month_date,
                                        finance_transactions.transaction_date, payslips_date_ranges.start_date,
                                        payslips_date_ranges.end_date, payroll_groups.payment_period,
                                        employee_payslips.id as payslip_id
                              FROM finance_transactions
                      INNER JOIN employees on employees.id= finance_transactions.payee_id
                      INNER JOIN employee_payslips on employee_payslips.finance_transaction_id = finance_transactions.id
                      INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id
                      INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id #{joins}
                            WHERE (finance_transactions.title = 'Monthly Salary' AND
                                         employees.employee_department_id = ? AND
                                         finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}"
      values += [params[:id], @start_date, @end_date] + filter_values

      employee_salary = FinanceTransaction.all(:select => "SUM(amount) AS full_amount",
        :conditions => ["title = 'Monthly Salary' AND (transaction_date BETWEEN ? AND ?) AND
                                 employees.employee_department_id = ? #{filter_conditions}",
          @start_date, @end_date, params[:id]] + filter_values,
        :joins => "INNER JOIN employees on employees.id = finance_transactions.payee_id #{joins}")

      archived_employee_salary = FinanceTransaction.all(
        :select => "SUM(amount) AS full_amount",
        :conditions => ["title = 'Monthly Salary' AND (transaction_date BETWEEN ? AND ?) AND
                                 archived_employees.employee_department_id = ? #{filter_conditions}",
          @start_date, @end_date, params[:id]] + filter_values,
        :joins => "INNER JOIN archived_employees on archived_employees.former_id= finance_transactions.payee_id #{joins}")

      sql = "(#{archived_employees}) UNION ALL (#{employees}) ORDER BY start_date DESC"

      @employees_salary_payslip = FinanceTransaction.paginate_by_sql([sql]+ values, :page => params[:page], :per_page => 30)
      @grand_total = archived_employee_salary.first.full_amount.to_f+employee_salary.first.full_amount.to_f
      @employees_salary = @employees_salary_payslip #to  avoid pagination problem
      @employees_salary = @employees_salary.group_by(&:month_date)
      @department = EmployeeDepartment.find(params[:id])

      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "salary_employee"
        end
      end
    else
      render_date_error_partial
    end
  end

  # get csv for list of salaries as per filters ( link via transaction report page)
  def salary_employee_csv
    if date_format_check

      filter_by_account, account_id = account_filter

      if filter_by_account
        joins = "INNER JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id"
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_conditions = joins = ""
        filter_values = []
      end

      values = []
      archived_employees = "SELECT amount, archived_employees.employee_number, archived_employees.first_name,
                                                      archived_employees.middle_name, archived_employees.last_name,
                                                      archived_employees.id as employee_id, finance_transactions.id,
                                                      DATE_FORMAT(finance_transactions.transaction_date, '%M %Y') AS month_date,
                                                      finance_transactions.transaction_date, payslips_date_ranges.start_date,
                                                      payslips_date_ranges.end_date, payroll_groups.payment_period
                                             FROM `finance_transactions`
                                    INNER JOIN archived_employees on archived_employees.former_id= finance_transactions.payee_id
                                    INNER JOIN employee_payslips ON employee_payslips.finance_transaction_id = finance_transactions.id
                                    INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id
                                    INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id #{joins}
                                          WHERE (finance_transactions.title = 'Monthly Salary' AND
                                                       archived_employees.employee_department_id = ? AND
                                                       finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}"
      values += [params[:id], @start_date, @end_date] + filter_values
      employees = "SELECT amount, employees.employee_number, employees.first_name, employees.middle_name,
                                        employees.last_name, employees.id AS employee_id, finance_transactions.id,
                                        DATE_FORMAT(finance_transactions.transaction_date, '%M %Y') AS month_date,
                                        finance_transactions.transaction_date, payslips_date_ranges.start_date,
                                        payslips_date_ranges.end_date, payroll_groups.payment_period
                              FROM finance_transactions
                     INNER JOIN employees on employees.id= finance_transactions.payee_id
                     INNER JOIN employee_payslips on employee_payslips.finance_transaction_id = finance_transactions.id
                     INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id
                     INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id #{joins}
                           WHERE (finance_transactions.title = 'Monthly Salary' AND
                                        employees.employee_department_id = ? AND
                                        finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}"
      values += [params[:id], @start_date, @end_date] + filter_values
      sql = "(#{archived_employees}) UNION ALL (#{employees}) ORDER BY start_date DESC"
      @employees_salary = FinanceTransaction.find_by_sql([sql]+ values)
      @employees_salary = @employees_salary.group_by(&:month_date)
      csv_string = FasterCSV.generate do |csv|
        csv << [t('employee_salary')]
        csv << [t('start_date'), format_date(@start_date)]
        csv << [t('end_date'), format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        csv << [t('employee_name'), t('transaction_date'), t('pay_frequency'), t('pay_period'), t('salary')]
        total = 0
        @employees_salary.each do |salary_month, employees|
          csv << ""
          csv << [format_date(employees.first.transaction_date, :format => :month_year)]
          employees.each do |employee|
            csv << ["#{employee.first_name} #{employee.middle_name} #{employee.last_name} (#{employee.employee_number})",
              format_date(employee.transaction_date), PayrollGroup.payment_period_translation(employee.payment_period),
              payslip_range(nil, employee.start_date, employee.end_date, employee.payment_period.to_i),
              precision_label(employee.amount)]
            total += employee.amount.to_f
          end
        end
        csv << ""
        csv << [t('net_expenses'), precision_label(total)]
      end
      filename = "#{t('employee_salary')}-#{format_date(@start_date)}-#{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end

  # get details of donations as per filters ( link from transaction report page)
  def donations_report
    if validate_date

      filter_by_account, account_id = account_filter

      if filter_by_account
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        ft_joins = {:transaction => :finance_transaction_receipt_record}
      else
        filter_conditions = ft_joins = ""
        filter_values = []
      end

      @target_action = "donations_report"
      category_id = FinanceTransactionCategory.find_by_name("Donation").id
      # to get grand total  to avoid pagination problem
      @grand_total = FinanceDonation.all(:select => "finance_donations.amount", :joins => ft_joins,
        :conditions => ["(finance_donations.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          @start_date, @end_date] + filter_values).map { |x| x.amount.to_f }.sum

      @donations = FinanceDonation.paginate(:page => params[:page], :per_page => 10,
        :joins => {:transaction => :transaction_receipt},
        :order => 'finance_transactions.transaction_date desc',
        :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ?) AND category_id = ?
                                 #{filter_conditions}", @start_date, @end_date, category_id] + filter_values,
        :select => "finance_donations.*, CONCAT(IFNULL(transaction_receipts.receipt_sequence,''),
                                                                      transaction_receipts.receipt_number) AS receipt_no,
                          finance_transactions.voucher_no")

      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "donation_report_partial"
        end
      end
    else
      render_date_error_partial
    end

  end

  # get csv of donations as per filters ( link via transaction report page)
  def donation_report_csv
    if date_format_check

      filter_by_account, account_id = account_filter

      csv_string = FasterCSV.generate do |csv|

        if filter_by_account
          filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
          filter_values = [account_id]
        else
          filter_conditions = ""
          filter_values = []
        end

        category_id = FinanceTransactionCategory.find_by_name("Donation").id
        @donations = FinanceDonation.all(:joins => {:transaction => :transaction_receipt},
          :order => 'finance_transactions.transaction_date desc',
          :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ?) AND category_id = ?
                                 #{filter_conditions}", @start_date, @end_date, category_id] + filter_values,
          :select => "finance_donations.*, CONCAT(IFNULL(transaction_receipts.receipt_sequence, ''),
                                                                       transaction_receipts.receipt_number) AS receipt_no,
                          finance_transactions.voucher_no")

        csv << [t('donations')]
        csv << [t('start_date'), format_date(@start_date)]
        csv << [t('end_date'), format_date(@end_date)]
        csv << [t('fee_account_text'), "#{@account_name}"] if @accounts_enabled
        csv << ""
        cols = [t('donor'), ('amount'), t('receipt_or_voucher_no'), t('date_text')]
        csv << cols

        total = 0

        @donations.each do |d|
          csv << [d.donor, precision_label(d.amount.to_f), d.receipt_no.nil? ? d.voucher_no : d.receipt_no,
            format_date(d.transaction_date)]
          total += d.amount.to_f
        end

        csv << [t('net_income'), precision_label(total)]
      end

      filename = "#{t('donations')}-#{format_date(@start_date)}-#{format_date(@end_date)}.csv"
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
    end
  end

  # paid student fee details as per filters ( link from transaction report page)
  def fees_report
    if validate_date
      #@batches= FinanceTransaction.total_fees(@start_date, @end_date)

      filter_by_account, account_id = account_filter

      if filter_by_account
        ft_joins = [:finance_transaction_receipt_record]
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        filter_select = ", finance_transaction_receipt_records.fee_account_id AS account_id"
      else
        ft_joins = []
        filter_conditions = ""
        filter_values = []
        filter_select = ""
      end

      @target_action = "fees_report"
      fee_id = FinanceTransactionCategory.find_by_name("Fee").id
      @grand_total = FinanceTransaction.all(:select => "amount",
        :joins => ft_joins,
        :conditions => ["finance_type = 'FinanceFee' and category_id = #{fee_id} and
                                transaction_date <= '#{@end_date}' and 
                                transaction_date >= '#{@start_date}' #{filter_conditions}"] + filter_values).
        map { |x| x.amount.to_f }.sum

      @collections = FinanceFeeCollection.paginate(:page => params[:page], :per_page => 10,
        :joins => {:finance_fees => {:finance_transactions => ft_joins}}, :group => :fee_collection_id,
        :conditions => ["finance_transactions.finance_type = 'FinanceFee' AND finance_transactions.category_id = ? AND
                                 (finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          fee_id, @start_date.to_s, @end_date] + filter_values,
        :order => "finance_fee_collections.id DESC",
        :select => "finance_fee_collections.id AS collection_id,
                         finance_fee_collections.name AS collection_name,
                         finance_fee_collections.tax_enabled,
                         SUM(finance_transactions.amount) AS amount,
                         IF(finance_fee_collections.tax_enabled,
                            SUM(finance_transactions.tax_amount),0) AS total_tax,
                         SUM(finance_transactions.fine_amount) AS total_fine #{filter_select}")

      collection_ids = @collections.collect(&:collection_id) << 0
      conditions = ["((`particular_payments`.`transaction_date` BETWEEN '#{@start_date}' AND
                                '#{@end_date}') OR particular_payments.id is null) AND
                                `ffc`.`id` IN (#{collection_ids.join(',')}) #{filter_conditions}"] + filter_values

      joins = "LEFT JOIN particular_payments
                            ON particular_payments.finance_fee_particular_id = finance_fee_particulars.id AND
                               particular_payments.is_active = true
                  LEFT JOIN particular_discounts
                            ON particular_discounts.particular_payment_id = particular_payments.id AND
                               particular_discounts.is_active = true
               INNER JOIN finance_fees ff
                            ON ff.id = particular_payments.finance_fee_id
               INNER JOIN finance_fee_collections ffc
                            ON ffc.id = ff.fee_collection_id"
      joins += filter_by_account ?
        " LEFT JOIN finance_transactions ON finance_transactions.id = particular_payments.finance_transaction_id
          LEFT JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.id = finance_transactions.id" : ""

      tax_select = ",(SELECT SUM(tax_amount) FROM tax_payments WHERE
tax_payments.taxed_entity_id = particular_payments.finance_fee_particular_id AND
tax_payments.taxed_entity_type = 'FinanceFeeParticular' AND
tax_payments.taxed_fee_id = particular_payments.finance_fee_id AND
tax_payments.taxed_fee_type = 'FinanceFee') AS tax_paid"

      collection_and_particulars = FinanceFeeParticular.find(:all, :joins => joins, :conditions => conditions,
        :select => "finance_fee_particulars.name, ffc.id AS collection_id,
                          (SUM(particular_payments.amount)) AS amount_paid,
                          IFNULL(SUM(particular_discounts.discount),0) AS discount_paid #{tax_select} #{filter_select}",
        :group => "finance_fee_particulars.name, ffc.id")

      @collection_and_particulars = collection_and_particulars.group_by(&:collection_id)

      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "fees_report"
        end
      end
    else
      render_date_error_partial
    end
    #fees_id = FinanceTransactionCategory.find_by_name('Fee').id
    #@fee_collections = FinanceFeeCollection.find(:all,:joins=>"INNER JOIN finance_fees ON finance_fees.fee_collection_id = finance_fee_collections.id INNER JOIN finance_transactions ON finance_transactions.finance_id = finance_fees.id AND finance_transactions.transaction_date >= '#{@start_date}' AND finance_transactions.transaction_date <= '#{@end_date}' AND finance_transactions.category_id = #{fees_id}",:group=>"finance_fee_collections.id")
  end

  # course-wise paid student fee details as per filters ( link via transaction report page)
  def course_wise_collection_report
    if validate_date

      filter_by_account, account_id = account_filter

      if filter_by_account
        ft_joins = [{:finance_transactions => :finance_transaction_receipt_record}]
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        filter_select = ", finance_transaction_receipt_records.fee_account_id AS account_id"
      else
        ft_joins = [:finance_transactions]
        filter_conditions = ""
        filter_values = []
        filter_select = ""
      end

      @fee_collection = FinanceFeeCollection.find(params[:id])
      @target_action = "course_wise_collection_report"
      @grand_total = FinanceFee.all(:select => "amount #{filter_select}", :joins => ft_joins,
        :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                 finance_fees.fee_collection_id = ? #{filter_conditions}",
          @start_date.to_s, @end_date.to_s, params[:id]] + filter_values).map { |x| x.amount.to_f }.sum

      @course_ids = FinanceFee.paginate(:page => params[:page], :per_page => 10,
        :joins => [{:batch => :course}, ft_joins],
        :conditions => ["(finance_transactions.transaction_date BETWEEN ? AND ?) AND
                                 finance_fees.fee_collection_id = ? #{filter_conditions}",
          @start_date, @end_date, params[:id]] + filter_values,
        :group => "finance_fees.batch_id",
        :select => "SUM(finance_transactions.amount) AS amount,courses.course_name AS course_name,
                          courses.id AS course_id,batches.id AS batch_id,batches.name AS batch_name,
                          finance_fees.batch_id AS batch_fees_id #{filter_select}")
      @grouped_course_ids = @course_ids.group_by(&:course_id)

      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "course_wise_collection_report_partial"
        end
      end
    else
      render_date_error_partial
    end
  end

  # batch-wise paid student fee details as per filters ( link via transaction report page)
  def batch_fees_report
    if validate_date
      filter_by_account, account_id = account_filter

      if filter_by_account
        ft_joins = [{:finance_transactions => :finance_transaction_receipt_record}]
        filter_conditions = "AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
        filter_select = ", finance_transaction_receipt_records.fee_account_id AS account_id"
        joins = [:finance_transaction_receipt_record]
      else
        ft_joins = [:finance_transactions]
        filter_conditions = ""
        filter_values = []
        filter_select = ""
        joins = []
      end

      @target_action="batch_fees_report"
      @fee_collection = FinanceFeeCollection.find(params[:id])
      @batch = Batch.find(params[:batch_id])

      @grand_total = FinanceTransaction.all(:select => "amount", :joins => [:finance_fees] + joins,
        :conditions => ["finance_fees.batch_id = ? AND finance_fees.fee_collection_id = ? AND
                               (finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          params[:batch_id], params[:id], @start_date.to_s, @end_date.to_s] + filter_values).map { |x| x.amount.to_f }.sum

      @transactions = FinanceTransaction.paginate(:page => params[:page], :per_page => 10,
        :include => :transaction_ledger, :select => "finance_transactions.* #{filter_select}",
        :joins => [:finance_fees, :transaction_ledger] + joins,
        :conditions => ["finance_fees.batch_id = ? AND finance_fees.fee_collection_id = ? AND
                                (finance_transactions.transaction_date BETWEEN ? AND ?) #{filter_conditions}",
          params[:batch_id], params[:id], @start_date.to_s, @end_date.to_s] + filter_values)

      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "batch_fees_report"
        end
      end
    else
      render_date_error_partial
    end
  end

  # Not in use [deprecated]
  def student_fees_structure

    month_date
    @student = Student.find(params[:id])
    @components = @student.get_fee_strucure_elements

  end

  # approve montly payslip ----------------------

  def employee_payslip_approve
    ids = params[:id].present? ? params[:id].to_a : params[:payslip_ids].split(',')
    count = EmployeePayslip.approve_payslips(ids, current_user)
    employee_payslip = EmployeePayslip.find(params[:id], :include => :payslips_date_range) if params[:id]
    flash[:notice] = "#{t('flash8', {:employee_name => employee_payslip.employee.first_name})}" if params[:id].present? and params[:from] != 'all_payslips_finance'
    case params[:from]
    when 'past_payslips_finance', 'approve_payslips'
      redirect_to :controller => 'employee_payslips', :action => 'payslip_generation_list', :id => employee_payslip.payslips_date_range.payroll_group_id, :start_date => employee_payslip.payslips_date_range.start_date, :end_date => employee_payslip.payslips_date_range.end_date, :finance => 1, :from => params[:from]
    when 'all_payslips_finance'
      render :text => count
    when 'payslips_list_finance'
      redirect_to :controller => 'employee_payslips', :action => 'view_all_employee_payslip', :id => employee_payslip.payslips_date_range.payroll_group_id, :start_date => employee_payslip.payslips_date_range.start_date, :end_date => employee_payslip.payslips_date_range.end_date, :finance => 1, :from => 'past_payslips_finance'
    when 'approve_payslips_all'
      redirect_to :controller => 'employee_payslips', :action => 'view_all_employee_payslip', :id => employee_payslip.payslips_date_range.payroll_group_id, :start_date => employee_payslip.payslips_date_range.start_date, :end_date => employee_payslip.payslips_date_range.end_date, :finance => 1, :from => 'approve_payslips'
    when 'employee_payslips_finance'
      redirect_to :controller => 'employee_payslips', :action => 'view_employee_past_payslips', :employee_id => employee_payslip.employee_id, :finance => params[:finance]
    else
      redirect_to :action => :view_monthly_payslip
    end
  end

  def employee_payslip_reject
    payslip = EmployeePayslip.find(params[:id], :include => [:employee, :payslips_date_range])
    payslip.reject_payslip(current_user, params[:reason])
    flash[:notice] = "#{t('flash30', {:employee_name => payslip.employee.first_name})}" if params[:from] != 'all_payslips_finance'
    case params[:from]
    when 'past_payslips_finance', 'approve_payslips'
      redirect_to :controller => 'employee_payslips', :action => 'payslip_generation_list', :id => payslip.payslips_date_range.payroll_group_id, :start_date => payslip.payslips_date_range.start_date, :end_date => payslip.payslips_date_range.end_date, :finance => 1, :from => params[:from]
    when 'all_payslips_finance'
      render :text => true
    when 'payslips_list_finance'
      redirect_to :controller => 'employee_payslips', :action => 'view_all_employee_payslip', :id => payslip.payslips_date_range.payroll_group_id, :start_date => payslip.payslips_date_range.start_date, :end_date => payslip.payslips_date_range.end_date, :finance => 1, :from => 'past_payslips_finance'
    when 'approve_payslips_all'
      redirect_to :controller => 'employee_payslips', :action => 'view_all_employee_payslip', :id => payslip.payslips_date_range.payroll_group_id, :start_date => payslip.payslips_date_range.start_date, :end_date => payslip.payslips_date_range.end_date, :finance => 1, :from => 'approve_payslips'
    when 'employee_payslips_finance'
      redirect_to :controller => 'employee_payslips', :action => 'view_employee_past_payslips', :employee_id => payslip.employee_id, :from => params[:from], :finance => params[:finance]
    else
      redirect_to :action => :view_monthly_payslip
    end
  end

  def payslip_revert_transaction
    ids = params[:id].present? ? params[:id].to_a : params[:payslip_ids].split(',')
    employee_payslip = EmployeePayslip.find(params[:id], :include => :payslips_date_range) if params[:id]
    count = EmployeePayslip.revert_payslips(ids)
    flash[:notice] = "#{t('flash31', {:employee_name => employee_payslip.employee.first_name})}" if params[:id].present? and params[:from] != 'all_payslips_finance'
    case params[:from]
    when 'past_payslips_finance', 'approve_payslips'
      redirect_to :controller => 'employee_payslips', :action => 'payslip_generation_list', :id => employee_payslip.payslips_date_range.payroll_group_id, :start_date => employee_payslip.payslips_date_range.start_date, :end_date => employee_payslip.payslips_date_range.end_date, :finance => 1, :from => params[:from]
    when 'all_payslips_finance'
      render :text => count
    when 'payslips_list_finance'
      redirect_to :controller => 'employee_payslips', :action => 'view_all_employee_payslip', :id => employee_payslip.payslips_date_range.payroll_group_id, :start_date => employee_payslip.payslips_date_range.start_date, :end_date => employee_payslip.payslips_date_range.end_date, :finance => 1, :from => 'past_payslips_finance'
    when 'approve_payslips_all'
      redirect_to :controller => 'employee_payslips', :action => 'view_all_employee_payslip', :id => employee_payslip.payslips_date_range.payroll_group_id, :start_date => employee_payslip.payslips_date_range.start_date, :end_date => employee_payslip.payslips_date_range.end_date, :finance => 1, :from => 'approve_payslips'
    when 'employee_payslips_finance'
      redirect_to :controller => 'employee_payslips', :action => 'view_employee_past_payslips', :employee_id => employee_payslip.employee_id, :finance => params[:finance]
    when 'employee_payslips_finance_archived'
      redirect_to :controller => 'employee_payslips', :action => 'view_employee_past_payslips', :employee_id => employee_payslip.employee_id, :from => params[:from], :finance => params[:finance], :archived => 1
    when 'finance_report'
      redirect_to :action => 'salary_employee', :id => params[:dept_id], :start_date => params[:start_date], :end_date => params[:end_date]
    else
      redirect_to :action => :view_monthly_payslip
    end
  end

  #view monthly payslip -------------------------------
  def view_monthly_payslip
    ferch_payslip_query
    @pay_period = PayrollGroup::PAYMENT_PERIOD
    @payslip_status = EmployeePayslip::PAYSLIP_STATUS
    @departments = EmployeeDepartment.active_and_ordered
    grouping = @payslip_query[:department_id] == "All" ? "dept_name" : "payment_period"
    @department_name = @payslip_query[:department_id] == "All" ? t('all_departments') : EmployeeDepartment.find(@payslip_query[:department_id]).name
    conditions = EmployeePayslip.fetch_conditions(@payslip_query)
    where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
    @payslips_list = EmployeePayslip.paginate(:select => "employee_payslips.id, emp.first_name, emp.middle_name, emp.last_name, emp.employee_number, employee_departments.name AS dept_name, emp.emp_type, payroll_groups.payment_period, payslips_date_ranges.start_date, payslips_date_ranges.end_date, employee_payslips.net_pay, employee_payslips.is_approved, employee_payslips.is_rejected, employee_payslips.payslips_date_range_id",
      :joins => "INNER JOIN ((SELECT id AS emp_id, first_name, last_name, middle_name, employee_number, employee_department_id, 'Employee' AS emp_type from employees #{where_condition}) UNION ALL (SELECT id AS emp_id,first_name, last_name, middle_name, employee_number, employee_department_id, 'ArchivedEmployee' AS emp_type from archived_employees #{where_condition})) emp ON emp.emp_id = employee_payslips.employee_id AND employee_payslips.employee_type = emp.emp_type INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id INNER JOIN employee_departments ON emp.employee_department_id = employee_departments.id",
      :conditions => conditions, :page => params[:page], :per_page => 10, :order => "#{grouping}, first_name", :include => {:payslips_date_range => :payroll_group})
    @total = EmployeePayslip.first(:select => "COUNT(DISTINCT(emp_id)) AS total_employees, COUNT(employee_payslips.id) AS total_payslips, SUM(employee_payslips.net_pay) AS total_salary, SUM(CASE WHEN employee_payslips.is_approved = true THEN employee_payslips.net_pay ELSE 0 END) AS approved_salary",
      :joins => "INNER JOIN ((SELECT id AS emp_id, first_name, last_name, middle_name, employee_number, employee_department_id, 'Employee' AS emp_type from employees #{where_condition}) UNION ALL (SELECT id AS emp_id,first_name, last_name, middle_name, employee_number, employee_department_id, 'ArchivedEmployee' AS emp_type from archived_employees #{where_condition})) emp ON emp.emp_id = employee_payslips.employee_id AND employee_payslips.employee_type = emp.emp_type  INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id INNER JOIN employee_departments ON emp.employee_department_id = employee_departments.id",
      :conditions => conditions)
    @payslips = @payslips_list.group_by(&grouping.to_sym)
    @currency_type = currency
    if request.xhr?
      unless params[:filter].to_i == 1
        render :update do |page|
          page.replace_html :payslips_list, :partial => "list_payslips"
        end
      else
        render :partial => "list_payslips"
      end
    end
  end

  def view_monthly_payslip_pdf
    @data_hash = FinanceTransaction.fetch_finance_payslip_data(params)
    render :pdf => 'view_monthly_payslip_pdf'
  end


  def view_employee_payslip
    @employee_payslip = EmployeePayslip.find(params[:id], :include => [:employee, {:payslips_date_range => :payroll_group}, {:employee_payslip_categories => :payroll_category}])
    @individual_payslips = @employee_payslip.individual_payslip_categories
    @employee = @employee_payslip.employee
    @is_present_employee = @employee.nil?
    @employee = ArchivedEmployee.find_by_former_id @employee_payslip.employee_id if @employee.nil?
    @department = EmployeeDepartment.find(params[:dept_id]) if params[:dept_id].present?
    @payroll_revision = @employee_payslip.payroll_revision.payroll_details if @employee_payslip.deducted_from_categories and @employee_payslip.payroll_revision.present?
    @attendance_details = @employee.fetch_attendance_details(@employee_payslip)
    @currency_type = currency
    @info = @employee.prev_lops_present(@employee_payslip)
  end

  #asset-liability-----------
  # render form for adding new liability
  def new_liability
    @liability=Liability.new
  end

  # records new liability
  def create_liability
    @liability = Liability.new(params[:liability])
    render :update do |page|
      if @liability.save
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg23')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @liability
        page.visual_effect(:highlight, 'form-errors')
      end
    end

  end

  # render form to edit a liability
  def edit_liability
    @liability = Liability.find(params[:id])
  end

  # update a liability
  def update_liability
    @liability = Liability.find(params[:id])
    @currency_type = currency

    render :update do |page|
      if @liability.update_attributes(params[:liability])
        @liabilities = Liability.find(:all, :conditions => 'is_deleted = 0')
        page.replace_html "liability_list", :partial => "liability_list"
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg24')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @liability
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  # view a liability details
  def view_liability
    @liabilities = Liability.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
  end

  # get liability details as a pdf
  def liability_pdf
    @liabilities = Liability.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
    render :pdf => 'liability_report_pdf'
  end

  # delete a liability
  def delete_liability
    @liability = Liability.find(params[:id])
    @liability.update_attributes(:is_deleted => true)
    @liabilities = Liability.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
    render :update do |page|
      page.replace_html "liability_list", :partial => "liability_list"
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg25')}</p>"
    end
  end

  def each_liability_view
    @liability = Liability.find(params[:id])
    @currency_type = currency
  end

  # render form for new asset
  def new_asset
    @asset = Asset.new
  end

  # record a new asset
  def create_asset
    @asset = Asset.new(params[:asset])
    render :update do |page|
      if @asset.save
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg20')}</p>"

      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @asset
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  # view an asset details
  def view_asset
    @assets = Asset.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
  end

  # get an asset details as pdf
  def asset_pdf
    @assets = Asset.find(:all, :conditions => 'is_deleted = 0')
    @currency_type = currency
    render :pdf => 'asset_report_pdf'
  end

  # edit details of an asset
  def edit_asset
    @asset = Asset.find(params[:id])
  end

  # update details of an asset
  def update_asset
    @asset = Asset.find(params[:id])
    @currency_type = currency

    render :update do |page|
      if @asset.update_attributes(params[:asset])
        @assets = Asset.find(:all, :conditions => 'is_deleted = 0')
        page.replace_html "asset_list", :partial => "asset_list"
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg21')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @asset
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  # delete an asset record
  def delete_asset
    @asset = Asset.find(params[:id])
    @asset.update_attributes(:is_deleted => true)
    @assets = Asset.all(:conditions => 'is_deleted = 0')
    @currency_type = currency
    render :update do |page|
      page.replace_html "asset_list", :partial => "asset_list"
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg22')}</p>"
    end
  end

  def each_asset_view
    @asset = Asset.find(params[:id])
    @currency_type = currency
  end

  #fees ----------------

  # Manage structures for a finance fees for creating a finance fee collection
  # 1. manage finance fee categories
  # 2. manage finance fee particulars via this page
  # 3. manage fee discounts for finance fees via this page
  # 4. manage fine / fine slabs via this page
  def master_fees
    @finance_fee_category = FinanceFeeCategory.new
    @finance_fee_particular = FinanceFeeParticular.new
    @batchs = Batch.active
    @master_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1 and batch_id=?", params[:batch_id]]) unless params[:batch_id].blank?
    @student_categories = StudentCategory.active
  end

  # render form to create a new finance fee category
  def master_category_new
    @finance_fee_category = FinanceFeeCategory.new
    @batches = Batch.active
    respond_to do |format|
      format.js { render :action => 'master_category_new' }
    end
  end

  # records a new finance fee category
  def master_category_create
    if request.post?

      if params[:finance_fee_category][:category_batches_attributes].present?
        FinanceFeeCategory.transaction do
          #          name = params[:finance_fee_category][:name]
          configure_category = params[:configure_category].present? ? params[:configure_category] : {}
          @finance_fee_category = FinanceFeeCategory.new(params[:finance_fee_category].merge(configure_category))
          #          @finance_fee_category = FinanceFeeCategory.
          #            find_or_create_by_name_and_description_and_is_deleted(name, params[:finance_fee_category][:description], false)
          @finance_fee_category.is_master = true
          unless @finance_fee_category.save
            #          if @finance_fee_category.update_attributes(params[:finance_fee_category]) and @finance_fee_category.check_name_uniqueness
            #          else
            @batch_error=true if params[:finance_fee_category][:category_batches_attributes].nil?
            @error = true
            raise ActiveRecord::Rollback
          end
        end
      else
        @batch_error=true
        cat_params = params[:configure_category].present? ? params[:finance_fee_category].merge(params[:configure_category]) : params[:finance_fee_category]
        @finance_fee_category = FinanceFeeCategory.new(cat_params)
        #        @finance_fee_category = FinanceFeeCategory.new(params[:finance_fee_category])
        @finance_fee_category.valid?
        @error = true
      end
      @master_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1"])
      respond_to do |format|
        format.js { render :action => 'master_category_create' }
      end
    end
  end

  # render form to edit a finance fee category
  def master_category_edit
    @batch=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'master_category_edit' }
    end
  end

  # update a finance fee category
  def master_category_update
    @batches=Batch.find(params[:batch_id])
    finance_fee_category = FinanceFeeCategory.find(params[:id])
    params[:finance_fee_category][:name]=params[:finance_fee_category][:name]
    fy_id = current_financial_year_id
    if (params[:finance_fee_category][:name]==finance_fee_category.name) and (params[:finance_fee_category][:description]==finance_fee_category.description)
      render :update do |page|

        @master_categories = @batches.finance_fee_categories.for_financial_year(fy_id).all_active
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'categories', :partial => 'master_category_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg13')}</p>"
        @error=false
      end
    else
      attributes=finance_fee_category.attributes
      attributes.delete_if { |key, value| ["id", "name", "description", "created_at"].include? key }
      #@finance_fee_category=FinanceFeeCategory.new(attributes)
      @error=true
      render :update do |page|
        FinanceFeeCategory.transaction do
          @finance_fee_category=FinanceFeeCategory.find_or_create_by_name_and_description_and_is_deleted(params[:finance_fee_category][:name], params[:finance_fee_category][:description], false)
          if CategoryBatch.find_by_finance_fee_category_id_and_batch_id(@finance_fee_category.id, @batches.id).present?
            @error=true
            @finance_fee_category.errors.add_to_base(t('name_already_taken'))
          else
            if @finance_fee_category.update_attributes(attributes)
              @finance_fee_category.create_associates(finance_fee_category.id, @batches.id)
              cat_batch=CategoryBatch.find_by_finance_fee_category_id_and_batch_id(finance_fee_category.id, @batches.id)
              cat_batch.destroy if cat_batch
              finance_fee_category.update_attributes(:is_deleted => true) unless finance_fee_category.category_batches.present?
              @master_categories = @batches.finance_fee_categories.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = 1 "])

              if @finance_fee_category.check_category_name_exists(@batches)
                page.replace_html 'form-errors', :text => ''
                page << "Modalbox.hide();"
                page.replace_html 'categories', :partial => 'master_category_list'
                page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg13')}</p>"
                @error=false
              else
                @error=true
                @finance_fee_category.errors.add_to_base(t('name_already_taken'))
              end
            end
          end
          if @error
            page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_category

            page.visual_effect(:highlight, 'form-errors')
            raise ActiveRecord::Rollback
          end


        end
      end

    end
  end

  # render form to update tax slab for a finance fee particular
  # Any changes will be effective for a new finance fee collection only
  # TaxSlabAssignment tracks tax slab associated with a finance fee particular (as a structure only)
  # Note: (doesn't change tax slab for finance fee particular under an existing collection)
  def master_particular_tax_slab_update
    @tax_slabs = TaxSlab.all if @tax_enabled
    include_associations = @tax_enabled ? [:tax_slabs] : []
    @finance_fee_particular = FinanceFeeParticular.find(params[:id],
      :include => include_associations)
    if request.put? and params[:finance_fee_particular].present?
      #      flash[:notice] = res ? t('tax_slabs.flash2') : t('tax_slabs.flash7')
      #      redirect_to :action => "master_category_particulars"
      render :update do |page|
        if @finance_fee_particular.update_tax_slab(params[:finance_fee_particular][:tax_slab_id])
          @finance_fee_category = FinanceFeeCategory.find(@finance_fee_particular.finance_fee_category_id)
          @batch = @finance_fee_particular.batch
          @particulars = FinanceFeeParticular.paginate(:page => params[:page],
            :include => include_associations, :conditions => ["is_deleted = '#{false}' and
            finance_fee_category_id = '#{@finance_fee_category.id}' and 
            batch_id='#{@batch.id}'"])
          page.replace_html 'form-errors', :text => ''
          page << "Modalbox.hide();"
          page.replace_html 'categories', :partial => 'master_particulars_list'
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('tax_slabs.flash2')}</p>"
        else
          page.replace_html 'form-errors', :text => t('tax_slabs.flash7') #:partial => 'class_timings/errors', :object => @feeparticulars
          page.visual_effect(:highlight, 'form-errors')
        end
      end
    else
      respond_to do |format|
        format.js { render :action => 'master_particular_tax_slab_update' }
      end
    end
  end

  # list active finance fee particulars for a finance fee category associated to a selected batch
  # Note:: list is filtered by active financial year
  def master_category_particulars
    @batch=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    #categories=FinanceFeeCategory.find(:all,:include=>:category_batches,:conditions=>"name=@finance_fee_category.name and description=@finance_fee_category.description and is_deleted=#{false}").map{|d| d if d.category_batches.empty?}.compact
    #    categories=FinanceFeeCategory.find(:all,:include=>:category_batches,:conditions=>"name='#{@finance_fee_category.name}' and description='#{@finance_fee_category.description}' and is_deleted=#{false}").uniq.map{|d| d if d.batch_id==@batch.id}.compact
    #    if categories.present?
    #      @finance_fee_category = FinanceFeeCategory.find_by_name_and_batch_id_and_is_deleted(@finance_fee_category.name,@batch.id,false)
    #    end
    #@particulars = FinanceFeeParticular.paginate(:page => params[:page],:joins=>"INNER JOIN finance_fee_categories on finance_fee_categories.id=finance_fee_particulars.finance_fee_category_id",:conditions => ["finance_fee_particulars.is_deleted = '#{false}' and finance_fee_categories.name = '#{@finance_fee_category.name}' and finance_fee_categories.description = '#{@finance_fee_category.description}' and finance_fee_particulars.batch_id='#{@batch.id}' "])
    include_associations = [:collection_particulars, :master_fee_particular]
    include_associations += [:tax_slabs] if @tax_enabled
    @particulars = FinanceFeeParticular.paginate(:page => params[:page],
      :include => include_associations, :conditions => ["is_deleted = '#{false}' and
      finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@batch.id}' "])

  end

  # render form to edit a finance fee particular
  def master_category_particulars_edit
    @tax_slabs = TaxSlab.all if @tax_enabled
    include_associations = @tax_enabled ? [:tax_slabs] : []
    @finance_fee_particular= FinanceFeeParticular.find(params[:id],
      :include => include_associations)
    @master_fee_particulars = MasterFeeParticular.core
    @student_categories = StudentCategory.active
    unless @finance_fee_particular.student_category.present? and @student_categories.collect(&:name).include?(@finance_fee_particular.student_category.name)
      current_student_category=@finance_fee_particular.student_category
      @student_categories << current_student_category if current_student_category.present?
    end
    respond_to do |format|
      format.js { render :action => 'master_category_particulars_edit' }
    end
  end

  # update changes to finance fee particular
  def master_category_particulars_update
    include_associations = @tax_enabled ? [:tax_slabs] : []
    @feeparticulars = FinanceFeeParticular.find(params[:id])
    render :update do |page|
      #params[:finance_fee_particular][:student_category_id]="" if params[:finance_fee_particular][:student_category_id].nil?
      if @feeparticulars.collection_exist
        if @feeparticulars.update_attributes(params[:finance_fee_particular])
          @finance_fee_category = FinanceFeeCategory.find(@feeparticulars.finance_fee_category_id)
          @particulars = FinanceFeeParticular.paginate(:page => params[:page],
            :include => include_associations, :conditions => ["is_deleted = '#{false}' and
            finance_fee_category_id = '#{@finance_fee_category.id}' and 
            batch_id='#{@feeparticulars.batch_id}'"])
          @batch=@feeparticulars.batch
          page.replace_html 'form-errors', :text => ''
          page << "Modalbox.hide();"
          page.replace_html 'categories', :partial => 'master_particulars_list'
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg14')}</p>"
        else
          page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @feeparticulars
          page.visual_effect(:highlight, 'form-errors')
        end
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @feeparticulars
        page.visual_effect(:highlight, 'form-errors')
      end
    end
    #    respond_to do |format|
    #      format.js { render :action => 'master_category_particulars' }
    #    end
  end

  # marks a finance fee particular soft deleted (is_deleted => true)
  def master_category_particulars_delete
    include_associations = @tax_enabled ? [:tax_slabs] : []
    @feeparticular = FinanceFeeParticular.find(params[:id])
    @batch=@feeparticular.batch
    #discounts=@feeparticular.finance_fee_category.fee_discounts.all(:conditions=>"batch_id=#{@feeparticular.batch_id}")
    @error=true unless @feeparticular.delete_particular
    @finance_fee_category = FinanceFeeCategory.find(@feeparticular.finance_fee_category_id)
    @particulars = FinanceFeeParticular.paginate(:page => params[:page],
      :include => include_associations, :conditions => ["is_deleted = '#{false}' and
      finance_fee_category_id = '#{@finance_fee_category.id}' and 
      batch_id='#{@feeparticular.batch_id}' "])

  end

  # Removes linking betweeen batches and finance fee category and marks finance fee category soft deleted (is_deleted => true)
  def master_category_delete
    @error=false
    @batches=Batch.find(params[:batch_id])
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @catbatch=CategoryBatch.find_by_finance_fee_category_id_and_batch_id(params[:id], params[:batch_id])
    unless @catbatch.destroy
      @catbatch.errors.add_to_base(t('fee_collection_exists_cant_delete_this_category'))
      @error=true
    end
    @finance_fee_category.update_attributes(:is_deleted => true) unless @finance_fee_category.category_batches.present?
    #@finance_fee_category.delete_particulars
    fy_id = current_financial_year_id
    @master_categories = @batches.finance_fee_categories.for_financial_year(fy_id).all_active
    respond_to do |format|
      format.js { render :action => 'master_category_delete' }
    end
  end

  # lists active finance fee categories for selected batch
  # Note: list is filtered by active financial year
  def show_master_categories_list
    unless params[:id].empty?
      @finance_fee_category = FinanceFeeCategory.new
      @finance_fee_particular = FinanceFeeParticular.new
      @batches = Batch.find params[:id] unless params[:id] == ""
      fy_id = current_financial_year_id
      @master_categories = @batches.finance_fee_categories.for_financial_year(fy_id).all_active
      #@master_categories = FinanceFeeCategory.find(:all,:conditions=> ["is_deleted = '#{false}' and is_master = 1 and batch_id=?",params[:id]])
      @student_categories = StudentCategory.active

      render :update do |page|
        page.replace_html 'categories', :partial => 'master_category_list'
      end
    else
      render :update do |page|
        page.replace_html 'categories', :text => ""
      end
    end
  end

  # render form for new finance fee particular
  def fees_particulars_new
    @finance_fee_particular = FinanceFeeParticular.new(params[:finance_fee_particular])
    @master_fee_particulars = MasterFeeParticular.core
    @tax_slabs = TaxSlab.all if @tax_enabled
    fy_id = current_financial_year_id
    @fees_categories = FinanceFeeCategory.all(:select => "DISTINCT finance_fee_categories.*",
      :joins => "INNER JOIN category_batches ON category_batches.finance_fee_category_id = finance_fee_categories.id
                  INNER JOIN batches ON batches.id = category_batches.batch_id AND batches.is_active = true AND batches.is_deleted =  false",
      :conditions => ["finance_fee_categories.is_deleted = 0 AND finance_fee_categories.is_master = 1 AND
                        financial_year_id #{fy_id.present? ? '=' : 'IS'} ?", fy_id], :order => "name ASC")

    @student_categories = StudentCategory.active
    @all = true
    @student = false
    @category = false
  end

  # fetches finance fee categories associated with selected batch
  # Note: list is filtered by active financial year
  def list_category_batch
    fee_category=FinanceFeeCategory.find(params[:category_id])
    #@batches= Batch.find(:all,:joins=>"INNER JOIN `category_batches` ON `batches`.id = `category_batches`.batch_id INNER JOIN finance_fee_categories on finance_fee_categories.id=category_batches.finance_fee_category_id INNER JOIN courses on courses.id=batches.course_id",:conditions=>"finance_fee_categories.name = '#{fee_category.name}' and finance_fee_categories.description = '#{fee_category.description}'",:order=>"courses.code ASC")
    @batches=Batch.active.find(:all, :joins => [{:category_batches => :finance_fee_category}, :course], :conditions => "finance_fee_categories.id =#{fee_category.id}", :order => "courses.code ASC").uniq
    #@batches=fee_category.batches.all(:order=>"name ASC")
    render :update do |page|
      page.replace_html 'list-category-batch', :partial => 'list_category_batch'
    end
  end

  # records new finance fee particular
  def fees_particulars_create
    if request.get?
      redirect_to :action => "fees_particulars_new"
    else
      @finance_category=FinanceFeeCategory.find_by_id(params[:finance_fee_particular][:finance_fee_category_id])
      @tax_slabs = TaxSlab.all if @tax_enabled
      @batches= Batch.find(:all,
        :joins => "INNER JOIN `category_batches` ON `batches`.id = `category_batches`.batch_id
                        INNER JOIN finance_fee_categories on finance_fee_categories.id=category_batches.finance_fee_category_id 
                        INNER JOIN courses on courses.id=batches.course_id",
        :conditions => ["finance_fee_categories.name = ? and finance_fee_categories.description = ?",
          "#{@finance_category.name}", "#{@finance_category.description}"],
        :order => "courses.code ASC") if @finance_category
      if params[:particular] and params[:particular][:batch_ids]
        batches=Batch.find(params[:particular][:batch_ids])
        @cat_ids=params[:particular][:batch_ids]
        if params[:particular][:receiver_id].present?
          all_admission_no = admission_no=params[:particular][:receiver_id].split(',')
          all_students = batches.map { |b| b.students.map { |stu| stu.admission_no } }.flatten
          rejected_admission_no = admission_no.select { |adm| !all_students.include? adm }
          unless (rejected_admission_no.empty?)
            @error = true
            @finance_fee_particular = FinanceFeeParticular.new(params[:finance_fee_particular])
            @finance_fee_particular.batch_id=1
            @finance_fee_particular.save
            @finance_fee_particular.errors.add_to_base("#{rejected_admission_no.join(',')} #{t('does_not_belong_to_batch')} #{batches.map { |batch| batch.full_name }.join(',')}")
          end

          selected_admission_no = all_admission_no.select { |adm| all_students.include? adm }
          selected_admission_no.each do |a|
            s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
            if s.nil?
              @error = true
              @finance_fee_particular = FinanceFeeParticular.new(params[:finance_fee_particular])
              @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{a} #{t('does_not_exist')}")
            end
          end
          unless @error

            selected_admission_no.each do |a|
              s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
              batch=s.batch
              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @finance_fee_particular.receiver_id=s.id
              @error = true unless @finance_fee_particular.save
            end
          end
        else
          batches.each do |batch|
            if params[:finance_fee_particular][:receiver_type]=="Batch"

              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @finance_fee_particular.receiver_id=batch.id
              @error = true unless @finance_fee_particular.save
            elsif params[:finance_fee_particular][:receiver_type]=="StudentCategory"
              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @error = true unless @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{t('category_cant_be_blank')}") if params[:finance_fee_particular][:receiver_id]==""
            else

              @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
              @error = true unless @finance_fee_particular.save
              @finance_fee_particular.errors.add_to_base("#{t('admission_no_cant_be_blank')}")
            end

          end
        end
      else
        @error=true
        @finance_fee_particular =FinanceFeeParticular.new(params[:finance_fee_particular])
        @finance_fee_particular.save
      end

      if @error
        @fees_categories = FinanceFeeCategory.find(:all, :group => :name, :conditions => "is_deleted = 0 and is_master = 1")
        @student_categories = StudentCategory.active
        @master_fee_particulars = MasterFeeParticular.core
        @render=true
        if params[:finance_fee_particular][:receiver_type]=="Student"
          @student=true
        elsif params[:finance_fee_particular][:receiver_type]=="StudentCategory"
          @category=true
        else
          @all=true
        end

        render :action => 'fees_particulars_new'
      else
        flash[:notice]="#{t('particulars_created_successfully')}"
        redirect_to :action => "fees_particulars_new"
      end
    end
  end

  # render form creating new finance fee particular (from master category particulars page)
  def fees_particulars_new2
    @batch=Batch.find(params[:batch_id])
    @master_fee_particulars = MasterFeeParticular.core
    @fees_category = FinanceFeeCategory.find(params[:category_id])
    @tax_slabs = TaxSlab.all if @tax_enabled
    @student_categories = StudentCategory.active
    respond_to do |format|
      format.js { render :action => 'fees_particulars_new2' }
    end
  end

  # records finance fee particular (from master category particulars page)
  def fees_particulars_create2
    batch=Batch.find(params[:finance_fee_particular][:batch_id])
    @tax_slabs = TaxSlab.all if @tax_enabled
    if params[:particular] and params[:particular][:receiver_id]

      all_admission_no = admission_no=params[:particular][:receiver_id].split(',')
      all_students = batch.students.map { |stu| stu.admission_no }.flatten
      rejected_admission_no = admission_no.select { |adm| !all_students.include? adm }
      unless (rejected_admission_no.empty?)
        @error = true
        @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
        @finance_fee_particular.save
        @finance_fee_particular.errors.add_to_base("#{rejected_admission_no.join(',')} #{t('does_not_belong_to_batch')} #{batch.full_name}")
      end

      selected_admission_no = all_admission_no.select { |adm| all_students.include? adm }
      selected_admission_no.each do |a|
        s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
        if s.nil?
          @error = true
          @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
          @finance_fee_particular.save
          @finance_fee_particular.errors.add_to_base("#{a} #{t('does_not_exist')}")
        end
      end
      unless @error
        unless selected_admission_no.present?
          @finance_fee_particular=batch.finance_fee_particulars.new(params[:finance_fee_particular])
          @finance_fee_particular.save
          @finance_fee_particular.errors.add_to_base("#{t('admission_no_cant_be_blank')}")
          @error = true
        else
          selected_admission_no.each do |a|
            s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
            @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
            @finance_fee_particular.receiver_id=s.id
            @error = true unless @finance_fee_particular.save
          end
        end
      end
    elsif params[:finance_fee_particular][:receiver_type]=="Batch"

      @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
      @finance_fee_particular.receiver_id=batch.id
      @error = true unless @finance_fee_particular.save
    else
      @finance_fee_particular = batch.finance_fee_particulars.new(params[:finance_fee_particular])
      @error = true unless @finance_fee_particular.save
      @finance_fee_particular.errors.add_to_base("#{t('category_cant_be_blank')}") if params[:finance_fee_particular][:receiver_id]==""
    end
    @batch=batch
    @finance_fee_category = FinanceFeeCategory.find(params[:finance_fee_particular][:finance_fee_category_id])
    include_associations = @tax_enabled ? [:tax_slabs] : []
    @particulars = FinanceFeeParticular.paginate(:page => params[:page],
      :include => include_associations, :conditions => ["is_deleted = '#{false}' and
      finance_fee_category_id = '#{@finance_fee_category.id}' and batch_id='#{@batch.id}' "])

  end

  # not in use
  def additional_fees_create_form
    @batches = Batch.active
    @student_categories = StudentCategory.active
  end

  # not in use
  def additional_fees_create

    batch = params[:additional_fees][:batch_id] unless params[:additional_fees][:batch_id].nil?
    # batch ||=[]
    @batches = Batch.active
    @user = current_user
    @students = Student.find_all_by_batch_id(batch) unless batch.nil?
    @additional_category = FinanceFeeCategory.new(
      :name => params[:additional_fees][:name],
      :description => params[:additional_fees][:description],
      :batch_id => params[:additional_fees][:batch_id]
    )
    if params[:additional_fees][:due_date].to_date >= params[:additional_fees][:end_date].to_date
      if @additional_category.save && params[:additional_fees][:start_date].strip.length!=0 && params[:additional_fees][:due_date].strip.length!=0 && params[:additional_fees][:end_date].strip.length!=0
        # fetching account id
        account = @additional_category.get_multi_config[:account]
        account_id = (account.is_a?(Fixnum) ? account : (account.is_a?(FeeAccount) ? account.try(:id) : nil))

        @collection_date = FinanceFeeCollection.create(
          :name => @additional_category.name,
          :start_date => params[:additional_fees][:start_date],
          :end_date => params[:additional_fees][:end_date],
          :due_date => params[:additional_fees][:due_date],
          :batch_id => params[:additional_fees][:batch_id],
          :fee_category_id => @additional_category.id,
          :fee_account_id => account_id
        )
        body = "<p>#{t('fee_collection_date_for')} "+@additional_category.name+" #{t('has_been_published')} <br />
                               #{t('fees_submiting_date_starts_on')}< br />
                               #{t('start_date')} : "+format_date(@collection_date.start_date)+" <br />"+
          "#{t('end_date')} : "+format_date(@collection_date.end_date)+" <br />"+
          "#{t('due_date')} : "+format_date(@collection_date.due_date)
        @due_date = @collection_date.due_date.strftime("%Y-%b-%d") + " 00:00:00"
        unless batch.empty?
          @students.each do |s|
            FinanceFee.create(:student_id => s.id, :fee_collection_id => @collection_date.id)
            #            Reminder.create(:sender => @user.id, :recipient => s.id, :subject => subject,
            #              :body => body, :is_read => false, :is_deleted_by_sender => false, :is_deleted_by_recipient => false)
          end
          recipient_ids = @students.collect(&:user_id)
          inform(recipient_ids, body, "Finance")
          Event.create(:title => "#{t('fees_due')}", :description => @additional_category.name, :start_date => @due_date.to_datetime, :end_date => @due_date.to_datetime, :is_due => true, :origin => @collection_date)
        else
          recipient_ids = []
          @batches.each do |b|
            @students = Student.find_all_by_batch_id(b.id)
            @students.each do |s|
              FinanceFee.create(:student_id => s.id, :fee_collection_id => @collection_date.id)
              recipient_ids << s.user_id
              #              Reminder.create(:sender => @user.id, :recipient => s.user.id, :subject => subject,
              #                :body => body, :is_read => false, :is_deleted_by_sender => false, :is_deleted_by_recipient => false)
            end
          end
          inform(recipient_ids, body, "Finance")
          Event.create(:title => "#{t('fees_due')}", :description => @additional_category.name, :start_date => @due_date.to_datetime, :end_date => @due_date.to_datetime, :is_due => true, :origin => @collection_date)
        end
        flash[:notice] = "#{t('flash9')}"
        redirect_to(:action => "add_particulars", :id => @collection_date.id)
      else
        flash[:notice] = "#{t('flash10')}"
        redirect_to :action => "additional_fees_create_form"
      end
    else
      flash[:notice] = "#{t('flash11')}"
      redirect_to :action => "additional_fees_create_form"
    end
  end

  # not in use
  def additional_fees_edit
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@finance_fee_category.id)
    respond_to do |format|
      format.js { render :action => 'additional_fees_edit' }
    end
    flash[:notice] = "#{t('flash26')}"
  end

  # not in use
  def additional_fees_update
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@finance_fee_category.id)
    #    render :update do |page|

    if @finance_fee_category.update_attributes(:name => params[:finance_fee_category][:name], :description => params[:finance_fee_category][:description])
      if @collection_date.update_attributes(:start_date => params[:additional_fees][:start_date], :end_date => params[:additional_fees][:end_date], :due_date => params[:additional_fees][:due_date])
        @collection_date.event.update_attributes(:start_date => @collection_date.due_date.to_datetime, :end_date => @collection_date.due_date.to_datetime)
        @additional_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = '#{false}' and batch_id = '#{@finance_fee_category.batch_id}'"])
        #        page.replace_html 'form-errors', :text => ''
        #        page << "Modalbox.hide();"
        #        page.replace_html 'particulars', :partial => 'additional_fees_list'
        #        end
      else
        @error = true
      end
    else
      #        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_category
      #        page.visual_effect(:highlight, 'form-errors')
      @error = true
    end
    #    end
  end

  # not in use
  def additional_fees_delete
    @finance_fee_category = FinanceFeeCategory.find(params[:id])
    @finance_fee_category.update_attributes(:is_deleted => true)
    @finance_fee_collection = FinanceFeeCollection.find_by_fee_category_id(params[:id])
    @finance_fee_collection.update_attributes(:is_deleted => true)
    @finance_fee_category.delete_particulars
    # redirect_to :action => "additional_fees_list"
    @additional_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = '#{false}' and batch_id = '#{@finance_fee_category.batch_id}'"])
    respond_to do |format|
      format.js { render :action => 'additional_fees_delete' }
      flash[:notice] = "#{t('flash27')}"
    end
  end

  # not in use
  def add_particulars
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @student_categories = StudentCategory.active
    @finance_fee_particulars = FeeCollectionParticular.new
    @finance_fee_particulars_list = FeeCollectionParticular.find(:all, :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"])
  end

  # not in use
  def add_particulars_new
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @student_categories = StudentCategory.active
    @finance_fee_particulars = FeeCollectionParticular.new
  end

  # not in use
  def add_particulars_create
    @collection_date = FinanceFeeCollection.find(params[:id])
    @additional_category = FinanceFeeCategory.find(@collection_date.fee_category_id)
    @error = false
    unless params[:finance_fee_particulars][:admission_no].nil?
      unless params[:finance_fee_particulars][:admission_no].empty?
        posted_params = params[:finance_fee_particulars]
        admission_no = posted_params[:admission_no].split(",")
        posted_params.delete "admission_no"
        err = ""
        admission_no.each do |a|
          posted_params["admission_no"] = a.to_s
          @finance_fee_particulars = FeeCollectionParticular.new(posted_params)
          @finance_fee_particulars.finance_fee_collection_id = @collection_date.id
          s = Student.first(:conditions => ["admission_no LIKE BINARY(?)", a])
          unless s.nil?
            if (s.batch_id == @collection_date.batch_id) or (@collection_date.batch_id.nil?)
              unless @finance_fee_particulars.save
                @error = true
              end
            else
              @error = true
              err = err + "#{a}#{t('does_not_belong_to_batch')} #{@collection_date.batch.full_name}. <br />"
            end
          else
            @error = true
            err = err + "#{a} #{t('does_not_exist')}<br />"
          end
        end
        @finance_fee_particulars.errors.add(:admission_no, " #{t('invalid')} : <br />" + err) if @error==true
        @finance_fee_particulars_list = FeeCollectionParticular.find(:all, :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"]) unless @error== true
      else
        @error = true
        @finance_fee_particulars = FeeCollectionParticular.new(params[:finance_fee_particulars])
        @finance_fee_particulars.valid?
        @finance_fee_particulars.errors.add(:admission_no, "#{t('is_blank')}")
      end
    else
      @finance_fee_particulars = FeeCollectionParticular.new(params[:finance_fee_particulars])
      @finance_fee_particulars.finance_fee_collection_id = @collection_date.id
      unless @finance_fee_particulars.save
        @error = true
      else
        @finance_fee_particulars_list = FeeCollectionParticular.find(:all, :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}'"])
      end

    end
  end

  def student_or_student_category
    @student_categories = StudentCategory.active

    select_value = params[:select_value]

    if select_value == "StudentCategory"
      render :update do |page|
        page.replace_html "student", :partial => "student_category_particulars"
      end
    elsif select_value == "Student"
      render :update do |page|
        page.replace_html "student", :partial => "student_admission_particulars"
      end
    elsif select_value == "Batch"
      render :update do |page|
        page.replace_html "student", :text => ""
      end
    end
  end

  def additional_fees_list
    @batchs=Batch.active
    #@additional_categories = FinanceFeeCategory.paginate(:page => params[:page],:conditions => ["is_deleted = '#{false}' and is_master = '#{false}'"])
  end

  def show_additional_fees_list
    @additional_categories = FinanceFeeCategory.find(:all, :conditions => ["is_deleted = '#{false}' and is_master = '#{false}' and batch_id=?", params[:id]])
    render :update do |page|
      page.replace_html 'particulars', :partial => 'additional_fees_list'
    end
  end

  def additional_particulars
    @additional_category = FinanceFeeCategory.find(params[:id])
    @collection_date = FinanceFeeCollection.find_by_fee_category_id(@additional_category.id)
    @particulars = FeeCollectionParticular.find(:all, :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
  end

  def add_particulars_edit
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
  end

  def add_particulars_update
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
    render :update do |page|
      if @finance_fee_particulars.update_attributes(params[:finance_fee_particulars])
        @collection_date = @finance_fee_particulars.finance_fee_collection
        @additional_category =@collection_date.fee_category
        @particulars = FeeCollectionParticular.paginate(:page => params[:page], :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'particulars', :partial => 'additional_particulars_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg32')}</p>"
      else
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_particulars
        page.visual_effect(:highlight, 'form-errors')
      end
    end
  end

  def add_particulars_delete
    @finance_fee_particulars = FeeCollectionParticular.find(params[:id])
    @finance_fee_particulars.update_attributes(:is_deleted => true)
    @collection_date = @finance_fee_particulars.finance_fee_collection
    @additional_category =@collection_date.fee_category
    @particulars = FeeCollectionParticular.paginate(:page => params[:page], :conditions => ["is_deleted = '#{false}' and finance_fee_collection_id = '#{@collection_date.id}' "])
    render :update do |page|
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('particulars_deleted_successfully')}</p>"
      page.replace_html 'particulars', :partial => 'additional_particulars_list'
    end
  end

  def fee_collection_batch_update
    fee_collection_batch_update_data
    render :update do |page|
      page.replace_html "batchs", :partial => "fee_collection_batchs"
    end

  end

  def fee_collection_batch_update_data fee_category_id = nil
    if (fee_category_id || params[:id]).present?
      cat_id = [fee_category_id || params[:id]].compact
      @fee_category = FinanceFeeCategory.find_all_by_id(cat_id)
      @batches = Batch.active.find(:all, :joins => [{:finance_fee_particulars => :finance_fee_category}, :course],
        :conditions => ["finance_fee_categories.id = ? and finance_fee_particulars.is_deleted=#{false}",
          @fee_category.map(&:id).try(:last)], :order => "courses.code ASC").uniq
    end
  end

  def fee_collection_batch_update_for_fee_collection
    linking_required = FinanceFeeParticular.has_unlinked_particulars?(params[:id])
    @category_id = params[:id]
    # if linking_required and @category_id.present?
    #   render :update do |page|
    #     page.replace_html "form-errors", :partial => "finance/fees_payment/notice_link_particulars"
    #     page.replace_html "batchs", :text => ""
    #   end
    # else
    fee_collection_batch_update_data
    render :update do |page|
      page.replace_html "form-errors", :text => ""
      page.replace_html "batchs", :partial => "fee_collection_batches_for_fee_collection"
    end
    # end
  end

  # render form for new finance fee collection
  def fee_collection_new
    @fines = Fine.active
    fy_id = current_financial_year_id
    @fee_categories = FinanceFeeCategory.all(:select => "DISTINCT finance_fee_categories.*",
      :joins => [{:category_batches => :batch}, :fee_particulars],
      :conditions => ["batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0 AND
                       finance_fee_particulars.is_deleted = 0 AND financial_year_id #{fy_id.present? ? '=' : 'IS'} ?", fy_id])

    @finance_fee_collection = FinanceFeeCollection.new({:discount_mode => @school_discount_mode,
        :financial_year_id => fy_id})
    @start_date, @end_date = FinancialYear.fetch_current_range

    deliver_plugin_block :fedena_reminder do
      @finance_fee_collection.build_alert_settings
    end
  end

  # records new finance fee collection
  def fee_collection_create
    fy_id = current_financial_year_id
    @user = current_user
    @fee_categories = FinanceFeeCategory.all(:select => "DISTINCT finance_fee_categories.*",
      :joins => [{:category_batches => :batch}, :fee_particulars],
      :conditions => ["batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0 AND
                       finance_fee_particulars.is_deleted = 0 AND financial_year_id #{fy_id.present? ? '=' : 'IS'} ?", fy_id])
    unless params[:finance_fee_collection].nil?
      fee_category_name = params[:finance_fee_collection][:fee_category_id]
      @fee_category = FinanceFeeCategory.find_all_by_id(fee_category_name, :conditions => ['is_deleted is false'])
    end
    category = []
    @finance_fee_collection = FinanceFeeCollection.new({:discount_mode => @school_discount_mode,
        :financial_year_id => fy_id})
    if request.post?
      param = params[:finance_fee_collection].merge({:financial_year_id => fy_id})
      @finance_fee_collection = FinanceFeeCollection.new(param.merge({:discount_mode => @school_discount_mode}))
      if @finance_fee_collection.valid?
        Delayed::Job.enqueue(DelayedFeeCollectionJob.new(@user, param, params[:fee_collection]), {:queue => "fee_collections"})

        flash[:notice] = "Collection is in queue. <a href='/scheduled_jobs/FinanceFeeCollection/1'>Click Here</a> to view the scheduled job."
        redirect_to :action => 'fee_collection_new'
      else
        fee_collection_batch_update_data(fee_category_name)
        @fines = Fine.active
        render :action => 'fee_collection_new'
      end
    else
      redirect_to :action => 'fee_collection_new'
    end
  end

  # view finance fee collection details
  def fee_collection_view
    @batchs = Batch.active
  end

  def fee_collection_dates_batch
    if params[:id].present?
      @batch= Batch.find(params[:id])
      @finance_fee_collections = @batch.finance_fee_collections.current_active_financial_year.
        all(:include => {:collection_discounts =>
            {:fee_discount => :multi_fee_discount}},
        :conditions => "#{active_account_conditions}",
        # :conditions => "(finance_fee_collections.fee_account_id IS NULL OR
        #                  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
        :joins => "#{active_account_joins}")
      render :update do |page|
        page.replace_html 'fee_collection_dates', :partial => 'fee_collection_dates_batch'
        page.replace_html "financial_year_details", :partial => 'financial_year_info'
      end
    else
      render :update do |page|
        page.replace_html 'fee_collection_dates', :text => ''
        page.replace_html "financial_year_details", :partial => 'financial_year_info'
      end
    end
  end

  # render form to edit a finance fee collection
  def fee_collection_edit
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
    @batch=Batch.find(params[:batch_id])
  end

  # update a finance fee collection
  def fee_collection_update
    @batch=Batch.find(params[:batch_id])
    @user = current_user
    finance_fee_collection = FinanceFeeCollection.find params[:id]
    @old_collection=finance_fee_collection
    attributes = finance_fee_collection.attributes
    attributes.delete_if { |key, value| ["id", "name", "start_date", "due_date", "created_at"].include? key }
    @finance_fee_collection=FinanceFeeCollection.new(attributes)
    @error = true
    events = @finance_fee_collection.event
    @students = Student.find(:all, :joins => "INNER JOIN finance_fees ON finance_fees.student_id=students.id",
      :conditions => "students.batch_id=#{@batch.id} and students.has_paid_fees=0 and
                              finance_fees.fee_collection_id=#{finance_fee_collection.id} and 
                              students.has_paid_fees_for_batch=0")
    render :update do |page|
      FinanceFeeCollection.transaction do
        @old_collection.attributes=params[:finance_fee_collection]
        unless (@old_collection.changed?)
          @error = false
        else
          if @finance_fee_collection.update_attributes(params[:finance_fee_collection])
            if @old_collection.event
              new_event = @old_collection.event
              new_event.description = @finance_fee_collection.name
              new_event.start_date = @finance_fee_collection.due_date.to_datetime
              new_event.end_date = @finance_fee_collection.due_date.to_datetime
              new_event.origin = @finance_fee_collection
              new_event.save
            end

            fee_collection_batch=FeeCollectionBatch.find(:first, :conditions =>
                "finance_fee_collection_id='#{@old_collection.id}' and batch_id='#{@batch.id}'")
            if fee_collection_batch.present?
              fee_collection_batch.finance_fee_collection_id=@finance_fee_collection.id
              fee_collection_batch.save
            end
            # destroy link between collection & discounts
            CollectionDiscount.find(:all, :joins => [:finance_fee_collection, :fee_discount],
              :conditions => "fee_discounts.batch_id='#{@batch.id}' and
                                      finance_fee_collections.id='#{@old_collection.id}'").each do |cd|
              collection_discount_attributes=cd.attributes
              collection_discount_attributes.delete 'id'
              collection_discount=CollectionDiscount.new(collection_discount_attributes)
              collection_discount.finance_fee_collection_id=@finance_fee_collection.id
              collection_discount.save
              cd.destroy
            end

            linked_particular_ids = []
            # destroy link between collection & particulars
            CollectionParticular.find(:all, :joins => [:finance_fee_collection, :finance_fee_particular],
              :conditions => "finance_fee_particulars.batch_id='#{@batch.id}' and
                                      finance_fee_collections.id='#{@old_collection.id}'").each do |cp|
              collection_particular_attributes=cp.attributes
              collection_particular_attributes.delete 'id'
              collection_particular=CollectionParticular.new(collection_particular_attributes)
              collection_particular.finance_fee_collection_id=@finance_fee_collection.id
              linked_particular_ids << collection_particular.finance_fee_particular_id
              collection_particular.save
              cp.destroy
            end

            if @old_collection.tax_enabled?
              CollectibleTaxSlab.update_all({:collection_id => @finance_fee_collection.id}, {
                  :collectible_entity_id => linked_particular_ids, :collectible_entity_type =>
                    'FinanceFeeParticular', :collection_id => @old_collection.id, :collection_type =>
                    "FinanceFeeCollection", :school_id => @old_collection.school_id})
            end

            if @old_collection.batches.empty?
              @old_collection.update_attributes(:is_deleted => true)
            end

            @error=false

            fee_collection_name = @finance_fee_collection.name
            body = "#{t('fee_collection_date_for')} <b>#{fee_collection_name}</b> #{t('has_been_updated')}"
            recipient_ids = []
            if @old_collection.invoice_enabled
              old_finance_fees = FinanceFee.all(:select => "id as fee_id, student_id",
                :conditions => "batch_id='#{params[:batch_id]}' and
                                          fee_collection_id='#{@old_collection.id}'").group_by(&:student_id)
              no_fee_recs = old_finance_fees.keys.length
              old_fee_ids = old_finance_fees.values.flatten.map(&:fee_id)
              invoices_exists = no_fee_recs > 0 ? FeeInvoice.is_generated_for_collection?(@old_collection) : false
            end
            FinanceFee.destroy_all("batch_id='#{params[:batch_id]}' and fee_collection_id='#{@old_collection.id}'")
            # to prevent invoice number generation for these finance fee records
            # as we will re-link old invoice numbers
            # Only if collection is invoice enabled and there are fee records with invoice numbers generated
            if @students.present?
              if invoices_exists
                @finance_fee_collection.invoice_enabled = false
                update_fee_invoice_sql = "UPDATE fee_invoices SET fee_id = (CASE "
              end
              @students.each do |s|
                unless s.has_paid_fees
                  new_student_fee = FinanceFee.new_student_fee(@finance_fee_collection, s)
                  if @old_collection.invoice_enabled and invoices_exists
                    fee_id = old_finance_fees[s.id].try(:last).try(:fee_id)
                    when_cond = "fee_id = #{fee_id}"
                    update_fee_invoice_sql += " WHEN #{when_cond} THEN #{new_student_fee.id} "
                  end
                  recipient_ids << s.user.id if s.user
                end
              end
              if @old_collection.invoice_enabled and invoices_exists
                update_fee_invoice_sql += " END), invoice_data = NULL, is_active = true "
                update_fee_invoice_sql += " WHERE fee_type = 'FinanceFee' AND
                                                                      fee_id IN (#{old_fee_ids.join(',')}) AND is_active = false"
                # linking old fee invoices with new fee records
                ActiveRecord::Base.connection.execute(update_fee_invoice_sql)
              end
            end
            links = {:target => 'view_fees', :target_param => 'student_id'}
            inform(recipient_ids, body, 'Finance', links)
          else
            raise ActiveRecord::Rollback
          end
        end
      end
      if @error
        page.replace_html 'modal-box', :partial => 'fee_collection_edit', :object => finance_fee_collection
        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @finance_fee_collection
        page.visual_effect(:highlight, 'form-errors')
        page.replace_html 'financial_year_details', :partial => "finance/financial_year_info"
      else
        # @finance_fee_collections = @batch.finance_fee_collections.find(:all, :conditions => ["is_deleted = '#{false}'"])
        @finance_fee_collections = @batch.finance_fee_collections.active.current_active_financial_year.
          all(:include => {:collection_discounts => {:fee_discount => :multi_fee_discount}})
        page.replace_html 'form-errors', :text => ''
        page << "Modalbox.hide();"
        page.replace_html 'fee_collection_dates', :partial => 'fee_collection_list'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('finance.flash12')}</p>"
        page.replace_html 'financial_year_details', :partial => "finance/financial_year_info"
      end
    end
    #find(:all, :conditions => ["is_deleted = '#{false}'"])
    # @finance_fee_collections = @batch.finance_fee_collections.active.current_active_financial_year.
    #     all(:include => {:collection_discounts => {:fee_discount => :multi_fee_discount}})
  end

  # delete a finance fee collection
  def fee_collection_delete
    @batch=Batch.find(params[:batch_id])
    @finance_fee_collection = FinanceFeeCollection.find params[:id]
    unless @finance_fee_collection.has_paid_fees_for_the_batch?(@batch.id)
      @finance_fee_collection.delete_collection(@batch.id)
      @finance_fee_collections = @batch.finance_fee_collections.current_active_financial_year(:all, :conditions => ["is_deleted = '#{false}'"])
    else
      @has_error=true
      render :update do |page|
        flash[:error]=t('finance.flash29')
        page.redirect_to :action => 'fee_collection_view'
      end
    end
  end

  #fees_submission-----------------------------------

  # batch-wise fees submission
  def fees_submission_batch
    @batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => true},
      :joins => :course,
      :select => "`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
      :order => "course_full_name")
    @inactive_batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => false},
      :joins => :course,
      :select => "`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
      :order => "course_full_name")
    @dates = []
    render "finance/fees_payment/fees_submission_batch"
  end

  # fetch and update list of finance fee collection for selected batch
  # Note: list is filtered by active fee accounts
  def update_fees_collection_dates

    @batch = Batch.find_by_id(params[:batch_id])
    #   @dates = @batch.finance_fee_collections
    if @batch.present?
      master_fee_collections="SELECT distinct finance_fee_collections.name as name, finance_fee_collections.id as id,
                                     'load_fees_submission_batch' as action, 'finance' as controller, 'Master Fees' as fee_type
                                          FROM `finance_fee_collections`
                                     #{active_account_joins}
                                    INNER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id
                                    INNER JOIN collection_particulars on collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id
                                    INNER JOIN finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id
                                         WHERE (finance_fees.batch_id=#{@batch.id} and
                                                finance_fee_collections.is_deleted=false and #{active_account_conditions} and " +
        # (finance_fee_collections.fee_account_id IS NULL OR
      #  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false)) AND
      "finance_fee_particulars.batch_id=#{@batch.id} and
                                                ((finance_fee_particulars.receiver_type='Batch' and
                                                 finance_fee_particulars.receiver_id=finance_fees.batch_id) or
                                                 (finance_fee_particulars.receiver_type='Student' and
                                                  finance_fee_particulars.receiver_id=finance_fees.student_id) or
                                                 (finance_fee_particulars.receiver_type='StudentCategory' and
                                                  finance_fee_particulars.receiver_id=finance_fees.student_category_id)))"

      (FedenaPlugin.can_access_plugin?("fedena_transport") and (@current_user.admin? or
            @current_user.privileges.collect(&:name).include? "TransportAdmin")) ?
        transport_fee_collections="UNION ALL(SELECT distinct `transport_fee_collections`.name as name,
                                                      `transport_fee_collections`.id as id,
                                                      'transport_fee_collection_details' as action,
                                                      'transport_fee' as controller,'Transport Fees' as fee_type
                                                 FROM `transport_fee_collections`
                                            #{active_account_joins(true, 'transport_fee_collections')}
                                           INNER JOIN transport_fees
                                                   ON transport_fees.transport_fee_collection_id =transport_fee_collections.id and
                                                      transport_fees.groupable_type='Batch'
                                                WHERE (transport_fees.groupable_id=#{@batch.id} and
                                                       transport_fee_collections.is_deleted=0 and
                                                       transport_fees.is_active=1 and
                                                       transport_fees.bus_fare > 0.0) AND
                                                       #{active_account_conditions(true, 'transport_fee_collections')}
                                             GROUP BY transport_fee_collections.id)" : transport_fee_collections=''

      (FedenaPlugin.can_access_plugin?("fedena_hostel") and (@current_user.admin? or
            @current_user.privileges.collect(&:name).include? "HostelAdmin")) ?
        hostel_fee_collections="UNION ALL(SELECT distinct hostel_fee_collections.name as name,
                                                   hostel_fee_collections.id as id,
                                                   'hostel_fee_collection_details' as action,'hostel_fee' as controller,
                                                   'Hostel Fees' as fee_type
                                              FROM `hostel_fee_collections`
                                         #{active_account_joins(true, 'hostel_fee_collections')}
                                        INNER JOIN `hostel_fees` ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                                        INNER JOIN `students` ON `students`.id = `hostel_fees`.student_id
                                             WHERE (hostel_fees.batch_id=#{@batch.id} and
                                                    hostel_fees.is_active=1 and hostel_fee_collections.is_deleted=false) AND
                                                    #{active_account_conditions(true, 'hostel_fee_collections')} )" :
        hostel_fee_collections=''

      @dates = FinanceFeeCollection.find_by_sql("#{master_fee_collections} #{transport_fee_collections} #{hostel_fee_collections}").
        group_by(&:fee_type)
    else
      @dates = {}
    end

    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "finance/fees_payment/fees_collection_dates"
    end
  end

  # load fees data for selected batch and collection
  def load_fees_submission_batch
    @batch = Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @fine_waiver_val = false
    @students=Student.find(:all,
      :joins => "INNER JOIN finance_fees
                                  ON finance_fees.student_id=students.id AND 
                                       finance_fees.batch_id=#{@batch.id} 
                      INNER JOIN collection_particulars 
                                  ON collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id 
                      INNER JOIN finance_fee_particulars 
                                  ON finance_fee_particulars.id=collection_particulars.finance_fee_particular_id",
      :conditions => "finance_fees.fee_collection_id='#{@date.id}' and
                               finance_fee_particulars.batch_id='#{@batch.id}' and 
                               ((finance_fee_particulars.receiver_type='Batch' and 
                                 finance_fee_particulars.receiver_id=finance_fees.batch_id) or 
                                (finance_fee_particulars.receiver_type='Student' and 
                                 finance_fee_particulars.receiver_id=finance_fees.student_id) or 
                                (finance_fee_particulars.receiver_type='StudentCategory' and 
                                 finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
    student_ids=@students.collect(&:id).join(',')
    @dates = @batch.finance_fee_collections
    @transaction_date = @payment_date = params[:payment_date].present? ? Date.parse(params[:payment_date]) :
      Date.today_with_timezone.to_date
    financial_year_check
    @target_action='load_fees_submission_batch'
    @target_controller='finance'
    fee_inc_assoc = [:finance_transactions]
    if params[:student]
      @student = Student.find(params[:student])
      @fee = FinanceFee.first(:conditions => "fee_collection_id = #{@date.id}",
        :joins => "INNER JOIN students ON finance_fees.student_id = '#{@student.id}'",
        :include => fee_inc_assoc)
    else
      @fee = FinanceFee.first(:conditions => "fee_collection_id = #{@date.id} and
                                              FIND_IN_SET(students.id,'#{ student_ids}')",
        :joins => 'INNER JOIN students ON finance_fees.student_id = students.id',
        :include => fee_inc_assoc)
      @student ||= @fee.try(:student)
    end

    # calculating total collected advance fee amount
    @advance_fee_used = @fee_collection.finance_fees.all(:conditions => {:student_id => @student.id, :batch_id => @batch.id}).collect(&:finance_transactions).flatten.compact.sum(&:wallet_amount).to_f

    # @linking_required = @fee_collection.has_linked_unlinked_masters(false, @student.id) if @student.present? and !@fee.is_paid
    #@fine_waiver_val = false
    unless @fee.nil?
      # if paid by particular wise block here
      @particular_wise_paid = @date.discount_mode != "OLD_DISCOUNT" && @fee.finance_transactions.map(&:trans_type).include?("particular_wise")
      #      @particular_wise_paid = @fee.finance_transactions.map(&:trans_type).include?("particular_wise")
      flash.now[:notice]="#{t('particular_wise_paid_fee_payment_disabled')}" if @particular_wise_paid
      @students = [@student] unless @students.present?
      @prev_student = @student.previous_fee_student(@date.id, student_ids) || @student
      @next_student = @student.next_fee_student(@date.id, student_ids) || @student
      @financefee = @student.finance_fee_by_date @date
      @due_date = @fee_collection.due_date
      @paid_fees = @fee.finance_transactions.all(:include => :transaction_ledger)
      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,
        :conditions => ["is_deleted = false"])
      particular_and_discount_details
      bal = (@total_payable - @total_discount).to_f
      days = (@payment_date - @date.due_date.to_date).to_i
      #      auto_fine=@date.fine
      #      if days > 0 and auto_fine
      #        @fine=params[:fine].to_f if params[:fine].present? and params[:fine].to_f > 0.0
      #        @fine_rule=auto_fine.fine_rules.find(:last,
      #                                             :conditions => ["fine_days <= '#{days}' and
      #                                    created_at <= '#{@date.created_at}'#"],
      #                                             :order => 'fine_days ASC')
      #        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount :
      #            (bal*@fine_rule.fine_amount)/100 if @fine_rule
      auto_fine=@date.fine 
      unless @financefee.is_fine_waiver
        if days > 0 and auto_fine
          @fine=params[:fine].to_f  if params[:fine].present? and params[:fine].to_f > 0.0
          if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
            @fine_amount = @financefee.balance_fine
          else
            @fine_rule=auto_fine.fine_rules.find(:last, 
              :conditions => ["fine_days <= '#{days}' and 
                                       created_at <= '#{@date.created_at}'"], 
              :order => 'fine_days ASC')
            @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : 
              (bal*@fine_rule.fine_amount)/100 if @fine_rule
            if @fine_rule and @financefee.balance==0
              @fine_amount = @fine_amount - @financefee.paid_auto_fine
            end
          end
        end
      end
      @fine_amount=0 if @financefee.is_paid
      render :update do |page|
        # page.replace_html "fees_detail", :partial => "finance/fees_payment/#{@linking_required ? 'notice_link_particulars' : 'student_fees_submission'}"
        page.replace_html "fees_detail", :partial => "finance/fees_payment/student_fees_submission"
        page.replace_html "show_cat_name", :text => @fee_category.name
      end
    else
      render :update do |page|
        page.replace_html "fees_detail",
          :text => "<p class='flash-msg'>#{t('no_student_assigned')}</p>"
      end
    end
  end

  #
  def update_fine_list_ajax
    date=Date.parse(params[:date])
    total_fees=0 #FIXME
    render :update do |page|
      page.replace_html "fees_detail", :partial => "finance/fees_payment/student_fees_submission", :locals => {:i => 0,
        :total_fees => total_fees, :payment_date => date}
    end
  end

  # submits fee from batchwise collection page
  def update_ajax
    @target_action = 'load_fees_submission_batch'
    @target_controller = 'finance'
    @batch = Batch.find(params[:batch_id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @students = Student.find(:all,
      :joins => "inner join finance_fees on finance_fees.student_id=students.id and finance_fees.batch_id=#{@batch.id}
                      inner join collection_particulars on collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id 
                      inner join finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id",
      :conditions => "finance_fees.fee_collection_id='#{@date.id}' and finance_fee_particulars.batch_id='#{@batch.id}' and
                              ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or 
                               (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or 
                               (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
    student_ids=@students.collect(&:id).join(',')
    @dates = @batch.finance_fee_collections
    @student = Student.find(params[:student]) if params[:student]
    @student ||= FinanceFee.first(:conditions => "fee_collection_id = #{@date.id}", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id').student
    @prev_student = @student.previous_fee_student(@date.id, student_ids)
    @next_student = @student.next_fee_student(@date.id, student_ids)
    @due_date = @fee_collection.due_date
    total_fees = 0

    @financefee = @student.finance_fee_by_date @date
    @particular_wise_paid = (@date.discount_mode != "OLD_DISCOUNT" && @financefee.finance_transactions.map(&:trans_type).include?("particular_wise"))
    #    @particular_wise_paid = @financefee.finance_transactions.map(&:trans_type).include?("particular_wise")
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    bal = (@total_payable - @total_discount).to_f
    #@payment_date=@financefee.finance_transactions.last.try(:transaction_date) || @payment_date
    @transaction_date = request.post? ? Date.parse(params[:transaction_date]) : Date.today_with_timezone
    #    days=(Date.today_with_timezone.to_date - @date.due_date.to_date).to_i
    # days = (@transaction_date.to_date - @date.due_date.to_date).to_i
    # auto_fine = @date.fine
    # if days > 0 and auto_fine
    #   @fine_rule=auto_fine.fine_rules.find(:last,
    #     :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],
    #     :order => 'fine_days ASC')
    #   @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount :
    #     (bal*@fine_rule.fine_amount)/100 if @fine_rule
    # end
    # @linking_required = @fee_collection.has_linked_unlinked_masters(false, @student.id) if @student.present? and @fee.present? and !@fee.is_paid
    financial_year_check
    total_fees = @financefee.balance.to_f + params[:special_fine].to_f
    unless params[:fine].nil?
      unless @financefee.is_paid == true
        total_fees += params[:fine].to_f
      else
        total_fees = params[:fine].to_f
      end
    end
    fine_waiver_value = params[:fine_waiver_val].present? ? params[:fine_waiver_val] : @financefee.is_fine_waiver? ? true :false
    unless @particular_wise_paid
      unless params[:fees][:fees_paid].to_f <= 0
        unless params[:fees][:payment_mode].blank?
          unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.
              set_and_modify_precision(total_fees).to_f
            transaction = FinanceTransaction.new
            (@financefee.balance.to_f > params[:fees][:fees_paid].to_f) ?
              transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" :
              transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
            transaction.category = FinanceTransactionCategory.find_by_name("Fee")
            transaction.payee = @student
            transaction.amount = params[:fees][:fees_paid].to_f
            transaction.reference_no = params[:fees][:reference_no]
            transaction.cheque_date = params[:fees][:cheque_date] if params[:fees][:cheque_date].present?
            transaction.bank_name = params[:fees][:bank_name] if params[:fees][:bank_name].present?
            transaction.fine_amount = params[:fine].to_f
            transaction.fine_included = true unless params[:fine].nil?
            if params[:special_fine] and FedenaPrecision.set_and_modify_precision(total_fees)==params[:fees][:fees_paid]
              # transaction.fine_amount = params[:fine].to_f
              # transaction.fine_included = true
              @fine_amount=0
            end
            transaction.finance = @financefee
            transaction.transaction_date=params[:transaction_date]
            transaction.payment_mode = params[:fees][:payment_mode]
            transaction.payment_note = params[:fees][:payment_note]
            transaction.wallet_amount_applied = params[:fees][:wallet_amount_applied]
            transaction.wallet_amount = params[:fees][:wallet_amount]
            transaction.transaction_type = 'SINGLE'
            transaction.fine_waiver = fine_waiver_value
            transaction.safely_create
            #            transaction.save
            @financefee.reload
            #FIXME Never use java script in flash message
            unless transaction.new_record?
              flash[:warning] = "#{t('flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"
            else
              transaction.errors.full_messages.each do |err_msg|
                @financefee.errors.add_to_base(err_msg)
              end if transaction.errors.full_messages.present?
              @financefee.errors.add_to_base(t('fee_payment_failed')) unless transaction.errors.full_messages.present?
            end
            # is_paid =@financefee.balance==0 ? true : false
            # @financefee.update_attributes(:is_paid => is_paid)

            @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
          else
            @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
            @financefee.errors.add_to_base("#{t('flash19')}")
          end
        else
          @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
          @financefee.errors.add_to_base("#{t('select_one_payment_mode')}")
        end
      else
        @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
        @financefee.errors.add_to_base("#{t('flash23')}")
      end
    else
      @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
      @financefee.errors.add_to_base("#{t('particular_wise_paid_fee_payment_disabled')}")
    end
    if @fine_rule and @financefee.balance == 0
      @fine_amount = @fine_amount.to_f - @financefee.paid_auto_fine
    end

    if !@financefee.is_paid #and @financefee.errors.present? # when payment fails for some reason recalculate fine
      days = (@transaction_date.to_date - @date.due_date.to_date).to_i
      auto_fine = @date.fine
      if days > 0 and auto_fine and !@financefee.is_fine_waiver
        if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
          @fine_amount = @financefee.balance_fine
        else
          @fine_rule=auto_fine.fine_rules.find(:last,
            :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],
            :order => 'fine_days ASC')

          @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount :
            (bal*@fine_rule.fine_amount)/100 if @fine_rule
          # ====== Fixing Existing issue on calculating fine when the final due date is exceeded ======
          if @fine_rule and @financefee.balance==0
            @fine_amount = @fine_amount.to_f-@financefee.paid_auto_fine
          end
        end
      elsif @financefee.is_fine_waiver 
        @fine_amount =0.0
      end
    end

    # calculating total collected advance fee amount
    @advance_fee_used = @fee_collection.finance_fees.all(:conditions => {:student_id => @student.id, :batch_id => @batch.id}).collect(&:finance_transactions).flatten.compact.sum(&:wallet_amount).to_f
    
    @payment_date = Date.today_with_timezone.to_date
    render :update do |page|
      page.replace_html "fees_detail", :partial => "finance/fees_payment/student_fees_submission"
      # page.replace_html "fees_detail", :partial => "finance/fees_payment/#{@linking_required ? 'notice_link_particulars' : 'student_fees_submission'}"
      page.replace_html 'flash', :text => (flash[:warning].present? ? "<p class='flash-msg'>#{flash[:warning]}</p>" : "")
    end

  end

  #  def fees_receipt_settings
  #    @receipt_printer_types=ReceiptPrinter::RECEIPT_PRINTER_TYPES
  #    @receipt_printer=ReceiptPrinter.current_settings_object
  #    @settings=@receipt_printer.available_templates
  #    if request.post? || request.put?
  #      @receipt_printer=ReceiptPrinter.new(params[:receipt_printer])
  #      if @receipt_printer.save
  #        flash[:notice] = t('fees_receipt_settings_saved')
  #      else
  #        flash[:notice] ="error_while_saving #{params[:receipt_printer].inspect}"
  #      end
  #      redirect_to :back
  #    end
  #  end

  #  def fees_receipt_preview
  #    receipt_printer_type = params[:type].to_i
  #    # get_student_fee_receipt_new(5)
  #    @transactions = get_receipt_dummy_data(false)
  #    @template_name = ReceiptPrinter::RECEIPT_PRINTER_TEMPLATES[receipt_printer_type]
  #    if params[:template].present?
  #      @fee_template = FeeReceiptTemplate.find(params[:template])
  #      @data = {:templates => {params[:template].to_i  => @fee_template.to_a }} if @fee_template.present?
  #    end
  #    unless params[:logo].present?
  #      @logo_style = ReceiptPrinter.current_settings_object.dot_matrix? ? 'none':'block'
  #    else
  #      @logo_style = params[:logo] == "true" ? 'none' : 'block'
  #      @domatrix = true
  #    end
  #    render :layout => "print"
  #  end

  # fetch fee receipt pdf for a transaction or a transaction ledger
  def generate_fee_receipt_pdf
   transaction = FinanceTransaction.find_by_id(params[:transaction_id])
   @archived_student = ArchivedStudent.find_by_former_id(transaction.payee_id) if transaction.present? && transaction.payee_type == 'Student'
    if params[:detailed].present? and params[:detailed].present? == true
      ledger = FinanceTransactionLedger.find(params[:transaction_id],
        :joins => "LEFT JOIN finance_transactions ft ON ft.transaction_ledger_id = finance_transaction_ledgers.id
                   INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        # :conditions => "(ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
        :conditions => "#{active_account_conditions(true, 'ftrr')}",
        :include => {:finance_transactions => :finance_transaction_receipt_record})

      finance_transactions = ledger.finance_transactions #.all(:include => :finance_transaction_receipt_record)
    else
      finance_transactions = FinanceTransaction.find_all_by_id(params[:transaction_id],
        :joins => "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        # :conditions => "(ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
        :conditions => "#{active_account_conditions(true, 'ftrr')}",
        :include => :finance_transaction_receipt_record)
    end
    template_ids = []
    @transactions = finance_transactions.map do |ft|
      #      puts "ft = #{ft.inspect}"
      # fetches cached receipt data for each transaction record
      receipt_data = ft.receipt_data
      template_ids << receipt_data.template_id = ft.fetch_template_id
      # works for both active or pending transaction
      receipt_data.transaction_status = ft.transaction_ledger.status
      receipt_data
    end
    unless finance_transactions.present?
      flash[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller => "user", :action => "dashboard"
    else
      template_ids = template_ids.compact.uniq

      @data = {:templates => template_ids.present? ? FeeReceiptTemplate.find(template_ids).group_by(&:id) : {} }
      render :pdf => finance_transactions.first.try(:particular_wise?) ? 'generate_particular_fee_receipt_pdf' : 'generate_fee_receipt_pdf',
        #      :template => "finance_extensions/receipts/#{finance_transactions.first.try(:particular_wise?) ?
      #    'generate_particular_fee_receipt_pdf.erb' : 'generate_fee_receipt_pdf.erb'}",
      :template => "finance_extensions/receipts/generate_fee_receipt_pdf.erb",
        :margin =>{:top => 2, :bottom => 20, :left => 5, :right => 5},
        :header => {:html => { :content=> ''}},
        :footer => {:html => {:content => ''}},
        :show_as_html => params.key?(:debug)
    end
  end

  # fetches fee receipt data for print version of fee receipt
  def generate_fee_receipt
    if params[:detailed].present? and params[:detailed] == "true"
      ledger = FinanceTransactionLedger.find(params[:transaction_id],
        :joins => "LEFT JOIN finance_transactions ft ON ft.transaction_ledger_id = finance_transaction_ledgers.id
                            INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                            LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        # :conditions => "(ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
        :conditions => "#{active_account_conditions(true, 'ftrr')}",
        :include => {:finance_transactions => :finance_transaction_receipt_record})
      finance_transactions = ledger.finance_transactions #.all(:include => :finance_transaction_receipt_record)
    else
      finance_transactions = FinanceTransaction.find_all_by_id(params[:transaction_id],
        :joins => "INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                            LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        # :conditions => "(ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
        :conditions => "#{active_account_conditions(true, 'ftrr')}",
        :include => :finance_transaction_receipt_record)
    end
    template_ids = []
    @transactions = finance_transactions.map do |ft|
      receipt_data = ft.receipt_data
      template_ids << receipt_data.template_id = ft.fetch_template_id
      receipt_data.transaction_status = ft.transaction_ledger.status
      receipt_data
    end
    template_ids = template_ids.compact.uniq
    @data = {:templates => template_ids.present? ? FeeReceiptTemplate.find(template_ids).group_by(&:id) : {} }
    render :layout => "print"
  end

  def generate_fee_receipt_text
    if params[:particular_wise].present?
      get_student_fee_receipt(params[:transaction_id], true)
    else
      get_student_fee_receipt(params[:transaction_id])
    end
    # require 'text-table'

    table = Text::Table.new
    table.head = ['Print Receipt', '']
    table.rows = [['a1', 'b1']]
    table.rows << ['a2', 'b2']

    output=table.to_s
    # render :text=> output
    render :text => output, :content_type => "text/plain"
  end

  # fee receipts search page
  def fee_receipts
    unless params[:search].present?
      @start_date=@end_date=FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    else
      @start_date=date_fetch('start_date_as')
      @end_date=date_fetch('end_date_as')
    end
    @search_params = params[:search] || Hash.new
    @search_params[:start_date_as] = @start_date
    @search_params[:end_date_as] = @end_date
    @search = fetched_fee_receipts.search(@search_params)
    @receipts=@search.concat AdvanceFeeCollection.fetch_advance_fees_receipts(@start_date, @end_date, params)
    @fee_receipts = @receipts.sort_by{|o| o.transaction_date.to_date}.reverse.paginate(
      :per_page => 20,
      :page => params[:page])
    @grand_total = 0.00
    @fee_receipts.each {|f| @grand_total += f.amount.to_f }
  end

  # get csv of fee receipts ( as per applied filters if any)
  def fee_reciepts_export_csv
    parameters={:search => params[:search] ,:filename => filename}
    csv_export('finance_transaction', 'fee_reciepts_export', parameters) 
  end

  # get pdf of fee receipts (as per applied filters if any)
  def fee_reciepts_export_pdf
    parameters={:search => params[:search] ,:filename => filename, :controller_name => controller_name, :action_name => action_name}
    opts = {
      :margin => {:left => 10, :right => 10, :bottom => 5}, 
      :template=>"delayed_pdfs/fee_reciepts/fee_reciepts_export_pdf.html",
      :layout => "layouts/pdf.html"
    }    
    GenerateReportPdf.export_pdf('finance_transaction','fee_reciepts_export_to_pdf', parameters, opts)
    flash[:notice]="#{t('pdf_report_is_in_queue')}"
    redirect_to :controller => :report, :action=>:pdf_reports,:model=>'finance_transaction',:method=>'fee_reciepts_export_to_pdf'
  end

  def get_payee
    render :partial => "#{params[:payee_type]}_search"
  end

  def get_advance_time
    @search = fetched_fee_receipts.search(params[:search])
    @start_date=params[:start_date_as].to_date
    @end_date=params[:end_date_as].to_date
    render :partial => 'advance_time_selection'
  end

  def get_advance_search
    @accounts_enabled = (Configuration.get_config_value("MultiFeeAccountEnabled").to_i == 1)
    @accounts = @accounts_enabled ? FeeAccount.all : []
    @search = fetched_fee_receipts.search(params[:search])
    @start_date = params[:search][:start_date_as].to_date
    @end_date = params[:search][:end_date_as].to_date
    @users = User.find(:all, :conditions => ["id in (?)", @search.collect(&:user_id).uniq], :order => 'first_name asc')
    @payment_modes = @search.present? ? @search.collect(&:payment_mode).compact.uniq.sort : ""
  end

  def get_collection_list
    collections= FinanceTransaction.find_by_sql(fee_sql(params["query"]))
    collections.sort! { |a, b| a.collection_name <=> b.collection_name }
    #render :json=>{'query'=>params["query"],'suggestions'=>collections.collect{|c| c.collection_name}.uniq,'data'=>collections.map{|e| "#{e.collection_id}:#{e.fin_type}:#{e.collection_name}"}.uniq  }
    render :json => {'query' => params["query"], 'suggestions' => collections.collect { |c| "#{c.collection_name} - #{c.fin_type}" }.uniq, 'data' => collections.map { |e| "#{e.collection_name} - #{e.fin_type}" }.uniq}
  end

  def student_fee_receipt_pdf
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
    end
    @date = @fee_collection = FinanceFeeCollection.find(params[:id2],
      :joins => "LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id",
      :conditions => "#{active_account_conditions}")
    # :conditions => "finance_fee_collections.fee_account_id IS NULL OR
    #                 (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false)")
    unless @date.present? # belongs to deleted account
      flash[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller => "user", :action => "dashboard"
    else
      @student = Student.find(params[:id])
      @financefee = @student.finance_fee_by_date @date
      @due_date = @fee_collection.due_date

      @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,
        :conditions => ["is_deleted = false"])

      @currency_type = currency
      particular_and_discount_details
      bal = (@total_payable - @total_discount).to_f
      days = (Date.today - @date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine and !@financefee.is_fine_waiver
        if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
          @fine_amount = @financefee.balance_fine
        else
          @fine_rule=auto_fine.fine_rules.find(:last,
            :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],
            :order => 'fine_days ASC')
          @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount :
            (bal*@fine_rule.fine_amount)/100 if @fine_rule

          if @fine_rule and @financefee.balance==0
            @fine_amount = @fine_amount - @financefee.finance_transactions.all(:conditions =>
                ["description=?", 'fine_amount_included']).sum(&:fine_amount)
          end
        end
      end
      @fine_amount=0 if @financefee.is_paid

      render :pdf => 'student_fee_receipt_pdf'
    end
  end

  # updates the fee submission view after applying manual fine
  def update_fine_ajax
    @target_action='load_fees_submission_batch'
    @target_controller='finance'
    @date = @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @batch = Batch.find(params[:fine][:batch_id])
    @student = Student.find(params[:fine][:student]) if params[:fine][:student]
    @transaction_date = @payment_date= params[:fine][:payment_date].present? ? Date.parse(params[:fine][:payment_date]) : Date.today_with_timezone.to_date
    @fine_waiver_val = params[:fine].present? && params[:fine][:is_fine_waiver].present? ? params[:fine][:is_fine_waiver] : false
    financial_year_check
    if request.post?
      @students=Student.find(:all,
        :joins => "INNER JOIN finance_fees on finance_fees.student_id=students.id and finance_fees.batch_id=#{@batch.id}
                        INNER JOIN collection_particulars on collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id 
                        INNER JOIN finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id",
        :conditions => "finance_fees.fee_collection_id='#{@date.id}' and
                                finance_fee_particulars.batch_id='#{@batch.id}' and 
                                ((finance_fee_particulars.receiver_type='Batch' and 
                                  finance_fee_particulars.receiver_id=finance_fees.batch_id) or 
                                 (finance_fee_particulars.receiver_type='Student' and 
                                  finance_fee_particulars.receiver_id=finance_fees.student_id) or 
                                 (finance_fee_particulars.receiver_type='StudentCategory' and 
                                  finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
      student_ids = @students.collect(&:id).join(',')
      @dates = @batch.finance_fee_collections
      @student ||= FinanceFee.first(:conditions => "fee_collection_id = #{@date.id}",
        :joins => 'INNER JOIN students ON finance_fees.student_id = students.id').student
      @prev_student = @student.previous_fee_student(@date.id, student_ids)
      @next_student = @student.next_fee_student(@date.id, student_ids)

      @financefee = @student.finance_fee_by_date @date
      finance_fee_balance = @financefee.balance
      finance_fee_is_paid = @financefee.is_paid
      update_fine_waiver(@fine_waiver_val,@financefee)
      @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
      @fine = nil
      unless params[:fine][:fee].nil?
        @fine = params[:fine][:fee]
      end

      @due_date = @fee_collection.due_date

      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
      particular_and_discount_details
      calculate_auto_fine_for_waiver_tracker if @fine_waiver_val && finance_fee_balance <= 0 && !finance_fee_is_paid
      bal=(@total_payable-@total_discount).to_f
      days=(Date.today-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine and ((params[:fine].present? && !params[:fine][:is_fine_waiver].present?) && !@financefee.is_fine_waiver)
        if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
          @fine_amount = @financefee.balance_fine
        else
          @fine_rule = auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
          @fine_amount = @fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule

          if @fine_rule and @financefee.balance==0
            @fine_amount = @fine_amount - @financefee.paid_auto_fine
          end
        end
      end
      render :update do |page|

        if @fine.nil? or @fine.to_f > 0
          page.replace_html "fees_detail", :partial => "finance/fees_payment/student_fees_submission", :with => @fine
          page << "Modalbox.hide();"
        elsif @fine.to_f <=0
          page.replace_html 'modal-box', :partial => 'fine_submission'
          page.replace_html 'form-errors', :text => "<div id='error-box'><ul><li>#{t('finance.flash24')}</li></ul></div>"
        end
      end
    else
      render :update do |page|
        page.replace_html 'modal-box', :partial => 'fine_submission'
        page << "Modalbox.show($('modal-box'), {title: ''});"

      end
    end
  end

  def search_logic #student search (fees submission)
    query = params[:query].tr('+', ' ').strip # Instead of whitespace browser sent + with string - Remove
    @target_action=params[:target_action]
    @target_controller=params[:target_controller]
    if query.length>= 3
      @students_result = Student.find(:all,
        :conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                          OR admission_no = ? OR (concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? )
                          OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ) ",
          "#{query}%", "#{query}%", "#{query}%", "#{query}", "#{query}%", "#{query}%"],
        :order => "first_name asc") unless query == ''
    else
      @students_result = Student.find(:all,
        :conditions => ["admission_no = ? ", query],
        :order => "first_name asc") unless query == ''
    end
    render :layout => false
  end

  # render collection page for a student from pay all search
  def fees_student_dates
    @student = Student.find(params[:id])
    @dates = FinanceFeeCollection.find(:all,
      :joins => "LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
                 INNER JOIN collection_particulars on collection_particulars.finance_fee_collection_id=finance_fee_collections.id
                 INNER JOIN finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id
                 INNER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id",
      :conditions => "finance_fees.student_id='#{@student.id}' AND
                      finance_fee_collections.is_deleted = false AND #{active_account_conditions} AND " +
        # (finance_fee_collections.fee_account_id IS NULL OR
      #  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false)) AND
      "((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or
                       (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id='#{@student.id}') or
                       (finance_fee_particulars.receiver_type='StudentCategory' and
                        finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
    render "finance/fees_payment/fees_student_dates"
  end

  # render fee submission page for student for selected finance fee collection (via pay all search page)
  def fees_submission_student
    if params[:date].present?
      @date = @fee_collection = FinanceFeeCollection.find(params[:date])
      @transaction_date= params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.today_with_timezone.to_date
      @target_action='fees_submission_student'
      @target_controller='finance'
      @student = Student.find(params[:id])
      
      # calculating total collected advance fee amount
      @advance_fee_used = @fee_collection.finance_fees.all(:conditions => {:student_id => @student.id, :batch_id => @student.batch.id}).collect(&:finance_transactions).flatten.compact.sum(&:wallet_amount).to_f
      
      @fee = @student.finance_fee_by_date(@date)
      @fine_waiver_val = params[:fine].present? && params[:fine][:is_fine_waiver].present?? params[:fine][:is_fine_waiver] : 'false'
      financial_year_check
      unless @fee.nil?
        @particular_wise_paid = (@date.discount_mode != "OLD_DISCOUNT" && @fee.finance_transactions.map(&:trans_type).include?("particular_wise"))
        #        @particular_wise_paid = @fee.finance_transactions.map(&:trans_type).include?("particular_wise")
        flash.now[:notice]="#{t('particular_wise_paid_fee_payment_disabled')}" if @particular_wise_paid
        @batch = @fee.batch
        @financefee = @student.finance_fee_by_date @date
        #        @financefee.update_attributes(:is_fine_waiver=>true) if params[:is_fine_waiver]
        # @linking_required = @fee_collection.has_linked_unlinked_masters(false, @student.id) if @student.present? and !@financefee.is_paid
        @due_date = @fee_collection.due_date
        @paid_fees = @fee.finance_transactions
        @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
        @fine=nil
        @fine=params[:fine][:fee] if (params[:fine].present? and params[:fine][:fee].present?)
        particular_and_discount_details
        bal=(@total_payable-@total_discount).to_f
        days=(@transaction_date-@date.due_date.to_date).to_i
        auto_fine=@date.fine
        if days > 0 and auto_fine and !@financefee.is_fine_waiver
          if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
            @fine_amount = @financefee.balance_fine
          else
            @fine=params[:fine][:fee].to_f  if params[:fine].present? and params[:fine][:fee].present? and params[:fine][:fee].to_f > 0.0
            @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
            @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
            if @fine_rule and @financefee.balance==0
              @fine_amount=@fine_amount-@financefee.paid_auto_fine
            end
          end
        elsif @financefee.is_fine_waiver 
          @fine_amount =0.0
        end
        @fine_amount=0 if @financefee.is_paid
        render :update do |page|
          if params[:add_fine].present?
            page.replace_html 'modal-box', :partial => 'individual_fine_submission'
            page << "Modalbox.show($('modal-box'), {title: ''});"
          elsif @fine.nil? or @fine.to_f > 0
            # page.replace_html "fee_submission",
            #                   :partial => "finance/fees_payment/#{@linking_required ? 'notice_link_particulars' : 'fees_submission_form'}",
            #                   :with => @fine
            page.replace_html "fee_submission",
              :partial => "finance/fees_payment/fees_submission_form", :with => @fine
            page << "Modalbox.hide();"
          elsif @fine.to_f <=0
            page.replace_html 'modal-box', :text => 'fine_submission'
            page.replace_html 'form-errors', :text => "<div id='error-box'><ul><li>#{t('finance.flash24')}</li></ul></div>"
          end
        end
      else
        render :update do |page|
          page.replace_html "fee_submission", :text => '<p class="flash-msg">No students have been assigned this fee.</p>'
        end
      end
    else
      render :update do |page|
        page.replace_html "fee_submission", :text => ''
      end
    end

  end

  def update_student_fine_ajax
    @target_action='fees_submission_student'
    @target_controller='finance'
    @student = Student.find(params[:fine][:student])
    @date = @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @student.finance_fee_by_date(@date)
    unless params[:fine][:fee].to_f < 0
      @fine = (params[:fine][:fee])
      flash[:notice] = nil
    else
      flash[:notice] = "#{t('flash24')}"
    end
    @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    bal=(@total_payable-@total_discount).to_f
    @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.today
    financial_year_check
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@financefee.paid_auto_fine
      end
    end
    render :update do |page|
      page.replace_html "fee_submission", :partial => "finance/fees_payment/fees_submission_form"
    end

  end
  def update_student_auto_fine_ajax
    @target_action='fees_submission_student'
    @target_controller='finance'
    @student = Student.find(params[:fine][:student])
    @date = @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @student.finance_fee_by_date(@date)
    unless params[:fine][:fee].to_f < 0
      @fine = (params[:fine][:fee])
      flash[:notice] = nil
    else
      flash[:notice] = "#{t('flash24')}"
    end
    @fine_waiver_val = params[:fine].present? && params[:fine][:is_fine_waiver].present? ? params[:fine][:is_fine_waiver] : false
    finance_fee_balance = @financefee.balance
    finance_fee_is_paid = @financefee.is_paid
    update_fine_waiver(@fine_waiver_val,@financefee)
    @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    calculate_auto_fine_for_waiver_tracker if @fine_waiver_val && finance_fee_balance <= 0 && !finance_fee_is_paid
    bal=(@total_payable-@total_discount).to_f
    @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.today
    financial_year_check
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine and ((params[:fine].present? && !params[:fine][:is_fine_waiver].present?) && !@financefee.is_fine_waiver)
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      if @fine_rule and @financefee.balance==0
        @fine_amount=@fine_amount-@financefee.paid_auto_fine
      end
    else
      @fine_amount= 0.0
    end
    render :update do |page|
      page.replace_html "fee_submission", :partial => "finance/fees_payment/fees_submission_form"
    end
  end
    
  # render payment modes in various payment pages ( other than student / parent login)
  def select_payment_mode
    @payment_mode = params[:payment_mode]
    if @payment_mode == "Others" or @payment_mode == "Cheque"
      render :update do |page|
        page.replace_html "payment_mode_details", :partial => "finance/fees_payment/select_payment_mode"
      end
    else
      render :update do |page|
        page.replace_html "payment_mode_details", :text => ""
      end
    end
  end

  # submit fee payment for selected student against a collection (via pay all search page)
  def fees_submission_save
    @target_action='fees_submission_student'
    @target_controller='finance'
    @student = Student.find(params[:student])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @date.fee_transactions(@student.id)
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    total_fees = @financefee.balance.to_f+FedenaPrecision.set_and_modify_precision(params[:special_fine]).to_f
    unless params[:fine].nil?
      total_fees += FedenaPrecision.set_and_modify_precision(params[:fine]).to_f
    end
    @transaction_date= params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.today_with_timezone
    fine_waiver_value = params[:fine_waiver_val].present? ? params[:fine_waiver_val] : @financefee.is_fine_waiver? ? true :false
    financial_year_check
    if @financial_year_enabled
      if request.post?
        unless params[:fees][:fees_paid].to_f <= 0
          unless params[:fees][:payment_mode].blank?
            unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
              transaction = FinanceTransaction.new
              ActiveRecord::Base.transaction do
                #              begin
                (@financefee.balance.to_f > params[:fees][:fees_paid].to_f) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" : transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
                transaction.category = FinanceTransactionCategory.find_by_name("Fee")
                transaction.payee = @student
                transaction.finance = @financefee
                transaction.fine_included = true unless params[:fine].nil?
                transaction.amount = params[:fees][:fees_paid].to_f
                transaction.fine_amount = params[:fine].to_f
                transaction.transaction_type = 'SINGLE'
                if params[:special_fine] and total_fees==params[:fees][:fees_paid].to_f
                  # transaction.fine_amount = params[:fine].to_f+params[:special_fine].to_f
                  # transaction.fine_included = true
                  @fine_amount=0
                end
                transaction.transaction_date = params[:transaction_date]
                transaction.payment_mode = params[:fees][:payment_mode]
                transaction.reference_no = params[:fees][:reference_no]
                transaction.cheque_date = params[:fees][:cheque_date] if params[:fees][:cheque_date].present?
                transaction.bank_name = params[:fees][:bank_name] if params[:fees][:bank_name].present?
                transaction.payment_note = params[:fees][:payment_note]
                transaction.fine_waiver = fine_waiver_value
                transaction.wallet_amount_applied = params[:fees][:wallet_amount_applied] if params[:fees][:wallet_amount_applied].present?
                transaction.wallet_amount = params[:fees][:wallet_amount] if params[:fees][:wallet_amount].present?
                transaction.safely_create
                #              transaction.save
                if transaction.errors.present?
                  flash[:notice] = "#{t('fee_payment_failed')}"
                  transaction.errors.full_messages.each do |err_msg|
                    @financefee.errors.add_to_base(err_msg)
                  end
                  raise ActiveRecord::Rollback
                else
                  flash[:warning] = "#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"
                end
                #              rescue Exception => e
                #                puts e.inspect
                #                raise ActiveRecord::Rollback
                #              end
              end
              @financefee.reload
              # is_paid = @financefee.balance==0 ? true : false
              # @financefee.update_attributes(:is_paid => is_paid)
              # flash[:warning] = "#{t('flash14')}.  <a href ='http://#{request.host_with_port}/finance/generate_fee_receipt_pdf?transaction_id=#{transaction.id}' target='_blank'>#{t('print_receipt')}</a>"

              flash[:notice]=nil
            else
              flash[:warning]=nil
              flash[:notice] = "#{t('flash19')}"
            end
          else
            flash[:warning]=nil
            flash[:notice] = "#{t('select_one_payment_mode')}"
          end
        else
          flash[:warning]=nil
          flash[:notice] = "#{t('flash23')}"
        end
      end
    end
    @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
    bal=(@total_payable-@total_discount).to_f
    days=(@transaction_date - @date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine and !@financefee.is_fine_waiver
      @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
      if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && @financefee.balance_fine.present?
        @fine_amount = @financefee.balance_fine
      else
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule and @financefee.is_paid==false
        if @fine_rule and @financefee.balance==0
          @fine_amount=@fine_amount.to_f-@financefee.paid_auto_fine
        end
      end
    end

    @fine_amount=0 if @financefee.is_paid
    @transaction_date = Date.today_with_timezone if request.post?
    render :update do |page|
      page.replace_html "fee_submission", :partial => "finance/fees_payment/fees_submission_form"
    end
  end

  #fees structure ----------------------
  # fetches list of students for fee structure search page
  def fees_student_structure_search_logic # student search fees structure
    query = params[:query]
    unless query.length < 3
      @students_result = Student.find(:all,
        :conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                         OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ",
          "#{query}%", "#{query}%", "#{query}%", "#{query}", "#{query}"],
        :order => "batch_id asc,first_name asc") unless query == ''
    else
      @students_result = Student.find(:all,
        :conditions => ["admission_no = ? ", query],
        :order => "batch_id asc,first_name asc") unless query == ''
    end
    render :layout => false
  end


  def fees_structure_dates
    @student = Student.find(params[:id])
    #@dates = @student.batch.fee_collection_dates
    @student_fees = FinanceFee.find_all_by_student_id(@student.id, :select => 'fee_collection_id')
    @student_dates = ""
    @student_fees.map { |s| @student_dates += s.fee_collection_id.to_s + "," }
    @dates = FinanceFeeCollection.find(:all,
      :select => "distinct finance_fee_collections.*",
      :joins => :collection_particulars,
      :conditions => "FIND_IN_SET(finance_fee_collections.id,\"#{@student_dates}\") and
                      finance_fee_collections.is_deleted = 0")
  end

  def student_fees_structure
    @student = Student.find(params[:id])
    @fee_collection = FinanceFeeCollection.find params[:id2]
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @fee_collection.finance_fee_particulars.all(:conditions => "batch_id=#{@student.batch_id} and is_deleted=#{false}").select { |par| (par.receiver.present?) and (par.receiver==@student or par.receiver==@financefee.student_category or par.receiver==@student.batch) and (!par.is_deleted and par.batch_id==@student.batch_id) }

  end


  #fees defaulters-----------------------
  # fetches and renders list of defaulters
  def fees_defaulters
    @courses = Course.all(
      :joins => {
        :batches => [
          {:students => :finance_fees}, :finance_fee_collections
        ]
      },
      :conditions => ["courses.is_deleted=? and finance_fees.balance > ? and finance_fee_collections.is_deleted=? and finance_fee_collections.due_date < ? and batches.is_active =?", false, 0, false, Date.today, true],
      :group => "courses.id")
    @batchs = []
    @dates = []
  end

  def update_batches
    @course = Course.find_by_id(params[:course_id])
    @batchs = @course.present? ? @course.batches.all(:joins =>  {:finance_fees => :finance_fee_collection},
      :conditions => ["finance_fees.balance > ? and finance_fee_collections.is_deleted=? and
                                     finance_fee_collections.due_date < ?", 0, false, Date.today],
      :group => "batches.id") : []

    render :update do |page|
      page.replace_html "batches_list", :partial => "batches_list"
    end
  end

  def update_fees_collection_dates_defaulters
    @batch = Batch.find_by_id(params[:batch_id])
    @dates = @batch.finance_fee_collections.all(
      :joins => " LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
                   INNER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id
                   INNER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id
                   INNER JOIN students on students.id=finance_fees.student_id",
      :conditions => ["finance_fee_collections.is_deleted=? AND
                         finance_fee_collections.due_date < ? AND finance_fees.balance> ? AND #{active_account_conditions}", false,
        # (finance_fee_collections.fee_account_id IS NULL OR
        #  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false))", false,
        Date.today, 0.0],
      :group => "id") if @batch.present?
    @dates ||= []
    render :update do |page|
      page.replace_html "fees_collection_dates", :partial => "fees_collection_dates_defaulters"
    end
  end

 
  def fees_defaulters_students
    @batch = Batch.find(params[:batch_id])
    @fee_collection = @date = FinanceFeeCollection.find_by_id(params[:date])
    @defaulters = @date.present? ? Student.find(:all,
      :joins => "INNER JOIN finance_fees on finance_fees.student_id=students.id
                                    INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
                                     LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id",
      :conditions => ["finance_fees.fee_collection_id='#{@date.id}' AND
                                          (fa.id IS NULL OR fa.is_deleted = false) AND
                                          finance_fees.balance > 0 AND
                                          finance_fees.batch_id='#{@batch.id}'"],
      :order => "students.first_name ASC").uniq : []
    # @linking_required = @date.try(:has_linked_unlinked_masters) || false

    render :update do |page|
      # page.replace_html "student", :partial => (@linking_required ? "finance/fees_payment/notice_link_particulars" : "student_defaulters")
      page.replace_html "student", :partial => "student_defaulters"
    end
  end

  def fee_defaulters_pdf
    @batch = Batch.find(params[:batch_id])
    @date = @finance_fee_collection = FinanceFeeCollection.find(params[:date])
    @defaulters = Student.find(:all, :joins => "INNER JOIN finance_fees on finance_fees.student_id=students.id ",
      :conditions => ["finance_fees.fee_collection_id='#{@date.id}' and finance_fees.balance > 0 and finance_fees.batch_id='#{@batch.id}'"],
      :select => ["students.*,finance_fees.balance as balance"],
      :order => "students.first_name ASC").uniq
    @currency_type = currency

    render :pdf => 'fee_defaulters_pdf'
  end

  def pay_fees_defaulters
    @target_action='pay_fees_defaulters'
    @target_controller='finance'
    @batch=Batch.find(params[:batch_id])
    # @transaction_date = params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.today_with_timezone
    @transaction_date = @payment_date = (Date.parse(params[:payment_date] || params[:transaction_date]) rescue
      Date.today_with_timezone.to_date)
    financial_year_check   
    if params[:payer_type].present?
      @payer_type=params[:payer_type]
      if params[:payer_type]=='Archived Student'
        @student = ArchivedStudent.find_by_former_id(params[:id] || params[:student])
        unless @student.present?
          flash[:notice] = "#{t('no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
        @student.id=@student.former_id
      else
        @student = Student.find_by_id(params[:id] || params[:student])
        unless @student.present?
          flash[:notice] = "#{t('no_payer')}"
          redirect_to :controller => 'user', :action => 'dashboard' and return
        end
      end
    else
      @student = Student.find_by_id(params[:id] || params[:student])
      unless @student.present?
        flash[:notice] = "#{t('finance.no_payer')}"
        redirect_to :controller => 'user', :action => 'dashboard' and return
      end
    end

    @date = @fee_collection = params[:date].present? ? FinanceFeeCollection.find(params[:date],
      :joins => "LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id",
      :conditions => "#{active_account_conditions}") : nil
    # :conditions => "(finance_fee_collections.fee_account_id IS NULL OR
    #                  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false))") : nil
    unless @date.present?
      flash.now[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller => 'user', :action => 'dashboard' and return
    end
    
    # calculating total collected advance fee amount
    @advance_fee_used = @fee_collection.finance_fees.all(:conditions => {:student_id => @student.id, :batch_id => @batch.id}).collect(&:finance_transactions).flatten.compact.sum(&:wallet_amount).to_f
    
    @fine_waiver_val =  params[:is_fine_waiver].present? ? params[:is_fine_waiver] : false
    @financefee = @date.fee_transactions(@student.id)
    finance_fee_balance = @financefee.balance
    finance_fee_is_paid = @financefee.is_paid
    update_fine_waiver(@fine_waiver_val,@financefee)
    @particular_wise_paid = (@date.discount_mode != "OLD_DISCOUNT" && @financefee.finance_transactions.map(&:trans_type).include?("particular_wise"))
    #    @particular_wise_paid = @financefee.finance_transactions.map(&:trans_type).include?("particular_wise")
    flash.now[:notice]="#{t('particular_wise_paid_fee_payment_disabled')}" if @particular_wise_paid
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    particular_and_discount_details
    calculate_auto_fine_for_waiver_tracker if @fine_waiver_val && finance_fee_balance <= 0 && !finance_fee_is_paid
    bal=(@total_payable-@total_discount).to_f
    #    days=(@transaction_date-@date.due_date.to_date).to_i
    days=(@payment_date-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
    @fine = params[:fine].to_f if days > 0 and params[:fine].present?
    if days > 0 and auto_fine and ( !params[:is_fine_waiver].present? && !@financefee.is_fine_waiver)
      if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
        @fine_amount = @financefee.balance_fine
      else
        @fine_rule=auto_fine.fine_rules.find(:last, :order => 'fine_days ASC',
          :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"])
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
      end
    end
    total_fees = @financefee.balance.to_f+FedenaPrecision.set_and_modify_precision(@fine_amount).to_f
    total_fees += @fine unless @fine.nil?
    if request.post? 
      if params[:cancel_auto_fine].present?
        if @fine_rule and @financefee.balance==0
          @fine_amount = @fine_amount - @financefee.paid_auto_fine
          @fine_amount= 0 if @fine_amount < 0
        end
        if @financefee.is_paid_with_fine?
          @fine=nil
          @fine_amount=0
        end
        render :update do |page|
          page.replace_html "fees_detail", 
            :partial => "finance/fees_payment/fees_details"
        end
      elsif !@particular_wise_paid and @financial_year_enabled
        unless params[:fees][:fees_paid].to_f <= 0
          unless params[:fees][:payment_mode].blank?
            #unless params[:fees][:fees_paid].to_f> @total_fees
            unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
              transaction = FinanceTransaction.new
              (@financefee.balance.to_f > params[:fees][:fees_paid].to_f) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" : transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
              transaction.category = FinanceTransactionCategory.find_by_name("Fee")
              transaction.payee = @student
              transaction.finance = @financefee
              transaction.amount = params[:fees][:fees_paid].to_f
              unless (@fine.nil? || @fine.to_i.zero?)
                transaction.fine_included = true
                transaction.fine_amount = params[:fine].to_f
              end

              if params[:special_fine] and total_fees==params[:fees][:fees_paid].to_f
                # transaction.fine_amount = params[:fine].to_f+FedenaPrecision.set_and_modify_precision(params[:special_fine]).to_f
                # transaction.fine_included = true
                @fine_amount=0
              end
              transaction.transaction_date = params[:transaction_date]
              transaction.payment_mode = params[:fees][:payment_mode]
              transaction.reference_no = params[:fees][:reference_no]
              transaction.cheque_date = params[:fees][:cheque_date] if params[:fees][:cheque_date].present?
              transaction.bank_name = params[:fees][:bank_name] if params[:fees][:bank_name].present?
              transaction.payment_note = params[:fees][:payment_note]
              #            transaction.fine_waiver = params[:is_fine_waiver] if params[:is_fine_waiver].present?
              transaction.fine_waiver = params[:fine_waiver_val] if params[:fine_waiver_val].present?
              transaction.wallet_amount_applied = params[:fees][:wallet_amount_applied] if params[:fees][:wallet_amount_applied].present?
              transaction.wallet_amount = params[:fees][:wallet_amount] if params[:fees][:wallet_amount].present?
              transaction.safely_create
              #            transaction.save

              # is_paid =@financefee.balance==0 ? true : false
              # @financefee.update_attributes(:is_paid => is_paid)

              @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
              flash[:notice] = "#{t('flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"
              # flash[:notice] = "#{t('flash14')}.  <a href ='http://#{request.host_with_port}/finance/generate_fee_receipt_pdf?transaction_id=#{transaction.id}' target='_blank'>#{t('print_receipt')}</a>"
              redirect_to :action => "pay_fees_defaulters", :id => @student, :date => @date, :batch_id => @batch.id
            else
              flash[:notice] = "#{t('flash19')}"
              render "finance/fees_payment/pay_fees_defaulters"
            end
          else
            flash[:warn_notice] = "#{t('select_one_payment_mode')}"
            render "finance/fees_payment/pay_fees_defaulters"
          end
        else
          flash[:warn_notice] = "#{t('flash23')}"
          render "finance/fees_payment/pay_fees_defaulters"
        end
      end
    else
      if @fine_rule and @financefee.balance==0
        @fine_amount = @fine_amount - @financefee.paid_auto_fine
        @fine_amount= 0 if @fine_amount < 0
      end
      if @financefee.is_paid_with_fine?
        @fine=nil
        @fine_amount=0
      end
      #      render "finance/fees_payment/pay_fees_defaulters"
      #    end
      unless params[:payment_date].present?
        render "finance/fees_payment/pay_fees_defaulters"
      else
        render :update do |page|
          page.replace_html "fee_defaulter_main", 
            :partial => "finance/fees_payment/pay_fees_defaulters"
        end      
      end
    end
  end

  def update_defaulters_fine_ajax
    @target_action = 'pay_fees_defaulters'
    @target_controller = 'finance'
    @student = Student.find(params[:fine][:student])
    @date = FinanceFeeCollection.find(params[:fine][:date])
    @financefee = @date.fee_transactions(@student.id)
    @fee_collection = FinanceFeeCollection.find(params[:fine][:date])
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @date.fees_particulars(@student)
    unless params[:fine][:fee].to_f < 0
      @fine = params[:fine][:fee] || nil
      total_fees = 0
      @fee_particulars.each do |p|
        total_fees += p.amount
      end
      total_fees += @fine.to_f unless @fine.nil?
    else
      flash[:notice] = "#{t('flash24')}"
    end

    redirect_to :action => "pay_fees_defaulters", :id => @student.id,
      :date => @date.id, :fine => @fine,
      :batch_id => params[:fine][:batch_id] || params[:batch_id],
      :payment_note => params[:payment_note],
      :transaction_date => params[:transaction_date],
      :reference_no => params[:reference_no]
  end

  # render compare transaction report
  def compare_report
    @accounts_enabled = (Configuration.get_config_value 'MultiFeeAccountEnabled').to_i == 1
    @accounts = FeeAccount.all if @accounts_enabled
  end

  # render compare transaction report based of applied filters
  def report_compare
    @error = false
    unless date_validation
      unless request.xhr?
        redirect_to :action => "compare_report"
      else
        @error=true
        if request.xhr?
          render(:update) do |page|
            page.replace_html "date_error_div", :partial => "date_error"
          end
        end
      end
    else
      fixed_category_name

      filter_by_account, account_id = account_filter
      common_joins = "LEFT JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id
                   LEFT JOIN fee_accounts fa ON fa.id = finance_transaction_receipt_records.fee_account_id"
      ft_joins = "INNER JOIN finance_transactions ON finance_transactions.category_id = finance_transaction_categories.id
                  #{common_joins}"
      joins = "INNER JOIN finance_transaction_categories ON finance_transaction_categories.id = finance_transactions.category_id
                  #{common_joins}"

      common_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "
      if filter_by_account
        filter_conditions = " AND #{common_conditions} AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
        filter_values = [account_id]
      else
        filter_values = []
      end

      @target_action='report_compare'
      @hr = Configuration.find_by_config_value("HR")
      @start_date = (params[:start_date]).to_date
      @end_date = (params[:end_date]).to_date
      @start_date2 = (params[:start_date2]).to_date
      @end_date2 = (params[:end_date2]).to_date
      graph_data = ""
      # refund_transaction_category = FinanceTransactionCategory.find_by_name('Refund')
      # other_category_ids = (@fixed_cat_ids.join(",") + refund_transaction_category.try(:id)).compact
      other_category_ids = @fixed_cat_ids.join(",") #(@fixed_cat_ids.join(",")).compact
      @other_transaction_categories = FinanceTransactionCategory.all(
        :joins => ft_joins,
        :group => "finance_transactions.category_id",
        :select => "finance_transaction_categories.name, finance_transaction_categories.id AS cat_id, is_income,
                          IFNULL(SUM(CASE WHEN transaction_date >= '#{@start_date}' AND
                                                                 transaction_date <= '#{@end_date}'
                                              THEN finance_transactions.amount end),0) AS first,
                          IFNULL(SUM(CASE WHEN transaction_date >= '#{@start_date2}' AND
                                                                 transaction_date <= '#{@end_date2}'
                                              THEN finance_transactions.amount end),0) AS second",
        :conditions => ["#{common_conditions} AND category_id NOT IN (#{other_category_ids}) #{filter_conditions}"] + filter_values)

      # @refund_transaction =

      @salary = FinanceTransaction.get_total_amount("Salary", [@start_date, @end_date], [@start_date2, @end_date2],
        {:joins => common_joins, :conditions => common_conditions})
      graph_data += "&salary=#{@salary.first.to_f},#{@salary.second.to_f}"
      @donations_total = FinanceTransaction.get_total_amount("Donation",[@start_date,@end_date],[@start_date2,@end_date2],
        {:joins => common_joins, :conditions => common_conditions})
      graph_data += "&donations=#{@donations_total.first.to_f},#{@donations_total.second.to_f}"
      @transactions_fees = FinanceTransaction.get_total_amount("Fee",[@start_date,@end_date],[@start_date2,@end_date2],
        {:joins => common_joins, :conditions => common_conditions})
      graph_data += "&fees=#{@transactions_fees.first.to_f},#{@transactions_fees.second.to_f}"
      @category_transaction_totals = {}
      plugin_categories = FedenaPlugin::FINANCE_CATEGORY.collect{|p_c| p_c[:category_name] if can_access_request? "#{p_c[:destination][:action]}".to_sym,"#{p_c[:destination][:controller]}".to_sym}.compact

      @plugin_amount = FinanceTransaction.find(:all,
        :conditions => ["#{common_conditions} AND finance_transaction_categories.name IN (?) #{filter_conditions}",
          plugin_categories] + filter_values,
        :joins => joins, :group => 'finance_transaction_categories.name',
        :select => "IFNULL(SUM(CASE WHEN transaction_date >= '#{@start_date}' AND
                                                                 transaction_date <= '#{@end_date}'
                                              THEN finance_transactions.amount end),0) AS amount_1,
                          IFNULL(SUM(CASE WHEN transaction_date >= '#{@start_date2}' AND
                                                                  transaction_date <= '#{@end_date2}'
                                              THEN finance_transactions.amount end),0) AS amount_2,
                          finance_transaction_categories.is_income AS is_income,
                          finance_transaction_categories.name AS pl_name").group_by(&:pl_name)
      plugin_categories.each do |category|
        unless @plugin_amount[category.camelize].nil?
          amount1=@plugin_amount[category.camelize].first.amount_1.to_f
          amount2=@plugin_amount[category.camelize].first.amount_2.to_f

          if amount1 > 0 || amount2 > 0
            graph_data += "&ICATEGORY#{category.underscore.gsub(/\s+/, '_')+'_fees'}=#{amount1},#{amount2}"
            # plugin_amount[category[:category_name].camelize].first.is_income.to_f==1 ? data << amount : data << amount-(amount*2)
            # largest_value = amount if largest_value < amount
          end
        end
      end
      # advance fees comparison
      @w_c_amount, @w_c_amount2, @w_d_amount, @w_d_amount2 = AdvanceFeeCategory.comparison_for_advance_fees(@start_date, @end_date, @start_date2, @end_date2, params[:fee_account_id])

      @other_transaction_categories.each do |cat|
        graph_data += "&#{cat.is_income ? 'IO':'EO'}CATEGORY#{cat.name}=#{cat.first.to_f},#{cat.second.to_f}"
      end

      @graph = open_flash_chart_object(1200, 500, "graph_for_compare_monthly_report?start_date=#{@start_date}&end_date=#{@end_date}&start_date2=#{@start_date2}&end_date2=#{@end_date2}&fee_account_id=#{@account_id}&#{graph_data}")

      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "report_compare"
        end
      end
    end
  end

  def month_date
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
  end

  def partial_payment
    render :update do |page|
      page.replace_html "partial_payment", :partial => "partial_payment"
    end
  end


  #reports pdf---------------------------
  # get pdf of a student's fee structure for a collection
  def fee_structure_pdf
    @student = Student.find(params[:id])
    #    @institution_name = Configuration.find_by_config_key("InstitutionName")
    #    @institution_address = Configuration.find_by_config_key("InstitutionAddress")
    #    @institution_phone_no = Configuration.find_by_config_key("InstitutionPhoneNo")
    #    @currency_type = currency
    @financefee= FinanceFee.last(:conditions => {:student_id => @student.id,
        :fee_collection_id => params[:id2]}, :include => [:finance_transactions,
        :finance_fee_collection,
        {:tax_collections => :tax_slab}])
    #    @fee_category = FinanceFeeCategory.find(@date.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
    #    particular_and_discount_details

    #    render :pdf => 'pdf_fee_structure'
    #    finance_transaction=FinanceTransaction.find_all_by_id(params[:transaction_id])
    @config = Configuration.get_multiple_configs_as_hash ['PdfReceiptSignature', 'PdfReceiptSignatureName',
      'PdfReceiptCustomFooter', 'PdfReceiptAtow', 'PdfReceiptNsystem', 'PdfReceiptHalignment']
    @default_currency = Configuration.default_currency

    get_student_invoice(@financefee)
    render :pdf => 'fee_structure_pdf',
      :template => 'finance_extensions/fee_structure_pdf.erb',
      :margin => {:top => 2, :bottom => 20, :left => 5, :right => 5},
      :header => {:html => {:content => ''}},
      :footer => {:html => {:content => ''}},
      :show_as_html => params.key?(:debug)

  end

  #graph------------------------------------
  # renders graph for transaction report
  def graph_for_update_monthly_report
    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date

    expenses = Hash[params.select {|x,y| x.match /ECATEGORY(.)*/ }]
    incomes = Hash[params.select {|x,y| x.match /ICATEGORY(.)*/ }]
    other_expenses = Hash[params.select {|x,y| x.match /EOCATEGORY(.)*/ }]
    other_incomes = Hash[params.select {|x,y| x.match /IOCATEGORY(.)*/ }]

    donations_total = params[:donations].present? ? params[:donations].to_f : 0
    fees = params[:fees].present? ? params[:fees].to_f : 0
    salary = params[:salary].present? ? params[:salary].to_f : 0
    refund = params[:refund].present? ? params[:refund].to_f : 0

    income = expense = 0

    x_labels = []
    data = []
    largest_value = 0

    if salary > 0
      x_labels << "#{t('employee_salary')}"
      data << -(salary)
      largest_value = salary if largest_value < salary
    end

    if donations_total > 0
      x_labels << "#{t('donations')}"
      data << donations_total
      largest_value = donations_total if largest_value < donations_total
    end

    if fees > 0
      x_labels << "#{t('student_fees')}"
      data << FedenaPrecision.set_and_modify_precision(fees).to_f
      largest_value = fees if largest_value < fees
    end

    incomes.each_pair do |cat, amt|
      x_labels << "#{t(cat.gsub('ICATEGORY',''))}"
      data << amount = amt.to_f
      largest_value = amount if largest_value < amount
    end

    expenses.each_pair do |cat, amt|
      x_labels << "#{t(cat.gsub('ECATEGORY',''))}"
      data << amount = amt.to_f
      largest_value = amount if largest_value < amount
    end

    other_expenses.each_pair do |cat, amt|
      expense += amt.to_f
    end

    other_incomes.each_pair do |cat, amt|
      income += amt.to_f
    end

    if income > 0
      x_labels << "#{t('other_income')}"
      data << income
      largest_value = income if largest_value < income
    end

    if refund > 0
      x_labels << "#{t('refund')}"
      data << -(refund)
      largest_value = refund if largest_value < refund
    end

    if expense > 0
      x_labels << "#{t('other_expense')}"
      data << -(FedenaPrecision.set_and_modify_precision(expense).to_f)
      largest_value = expense if largest_value < expense
    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('amount')}"
    bargraph.values = data

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(FedenaPrecision.set_and_modify_precision(-(largest_value)),
      FedenaPrecision.set_and_modify_precision(largest_value),
      FedenaPrecision.set_and_modify_precision(largest_value/5))

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("Examination name")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("Marks")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis
    chart.add_element(bargraph)
    render :text => chart.render
  end

  # renders graph for comparison transaction report
  def graph_for_compare_monthly_report
    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    start_date2 = (params[:start_date2]).to_date
    end_date2 = (params[:end_date2]).to_date

    expenses = Hash[params.select {|x,y| x.match /ECATEGORY(.)*/ }]
    incomes = Hash[params.select {|x,y| x.match /ICATEGORY(.)*/ }]
    other_expenses = Hash[params.select {|x,y| x.match /EOCATEGORY(.)*/ }]
    other_incomes = Hash[params.select {|x,y| x.match /IOCATEGORY(.)*/ }]

    donations_total = params[:donations].present? ? params[:donations].split(",")[0].to_f : 0
    donations_total2 = params[:donations].present? ? params[:donations].split(",")[1].to_f : 0

    fees = params[:fees].present? ? params[:fees].split(",")[0].to_f : 0
    fees2 = params[:fees].present? ? params[:fees].split(",")[1].to_f : 0

    salary = params[:salary].present? ? params[:salary].split(",")[0].to_f : 0
    salary2 = params[:salary].present? ? params[:salary].split(",")[1].to_f : 0

    total_other_trans1 = total_other_trans2 = income = expense = income2 = expense2 = 0

    x_labels = []
    data = []
    data2 = []
    largest_value = 0

    unless salary <= 0 and salary2 <= 0
      x_labels << "#{t('employee_salary')}"
      data << -(salary)
      data2 << -(salary2)
      largest_value = salary if largest_value < salary
      largest_value = salary2 if largest_value < salary2
    end

    unless donations_total <= 0 and donations_total2 <= 0
      x_labels << "#{t('donations')}"
      data << donations_total
      data2 << donations_total2
      largest_value = donations_total if largest_value < donations_total
      largest_value = donations_total2 if largest_value < donations_total2
    end

    unless fees <= 0 and fees2 <= 0
      x_labels << "#{t('student_fees')}"
      data << FedenaPrecision.set_and_modify_precision(fees).to_f
      data2 << FedenaPrecision.set_and_modify_precision(fees2).to_f
      largest_value = fees if largest_value < fees
      largest_value = fees2 if largest_value < fees2
    end

    incomes.each_pair do |cat, amt|
      x_labels << "#{t(cat.gsub('ICATEGORY',''))}"
      data << amount1 = amt.split(',')[0].to_f
      data2 << amount2 = amt.split(',')[1].to_f
      largest_value = amount1 if largest_value < amount1
      largest_value = amount2 if largest_value < amount2
    end

    expenses.each_pair do |cat, amt|
      x_labels << "#{t(cat.gsub('ECATEGORY',''))}"
      amount1 = amt.split(',')[0].to_f
      amount2 = amt.split(',')[1].to_f
      data << -(amount1)
      data2 << -(amount2)
      largest_value = amount1 if largest_value < amount1
      largest_value = amount2 if largest_value < amount2
    end

    refund = refund2 = 0

    other_expenses.each_pair do |cat, amt|
      unless cat == 'Refund'
        expense += amt.split(',')[0].to_f
        expense2 += amt.split(',')[1].to_f
      else
        refund = amt.split(',')[0].to_f
        refund2 = amt.split(',')[1].to_f
      end
    end

    other_incomes.each_pair do |cat, amt|
      income += amt.split(',')[0].to_f
      income2 += amt.split(',')[1].to_f
    end

    unless income <= 0 and income2 <= 0
      x_labels << "#{t('other_income')}"
      data << income
      data2 << income2
      largest_value = income if largest_value < income
      largest_value = income2 if largest_value < income2
    end

    unless refund <= 0 and refund2 <= 0
      x_labels << "#{t('refund')}"
      data << refund
      data2 << refund2
      largest_value = refund if largest_value < refund
      largest_value = refund2 if largest_value < refund2
    end

    unless expense <= 0 and expense2 <= 0
      x_labels << "#{t('other_expense')}"
      data << -(FedenaPrecision.set_and_modify_precision(expense).to_f)
      data2 << -(FedenaPrecision.set_and_modify_precision(expense2).to_f)
      largest_value = expense if largest_value < expense
      largest_value = expense2 if largest_value < expense2
    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('for_the_period')} #{format_date(start_date)} #{t('to')} #{format_date(end_date)}"
    bargraph.values = data
    bargraph2 = BarFilled.new()
    bargraph2.width = 1;
    bargraph2.colour = '#000000';
    bargraph2.dot_size = 3;
    bargraph2.text = "#{t('for_the_period')} #{format_date(start_date2)} #{t('to')} #{format_date(end_date2)}"
    bargraph2.values = data2

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(FedenaPrecision.set_and_modify_precision(-(largest_value)),
      FedenaPrecision.set_and_modify_precision(largest_value),
      FedenaPrecision.set_and_modify_precision(largest_value/5))

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("#{t('examination_name')}")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("#{t('marks')}")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)
    chart.add_element(bargraph2)

    render :text => chart.render
  end

  # def graph_for_compare_monthly_report
  #
  #   start_date = (params[:start_date]).to_date
  #   end_date = (params[:end_date]).to_date
  #   start_date2 = (params[:start_date2]).to_date
  #   end_date2 = (params[:end_date2]).to_date
  #   employees = Employee.find(:all)
  #   filter_by_account, account_id = account_filter
  #   common_joins = "LEFT JOIN finance_transaction_receipt_records ON finance_transaction_receipt_records.finance_transaction_id = finance_transactions.id
  #                  LEFT JOIN fee_accounts fa ON fa.id = finance_transaction_receipt_records.fee_account_id"
  #   ft_joins = "INNER JOIN finance_transactions ON finance_transactions.category_id = finance_transaction_categories.id
  #                 #{common_joins}"
  #   joins = "INNER JOIN finance_transaction_categories ON finance_transaction_categories.id = finance_transactions.category_id
  #                 #{common_joins}"
  #
  #   common_conditions = " (fa.id IS NULL OR fa.is_deleted = false) "
  #
  #   if filter_by_account
  #     filter_conditions = " #{common_conditions} AND finance_transaction_receipt_records.fee_account_id #{account_id == nil ? 'IS' : '='} ?"
  #     filter_values = [account_id]
  #   else
  #     filter_conditions = "#{common_conditions} "
  #     filter_values = []
  #   end
  #
  #   hr = Configuration.find_by_config_value("HR")
  #   donations_total = FinanceTransaction.donations_triggers(start_date, end_date,
  #    {:conditions => filter_conditions, :values => filter_values, :joins => common_joins})
  #   donations_total2 = FinanceTransaction.donations_triggers(start_date2, end_date2,
  #    {:conditions => filter_conditions, :values => filter_values, :joins => common_joins})
  #   fees = FinanceTransaction.total_fees(start_date, end_date,
  #    {:conditions => filter_conditions, :values => filter_values, :joins => common_joins}).map { |t| t.transaction_total.to_f }.sum
  #   fees2 = FinanceTransaction.total_fees(start_date2, end_date2,
  #    {:conditions => filter_conditions, :values => filter_values, :joins => common_joins}).map { |t| t.transaction_total.to_f }.sum
  #   total_other_trans1 = FinanceTransaction.total_other_trans(start_date, end_date,
  #    {:conditions => filter_conditions, :values => filter_values, :joins => common_joins})
  #   total_other_trans2 = FinanceTransaction.total_other_trans(start_date2, end_date2,
  #    {:conditions => filter_conditions, :values => filter_values, :joins => common_joins})
  #   income = total_other_trans1[0]
  #   expense = total_other_trans1[1]
  #   income2 = total_other_trans2[0]
  #   expense2 = total_other_trans2[1]
  #
  #   x_labels = []
  #   data = []
  #   data2 = []
  #   largest_value =0
  #
  #   unless hr.nil?
  #     salary = FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => start_date..end_date}).to_f
  #     salary2 = FinanceTransaction.sum('amount', :conditions => {:title => "Monthly Salary", :transaction_date => start_date2..end_date2}).to_f
  #     unless salary <= 0 and salary2 <= 0
  #       x_labels << "#{t('employee_salary')}"
  #       data << salary-(salary*2)
  #       data2 << salary2-(salary2*2)
  #       largest_value = salary if largest_value < salary
  #       largest_value = salary2 if largest_value < salary2
  #     end
  #   end
  #   unless donations_total <= 0 and donations_total2 <= 0
  #     x_labels << "#{t('donations')}"
  #     data << donations_total
  #     data2 << donations_total2
  #     largest_value = donations_total if largest_value < donations_total
  #     largest_value = donations_total2 if largest_value < donations_total2
  #   end
  #
  #   unless fees <= 0 and fees2 <= 0
  #     x_labels << "#{t('student_fees')}"
  #     data << FedenaPrecision.set_and_modify_precision(fees).to_f
  #     data2 << FedenaPrecision.set_and_modify_precision(fees2).to_f
  #     largest_value = fees if largest_value < fees
  #     largest_value = fees2 if largest_value < fees2
  #   end
  #
  #   plugin_categories=FedenaPlugin::FINANCE_CATEGORY.collect{|p_c| p_c[:category_name] if can_access_request? "#{p_c[:destination][:action]}".to_sym,"#{p_c[:destination][:controller]}".to_sym}
  #   plugin_amount=FinanceTransaction.find(:all,
  #     :conditions => ["ftc.name in(?) #{filter_conditions}", plugin_categories] + filter_values,
  #     :joins => "INNER JOIN finance_transaction_categories ftc ON ftc.id = finance_transactions.category_id #{common_joins}",
  #     :group => 'ftc.name',
  #     :select => "ifnull(sum(case when transaction_date >= '#{@start_date}' and transaction_date <= '#{@end_date}'
  #                                 then finance_transactions.amount end),0) as amount_1,
  #                 ifnull(sum(case when transaction_date >= '#{@start_date2}' and transaction_date <= '#{@end_date2}'
  #                                 then finance_transactions.amount end),0)  as amount_2,
  #                 ftc.is_income as is_income, ftc.name as pl_name").group_by(&:pl_name)
  #
  #   FedenaPlugin::FINANCE_CATEGORY.each do |category|
  #     unless plugin_amount[category[:category_name].camelize].nil?
  #       transaction1 = FinanceTransaction.total_transaction_amount(category[:category_name], start_date, end_date)
  #       transaction2 = FinanceTransaction.total_transaction_amount(category[:category_name], start_date2, end_date2)
  #       amount1 = transaction1[:amount]
  #       amount2 = transaction2[:amount]
  #       x_labels << "#{t(category[:category_name].underscore.gsub(/\s+/, '_')+'_fees')}"
  #       plugin_amount[category[:category_name].camelize].first.is_income.to_f==1 ? data << amount1 : data << amount1-(amount1*2)
  #       plugin_amount[category[:category_name].camelize].first.is_income.to_f==1 ? data2 << amount2 : data2 << amount2-(amount2*2)
  #       largest_value = amount1 if largest_value < amount1
  #       largest_value = amount2 if largest_value < amount2
  #     end
  #   end
  #
  #   unless income <= 0 and income2 <= 0
  #     x_labels << "#{t('other_income')}"
  #     data << income
  #     data2 << income2
  #     largest_value = income if largest_value < income
  #     largest_value = income2 if largest_value < income2
  #   end
  #
  #   unless expense <= 0 and expense2 <= 0
  #     x_labels << "#{t('other_expense')}"
  #     data << FedenaPrecision.set_and_modify_precision(expense-(expense*2)).to_f
  #     data2 << FedenaPrecision.set_and_modify_precision(expense2-(expense2*2)).to_f
  #     largest_value = expense if largest_value < expense
  #     largest_value = expense2 if largest_value < expense2
  #   end
  #
  #   largest_value += 500
  #
  #   bargraph = BarFilled.new()
  #   bargraph.width = 1;
  #   bargraph.colour = '#bb0000';
  #   bargraph.dot_size = 3;
  #   bargraph.text = "#{t('for_the_period')} #{format_date(start_date)} #{t('to')} #{format_date(end_date)}"
  #   bargraph.values = data
  #   bargraph2 = BarFilled.new()
  #   bargraph2.width = 1;
  #   bargraph2.colour = '#000000';
  #   bargraph2.dot_size = 3;
  #   bargraph2.text = "#{t('for_the_period')} #{format_date(start_date2)} #{t('to')} #{format_date(end_date2)}"
  #   bargraph2.values = data2
  #
  #   x_axis = XAxis.new
  #   x_axis.labels = x_labels
  #
  #   y_axis = YAxis.new
  #   y_axis.set_range(FedenaPrecision.set_and_modify_precision(largest_value-(largest_value*2)), FedenaPrecision.set_and_modify_precision(largest_value), FedenaPrecision.set_and_modify_precision(largest_value/5))
  #
  #   title = Title.new("#{t('finance_transactions')}")
  #
  #   x_legend = XLegend.new("#{t('examination_name')}")
  #   x_legend.set_style('{font-size: 14px; color: #778877}')
  #
  #   y_legend = YLegend.new("#{t('marks')}")
  #   y_legend.set_style('{font-size: 14px; color: #770077}')
  #
  #   chart = OpenFlashChart.new
  #   chart.set_title(title)
  #   chart.set_x_legend = x_legend
  #   chart.set_y_legend = y_legend
  #   chart.y_axis = y_axis
  #   chart.x_axis = x_axis
  #
  #   chart.add_element(bargraph)
  #   chart.add_element(bargraph2)
  #
  #   render :text => chart.render
  #
  # end

  #ddnt complete this graph!

  def graph_for_transaction_comparison

    start_date = (params[:start_date]).to_date
    end_date = (params[:end_date]).to_date
    employees = Employee.find(:all)

    hr = Configuration.find_by_config_value("HR")
    donations_total = FinanceTransaction.donations_triggers(start_date, end_date)
    fees = FinanceTransaction.total_fees(start_date, end_date).map { |t| t.transaction_total.to_f }.sum
    income = FinanceTransaction.total_other_trans(start_date, end_date)[0]
    expense = FinanceTransaction.total_other_trans(start_date, end_date)[1]
    #    other_transactions = FinanceTransaction.find(:all,
    #      :conditions => ["transaction_date >= '#{start_date}' and transaction_date <= '#{end_date}'and category_id !='#{3}' and category_id !='#{2}'and category_id !='#{1}'"])


    x_labels = []
    data1 = []
    data2 = []

    largest_value =0

    unless hr.nil?
      salary = Employee.total_employees_salary(employees, start_date, end_date)
    end
    unless salary <= 0
      x_labels << "#{t('salary')}"
      data << salary-(salary*2)
      largest_value = salary if largest_value < salary
    end
    unless donations_total <= 0
      x_labels << "#{t('donations')}"
      data << donations_total
      largest_value = donations_total if largest_value < donations_total
    end

    unless fees <= 0
      x_labels << "#{t('fees_text')}"
      data << fees
      largest_value = fees if largest_value < fees
    end

    unless income <= 0
      x_labels << "#{t('other_income')}"
      data << income
      largest_value = income if largest_value < income
    end

    unless expense <= 0
      x_labels << "#{t('other_expense')}"
      data << expense
      largest_value = expense if largest_value < expense
    end

    #    other_transactions.each do |trans|
    #      x_labels << trans.title
    #      if trans.category.is_income? and trans.master_transaction_id == 0
    #        data << trans.amount
    #      else
    #        data << ("-"+trans.amount.to_s).to_i
    #      end
    #      largest_value = trans.amount if largest_value < trans.amount
    #    end

    largest_value += 500

    bargraph = BarFilled.new()
    bargraph.width = 1;
    bargraph.colour = '#bb0000';
    bargraph.dot_size = 3;
    bargraph.text = "#{t('amount')}"
    bargraph.values = data

    x_axis = XAxis.new
    x_axis.labels = x_labels

    y_axis = YAxis.new
    y_axis.set_range(largest_value-(largest_value*2), largest_value, largest_value/5)

    title = Title.new("#{t('finance_transactions')}")

    x_legend = XLegend.new("#{t('examination_name')}")
    x_legend.set_style('{font-size: 14px; color: #778877}')

    y_legend = YLegend.new("#{t('marks')}")
    y_legend.set_style('{font-size: 14px; color: #770077}')

    chart = OpenFlashChart.new
    chart.set_title(title)
    chart.set_x_legend = x_legend
    chart.set_y_legend = y_legend
    chart.y_axis = y_axis
    chart.x_axis = x_axis

    chart.add_element(bargraph)


    render :text => chart.render


  end

  #fee Discount
  def fee_discounts
    @batches = Batch.active
  end

  def fee_discount_new
    @batches = Batch.active
  end

  def load_discount_create_form
    @fee_categories = FinanceFeeCategory.all(:select => "DISTINCT finance_fee_categories.*",
      :joins => [{:category_batches => :batch}, :fee_particulars],
      :conditions => ["batches.is_active = 1 AND batches.is_deleted = 0 AND finance_fee_categories.is_deleted=0 AND
                       finance_fee_particulars.is_deleted = 0 AND
                       financial_year_id #{current_financial_year_id.present? ? '=' : 'IS'} ?", current_financial_year_id])
    @master_discounts = MasterFeeDiscount.core
    if params[:type] == "batch_wise"
      @fee_discount = BatchFeeDiscount.new
      render_partial({'form-box' => ['partial', "batch_wise_discount_form"], 'form-errors' => ['text', ""]})
    elsif params[:type] == "category_wise"
      @student_categories = StudentCategory.active
      render_partial({'form-box' => ['partial', "category_wise_discount_form"], 'form-errors' => ['text', ""]})
    elsif params[:type] == "student_wise"
      @courses = Course.active
      @students = []
      render_partial({'form-box' => ['partial', "student_wise_discount_form"], 'form-errors' => ['text', ""]})
    else
      render_partial({'form-box' => ['text', ""], 'form-errors' => ['text', ""]})
    end

  end

  def load_discount_batch
    if params[:id].present?
      @course = Course.find(params[:id])
      @batches =Batch.find(:all, :joins => "INNER JOIN students on students.batch_id=batches.id", :conditions => "batches.course_id=#{@course.id}").uniq
      #@batches = @course.batches.active
      render :update do |page|
        page.replace_html "batch-box", :partial => "fee_discount_batch_list"
      end
    else
      render :update do |page|
        page.replace_html "batch-box", :text => ""
      end
    end
  end

  def load_particular_fee_categories
    if params[:batch]
      @fees_categories=FinanceFeeCategory.find(:all, :select => "distinct finance_fee_categories.*", :joins => [:fee_particulars], :conditions => ["finance_fee_particulars.is_deleted=false and finance_fee_particulars.batch_id=?", "#{params[:batch]}"])
      render :update do |page|
        page.replace_html "fee-category-box", :partial => "fee_particular_category_list"
      end
    else
      render :update do |page|
        page.replace_html "fee-category-box", :text => ""
      end
    end
  end

  def load_fee_category_particulars
    if params[:id].present?
      if params[:cat_id].present?
        @particulars=FinanceFeeParticular.find(:all, :select => "finance_fee_particulars.*",
          :conditions => ["finance_fee_category_id =? and is_deleted = false and
                                  (receiver_type='Batch' or (receiver_type='StudentCategory' and 
                                   receiver_id=?) ) ", params[:id], params[:cat_id]])
      else
        @particulars=FinanceFeeParticular.find(:all, :select => "finance_fee_particulars.*",
          :conditions => {:finance_fee_category_id => params[:id], :is_deleted => false})
      end
      # @student_categories=StudentCategory.active
      render :update do |page|
        page.replace_html "batch-data", :partial => "discount_particulars_list"
      end
    else
      render :update do |page|
        page.replace_html "batch-data", :text => ""
      end
    end

  end

  def particular_discount_applicable_students
    if params[:particulars].present?
      @students= Student.find(:all, :select => "distinct students.*,ffp.id as master_receiver_id,concat(ffp.name,'-',batches.name) as receiver_name,'FinanceFeeParticular' as master_receiver_type", :joins => "inner join batches on batches.id=students.batch_id inner join finance_fee_particulars ffp on ffp.batch_id=students.batch_id and ((ffp.receiver_type='Student' and ffp.receiver_id=students.id) or (ffp.receiver_type='Batch' and ffp.receiver_id=students.batch_id) or (ffp.receiver_type='StudentCategory' and ffp.receiver_id=students.student_category_id))", :conditions => ["ffp.id in (?)", params[:particulars]], :order => "students.first_name asc").group_by(&:receiver_name)
    else
      @students=Student.find(:all, :joins => {:batch => :course}, :select => "distinct students.*,students.batch_id as master_receiver_id,concat(courses.code,'-',batches.name) as receiver_name,'Student' as master_receiver_type", :conditions => ["students.batch_id in (?) and students.is_deleted=false", params[:batch_ids]], :order => "students.first_name asc").group_by(&:receiver_name)
    end
    respond_to do |format|
      format.js { render :action => 'particular_discount_applicable_students.js.erb'
      }
      format.html
    end
  end

  def load_batch_fee_category
    if params[:batch].present?
      @batch=Batch.find(params[:batch])
      fees_categories =FinanceFeeCategory.find(:all, :joins => "INNER JOIN category_batches on category_batches.finance_fee_category_id=finance_fee_categories.id INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=category_batches.finance_fee_category_id",
        :conditions => "finance_fee_particulars.batch_id=#{@batch.id} and category_batches.batch_id=#{@batch.id} and finance_fee_particulars.is_deleted=false and finance_fee_categories.is_deleted=false and finance_fee_categories.is_master=1").uniq
      #fees_categories = @batch.finance_fee_categories.find(:all,:conditions=>"is_deleted = 0 and is_master = 1")
      @fees_categories=[]
      fees_categories.each do |f|
        particulars=f.fee_particulars.select { |s| s.is_deleted==false }
        unless particulars.empty?
          @fees_categories << f
        end
      end
      render :update do |page|
        page.replace_html "fee-category-box", :partial => "fee_discount_category_list"
      end
    else
      render :update do |page|
        page.replace_html "fee-category-box", :text => ""
      end
    end
  end


  def batch_wise_discount_create
    unless params[:fee_discount][:finance_fee_category_id].blank? or params[:fee_collection].blank?
      FeeDiscount.transaction do
        params[:fee_collection][:category_ids].each do |c|
          @fee_discount = FeeDiscount.new(params[:fee_discount])

          if params[:fee_discount][:master_receiver_type]=='FinanceFeeParticular'
            master_receiver=FinanceFeeParticular.find(c)
            @fee_discount.master_receiver=master_receiver
            @fee_discount.receiver = master_receiver.receiver
            @fee_discount.batch_id=master_receiver.batch_id
          else
            @fee_discount.receiver_type="Batch"
            @fee_discount.receiver_id = c
            @fee_discount.batch_id=c
          end

          unless @fee_discount.save
            @error = true
            raise ActiveRecord::Rollback
          end
        end
      end
    else
      @fee_discount = FeeDiscount.new(params[:fee_discount])
      @fee_discount.save
      @error = true
    end
  end

  def category_wise_fee_discount_create
    unless params[:fee_discount][:finance_fee_category_id].blank? or params[:fee_collection].blank?
      FeeDiscount.transaction do
        params[:fee_collection][:category_ids].each do |c|
          @fee_discount = FeeDiscount.new(params[:fee_discount])
          if params[:fee_discount][:master_receiver_type]=='FinanceFeeParticular'
            master_receiver=FinanceFeeParticular.find(c)
            @fee_discount.master_receiver=master_receiver
            @fee_discount.batch_id=master_receiver.batch_id
          else
            @fee_discount.receiver_type="StudentCategory"
            @fee_discount.batch_id=c
          end

          unless @fee_discount.save
            @error = true
            @fee_discount.errors.add_to_base("#{t('select_student_category')}") if params[:fee_discount][:receiver_id].empty?
            raise ActiveRecord::Rollback
          end
        end
      end
    else
      @fee_discount = FeeDiscount.new(params[:fee_discount])
      @fee_discount.save
      @error = true
    end
  end

  def student_wise_fee_discount_create
    unless params[:fee_discount][:finance_fee_category_id].blank?
      @fee_category=FinanceFeeCategory.find(params[:fee_discount][:finance_fee_category_id])
      s=@fee_category
      discount_attributes=params[:discounts]
      if params[:discounts].present?
        attributes_to_be_merged=params[:fee_discount].delete_if { |k, v| k=='master_receiver_type' or k=='finance_fee_category_id' }
        discount_attributes[:fee_discounts_attributes].each { |k, v| v.merge!(attributes_to_be_merged) }

        @fee_category.fee_discounts_attributes=discount_attributes['fee_discounts_attributes']
        #        unless @fee_category.valid?
        #          @error=true
        #        else
        Delayed::Job.enqueue(DelayedStudentFeeDiscount.new(@fee_category.id, discount_attributes))
        #        end
      else
        @error=true
        @fee_category.errors.add_to_base("#{t('select_at_least_one_student')}")
      end
    else
      @fee_category=FinanceFeeCategory.new()
      @error=true
      @fee_category.errors.add_to_base(t('fees_category_cant_be_blank'))
    end
  end


  def update_master_fee_category_list
    @batch = Batch.find_by_id(params[:id])
    if @batch.present?
      fy_id = current_financial_year_id
      @fee_categories = @batch.finance_fee_categories.current_active_financial_year.all(
        :conditions => ["is_master=1 and is_deleted= 0"], :order => "name asc")
      render_partial({'master-category-box' => ['partial', "update_master_fee_category_list"]})
    else
      render_partial({'master-category-box' => ['text', ""]})
    end
  end

  def show_fee_discounts
    @batch=Batch.find(params[:b_id])
    if params[:id]==""
      render :update do |page|
        page.replace_html "discount-box", :text => ""
      end
    else

      @fee_category = FinanceFeeCategory.find(params[:id])
      @discounts = @fee_category.fee_discounts.all(:joins => "LEFT OUTER JOIN students ON students.id = fee_discounts.receiver_id AND fee_discounts.receiver_type = 'Student' LEFT OUTER JOIN batches ON batches.id = fee_discounts.receiver_id AND fee_discounts.receiver_type = 'Batch' LEFT OUTER JOIN student_categories ON student_categories.id = fee_discounts.receiver_id AND fee_discounts.receiver_type = 'StudentCategory'", :conditions => ["(students.id IS NOT NULL OR batches.id IS NOT NULL OR student_categories.id IS NOT NULL) AND fee_discounts.batch_id='#{@batch.id}' AND fee_discounts.is_deleted= 0"])

      render :update do |page|
        page.replace_html "discount-box", :partial => "show_fee_discounts"
      end
    end
  end

  def edit_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
    @master_discounts = MasterFeeDiscount.core
  end

  def update_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
    unless @fee_discount.update_attributes(params[:fee_discount])
      @error = true
    else
      @fee_category = @fee_discount.finance_fee_category
      @discounts = @fee_category.fee_discounts.all(:conditions => ["batch_id='#{@fee_discount.batch_id}'  and is_deleted= 0"])
      #@fee_category.is_collection_open ? @discount_edit = false : @discount_edit = true
    end
  end

  def delete_fee_discount
    @fee_discount = FeeDiscount.find(params[:id])
    #batch=@fee_discount.batch
    @fee_category = FinanceFeeCategory.find(@fee_discount.finance_fee_category_id)
    @error = true unless @fee_discount.update_attributes(:is_deleted => true)
    unless @fee_category.nil?
      @discounts = @fee_category.fee_discounts.all(:conditions => ["batch_id='#{@fee_discount.batch_id}' and is_deleted= #{false}"])
      #@fee_category.is_collection_open ? @discount_edit = false : @discount_edit = true
    end
    render :update do |page|
      page.replace_html "discount-box", :partial => "show_fee_discounts"
      page.replace_html "flash-notice", :text => "<p class='flash-msg'>#{t('discount_deleted_successfully')}.</p>"
    end

  end

  def collection_details_view
    @fee_collection = FinanceFeeCollection.find_by_id(params[:id], :include => :fee_account,
      :conditions => "fa.id IS NULL OR fa.is_deleted = false",
      :joins => "LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id")
    precision_count = FedenaPrecision.get_precision_count
    unless @fee_collection.present?
      flash[:notice] = t("flash_msg5")
      redirect_to :controller => "user", :action => "dashboard"
    else
      if @fee_collection.tax_enabled?
        particular_joins = "LEFT JOIN collectible_tax_slabs cts
                                             ON cts.collectible_entity_id = finance_fee_particulars.id AND
                                                   cts.collectible_entity_type = 'FinanceFeeParticular' AND
                                                   cts.collection_id = #{@fee_collection.id} AND
                                                   cts.collection_type = 'FinanceFeeCollection'
                                    LEFT JOIN tax_slabs ts ON ts.id = cts.tax_slab_id"
        particular_select = ",IFNULL(CONCAT(ts.name,'(',ROUND(ts.rate,#{precision_count}),')%'),'-') AS slab_name"
      else
        particular_select = ""
        particular_joins = ""
      end
      @particulars = @fee_collection.finance_fee_particulars.all(
        :select => "DISTINCT finance_fee_particulars.*#{particular_select}",
        :conditions => {:batch_id => params[:batch_id]},
        :joins => "#{particular_joins}")
      @total_payable=@particulars.map { |s| s.amount }.sum.to_f
      @discounts = @fee_collection.fee_discounts.all(:conditions => {:batch_id => params[:batch_id]})
    end
  end

  def fixed_category_name
    @cat_names = ['Fee', 'Salary', 'Donation']
    @plugin_cat = []
    FedenaPlugin::FINANCE_CATEGORY.each do |category|
      @cat_names << "#{category[:category_name]}"
      @plugin_cat << "#{category[:category_name]}"
    end
    @fixed_cat_ids = FinanceTransactionCategory.find(:all, :conditions => {:name => @cat_names}).collect(&:id)
  end

  def delete_transaction_fees_defaulters
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)
    # the following query (till end of transaction block) is to delete the waiver discount in fee discount
    fee_discounts = @financefee.fee_discounts
    fee_discount_record = fee_discounts.detect{|x| x.finance_transaction_id.present?} if fee_discounts.present?
    transaction_id = params[:transaction_id]
    if fee_discount_record.present?
      if fee_discount_record.finance_transaction_id.to_i == transaction_id.to_i
        FinanceFeeParticular.transaction do
          fee_discount = FeeDiscount.find(fee_discount_record.id)
          fee_discount.destroy
          DiscountParticularLog.create(:amount => fee_discount_record.discount, :is_amount => fee_discount_record.is_amount,
            :receiver_type => "FeeDiscount", :finance_fee_id => @financefee.id, :user_id => current_user.id,
            :name => fee_discount_record.name)
          @financefee.reload
          FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
        end
      end
    end
    @financefee.reload
    @target_action='pay_fees_defaulters'
    @target_controller='finance'
    transaction_deletion
    render :update do |page|
      page.redirect_to :action => "pay_fees_defaulters", :id => @student, :date => @date, :batch_id => params[:batch_id]
    end
  end


  def delete_transaction_for_particular_wise_fee_pay
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)
    # the following query (till end of transaction block) is to delete the waiver discount in fee discount
    fee_discounts = @financefee.fee_discounts
    fee_discount_record = fee_discounts.detect{|x| x.finance_transaction_id.present?} if fee_discounts.present?
    transaction_id = params[:transaction_id]
    if fee_discount_record.present?
      if fee_discount_record.finance_transaction_id.to_i == transaction_id.to_i
        FinanceFeeParticular.transaction do
          fee_discount = FeeDiscount.find(fee_discount_record.id)
          fee_discount.destroy
          DiscountParticularLog.create(:amount => fee_discount_record.discount, :is_amount => fee_discount_record.is_amount,
            :receiver_type => "FeeDiscount", :finance_fee_id => @financefee.id, :user_id => current_user.id,
            :name => fee_discount_record.name)
          @financefee.reload
          FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
        end
      end
    end
    @financefee.reload
    @target_action = 'particular_wise_fee_payment'
    @target_controller = 'finance_extensions'
    transaction_deletion
    @financefee.reload
    @transaction_date = @financefee.is_paid? ? @financefee.transactions.last.transaction_date :
      Date.today_with_timezone
    @applied_discount = ParticularDiscount.find(:all, :joins => [{:particular_payment => :finance_fee}],
      :conditions => "particular_discounts.is_active = true and finance_fees.id=#{@financefee.id}").
      sum(&:discount).to_f
    @transaction_category_id = FinanceTransactionCategory.find_by_name("Fee").id
    financial_year_check
    render :update do |page|
      flash[:notice] = "#{t('finance.flash18')}"
      page.replace_html "fee_submission", :partial => "finance_extensions/particular_wise_payment/particular_fees_submission_form"
    end
  end


  def delete_transaction_for_student
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)
    @fine_waiver_val = false
    # the following query (till end of transaction block) is to delete the waiver discount in fee discount
    fee_discounts = @financefee.fee_discounts
    fee_discount_record = fee_discounts.detect{|x| x.finance_transaction_id.present?} if fee_discounts.present?
    transaction_id = params[:transaction_id]
    if fee_discount_record.present?
      if fee_discount_record.finance_transaction_id.to_i == transaction_id.to_i
        FinanceFeeParticular.transaction do
          fee_discount = FeeDiscount.find(fee_discount_record.id)
          fee_discount.destroy
          DiscountParticularLog.create(:amount => fee_discount_record.discount, :is_amount => fee_discount_record.is_amount,
            :receiver_type => "FeeDiscount", :finance_fee_id => @financefee.id, :user_id => current_user.id,
            :name => fee_discount_record.name)
          @financefee.reload
          FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
        end
      end
    end
    @financefee.reload
    transaction_deletion
    @target_action='fees_submission_student'
    @target_controller='finance'
    @transaction_date=Date.today_with_timezone
    financial_year_check
    render :update do |page|
      page.replace_html "fee_submission", :partial => "finance/fees_payment/fees_submission_form"
    end
  end

  def delete_transaction_by_batch
    @target_action='load_fees_submission_batch'
    @target_controller='finance'
    @student = Student.find(params[:id])
    @fine_waiver_val = false
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)
    # the following query (till end of transaction block) is to delete the waiver discount in fee discount
    fee_discounts = @financefee.fee_discounts
    fee_discount_record = fee_discounts.detect{|x| x.finance_transaction_id.present?} if fee_discounts.present?
    transaction_id = params[:transaction_id]
    if fee_discount_record.present?
      if fee_discount_record.finance_transaction_id.to_i == transaction_id.to_i
        FinanceFeeParticular.transaction do
          fee_discount = FeeDiscount.find(fee_discount_record.id)
          fee_discount.destroy 
          DiscountParticularLog.create(:amount => fee_discount_record.discount, :is_amount => fee_discount_record.is_amount,
            :receiver_type => "FeeDiscount", :finance_fee_id => @financefee.id, :user_id => current_user.id,
            :name => fee_discount_record.name)
          @financefee.reload
          FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
        end
      end
    end
    @financefee.reload
    transaction_deletion
    @batch = Batch.find(params[:batch_id])
    @students=Student.find(:all,
      :joins => "INNER JOIN finance_fees
                                 ON finance_fees.student_id=students.id AND 
                                       finance_fees.batch_id=#{@batch.id} 
                      INNER JOIN collection_particulars 
                                 ON collection_particulars.finance_fee_collection_id=finance_fees.fee_collection_id 
                      INNER JOIN finance_fee_particulars 
                                 ON finance_fee_particulars.id=collection_particulars.finance_fee_particular_id",
      :conditions => "finance_fees.fee_collection_id='#{@date.id}' and
                              finance_fee_particulars.batch_id='#{@batch.id}' and 
                            ((finance_fee_particulars.receiver_type='Batch' and 
                              finance_fee_particulars.receiver_id=finance_fees.batch_id) or 
                             (finance_fee_particulars.receiver_type='Student' and 
                              finance_fee_particulars.receiver_id=finance_fees.student_id) or 
                             (finance_fee_particulars.receiver_type='StudentCategory' and 
                              finance_fee_particulars.receiver_id=finance_fees.student_category_id))").uniq
    student_ids=@students.collect(&:id).join(',')
    @dates = FinanceFeeCollection.find(:all)
    @fee = FinanceFee.first(:conditions => "fee_collection_id = #{@date.id}",
      :joins => 'INNER JOIN students ON finance_fees.student_id = students.id')
    @student ||= @fee.student
    @prev_student = @student.previous_fee_student(@date.id, student_ids)
    @next_student = @student.next_fee_student(@date.id, student_ids)
    @transaction_date = @payment_date = Date.today_with_timezone
    financial_year_check
    #@payment_date= @fee.finance_transactions.last.try(:transaction_date) || Date.today
    render :update do |page|
      page.replace_html "fees_detail", :partial => "finance/fees_payment/student_fees_submission"
    end
  end

  # delete a transaction
  def transaction_deletion
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financetransaction=FinanceTransaction.find(params[:transaction_id])
    @financetransaction.cancel_reason = params[:reason]

    ActiveRecord::Base.transaction do
      if FedenaPlugin.can_access_plugin?("fedena_pay")
        finance_payment = @financetransaction.finance_payment
        unless finance_payment.nil?
          status = Payment.payment_status_mapping[:reverted]
          finance_payment.payment.update_attributes(:status_description => status)
        end
      end
      if @financetransaction
        transaction_ledger = @financetransaction.transaction_ledger
        if transaction_ledger.transaction_mode == 'SINGLE'
          transaction_ledger.mark_cancelled(params[:reason])
        else
          raise ActiveRecord::Rollback unless @financetransaction.destroy
        end
      end
    end
    @financefee = @student.finance_fee_by_date(@date)
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,
      :conditions => ["is_deleted IS NOT NULL"])

    flash[:warning]=nil
    flash[:notice]=nil

    @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
    particular_and_discount_details
    bal = (@total_payable-@total_discount).to_f
    days = (Date.today-@date.due_date.to_date).to_i
    auto_fine = @date.fine
    @fine_amount = 0
    @paid_fine = 0
    if days > 0 and auto_fine
      if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
        @fine_amount = @financefee.balance_fine
        @paid_fine = @fine_amount
      else
        @fine_rule = auto_fine.fine_rules.find(:last, :conditions =>
            ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
        @fine_amount = @fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
        @paid_fine = @fine_amount
        if @fine_rule.present?
          @fine_amount = @fine_amount - @financefee.paid_auto_fine
        end
      end
    end
  end

  # calculates discounts and particular details for a fee record
  def particular_and_discount_details
    include_particular_associations = @financefee.tax_enabled ? [:pay_all_discounts] : [:collection_tax_slabs]
    @fee_particulars = @date.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}",
      :include => include_particular_associations).select do |par|
      (par.receiver_type=='Student' and
          par.receiver_id==@student.id) ? par.receiver=@student : par.receiver; (par.receiver.present?) and
        (par.receiver==@student or par.receiver==@financefee.student_category or
          par.receiver==@financefee.batch)
    end
    @categorized_particulars=@fee_particulars.group_by(&:receiver_type)
    if @financefee.tax_enabled?
      @tax_collections = @financefee.tax_collections.all(:include => :tax_slab)
      #      (:select => "distinct tax_collections.*,
      #                        ctxs.tax_slab_id as tax_slab_id, ffp.name as particular_name",
      #        :include => :tax_slab,
      #        :joins => "INNER JOIN collectible_tax_slabs ctxs
      #                                    ON ctxs.collectible_entity_type = tax_collections.taxable_entity_type AND
      #                                          ctxs.collectible_entity_id = tax_collections.taxable_entity_id AND
      #                                          ctxs.collection_id = #{@financefee.fee_collection_id} AND
      #                                          ctxs.collection_type = 'FinanceFeeCollection'
      #                        INNER JOIN tax_slabs
      #                                    ON tax_slabs.id = ctxs.tax_slab_id
      #                        INNER JOIN finance_fee_particulars ffp
      #                                    ON ffp.id=tax_collections.taxable_entity_id")

      @total_tax = @tax_collections.map do |x|
        FedenaPrecision.set_and_modify_precision(x.tax_amount).to_f
      end.sum.to_f

      #      @tax_slabs = @tax_collections.map {|tax_col| tax_col.tax_slab }.uniq

      #      @tax_slabs =  TaxSlab.all(:conditions => {:id => @tax_collections.keys })
      @tax_slabs = @tax_collections.group_by { |x| x.tax_slab }

      @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
          'FinanceTaxIdentificationNumber']) if @tax_slabs.present?
    end
    @discounts=@date.fee_discounts.all(:conditions => "batch_id=#{@financefee.batch_id}").
      select do |par|
      (par.receiver.present?) and
        ((par.receiver==@financefee.student or
            par.receiver==@financefee.student_category or
            par.receiver==@financefee.batch) and
          (par.master_receiver_type!='FinanceFeeParticular' or
            (par.master_receiver_type=='FinanceFeeParticular' and
              (par.master_receiver.receiver.present? and
                @fee_particulars.collect(&:id).include? par.master_receiver_id) and
              (par.master_receiver.receiver==@financefee.student or
                par.master_receiver.receiver==@financefee.student_category or
                par.master_receiver.receiver==@financefee.batch))))
    end
    @categorized_discounts=@discounts.group_by(&:master_receiver_type)
    @total_discount = 0
    @total_payable=@fee_particulars.map { |s| s.amount }.sum.to_f
    @total_discount =@discounts.map do |d|
      d.master_receiver_type=='FinanceFeeParticular' ?
        (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) :
        @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100)
    end.sum.to_f unless @discounts.nil?
  end

  # fetches cancelled finance transactions
  def update_deleted_transactions
    all_fee_types = ['HostelFee', 'TransportFee', 'FinanceFee', 'Refund', 'BookMovement', 'InstantFee']
    @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,
      :include => [:user], :order => 'created_at desc',
      :select => "cancelled_finance_transactions.payee_id, cancelled_finance_transactions.payee_type,
                  IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no,
                  cancelled_finance_transactions.amount, cancel_reason,
                  cancelled_finance_transactions.user_id, cancelled_finance_transactions.created_at,
                  collection_name, finance_type",
      :conditions => ["#{active_account_conditions(true,'ftrr')} AND
                       cancelled_finance_transactions.created_at BETWEEN ? AND ? and
                       (collection_name is not null or finance_type in (?))", Date.today, Date.today, all_fee_types],
      :joins => "INNER JOIN finance_transaction_receipt_records ftrr
                         ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                  #{active_account_joins(true,'ftrr')}
                 INNER JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id")
    if request.xhr?
      render :update do |page|
        page.replace_html 'deleted_transactions', :partial => "finance/deleted_transactions"
      end
    end
  end

  # fetches cancelled finance transactions by date range
  def transaction_filter_by_date
    @start_date, @end_date = params[:s_date], params[:e_date]
    all_fee_types = ['HostelFee', 'TransportFee', 'FinanceFee', 'Refund', 'BookMovement', 'InstantFee']
    salary = FinanceTransaction.get_transaction_category('Salary')
    joins = ""
    if params['transaction_type'] == t('advance_fees_text')
      @transactions = CancelledAdvanceFeeTransaction.paginate(:page => params[:page], :per_page => 20, 
        :order => "cancelled_advance_fee_transactions.created_at desc",
        :joins => [:student, :transaction_receipt], 
        :conditions => ['cancelled_advance_fee_transactions.created_at BETWEEN ? AND ?', @start_date, @end_date.to_date+1.day], 
        :select => "concat(students.first_name, ' ', students.middle_name, ' ', students.last_name) as payee_name, transaction_receipts.ef_receipt_number as receipt_no, 'Advance Fees' as finance_type, 
        cancelled_advance_fee_transactions.fees_paid as amount, cancelled_advance_fee_transactions.user_id as user_id, cancelled_advance_fee_transactions.reason_for_cancel as cancel_reason, cancelled_advance_fee_transactions.created_at")
    else
      if params['transaction_type'].present? and params['transaction_type'] == t('others')
        conditions = "and (collection_name is null or finance_type not in (?)) and category_id <> ?"
      elsif params['transaction_type'].present? and params['transaction_type'] == t('payslips')
        conditions = "and (collection_name is null or finance_type not in (?)) and category_id = ?"
      else
        joins = "LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
        conditions = "and (fa.id IS NULL OR fa.is_deleted = false) AND (collection_name is not null or finance_type in (?)) and category_id <> ?"
      end
  
      @transactions = CancelledFinanceTransaction.paginate(:page => params[:page],
        :per_page => 20, :order => 'cancelled_finance_transactions.created_at desc',
        :select => "cancelled_finance_transactions.*,
                          IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number), '-') AS receipt_no",
        :joins => "LEFT JOIN finance_transaction_receipt_records ftrr
                          ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                   LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id #{joins}",
        :conditions => ["cancelled_finance_transactions.created_at BETWEEN ? AND ?
                                 #{conditions}", @start_date, @end_date, all_fee_types, salary])
    end
    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/search_by_date_deleted_transactions"
    end
  end

  # list cancelled transactions
  def list_deleted_transactions
    @transactions = CancelledFinanceTransaction.paginate(:page => params[:page],
      :select => "cancelled_finance_transactions.*,
                        IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no",
      :joins => "LEFT JOIN finance_transaction_receipt_records ftrr
                        ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                 #{active_account_joins(true,'ftrr')}
                 LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id",
      :conditions => ["(fa.id IS NULL OR ) AND created_at >='#{FedenaTimeSet.current_time_to_local_time(Time.now).to_date}' and
                                 created_at <'#{FedenaTimeSet.current_time_to_local_time(Time.now).to_date+1.day}'"],
      :per_page => 20, :order => 'created_at desc')
    render :update do |page|
      page.replace_html 'deleted_transactions', :partial => "finance/deleted_transactions"
    end
  end

  # fetch cancelled transactions by collections
  def search_fee_collection
    if params[:option] == t('fee_collection_name')
      @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,
        :select => "cancelled_finance_transactions.*,
                    IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no",
        :order => "cancelled_finance_transactions.created_at desc",
        :joins => "LEFT JOIN finance_transaction_receipt_records ftrr
                          ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                   LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                   #{active_account_joins(true,'ftrr')}",
        :conditions => ["collection_name LIKE ? AND #{active_account_conditions(true, 'ftrr')}",
          # (ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
          "#{params[:query]}%"]) unless params[:query] == ''
    elsif params[:option]==t('date_text')
      @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,
        :select => "cancelled_finance_transactions.*,
                          IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no",
        :order => 'cancelled_finance_transactions.created_at desc',
        :joins => "LEFT JOIN finance_transaction_receipt_records ftrr
                          ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                   LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                   #{active_account_joins(true,'ftrr')}",
        :conditions => ["cancelled_finance_transactions.created_at LIKE ? AND #{active_account_conditions(true, 'ftrr')}",
          # (ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
          "#{params[:query]}%"]) unless params[:query] == ''
    else
      if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,
          :include => :user, :order => 'cancelled_finance_transactions.created_at desc',
          :select => "cancelled_finance_transactions.payee_id, cancelled_finance_transactions.payee_type,
                            IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no, 
                            cancelled_finance_transactions.amount, cancel_reason, 
                            cancelled_finance_transactions.user_id, cancelled_finance_transactions.created_at, 
                            collection_name, finance_type",
          :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                     LEFT OUTER JOIN employees ON employees.id = payee_id
                     LEFT OUTER JOIN instant_fees ON instant_fees.id = finance_id
                           LEFT JOIN finance_transaction_receipt_records ftrr
                                  ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                           LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                           #{active_account_joins(true,'ftrr')}",
          :conditions => ["(students.admission_no LIKE ? OR employees.employee_number LIKE ? OR
                           instant_fees.guest_payee LIKE ?) AND #{active_account_conditions(true, 'ftrr')}",
            # (ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
            "#{params[:query]}%", "#{params[:query]}%",
            "#{params[:query]}%"]) unless params[:query] == ''
      else
        @transactions = CancelledFinanceTransaction.paginate(:page => params[:page], :per_page => 20,
          :select => "cancelled_finance_transactions.payee_id, cancelled_finance_transactions.payee_type,
                            IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no, 
                            cancelled_finance_transactions.amount, cancel_reason, 
                            cancelled_finance_transactions.user_id, cancelled_finance_transactions.created_at, 
                            collection_name, finance_type",
          :include => [:user,:payee], :order => 'created_at desc',
          :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                     LEFT OUTER JOIN employees ON employees.id = payee_id
                           LEFT JOIN finance_transaction_receipt_records ftrr
                                  ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                           LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                           #{active_account_joins(true,'ftrr')}",
          :conditions => ["(students.admission_no LIKE ? OR employees.employee_number LIKE ?) AND #{active_account_conditions(true, 'ftrr')}",
            # (ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
            "#{params[:query]}%", "#{params[:query]}%"]) unless params[:query] == ''
      end
    end

    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/search_deleted_transactions"
    end
    #render :partial => "finance/search_deleted_transactions"
  end

  # fetch transactions by various filters
  def transactions_advanced_search
    @searched_for = ""
    if (params[:search] or params[:date])
      all_fee_types = "'HostelFee','TransportFee','FinanceFee','Refund','BookMovement','InstantFee'"
      salary = FinanceTransaction.get_transaction_category('Salary')
      if params['transaction']['type'].present? and params['transaction']['type']== "#{t('advance_fees_text')}"
        @searched_for = @searched_for+ "<span> #{t('transaction_type')}</span>: #{t('advance_fees_text')}"
        conditions = ''
      elsif params['transaction']['type'].present? and params['transaction']['type']==t('others')
        @searched_for = @searched_for+ "<span> #{t('transaction_type')}</span>: #{t('others')}"
        conditions="and (fa.id IS NULL OR fa.is_deleted = false) AND (cancelled_finance_transactions.collection_name is null or
                        cancelled_finance_transactions.finance_type not in (#{all_fee_types})) and category_id <> #{salary}"
      elsif params['transaction']['type'].present? and params['transaction']['type']==t('payslips')
        @searched_for = @searched_for+ "<span> #{t('transaction_type')}</span>: #{t('payslips')}"
        conditions="and (cancelled_finance_transactions.collection_name is null or
                         cancelled_finance_transactions.finance_type not in (#{all_fee_types})) and category_id = #{salary}"
      else
        @searched_for = @searched_for+ "<span> #{t('transaction_type')}</span>: #{t('fees_text')}"
        conditions="and (fa.id IS NULL OR fa.is_deleted = false) AND (cancelled_finance_transactions.collection_name is not null or
                         cancelled_finance_transactions.finance_type in (#{all_fee_types})) and category_id <> #{salary}"
      end

      search_attr=params[:search].delete_if { |k, v| v=="" }
      condition_attr=""
      search_attr.keys.each do |k|
        if ["collection_name", "category_id"].include?(k)

          condition_attr=condition_attr+" AND cancelled_finance_transactions.#{k} LIKE ? "

        elsif ["first_name", "admission_no"].include?(k)
          condition_attr=condition_attr+" AND students.#{k} LIKE ?"
        elsif ["employee_number", "employee_name"].include?(k)

          k=="employee_number" ? condition_attr=condition_attr+" AND employees.#{k} LIKE ?" : condition_attr=condition_attr+" AND employees.first_name LIKE ?"
        else
          condition_attr=condition_attr+" AND instant_fees.#{k} LIKE ?" if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
        end

      end
      condition_attr=condition_attr+conditions
      #p condition_attr.split(' ')[1..-1].join(' ')
      unless condition_attr.empty?
        condition_attr=condition_attr.split(' ')[1..-1].join(' ')
        condition_attr="("+condition_attr+")"+" AND (cancelled_finance_transactions.created_at < ? AND cancelled_finance_transactions.created_at > ?)"
      else
        condition_attr= "(cancelled_finance_transactions.created_at < ? AND cancelled_finance_transactions.created_at > ?)"
      end
      condition_array=[]
      condition_array << condition_attr
      search_attr.values.each { |c| condition_array<< (c+"%") }
      #i=2
      condition_array<<"#{params[:date][:end_date].to_date+1.day}%"
      condition_array<<"#{params[:date][:start_date]}%"
      #params[:date].values.each{|d| i=i-1;condition_array<< (d.to_date+i.day)}
      if params[:transaction][:type] == t('advance_fees_text')
        @start_date = "#{params[:date][:start_date]}%"
        @end_date = "#{params[:date][:end_date].to_date+1.day}%"
        @transactions = CancelledAdvanceFeeTransaction.paginate(:page => params[:page], :per_page => 20, :order => 'cancelled_advance_fee_transactions.created_at desc',
          :joins => [:student, :transaction_receipt], 
          :conditions => ['(cancelled_advance_fee_transactions.created_at BETWEEN ? AND ?) AND students.admission_no like ? AND students.first_name like ?', 
            @start_date, @end_date, params[:search][:admission_no], params[:search][:first_name]], 
          :select => "concat(students.first_name, ' ', students.middle_name, ' ', students.last_name) as payee_name, cancelled_advance_fee_transactions.fees_paid as amount, 
            cancelled_advance_fee_transactions.user_id as user_id, cancelled_advance_fee_transactions.reason_for_cancel as cancel_reason, 'Advance Fees' as finance_type,
            'Advance Fees' as collection_name, cancelled_advance_fee_transactions.created_at, cancelled_advance_fee_transactions.transaction_data, transaction_receipts.ef_receipt_number as receipt_number,
            transaction_receipts.ef_receipt_number as receipt_no")
      else
        if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
          @transactions = CancelledFinanceTransaction.paginate(:page => params[:page],
            :select => "cancelled_finance_transactions.*,
                              IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no",
            :per_page => 20, :order => 'created_at desc',
            :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                            LEFT OUTER JOIN employees ON employees.id = payee_id 
                            LEFT OUTER JOIN instant_fees ON instant_fees.id = finance_id
                            INNER JOIN finance_transaction_receipt_records ftrr
                                        ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                            INNER JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                            LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
            :conditions => condition_array) unless params[:query] == ''
        else
          @transactions = CancelledFinanceTransaction.paginate(:page => params[:page],
            :select => "cancelled_finance_transactions.*,
                              IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), tr.receipt_number),'') AS receipt_no",
            :per_page => 20, :order => 'created_at desc',
            :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                            LEFT OUTER JOIN employees ON employees.id = payee_id 
                            INNER JOIN finance_transaction_receipt_records ftrr 
                                        ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                            INNER JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                            LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
            :conditions => condition_array) unless params[:query] == ''
        end
      end
      search_attr.each do |k, v|
        @searched_for=@searched_for+ "<span> #{k.humanize}</span>"
        @searched_for=@searched_for+ ": " +v.humanize+" "
      end
      params[:date].each do |k, v|
        @searched_for=@searched_for+ "<span> #{k.humanize}</span>"
        @searched_for=@searched_for+ ": " +format_date(v.humanize)+" "
      end
      if params[:remote]=="remote"
        render :update do |page|
          page.replace_html 'search-result', :partial => "finance/transaction_advanced_search"
        end
      end
    end
  end

  # get fetched cancelled transactions as pdf / csv
  def advanced_cancelled_transaction_reports
    @data_hash = CancelledFinanceTransaction.fetch_cancelled_transactions_advance_search_result(params)
    if params[:report_format_type] == "pdf"
      render :pdf => "advanced_cancelled_transaction_reports",
        :margin => {:left => 10, :right => 10, :top => 5, :bottom => 5},
        :show_as_html => params.key?(:d), :header => {:html => nil}, :footer => {:html => nil}
    else
      send_data(@data_hash, :type => 'text/csv; charset=utf-8; header=present', :filename => "advanced_cancelled_transactions.csv")
    end
  end

  # render form for new RefundRule
  def new_refund
    @refund_rule=RefundRule.new
    @collections=FinanceFeeCollection.find(:all, :conditions => {:is_deleted => false}, :group => :name)
  end

  # records new refund rule
  def create_refund

    @refund_rule=RefundRule.new
    @old_collections = FinanceFeeCollection.current_active_financial_year.active.all(
      :joins => "#{active_account_joins}",
      :conditions => "finance_fee_collections.batch_id is not null AND #{active_account_conditions}",
      :group => :name)
    @new_collections = FinanceFeeCollection.current_active_financial_year.active.all(
      :select => "distinct finance_fee_collections.*",
      :joins => "INNER JOIN fee_collection_batches fcb ON fcb.finance_fee_collection_id = finance_fee_collections.id
                                    INNER JOIN batches b ON b.id = fcb.batch_id #{active_account_joins}",
      :conditions => "finance_fee_collections.batch_id IS NULL AND #{active_account_conditions} AND
                                         b.is_active = true AND b.is_deleted = false")
    @collections = (@old_collections + @new_collections).uniq
    if request.post?
      @refund_rule.attributes = params[:refund_rule]
      @refund_rule.user = current_user
      if @refund_rule.save
        flash[:notice] = "#{t('refund_rule_created')}"
        redirect_to :controller => 'finance', :action => 'create_refund'
      else
        render :create_refund
      end
    end
  end

  # search student refunds
  def refund_student_search
    query = params[:query]
    if query.length >= 3
      conditions = "first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR admission_no = ? OR
                         (concat(first_name, \" \", last_name) LIKE ? )"
      cond_vars = ["#{query}%", "#{query}%", "#{query}%", "#{query}", "#{query}"]
    else
      conditions = "admission_no = ? "
      cond_vars = ["#{query}"]
      # @students = Student.find(:all, :joins => 'INNER JOIN finance_fees ON finance_fees.student_id = students.id AND finance_fees.balance=0',
      # :conditions => ["admission_no = ? ", query],
      # :order => "batch_id asc,first_name asc") unless query == ''
    end
    @students = Student.find(:all,
      :joins => "INNER JOIN finance_fees ON finance_fees.student_id = students.id AND finance_fees.balance = 0
                                       INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
                                       #{active_account_joins(true, 'ffc')}",
      :conditions => ["#{conditions} AND #{active_account_conditions(true, 'ffc')}"] + cond_vars,
      :group => "students.id", :order => "batch_id asc,first_name asc") unless query == ''
    # @students = @students.uniq
    render :layout => false
  end

  # renders refunds for a student wrt collections
  def fees_refund_dates
    @student=Student.find(params[:id])
    @dates= FinanceFeeCollection.find(:all, :select => "distinct finance_fee_collections.*",
      :joins => " #{active_account_joins}
                 INNER JOIN finance_fees ff
                         ON ff.fee_collection_id = finance_fee_collections.id AND
                            ff.student_id='#{@student.id}' AND
                            ff.balance = 0 AND ff.is_paid=true
                  LEFT JOIN fee_collection_batches fcb
                         ON fcb.finance_fee_collection_id=finance_fee_collections.id and
                            fcb.batch_id=ff.batch_id
                  LEFT JOIN batches on batches.id=ff.batch_id
                  LEFT JOIN fee_refunds fr on fr.finance_fee_id=ff.id",
      :conditions => "(finance_fee_collections.is_deleted = false OR
                       fr.id is not null) and batches.is_active=true AND #{active_account_conditions}",
      :order => "name asc")
  end

  # apply refund for a student
  def fees_refund_student
    @student = Student.find(params[:id])
    if params[:date].present?
      @date = @fee_collection = FinanceFeeCollection.find(params[:date], :conditions => "#{active_account_conditions}",
        :joins => "#{active_account_joins}")
      if @date.present?
        ff_assoc = @date.tax_enabled? ? { :tax_collections => :tax_slab } : {}
        @financefee = @student.finance_fee_by_date(@date, ff_assoc)

        @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,
          :conditions => ["is_deleted IS NOT NULL"])

        @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)

        @refund_amount=0
        particular_and_discount_details
        #@collection=FinanceFeeCollection.find_by_name(@date.name, :conditions => {:is_deleted => false})
        @refund_rule=@date.refund_rules.find(:first, :order => 'refund_validity ASC',
          :conditions => ["refund_validity >=  '#{FedenaTimeSet.current_time_to_local_time(Time.now).
            to_date}'"])
        @fee_refund=@financefee.fee_refund
        if @fee_refund
          #@fee_refund=@financefee.fee_refund
          @refund_rule=@fee_refund.refund_rule if @fee_refund
        end
        total_fees = (@total_payable-@total_discount)
        @refund_amount=(total_fees)*(@refund_rule.amount.to_f)/(@refund_rule.is_amount ?
            total_fees : 100) if @refund_rule
        @eligible_refund= (total_fees > @refund_amount) ? @refund_amount : total_fees
        if request.post?
          FeeRefund.transaction do
            transaction = FinanceTransaction.new
            #          transaction.receipt_no = transaction.refund_receipt_no
            transaction.title = "#{@refund_rule.name} &#x200E;(#{@student.first_name}) &#x200E;"
            transaction.category = FinanceTransactionCategory.find_by_name("Refund")
            transaction.payee = @student
            transaction.amount = params[:fees][:amount].to_f
            transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
            transaction.description = params[:fees][:reason]
            transaction.save

            @fee_refund=transaction.build_fee_refund(params[:fees])
            @fee_refund.finance_fee_id=@financefee.id
            @fee_refund.user=current_user
            @fee_refund.refund_rule=@refund_rule
            unless @fee_refund.save
              raise ActiveRecord::Rollback
            else
              flash[:notice]="#{t('refund')} #{t('succesful')}"
            end

          end

          render :update do |page|
            page.replace_html "flash-div", :text => ''
            page.replace_html "refund", :partial => "fees_refund_form"
          end

        else
          render :update do |page|
            page.replace_html "fee_submission", :partial => "fees_refund_form"
          end
        end
      else
        flash.now[:notice] = t('flash_msg5')
        page.redirect_to :controller => 'user', :action => 'dashboard'
      end
    else
      render :update do |page|
        page.replace_html "fee_submission", :text => ""
      end
    end
  end

  # revert an applied refund
  def revert_fee_refund
    fee_refund=FeeRefund.find(params[:id])
    finance_fee=fee_refund.finance_fee
    transaction = fee_refund.finance_transaction
    transaction.cancel_reason = params[:reason]
    if transaction.destroy
      flash[:notice]="#{t('fees_refund')} #{t('successfully_reverted').downcase}"
    end
    student = finance_fee.student
    redirect_to :action => :fees_refund_dates, :id => student.id

  end

  #  def view_refund_rules
  #    @dates=FinanceFeeCollection.current_active_financial_year.all(:select => "distinct finance_fee_collections.*",
  #      :joins => "INNER JOIN refund_rules ON refund_rules.finance_fee_collection_id = finance_fee_collections.id
  #{active_account_joins}#",
  #                         :order => "students.first_name ASC").uniq : []
  #    # @linking_required = @date.try(:has_linked_unlinked_masters) || false
  #  end
  def view_refund_rules
    @dates=FinanceFeeCollection.current_active_financial_year.all(:select => "distinct finance_fee_collections.*",
      :joins => "INNER JOIN refund_rules ON refund_rules.finance_fee_collection_id = finance_fee_collections.id
                  #{active_account_joins}",
      :conditions => "finance_fee_collections.is_deleted = false AND #{active_account_conditions}")
  end


  def list_refund_rules
    @finance_fee_collection=FinanceFeeCollection.find(params[:id])
    @refund_rules=@finance_fee_collection.refund_rules
    render :update do |page|
      flash[:notice]=nil
      page.replace_html 'categories', :partial => 'refund_rules'
    end
  end

  def edit_refund_rules
    @refund_rule=RefundRule.find(params[:id])
    respond_to do |format|
      format.js { render :action => 'edit_refund_rules' }
    end
  end

  def refund_rule_update
    @refund_rule=RefundRule.find(params[:id])
    finance_fee_collection=@refund_rule.finance_fee_collection

    if @refund_rule.update_attributes(params[:refund_rule])
      render :update do |page|
        @refund_rules=finance_fee_collection.refund_rules
        page.replace_html 'form-errors', :text => ''
        page.replace_html 'categories', :partial => 'refund_rules'
        page << "Modalbox.hide();"
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('refund_rules').singularize} #{t('has_been_updated')}</p>"
        @error=false
      end
    else

      render :update do |page|

        page.replace_html 'form-errors', :partial => 'class_timings/errors', :object => @refund_rule

        page.visual_effect(:highlight, 'form-errors')
      end

    end
  end

  def refund_rule_delete
    refund_rule=RefundRule.find(params[:id])
    @finance_fee_collection=refund_rule.finance_fee_collection
    @refund_rules=@finance_fee_collection.refund_rules
    if refund_rule.destroy
      render :update do |page|
        flash[:notice]="#{t('finance.flash29')}"
        page.replace_html 'categories', :partial => 'refund_rules'
      end
    end
  end

  def fee_refund_student_pdf
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find(params[:date])
    @financefee = @student.finance_fee_by_date(@date)


    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])

    @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)

    @refund_amount=0
    particular_and_discount_details
    fee_refund=@financefee.fee_refund
    @refund_amount=fee_refund.amount.to_f
    @refund_percentage=fee_refund.refund_rule.refund_percentage
    render :pdf => 'fee_refund_student_pdf'
  end

  def view_refunds
    @page=0
    @current_user=current_user
    @start_date=FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    @end_date=FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    if @current_user.admin? or @current_user.privileges.collect(&:name).include? "ManageRefunds"
      if params[:id]
        @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => [:finance_fee], :conditions => ["finance_fees.student_id='#{params[:id].to_i}' and fee_refunds.created_at >='#{@start_date}' and fee_refunds.created_at <'#{@end_date+1.day}'"], :order => 'created_at desc')
      else
        @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10, :conditions => ["created_at >='#{@start_date}' and created_at <'#{@end_date+1.day}'"], :order => 'created_at desc')
      end
    elsif @current_user.parent?
      @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => [:finance_fee], :conditions => ["finance_fees.student_id='#{@current_user.guardian_entry.ward_id}' and fee_refunds.created_at >='#{FedenaTimeSet.current_time_to_local_time(Time.now).to_date}' and fee_refunds.created_at <'#{FedenaTimeSet.current_time_to_local_time(Time.now).to_date+1.day}'"], :order => 'created_at desc')
    else
      @refunds =FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => [:finance_fee], :conditions => ["finance_fees.student_id='#{@current_user.student_entry.id}' and fee_refunds.created_at >='#{FedenaTimeSet.current_time_to_local_time(Time.now).to_date}' and fee_refunds.created_at <'#{FedenaTimeSet.current_time_to_local_time(Time.now).to_date+1.day}'"], :order => 'created_at desc')
    end
  end

  def refund_student_view
    @page = 0
    if params[:student_type] == 'former'
      @archived_student = ArchivedStudent.find_by_former_id(params[:id].to_i) 
    else
      @student = Student.find_by_id(params[:id].to_i)
    end
    @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 5,
      :joins => "INNER JOIN finance_transactions ft ON ft.id = fee_refunds.finance_transaction_id
                  INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["ft.payee_id='#{params[:id].to_i}' and ft.payee_type='Student' AND
                        #{active_account_conditions}"], :order => 'created_at desc')
  end

  def refund_student_view_pdf
    refund_student_view
    render :pdf => 'refund_student_view_pdf'
  end

  def list_refunds
    @start_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    @end_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    joins = "INNER JOIN finance_fees ff ON ff.id = fee_refunds.finance_fee_id
             INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
              #{active_account_joins(true, 'ffc')}"
    cond = "#{active_account_conditions(true, 'ffc')} AND "
    @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 5, :joins => joins,
      :conditions => ["#{cond} created_at >='#{FedenaTimeSet.current_time_to_local_time(Time.now).to_date}' and
                       created_at <'#{FedenaTimeSet.current_time_to_local_time(Time.now).to_date+1.day}'"],
      :order => 'created_at desc')
    @page = params[:page] ? params[:page].to_i-1 : 0
    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/view_refunds"
    end
  end

  def refund_filter_by_date
    @start_date=params[:s_date].to_date
    @end_date=params[:e_date].to_date
    @page=params[:page] ? params[:page].to_i-1 : 0
    @current_user=current_user
    joins = "INNER JOIN finance_fees ff ON ff.id = fee_refunds.finance_fee_id
             INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
              #{active_account_joins(true, 'ffc')}"
    cond = "#{active_account_conditions(true, 'ffc')} AND "
    if @current_user.admin? or @current_user.privileges.collect(&:name).include? "ManageRefunds"
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => joins,
        :order => 'fee_refunds.created_at desc', :conditions => ["#{cond} fee_refunds.created_at >= '#{@start_date}' and
         fee_refunds.created_at < '#{@end_date.to_date+1.day}'"])
    elsif @current_user.parent?
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => joins,
        :order => 'created_at desc', :conditions => ["#{cond} finance_fees.student_id='#{@current_user.guardian_entry.ward_id}' and
         fee_refunds.created_at >= '#{@start_date}' and fee_refunds.created_at < '#{@end_date.to_date+1.day}'"])
    else
      @refunds = FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => joins,
        :order => 'created_at desc', :conditions => ["#{cond} finance_fees.student_id='#{@current_user.student_entry.id}' and
         fee_refunds.created_at >= '#{@start_date}' and fee_refunds.created_at < '#{@end_date.to_date+1.day}'"])
    end
    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/view_refunds_by_date"
    end
  end

  def search_fee_refunds
    @page=params[:page] ? params[:page].to_i-1 : 0
    joins = "INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id
             INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
             #{active_account_joins(true, 'ffc')}"
    student_join = " INNER JOIN students on students.id=finance_fees.student_id"
    cond = "#{active_account_conditions(true, 'ffc')} AND "
    if params[:option]==t('student_name')
      @refunds=FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => joins + student_join,
        :order => 'fee_refunds.created_at desc', :conditions => ["#{cond} students.first_name LIKE ?",
          "#{params[:query]}%"])
    else
      @refunds=FeeRefund.paginate(:page => params[:page], :per_page => 10, :joins => joins,
        :order => 'fee_refunds.created_at desc', :conditions => ["#{cond} ffc.name LIKE ?",
          "#{params[:query]}%"])
    end

    render :update do |page|
      page.replace_html 'search_div', :partial => "finance/view_refunds_by_search"
    end
  end

  def refund_search_pdf
    joins = "INNER JOIN finance_fees on finance_fees.id=fee_refunds.finance_fee_id
             INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
              #{active_account_joins(true, 'ffc')}"
    student_joins = "INNER JOIN students on students.id=finance_fees.student_id"
    cond = "#{active_account_conditions(true, 'ffc')} AND "
    if params[:option] == t('student_name')
      @refunds = FeeRefund.find(:all, :joins => joins + student_joins,
        :order => 'fee_refunds.created_at desc', :conditions => ["#{cond} students.first_name LIKE ?",
          "#{params[:query]}%"])
    elsif params[:option]==t('fee_collection_name') or params[:option]=="Fee Collection Name"
      @refunds = FeeRefund.find(:all, :joins => joins, :order => 'fee_refunds.created_at desc',
        :conditions => ["#{cond} finance_fee_collections.name LIKE ?", "#{params[:query]}%"])
    else
      if date_format_check
        if (params[:option] or (@start_date and @end_date))
          @refunds = FeeRefund.find(:all, :joins => joins,
            :order => 'fee_refunds.created_at desc', :conditions => ["#{cond} fee_refunds.created_at >= '#{@start_date}' and
              fee_refunds.created_at < '#{@end_date.to_date+1.day}'"])
        else
          error=true
        end
      end
    end

    if error
      flash[:notice]=t('invalid_date_format')
      redirect_to :controller => "user", :action => "dashboard"
    else
      render :pdf => 'refund_search_pdf'
    end
  end

  def generate_fine
    @fine=Fine.new
    @fine_rule=FineRule.new
    @fines=Fine.active

  end


  def fine_list
    if params[:id].present?
      @fine=Fine.find(params[:id])
      @fine_rules=@fine.fine_rules.order_in_fine_days
      render :update do |page|
        page.replace_html "fine_list", :partial => "list_fines"
      end
    else
      render :update do |page|
        page.replace_html "fine_list", :text => ""
      end
    end
  end

  def fine_slabs_edit_or_create

    if params[:id].present?
      if params[:id]=="0"
        @fine=Fine.new
        render :update do |page|
          page.replace_html "form-errors", :text => ""
          page.replace_html "select_fine", :partial => "new_fine"
          page.replace_html "flash_box", :text => ""
        end
      else
        @fine=Fine.find(params[:id])
        render :update do |page|
          page.replace_html "flash_box", :text => ""
          page.replace_html "form-errors", :text => ""
          page.replace_html "select_fine", :partial => "list_fine_slabs"
        end
      end
    end

    if request.post?
      if params[:fine_id].nil?
        flash[:notice]=t('fine_created_successfully')
      else
        flash[:notice]=t('fine_slabs_updated')
      end
      if params[:fine][:is_deleted].present?
        flash[:notice]=t('fine_deleted')
      end
      fine_id=params[:fine_id]
      @fine=Fine.find_or_initialize_by_id(fine_id)
      if @fine.update_attributes(params[:fine])
        # @fine=Fine.find(params[:fine_id])
        render :update do |page|
          page.redirect_to "generate_fine"
        end
      else
        flash[:notice]=nil
        render :update do |page|
          page.replace_html "form-errors", :partial => "errors", :object => @fine
          unless fine_id.present?
            page.replace_html "select_fine", :partial => "fine_errors"
          else
            page.replace_html "select_fine", :partial => "list_fine_slabs"
          end
        end
      end
    end
  end


  def student_wise_fee_payment
    @student=Student.find(params[:id])
  end

  def add_additional_details_for_donation
    @all_details = DonationAdditionalField.find(:all, :order => "priority ASC")
    @additional_details = DonationAdditionalField.find(:all, :conditions => {:status => true}, :order => "priority ASC")
    @inactive_additional_details = DonationAdditionalField.find(:all, :conditions => {:status => false}, :order => "priority ASC")
    @additional_field = DonationAdditionalField.new
    @finance_additional_field_option = @additional_field.donation_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map { |r| r.priority }.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = DonationAdditionalField.new(params[:donation_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "#{t('additional_field_added')}"
        redirect_to :controller => "finance", :action => "add_additional_details_for_donation"
      end
    end
  end

  def edit_additional_details_for_donation
    @additional_details = DonationAdditionalField.find(:all, :conditions => {:status => true}, :order => "priority ASC")
    @inactive_additional_details = DonationAdditionalField.find(:all, :conditions => {:status => false}, :order => "priority ASC")
    @additional_field = DonationAdditionalField.find(params[:id])
    @donation_additional_field_option = @additional_field.donation_additional_field_options
    if request.get?
      render :action => 'add_additional_details_for_donation'
    else
      if @additional_field.update_attributes(params[:donation_additional_field])
        flash[:notice] = "#{t('additional_filed_edittted')}"
        redirect_to :action => "add_additional_details_for_donation"
      else
        render :action => "add_additional_details_for_donation"
      end
    end
  end

  def delete_additional_details_for_donation
    donations = DonationAdditionalDetail.find(:all, :conditions => {:additional_field_id => params[:id]})
    if donations.blank?
      DonationAdditionalField.find(params[:id]).destroy
      @additional_details = DonationAdditionalField.find(:all, :conditions => {:status => true}, :order => "priority ASC")
      @inactive_additional_details = DonationAdditionalField.find(:all, :conditions => {:status => false}, :order => "priority ASC")
      flash[:notice]="#{t('additional_field_deleted')}"
      redirect_to :action => "add_additional_details_for_donation"
    else
      flash[:notice]="#{t('donations_with_this_field_exists')}"
      redirect_to :action => "add_additional_details_for_donation"
    end
  end

  def fees_student_search
    @target_action=params[:target_action]
    @target_controller=params[:target_controller]
    if @target_action.nil? && @target_controller.nil?
      page_not_found
    end
  end

  # get cancelled transaction report as pdf / csv (based on various filters)
  def cancelled_transaction_reports
    if params[:transaction_type] == t('advance_fees_text')
      if params[:report_format_type] == 'pdf'
        @transactions = CancelledAdvanceFeeTransaction.all(:order => "cancelled_advance_fee_transactions.created_at desc",
          :joins => [:student, :transaction_receipt], 
          :conditions => ['cancelled_advance_fee_transactions.created_at BETWEEN ? AND ?', params[:s_date].to_date, params[:e_date].to_date+1.day], 
          :select => "concat(students.first_name, ' ', students.middle_name, ' ', students.last_name) as payee_name, transaction_receipts.ef_receipt_number as receipt_no, 'Advance Fees' as finance_type, 
          cancelled_advance_fee_transactions.fees_paid as amount, cancelled_advance_fee_transactions.user_id as user_id, cancelled_advance_fee_transactions.reason_for_cancel as cancel_reason, cancelled_advance_fee_transactions.created_at")
      else
        @transactions = CancelledAdvanceFeeTransaction.all(:order => "cancelled_advance_fee_transactions.created_at desc",
          :joins => [:student, :transaction_receipt], 
          :conditions => ['cancelled_advance_fee_transactions.created_at BETWEEN ? AND ?', params[:s_date].to_date, params[:e_date].to_date+1.day], 
          :select => "concat(students.first_name, ' ', students.middle_name, ' ', students.last_name) as payee_name_for_csv, transaction_receipts.ef_receipt_number as receipt_number, 'Advance Fees' as finance_type, 
          cancelled_advance_fee_transactions.fees_paid as amount, cancelled_advance_fee_transactions.user_id as user_id, cancelled_advance_fee_transactions.reason_for_cancel as cancel_reason, cancelled_advance_fee_transactions.created_at")      
      end
    else
      unless params[:option].present?
        @start_date=params[:s_date] || Date.today
        @end_date=params[:e_date] || Date.today  
        all_fee_types=['HostelFee', 'TransportFee', 'FinanceFee', 'Refund', 'BookMovement', 'InstantFee']
        salary = FinanceTransaction.get_transaction_category('Salary')
        joins = ""
        if params['transaction_type'].present? and params['transaction_type']==t('others')
          conditions = "and (collection_name is null or finance_type not in (?)) and category_id <> ?"
        elsif params['transaction_type'].present? and params['transaction_type']==t('payslips')
          conditions = "and (collection_name is null or finance_type not in (?)) and category_id = ?"
        else
          joins = active_account_joins(true, 'ftrr')
          conditions = "and #{active_account_conditions(true, 'ftrr')} AND (collection_name is not null or finance_type in (?)) and category_id <> ?"
        end
        @transactions = CancelledFinanceTransaction.all(
          :order => 'cancelled_finance_transactions.created_at desc',
          :select => "cancelled_finance_transactions.*,
                      IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), 
                                    tr.receipt_number), '-') AS receipt_no",
          :joins => "LEFT JOIN finance_transaction_receipt_records ftrr
                            ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                     LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id #{joins}",
          :conditions => ["cancelled_finance_transactions.created_at BETWEEN ? AND ? #{conditions}",
            @start_date, @end_date, all_fee_types, salary])
      else
        if params[:option] == t('fee_collection_name')
          @transactions = CancelledFinanceTransaction.all(
            :order => 'cancelled_finance_transactions.created_at desc',
            :select => "cancelled_finance_transactions.*,
                        IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), 
                                      tr.receipt_number), '-') AS receipt_no",
            :joins => "LEFT JOIN finance_transaction_receipt_records ftrr
                              ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                       LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                       #{active_account_joins(true, 'ftrr')}",
            :conditions => ["#{active_account_conditions(true, 'ftrr')} AND collection_name LIKE ?", "#{params[:query]}%"]) unless params[:query] == ''
        elsif params[:option] == t('date_text')
          @transactions = CancelledFinanceTransaction.all(
            :order => 'cancelled_finance_transactions.created_at desc',
            :select => "cancelled_finance_transactions.*,
                        IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), 
                                      tr.receipt_number), '-') AS receipt_no",
            :joins => "LEFT JOIN finance_transaction_receipt_records ftrr
                              ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                       LEFT JOIN transaction_receipts tr ON tr.id = ftrr.transaction_receipt_id
                       #{active_account_joins(true, 'ftrr')}",
            :conditions => ["#{active_account_conditions(true, 'ftrr')} AND cancelled_finance_transactions.created_at LIKE ?", "#{params[:query]}%"]) unless params[:query] == ''
        else
          if FedenaPlugin.can_access_plugin?("fedena_instant_fee")
            @transactions = CancelledFinanceTransaction.all(
              :order => 'cancelled_finance_transactions.created_at desc',
              :select => "cancelled_finance_transactions.*,
                          IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), 
                                        tr.receipt_number), '-') AS receipt_no",
              :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                         LEFT OUTER JOIN employees ON employees.id = payee_id 
                         LEFT OUTER JOIN instant_fees ON instant_fees.id = finance_id
                               LEFT JOIN finance_transaction_receipt_records ftrr
                                      ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                               LEFT JOIN transaction_receipts tr
                                      ON tr.id = ftrr.transaction_receipt_id
                         #{active_account_joins(true, 'ftrr')}",
              :conditions => ["#{active_account_conditions(true, 'ftrr')} AND students.admission_no LIKE ? OR
                               employees.employee_number LIKE ? OR instant_fees.guest_payee LIKE ?",
                "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%"]) unless params[:query] == ''
          else
            @transactions = CancelledFinanceTransaction.all(
              :order => 'cancelled_finance_transactions.created_at desc',
              :select => "cancelled_finance_transactions.*,
                          IFNULL(CONCAT(IFNULL(tr.receipt_sequence, ''), 
                                        tr.receipt_number), '-') AS receipt_no",
              :joins => "LEFT OUTER JOIN students ON students.id = payee_id
                         LEFT OUTER JOIN employees ON employees.id = payee_id
                               LEFT JOIN finance_transaction_receipt_records ftrr
                                      ON ftrr.finance_transaction_id = cancelled_finance_transactions.finance_transaction_id
                               LEFT JOIN transaction_receipts tr
                                      ON tr.id = ftrr.transaction_receipt_id
                         #{active_account_joins(true, 'ftrr')}",
              :conditions => ["#{active_account_conditions(true, 'ftrr')} AND students.admission_no LIKE ? OR
                               employees.employee_number LIKE ?", "#{params[:query]}%", "#{params[:query]}%"]) unless params[:query] == ''
          end
        end
      end
    end

    if params[:report_format_type] == "pdf"
      render :pdf => "cancelled_transaction_reports",
        :margin => {:left => 10, :right => 10, :top => 5, :bottom => 5},
        :header => {:html => nil}, :footer => {:html => nil},
        :show_as_html => params.key?(:d)
    else
      csv_string = CancelledFinanceTransaction.generate_cancelled_transactions_csv(params, @transactions)
      send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present',
        :filename => "cancelled_transactions.csv")
    end
  end

  #  def receipt_settings
  #
  #  end

  def pdf_receipt_settings
    @config = Configuration.get_multiple_configs_as_hash ['PdfReceiptSignature', 'PdfReceiptSignatureName', 'PdfReceiptCustomFooter', 'PdfReceiptAtow', 'PdfReceiptNsystem', 'PdfReceiptHalignment']
    if request.post?
      @ret_val=Configuration.set_config_values(params[:configuration])
      flash[:notice] = "#{t('flash_msg8')}"
      redirect_to :action => "pdf_receipt_settings" and return
    end
  end

  private

  # checks if invoice number is enabled by configuration
  def invoice_number_enabled?
    @invoice_enabled = Configuration.get_config_value('EnableInvoiceNumber').to_i == 1
  end

  def join_sql_for_student_fees(batch_id=nil)
    if batch_id.present?
      transport_sql = "AND transport_fees.groupable_id=#{batch_id}"
      hostel_sql = "AND hostel_fees.batch_id=#{batch_id}"
      finance_sql = "AND finance_fees.batch_id=#{batch_id}"
    else
      transport_sql = hostel_sql = finance_sql=""
    end
    result ="INNER JOIN batches ON batches.id=students.batch_id
                   INNER JOIN courses ON courses.id=batches.course_id
                   LEFT JOIN finance_fees ON finance_fees.student_id=students.id #{finance_sql}"
    result +=" LEFT JOIN transport_fees
                               ON transport_fees.receiver_id=students.id AND
                                     transport_fees.receiver_type='Student' AND
                                     transport_fees.is_active=1 #{transport_sql}" if FedenaPlugin.
      can_access_plugin?("fedena_transport")
    result +=" LEFT JOIN hostel_fees 
                               ON hostel_fees.student_id=students.id AND 
                                     hostel_fees.is_active=1 #{hostel_sql}" if FedenaPlugin.
      can_access_plugin?("fedena_hostel")
    result
  end

  def transport_fee_due
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      "(select sum(tf.balance) from transport_fees tf where tf.receiver_id=students.id and tf.receiver_type='Student' and find_in_set(id,group_concat(distinct transport_fees.id)))"
    else
      0
    end
  end

  def hostel_fee_due
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      "(select sum(hf.balance) from hostel_fees hf where hf.student_id=students.id and find_in_set(id,group_concat(distinct hostel_fees.id)))"
    else
      0
    end
  end

  def load_tax_setting
    @tax_enabled = (Configuration.get_config_value('EnableFinanceTax').to_i != 0)
  end

  def date_validation
    check=true
    if (date_format(params[:start_date]).nil? or date_format(params[:end_date]).nil? or date_format(params[:start_date2]).nil? or date_format(params[:end_date2]).nil?)
      flash[:notice]=t('select_a_date_range')
      @error_msg=t('invalid_date_format')
      check=false
    elsif (params[:start_date]==params[:start_date2] and params[:end_date]==params[:end_date2])
      flash[:notice]=t('same_time_periods')
      @error_msg=t('same_time_periods')
      check= false
    elsif ((params[:end_date].to_date < params[:start_date].to_date) or (params[:end_date2].to_date < params[:start_date2].to_date))
      flash[:warn_notice]=t('end_date_lower')
      @error_msg=t('end_date_lower')
      check=false
    end
    return check
  end

  def date_format(date)
    /(\d{4}-\d{2}-\d{2})/.match(date)
  end

  def protect_access_by_other_students
    if current_user.student? or current_user.parent?
      ft = params[:detailed].present? ? FinanceTransactionLedger.find_by_id(params[:transaction_id]) :
        FinanceTransaction.find_by_id(params[:transaction_id])
      unless (ft.present? and ft.payee == current_user.student_record) or (ft.present? and ft.payee == current_user.parent_record)
        flash[:notice] = "#{t('flash_msg5')}"
        redirect_to :controller => "user", :action => "dashboard"
      end
    end
  end

  #  def get_receipt_partial(template)
  #    template_name = template.parameterize.underscore.to_s
  #    "_receipt_templates/a4/template_"+template_name+".html.erb"
  #  end


  def ferch_payslip_query
    unless params[:filter].to_i == 1
      payslip_query = params[:payslip]
    else
      payslip_query = JSON.parse(params[:payslip]).symbolize_keys
    end
    @payslip_query = {:department_id => payslip_query.blank? ? "All" : payslip_query[:department_id].blank? ? "All" : payslip_query[:department_id],
      :start_date => payslip_query.blank? ? Date.today.beginning_of_month : payslip_query[:start_date].blank? ? Date.today.beginning_of_month : payslip_query[:start_date],
      :end_date => payslip_query.blank? ? Date.today.end_of_month : payslip_query[:end_date].blank? ? Date.today.end_of_month : payslip_query[:end_date],
      :payslip_status => payslip_query.blank? ? "All" : payslip_query[:payslip_status].blank? ? "All" : payslip_query[:payslip_status],
      :payslip_period => payslip_query.blank? ? "All" : payslip_query[:payslip_period].blank? ? "All" : payslip_query[:payslip_period],
      :employee_name => payslip_query.blank? ? "" : payslip_query[:employee_name].blank? ? "" : payslip_query[:employee_name],
      :employee_no => payslip_query.blank? ? "" : payslip_query[:employee_no].blank? ? "" : payslip_query[:employee_no]
    }
  end

  def increse_group_concat_size_limit
    session_limit_row_sql="SET SESSION group_concat_max_len = 1000000;"
    ActiveRecord::Base.connection.execute(session_limit_row_sql)
  end

  private

  def render_partial arg
    if arg.is_a? Array
      ele, key, value = arg
      render :update do |page|
        page.replace_html ele, key.to_sym => value
      end
    else
      render :update do |page|
        arg.each_pair do |k, v|
          page.replace_html k, v[0].to_sym => v[1]
        end
      end
    end

  end

  def fetch_multiple_configs
    @accounts = FeeAccount.all
    @templates = FeeReceiptTemplate.all
    @receipt_sets = ReceiptNumberSet.all
    @multi_configs = FinanceTransactionCategory.get_multi_configuration @config
  end

  def fetch_config_hash config_keys
    @config = Configuration.get_multiple_configs_as_hash config_keys
  end
  
  def update_fine_waiver (fine_waiver_flag, finance_fee)
    if fine_waiver_flag && finance_fee.balance <= 0 && !finance_fee.is_paid
      @financefee.update_attributes(:is_fine_waiver=>fine_waiver_flag, :is_paid=>true) 
    end
  end
  
  def calculate_auto_fine_for_waiver_tracker
    bal=(@total_payable-@total_discount).to_f
    days=(Date.today-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine
      if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
        fine_amount = @financefee.balance_fine
      else
        fine_rule = auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
        fine_amount = fine_rule.is_amount ? fine_rule.fine_amount : (bal*fine_rule.fine_amount)/100 if fine_rule
        if fine_rule and @financefee.balance==0
          fine_amount = fine_amount - @financefee.paid_auto_fine
        end
      end
    end
    finance_type = "FinanceFee"
    @financefee.track_fine_calculation(finance_type, fine_amount, @financefee.id)
  end
  
  def csv_export(model,method,parameters)
      
    csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model,method)
    if csv_report.nil?
      csv_report=AdditionalReportCsv.new(:model_name=>model,:method_name=>method,:parameters=>parameters, :status => true)
      if csv_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
      end
    else
      unless csv_report.status
        if csv_report.update_attributes(:parameters=>parameters,:csv_report=>nil, :status => true)
          Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
        end
      end  
    end
    flash[:notice]="#{t('csv_report_is_in_queue')}"
    redirect_to :controller => :report, :action=>:csv_reports,:model=>model,:method=>method
  end
    
  #to fetch start and end date for fee receipt search  
  def date_fetch(type)
    params[type.to_sym].try(:to_date) || params[:search][type.to_sym].try(:to_date) ||
      FedenaTimeSet.current_time_to_local_time(Time.now).to_date
  end
    
  def filename
    start_date = params[:search].present? ? params[:search][:start_date_as].try(:to_date) || FedenaTimeSet.current_time_to_local_time(Time.now).to_date : params[:start_date_as] || FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    end_date = params[:search].present? ? params[:search][:end_date_as].try(:to_date) || FedenaTimeSet.current_time_to_local_time(Time.now).to_date : params[:end_date_as] || FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    return "fee_reciepts-#{start_date}-#{end_date}"
  end  
    
end
