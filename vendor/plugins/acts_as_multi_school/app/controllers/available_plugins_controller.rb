class AvailablePluginsController <  MultiSchoolController

  helper_method :owner_type
  before_filter :find_owner
  before_filter :load_available_plugin

  filter_access_to :all,:except=>[:plugin_list], :attribute_check=>true
  filter_access_to :plugin_list
  
  
  def show    
  end

  def new    
  end

  def create    
    if @available_plugin.save
      flash[:notice]="Plugins assigned successfully."
      if (@available_plugin.plugins.include?("fedena_pay") and admin_user_session.available_gateways.present?)
        r = "assign_gateways_#{owner_type}_payment_gateways_path"
        redirect_to(send r,@owner)
      else
      redirect_to @owner
      end
    else
      render :new
    end
  end

  def edit    
  end

  def update
    if params[:available_plugin]
      plugin_row = params[:available_plugin]
    else
      plugin_row = {:plugins=>[]}
    end
    if @available_plugin.update_attributes(plugin_row)
      flash[:notice]="Assigned Plugins updated successfully."
      unless @owner.class.name=="School"
        Delayed::Job.enqueue(@owner)
      end
      redirect_to @owner
    end
  end

  def destroy    
  end

  def plugin_list
    render :partial=>'plugin_list'
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
    params.each do |name, value|
      if name =~ /(.+)_id$/
        @owner = $1.classify.constantize.find(value)
      end
    end
    nil
  end

  def load_available_plugin
    case action_name
    when "show","plugin_list","destroy"
      @available_plugin = (@owner.available_plugin ?  @owner.available_plugin : @owner.build_available_plugin)
    when "new"
      if @owner.available_plugin
        re_path = "edit_#{owner_type}_available_plugin_path"
        redirect_to(send re_path,@owner)
      else
        @available_plugin = @owner.build_available_plugin(:plugins=>[])
      end
    when "create"
      @available_plugin = @owner.build_available_plugin(params[:available_plugin])
    when "edit"
      unless @owner.available_plugin
        re_path = "new_#{owner_type}_available_plugin_path"
        redirect_to(send re_path,@owner)
      else
        @available_plugin = @owner.available_plugin
      end
    when "update"
      @available_plugin = @owner.available_plugin
    end
  end

  
end
