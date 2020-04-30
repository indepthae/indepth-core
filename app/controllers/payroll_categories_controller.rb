class PayrollCategoriesController < ApplicationController
  filter_access_to :all
  lock_with_feature :hr_enhancement
  
  require 'lib/override_errors'
  helper OverrideErrors

  check_request_fingerprint :create, :update

  def index
    @earnings = PayrollCategory.earnings.paginate(:include => {:hr_formula => :formula_and_conditions}, :per_page => 10, :page => params[:page])
    @deductions = PayrollCategory.deductions.paginate(:include => {:hr_formula => :formula_and_conditions}, :per_page => 10, :page => params[:page])
    if request.xhr?
      render :update do |page|
        unless params[:is_deductions]
          page.replace_html :list_earnings, :partial => 'earnings_list'
        else
          page.replace_html :list_deductions, :partial => 'deductions_list'
        end
      end
    end
  end

  def new
    @category = PayrollCategory.create_new_category(params[:dup_id])
    @enable_round_off = @category.round_off_value.present? ? "1" : "0"
    categories_list
  end

  def create
    @category = PayrollCategory.new(params[:payroll_category])
    if @category.save
      flash[:notice] = "#{t('payroll.flash1')}"
      redirect_to :action => "index"
    else
      categories_list
      @errors = true
      render :action => 'new'
    end
  end

  def edit
    @category = PayrollCategory.find(params[:id])
    @enable_round_off = @category.round_off_value.present? ? "1" : "0"
    unless @category.dependent_categories_list.present? or @category.payroll_groups.present?
      if @category.hr_formula.nil?
        @category.build_hr_formula
        @category.hr_formula.formula_and_conditions.build
      else
        @category.hr_formula.default_value_valid = true
        @category.hr_formula.formula_and_conditions.each{|c| c.expression1_valid = true; c.expression2_valid = true; c.value_valid = true}
      end
      categories_list
    else
      redirect_to :action => :show
    end
  end

  def update
    @category = PayrollCategory.find(params[:id])
    if @category.update_attributes(params[:payroll_category])
      flash[:notice] = "#{t('payroll.flash2')}"
      redirect_to :action => "show", :id => @category.id
    else
      @enable_round_off = @category.round_off_value.present? ? "1" : "0"
      @object_name = "payroll_category[hr_formula_attributes]"
      @hr_formula = @category.hr_formula
      categories_list
      render :action => "edit" 
    end
  end

  def destroy
    @category = PayrollCategory.find(params[:id])
    if @category.check_dependency_and_delete
      flash[:notice] = "#{t('payroll.flash3')}"
    else
      flash[:notice] = "#{t('payroll.flash4')}"
    end
    redirect_to :action => "index"
  end

  def show
    @category = PayrollCategory.active.find(params[:id], :include => [{:hr_formula => :formula_and_conditions}, :payroll_groups])
  end

  def hr_formula_form
    @object = params[:object_type].constantize.send(:find, params[:object_id]) if params[:object_type].present? and params[:object_id].present?
    @object_name = params[:object_name]
    @object_type = params[:object_type]
    @hr_formula = (@object.present?  and @object.hr_formula.present? and @object.hr_formula.value_type == params[:formula_type].to_i) ? @object.hr_formula : HrFormula.new
    case params[:formula_type].to_i
    when 1
      render :partial => 'payroll_categories/numeric_value_field', :locals => {:object_name => @object_name, :hr_formula => @hr_formula}
    when 2
      render :partial => 'payroll_categories/formula_field', :locals => {:object_name => @object_name, :hr_formula => @hr_formula}
    when 3
      @hr_formula.formula_and_conditions.build if @hr_formula.new_record?
      render :partial => 'payroll_categories/formula_with_condition', :locals => {:object_name => @object_name, :hr_formula =>@hr_formula}
    else
      render :text => ''
    end
  end


  def validate_formula
    @errors = HrFormula.validate_formula(params[:formula].upcase, (params[:is_lop].to_i == 0), params[:cat_code], params[:selected_cats], params[:cat_formula])
    render :text => [@errors, params[:formula].gsub(/\n/," ").gsub(/\r/," ").squeeze(" ").upcase].to_json
  end

  private
  def categories_list
    @earnings_list = PayrollCategory.earnings - [@category]
    @deductions_list = PayrollCategory.deductions - [@category]
  end
  
end