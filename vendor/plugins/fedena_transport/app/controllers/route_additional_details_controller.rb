class RouteAdditionalDetailsController < ApplicationController
  
  before_filter :login_required
  before_filter :set_additional_field, :only => [:edit, :update, :delete_details]
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  check_request_fingerprint :create, :update
  
  def index
    all_fields
  end
  
  def new
    @route_addl_field = RouteAdditionalField.new()
    @route_additional_field_option = @route_addl_field.route_additional_field_options.build
    render_form
  end
  
  def create
    @route_addl_field = RouteAdditionalField.new(params[:route_additional_field])
    if @route_addl_field.save
      flash[:notice] = "#{t('flash1')}"
      render :update do |page|
        page.redirect_to(route_additional_details_path)
      end
    else
      render_form
    end
  end
  
  def edit
    build_options
    render_form
  end
  
  def update
    if @route_addl_field.update_attributes(params[:route_additional_field])
      flash[:notice] = "#{t('flash2')}"
      render :update do |page|
        page.redirect_to(route_additional_details_path)
      end
    else
      render_form
    end
  end
  
  def delete_details 
    if @route_addl_field.destroy
      flash[:notice] = "#{t('flash3')}"
    else
      flash[:notice] = "#{t('flash4')}"
    end
    redirect_to :action => :index
  end
  
  def change_field_priority
    RouteAdditionalField.change_priority(params[:id], params[:order])
    all_fields
    render(:update) do|page|
      page.replace_html "addl_details_list", :partial=>"additional_fields"
    end
  end
  
  private 
  
  def set_additional_field
    @route_addl_field = RouteAdditionalField.find(params[:id])
  end
  
  def build_options
    @route_additional_field_option = @route_addl_field.route_additional_field_options.
      build if @route_addl_field.route_additional_field_options.blank?
  end
  
  def render_form
    header = (@route_addl_field.new_record? ? t('create_new_route_additional_detail') : t('edit_route_additional_detail'))
    render :update do |page|
      page << "remove_popup_box(); build_modal_box({'title' : '#{header}', 'popup_class' : 'transport_form'})" unless params[:route_additional_field].present?
      page.replace_html 'popup_content', :partial => 'add_additional_field'
    end
  end
  
  def all_fields
    @additional_details = RouteAdditionalField.active.include_details
    @inactive_additional_details = RouteAdditionalField.inactive.include_details 
  end
  
end
