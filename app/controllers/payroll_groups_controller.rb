class PayrollGroupsController < ApplicationController
  require 'lib/override_errors'
  lock_with_feature :hr_enhancement
  
  helper OverrideErrors

  filter_access_to :all
  filter_access_to [:index, :show], :attribute_check => true ,:load_method => lambda {cur_user = current_user; cur_user.finance_flag = params[:finance].present?; cur_user}

  check_request_fingerprint :create, :update, :save_lop_settings

  def index
    @payroll_groups = PayrollGroup.paginate(:select => 'payroll_groups.id,name,salary_type,payment_period, count(employees.id) AS employees_count',:include => [:payroll_categories], :joins => "LEFT OUTER JOIN employee_salary_structures ON (payroll_groups.id = employee_salary_structures.payroll_group_id) LEFT OUTER JOIN employees ON (employees.id = employee_salary_structures.employee_id)",:group => 'payroll_groups.id', :per_page => 10, :page => params[:page], :order => "payroll_groups.name")
  end

  def new
    @payroll_group = PayrollGroup.new(:payment_period => 5)
    @payroll_group.build_formulas
    @pay_earnings = @pay_deductions = []
    fetch_payroll_group_data
    @selected_cat_ids = (@pay_earnings + @pay_deductions).collect{|c| c.payroll_category_id}
  end

  def create
    @payroll_group = PayrollGroup.new(params[:payroll_group])
    if @payroll_group.save
      flash[:notice] = t('payroll.flash7')
      redirect_to :action => :index
    else
      fetch_payroll_group_data
      fetch_data_with_errors
      @earnings_list = PayrollCategory.earnings - @earnings
      @deductions_list = PayrollCategory.deductions - @deductions
      render :action => :new
    end
  end

  def edit
    @payroll_group = PayrollGroup.find(params[:id], :include => :payroll_categories)
    fetch_payroll_group_data
    @payroll_group.build_formulas
    @earnings_list = @selected_earnings = @payroll_group.earnings_list
    @deductions_list = @selected_deductions = @payroll_group.deductions_list
    group_categories = @payroll_group.payroll_groups_payroll_categories
    @pay_earnings = group_categories.select{|pc| pc.payroll_category.is_deduction == false}
    @pay_deductions = group_categories.select{|pc| pc.payroll_category.is_deduction == true}
    @payroll_categories = @payroll_group.payroll_categories
    @payroll_group.validate_formula
    @selected_cat_ids = (@pay_earnings + @pay_deductions).collect{|c| c.payroll_category_id}
  end

  def update
    @payroll_group = PayrollGroup.find(params[:id], :include => :payroll_categories)
    old_cat_ids = @payroll_group.payroll_category_ids
    if @payroll_group.update_attributes(params[:payroll_group])
      new_cat_ids = @payroll_group.reload.payroll_category_ids
      @payroll_group.create_revision(old_cat_ids) unless old_cat_ids.uniq.sort == new_cat_ids.uniq.sort
      flash[:notice] = "#{t('payroll.flash8')}"
      redirect_to :action => "index"
    else
      fetch_payroll_group_data
      fetch_data_with_errors
      @earnings_list =  @payroll_group.payroll_categories.select{|pc| pc.is_deduction == false && @recent_categories.include?(pc.id) }
      @deductions_list = @payroll_group.payroll_categories.select{|pc| pc.is_deduction == true && @recent_categories.include?(pc.id)}
      @payroll_categories = @payroll_group.payroll_categories
      render :action => "edit"
    end
  end

  def show
    @payroll_group = PayrollGroup.find(params[:id], :include => [{:payroll_categories => {:hr_formula => :formula_and_conditions}}, {:employee_lop => [{:hr_formula => :formula_and_conditions}, {:lop_prorated_formulas => [:hr_formula, :payroll_category]}]}])
    @earnings = @payroll_group.payroll_categories.select{|c| !c.is_deduction}
    @deductions = @payroll_group.payroll_categories.select{|c| c.is_deduction}
    @lop_prorated_formulas = @payroll_group.employee_lop.lop_prorated_formulas if @payroll_group.enable_lop
  end

  def destroy
    payroll_group = PayrollGroup.find params[:id]
    if payroll_group.check_dependency_and_delete
      payroll_group.destroy
      flash[:notice] = "#{t('payroll.flash5')}"
    else
      flash[:notice] = "#{t('payroll.flash4')}"
    end
    redirect_to :action => "index"
  end
  
  def payslip_generation
    @generation_day =  params[:generation_day]
    @payslip_gen = PayrollGroup::PAYSLIP_GENERATION[params[:payment_period].to_i]
    unless @payslip_gen.empty? && params[:payment_period] != 1
      render :partial => "payslip_generation", :locals => {:generation_day => @generation_day }
    else
      render :text => ""
    end
  end

  def working_day_settings
    @payment_periods = PayrollGroup::PAYMENT_PERIOD.except(1)
    default_values = SalaryWorkingDay::DEFAULT_VALUES
    @nwd_values = SalaryWorkingDay::MONTH_VALUES
    @salary_working_days_without_months = []
    @salary_working_days_with_months = []
    @payment_periods.each do |key,value|
      @salary_working_days_without_months << SalaryWorkingDay.find_or_create_by_payment_period(:payment_period => key, :working_days => default_values[key])
      if key == 5
        for i in 1..12 do
          @salary_working_days_with_months << SalaryWorkingDay.find_or_create_by_payment_period_and_month_value(:payment_period => key,  :month_value => i,:working_days => @nwd_values[i])
        end
      end
    end
  end

  def update_working_day_settings
    if params[:salary_working_days].present?
      @errors = {}
      @salary_working_days = []
      @payment_periods = PayrollGroup::PAYMENT_PERIOD.except(1)
      ActiveRecord::Base.transaction do
        params[:salary_working_days].values.each do |set|
          salary_working_day = SalaryWorkingDay.find set["id"]
          salary_working_day.working_days = set["working_days"]
          @salary_working_days << salary_working_day
          @errors[set["id"].to_i] = salary_working_day.errors.map{|attr, msg| msg} unless salary_working_day.save
        end
        raise ActiveRecord::Rollback unless @errors.empty?
      end
      @salary_working_days_without_months = @salary_working_days.select{|c| !c.month_value.present?}.sort_by(&:id)
      @salary_working_days_with_months = @salary_working_days.select{|c| c.month_value.present?}.sort_by(&:month_value)
      flash[:notice] = "#{t('updated_working_days')}" if @errors.empty?
      render 'working_day_settings'
    else
      redirect_to :action => "working_day_settings"
    end
  end

  def lop_settings
    @payroll_group = PayrollGroup.find(params[:id], :include => {:payroll_categories => {:hr_formula => :formula_and_conditions}})
    @payroll_group.build_formulas
    @payroll_categories = @payroll_group.payroll_categories
    @earnings_list = @payroll_group.earnings_list
    @deductions_list = @payroll_group.deductions_list
    @hash = @payroll_group.fetch_categories
  end

  def categories_formula
    @hash = JSON.parse(params[:categories])
    @payroll_category = PayrollCategory.find(params[:cat_id])
    @lop_prorated_formula = LopProratedFormula.new
    @lop_prorated_formula.build_hr_formula
    @object_name = params[:object_name]
    render :partial => 'categories_lop_formula', :locals => { :lop_prorated_formula => @lop_prorated_formula, :object_name => @object_name }
  end
  
  def save_lop_settings
    @payroll_group = PayrollGroup.find(params[:id], :include => {:payroll_categories => {:hr_formula => :formula_and_conditions}})
    if params[:payroll_group].present?
      @payroll_group.convert_lop_formulas(params[:payroll_group])
      if @payroll_group.save
        flash[:notice] = "#{t('updated_lop_settings')}"
        redirect_to :action => 'show', :id => @payroll_group.id
      else
        @payroll_categories = @payroll_group.payroll_categories
        @earnings_list = @payroll_group.earnings_list
        @deductions_list = @payroll_group.deductions_list
        @hash = JSON.parse(params[:payroll_group][:lop_formulas])
        render :action => 'lop_settings'
      end
    else
      redirect_to :action => "lop_settings", :id => @payroll_group.id
    end
  end

  private
  def fetch_payroll_group_data
    @payslip_gen = PayrollGroup::PAYSLIP_GENERATION[@payroll_group.payment_period]
    @earnings = PayrollCategory.earnings.load_formulas
    @deductions = PayrollCategory.deductions.load_formulas
  end

  def fetch_data_with_errors
    @recent_categories = params[:payroll_group][:payroll_groups_payroll_categories_attributes].collect{|k,v| v["payroll_category_id"].to_i} if params[:payroll_group][:payroll_groups_payroll_categories_attributes]
    @group_categories = @payroll_group.payroll_groups_payroll_categories
    @pay_earnings = @group_categories.select{|pc| pc.payroll_category.is_deduction == false && @recent_categories.include?(pc.payroll_category.id)}.sort_by(&:sort_order)
    @pay_deductions = @group_categories.select{|pc| pc.payroll_category.is_deduction == true && @recent_categories.include?(pc.payroll_category.id)}.sort_by(&:sort_order)
    @payroll_group.build_formulas
    @selected_cat_ids = (@pay_earnings + @pay_deductions).collect{|c| c.payroll_category_id}
  end
end
