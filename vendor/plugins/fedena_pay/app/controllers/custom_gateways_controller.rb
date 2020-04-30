class CustomGatewaysController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @gateways = CustomGateway.available_gateways
    @own_gateways = CustomGateway.own_gateways
    #@own_gateways = CustomGateway.own_gateways
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway") || []
  end
  
  def manage_accounts
    @gateway = CustomGateway.find(params[:id])
    @available_gateways = CustomGateway.available_gateways
    if @available_gateways.collect(&:id).include?(@gateway.id)
      @financial_years = FinancialYear.all
      @active_financial_year = FinancialYear.active.first
      @finance_collections = []
      @hostel_collections = []
      @transport_collections = []
      if @active_financial_year.present?
        @finance_collections = @active_financial_year.finance_fee_collections.active
        @hostel_collections = @active_financial_year.hostel_fee_collections.active if FedenaPlugin.can_access_plugin?("fedena_hostel")
        @transport_collections = @active_financial_year.transport_fee_collections if FedenaPlugin.can_access_plugin?("fedena_transport")
      else
        @finance_collections = FinanceFeeCollection.find_all_by_financial_year_id_and_is_deleted(nil,false)
        @transport_collections = TransportFeeCollection.find_all_by_financial_year_id_and_is_deleted(nil,false) if FedenaPlugin.can_access_plugin?("fedena_transport")
        @hostel_collections = HostelFeeCollection.find_all_by_financial_year_id_and_is_deleted(nil,false) if FedenaPlugin.can_access_plugin?("fedena_hostel")
      end
    else
      flash[:notice]="#{t('flash_msg4')}"
      redirect_to :controller=>'user', :action=>'dashboard'
    end
  end
  
  def update_accounts
    @gateway = CustomGateway.find(params[:id])
    @available_gateways = CustomGateway.available_gateways
    if @available_gateways.collect(&:id).include?(@gateway.id)
      if @gateway.update_attributes(params[:custom_gateway])
        flash[:notice] = "Account Details updated successfully."
      else
        flash[:notice] = "Account Details could not be updated"
      end
      redirect_to custom_gateways_path
    else
      flash[:notice]="#{t('flash_msg4')}"
      redirect_to :controller=>'user', :action=>'dashboard'
    end
  end
  
  def change_financial_year
    @gateway = CustomGateway.find(params[:custom_gateway_id])
    @finance_collections = []
    @hostel_collections = []
    @transport_collections = []
    if params[:financial_year_id] == "0"
      @finance_collections = FinanceFeeCollection.find_all_by_financial_year_id_and_is_deleted(nil,false)
      @transport_collections = TransportFeeCollection.find_all_by_financial_year_id_and_is_deleted(nil,false) if FedenaPlugin.can_access_plugin?("fedena_transport")
      @hostel_collections = HostelFeeCollection.find_all_by_financial_year_id_and_is_deleted(nil,false) if FedenaPlugin.can_access_plugin?("fedena_hostel")
    else
      financial_year = FinancialYear.find(params[:financial_year_id])
      @finance_collections = financial_year.finance_fee_collections.active
      @hostel_collections = financial_year.hostel_fee_collections.active if FedenaPlugin.can_access_plugin?("fedena_hostel")
      @transport_collections = financial_year.transport_fee_collections if FedenaPlugin.can_access_plugin?("fedena_transport")
    end
    render :update do|page|
      page.replace_html "account-details", :partial=>"account_details"
    end
  end

  def new
    @gateway = CustomGateway.new
  end

  def create
    @gateway = CustomGateway.new(params[:custom_gateway])
    if @gateway.save
      flash[:notice] = "#{t('gateway_creation_msg')}"
      redirect_to custom_gateways_path
    else
      render :new
    end
  end

  def edit
    @gateway = CustomGateway.find(params[:id]).remodel_params_hash
  end

  def update
    @gateway = CustomGateway.find(params[:id])
    if @gateway.update_attributes(params[:custom_gateway])
      flash[:notice] = "#{t('gateway_updation_msg')}"
      redirect_to custom_gateways_path
    else
      render :edit
    end
  end

  def destroy
    @gateway = CustomGateway.find(params[:id])
    @active_gateway = PaymentConfiguration.config_value("fedena_gateway") || []
    unless @active_gateway.include? @gateway.id.to_s
      @gateway.update_attributes(:is_deleted=>true)
      flash[:notice]="#{t('gateway_deletion_msg')}"
    else
      flash[:notice]="#{t('cannot_delete_gateway')}"
    end
    redirect_to custom_gateways_path
  end

end
