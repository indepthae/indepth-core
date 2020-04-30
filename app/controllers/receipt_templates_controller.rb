class ReceiptTemplatesController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  before_filter :fetch_additional_templates, :only => [:new, :create, :edit, :update]
  #  require 'lib/override_errors'
  #  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  include FeeReceiptMod  
  include ReceiptPrinterHelper
  helper_method(:get_stylesheet_for_current_receipt_template,:get_stylesheet_for_receipt_template,:get_current_receipt_partial,:get_partial_for_current_receipt_template,:receipt_path,:get_receipt_partial,:precision_label_with_currency,
    :has_fine?,:has_discount?,:has_tax?,:has_previously_paid_fees?,:has_roll_number?,:particular_has_discount,:particular_has_previous_payments,
    :current_receipt_template_preview_url,:reference_no_label,:clean_output,:has_due?,:has_due_date?,:has_particulars?)
  
  def index
    ## TO DO :: add pagination
    @receipt_templates = FeeReceiptTemplate.all(:order => "name")
  end
  
  def new
    @receipt_template = FeeReceiptTemplate.new
  end
  
  def create
    @receipt_template = FeeReceiptTemplate.new(fee_receipt_template_params)
    if @receipt_template.save
      flash[:notice] = "#{t('receipt_templates.flash1')}"
      #      render :update do |page|
      #        page.redirect_to(receipt_templates_path)
      #      end
      
      redirect_to template_preview_receipt_template_path(@receipt_template) and return if params[:fee_receipt_template][:preview].to_i == 1
      redirect_to receipt_templates_path      
    else
      render :new
    end
  end
  
  def edit
    @receipt_template = FeeReceiptTemplate.find(params[:id])
    #    render_form
  end
  
  def update
    @receipt_template = FeeReceiptTemplate.find(params[:id])
    #    @receipt_template.has_assignments?
    if @receipt_template.update_attributes(fee_receipt_template_params)
      flash[:notice] = "#{t('receipt_templates.flash2')}"
      #      render :update do |page|
      #        page.redirect_to(receipt_templates_path)
      #      end
      redirect_to template_preview_receipt_template_path(@receipt_template) and return if params[:fee_receipt_template][:preview].to_i == 1
      redirect_to(receipt_templates_path)
    else
      render :edit
    end
  end
  
  def destroy
    @receipt_template = FeeReceiptTemplate.find(params[:id])
    #    @tax_slab.has_assignments?
    if @receipt_template.destroy
      flash[:notice] = "#{t('receipt_templates.flash3')}"
      #      redirect_to tax_slabs_path      
    else
      flash[:notice] = "#{t('receipt_templates.flash4')}"
      # 
    end
    render :update do |page|
      page.redirect_to(receipt_templates_path)
    end
    #    render :js=>"window.location='#{tax_slabs_path}'"
  end

  def template_preview
    @transactions = get_receipt_dummy_data(false)
    @frt = FeeReceiptTemplate.find(params[:id])
    #    @header_content = frt.header_content_for_pdf
    #    @footer_content = frt.footer_content
    @data = {:templates => {params[:id].to_i => @frt.to_a}}
    #    render :pdf => "showpdf", 
    render :pdf => "template_preview",
      #      :file => "showpdf",
    #      :header => {:html => {:content => frt.header_content_for_pdf}},
    #    :layout => false,
    #    :margin => { :top=> 25, :bottom => 10, :left => 5, :right => 5},
    #      :header => {:html => {:template => "receipt_templates/_header.html"}},
    #      :footer => {:html => {:template => "receipt_templates/_footer.html"}},
    #      :show_as_html => params[:debug].present?,    
    :template => "receipt_templates/template_preview.erb",
      :margin =>{:top => 2, :bottom => 20, :left => 5, :right => 5},
      :header => {:html => { :content=> ''}}, 
      :footer => {:html => {:content => ''}}, 
      :show_as_html => params.key?(:debug)
    ##,
    #      :content_type => "text/html"
    #      :show_as_html => true
    #      :footer => {:content => frt.footer_content} #,
    #      :footer => {:html => {:content => frt.footer_content}} #,:show_as_html => true
    #    puts frt.header_content
    #    render :pdf => frt.footer_content, 
    #      :header => frt.header_content,
    #      :footer => frt.footer_content,
    #      :content_type => "text/html"
    #      :layout => false,
    #      :header => nil, #{:html => {:template => frt.header_content}}, 
    #      :footer => frt.footer_content #{:html => {:template => frt.footer_content}}
      
  end
  
  private
  
  def fee_receipt_template_params
    params[:fee_receipt_template].present? ? 
      params[:fee_receipt_template].slice(:name, :header_content, :footer_content, :header_content_thermal_responsive,
      :header_content_a5_portrait, :redactor_to_delete, :redactor_to_update) : {}
  end

  def fetch_additional_templates    
    receipt_printer = ReceiptPrinter.current_settings_object
    @additional_templates = receipt_printer.all_templates(["A4", "A5 Landscape"])
  end
  #  def render_form
  #    respond_to do |format|
  #      format.js { render :action => :new }
  #    end
  #  end
end
