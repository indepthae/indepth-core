class PaymentGatewaysController < MultiSchoolController
  helper_method :school_group_session
  helper_method :owner_type
  before_filter :find_owner
  #filter_access_to :all, :attribute_check=>true
  filter_access_to [:index,:new,:create,:edit,:update,:assign_gateways,:show], :attribute_check=>true, :load_method => lambda { @owner.present? ? @owner : School.new }
  before_filter :check_assigned_plugin

  def index
    if owner_type.nil?
      @gateways = admin_user_session.available_gateways
    else
      @gateways = @owner.gateway_assignees.all(:include=>:custom_gateway)
    end
  end

  def new
    @gateway = CustomGateway.new
  end

  def create
    @gateway = CustomGateway.new(params[:custom_gateway])
    if @gateway.save
      unless admin_user_session.school_group.nil?
        GatewayAssignee.create(:custom_gateway_id=>@gateway.id,:assignee=>admin_user_session.school_group,:is_owner=>true)
      else
        GatewayAssignee.create(:custom_gateway_id=>@gateway.id,:is_owner=>true)
      end
      flash[:notice] = "New Payment Gateway created successfully."
      unless @owner.nil?
        r = "#{owner_type}_payment_gateways_path"
        redirect_to(send r,@owner)
      else
        redirect_to payment_gateways_path
      end
    else
      render :new
    end
  end

  def show
    unless @owner.nil?
      @assigned_gateway = @owner.gateway_assignees.first(:conditions=>{:custom_gateway_id=>params[:id]})
    else
      @assigned_gateway = GatewayAssignee.find(:first,:conditions=>{:assignee_id=>nil,:assignee_type=>nil,:custom_gateway_id=>params[:id]})
    end
    @gateway = CustomGateway.find(@assigned_gateway.present? ? @assigned_gateway.custom_gateway_id : nil)
  end

  def destroy
    unless @owner.nil?
      assigned_gateway = @owner.gateway_assignees.first(:conditions=>{:custom_gateway_id=>params[:id],:is_owner=>true})
    else
      assigned_gateway = GatewayAssignee.find(:first,:conditions=>{:assignee_id=>nil,:assignee_type=>nil,:custom_gateway_id=>params[:id],:is_owner=>true})
    end
    @gateway = CustomGateway.find(assigned_gateway.present? ? assigned_gateway.custom_gateway_id : nil)
    if @gateway.present?
      if @gateway.update_attributes(:is_deleted=>true)
        GatewayAssignee.destroy_all(:custom_gateway_id=>@gateway.id)
        flash[:notice] = "Payment Gateway deleted successfully."
      end
    end
    unless @owner.nil?
      r = "#{owner_type}_payment_gateways_path"
      redirect_to(send r,@owner)
    else
      redirect_to payment_gateways_path
    end
  end

  def edit
    unless @owner.nil?
      assigned_gateway = @owner.gateway_assignees.first(:conditions=>{:custom_gateway_id=>params[:id],:is_owner=>true})
    else
      assigned_gateway = GatewayAssignee.find(:first,:conditions=>{:assignee_id=>nil,:assignee_type=>nil,:custom_gateway_id=>params[:id],:is_owner=>true})
    end
    @gateway = CustomGateway.find(assigned_gateway.present? ? assigned_gateway.custom_gateway_id : nil).remodel_params_hash
  end

  def update
    unless @owner.nil?
      assigned_gateway = @owner.gateway_assignees.first(:conditions=>{:custom_gateway_id=>params[:id],:is_owner=>true})
    else
      assigned_gateway = GatewayAssignee.find(:first,:conditions=>{:assignee_id=>nil,:assignee_type=>nil,:custom_gateway_id=>params[:id],:is_owner=>true})
    end
    @gateway = CustomGateway.find(assigned_gateway.present? ? assigned_gateway.custom_gateway_id : nil)
    if @gateway.update_attributes(params[:custom_gateway])
      flash[:notice] = "Payment Gateway updated successfully."
      unless @owner.nil?
        r = "#{owner_type}_payment_gateways_path"
        redirect_to(send r,@owner)
      else
        redirect_to payment_gateways_path
      end
    else
      render :edit
    end
  end

  def assign_gateways
    @gateways = admin_user_session.available_gateways
    @assigned_gateways = @owner.gateway_assignees.all(:include=>:custom_gateway)
    if request.post?
      inherited_gateways = @assigned_gateways.collect(&:custom_gateway_id) & @gateways.collect(&:custom_gateway_id)
      updated_gateways = []
      if params[:assigned_gateways].present?
        updated_gateways = params[:assigned_gateways].map{|g| g.to_i}
      end
      removed_gateways = inherited_gateways - updated_gateways
      unless removed_gateways.empty?
        @owner.gateway_assignees.all(:conditions=>{:custom_gateway_id=>removed_gateways}).map{|r| r.destroy}
      end
      added_gateways = updated_gateways - inherited_gateways
      unless added_gateways.empty?
        added_gateways.map{|m| GatewayAssignee.create(:custom_gateway_id=>m,:assignee=>@owner)}
      end
      flash[:notice]="Payment gateways assigned successfully"
      unless @owner.class.name=="School"
        @owner.job_mode = "modify_gateways"
        Delayed::Job.enqueue(@owner)
      end
      redirect_to @owner
    end
  end

  private

  def owner_type
    params.each do |name, value|
      if name =~ /(.+)_id$/
        return $1
      end
    end
    nil
  end

  def find_owner
    @owner = nil
    params.each do |name, value|
      if name =~ /(.+)_id$/
        @owner = $1.classify.constantize.find(value)
      end
    end
    nil
  end

  def check_assigned_plugin
    unless @owner.nil?
      unless @owner.allowed_plugins.include?("fedena_pay")
        flash[:notice]="You are not allowed to view the requested page."
        redirect_to @owner
      end
    end
  end

end
