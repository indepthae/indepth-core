class SmsPackagesController < MultiSchoolController

  helper_method :school_group_session
  helper_method :owner_type
  before_filter :find_owner

  filter_access_to [:new,:create,:edit,:update,:package_list,:assigned_list,:assign_package,:update_assignee_list,:edit_assigned,:remove_package], :attribute_check=>true, :load_method => lambda { @owner.present? ? @owner : School.new }
  def new
    @sms_package = SmsPackage.new
  end

  def create
    @sms_package = SmsPackage.new(params[:sms_package])
    if @sms_package.save
      unless admin_user_session.school_group.nil?
        AssignedPackage.create(:sms_package_id=>@sms_package.id,:assignee=>@owner,:enable_sendername_modification=>@sms_package.enable_sendername_modification,:sendername=>@sms_package.settings[:sms_settings][:sendername],:sms_count=>@sms_package.message_limit,:validity=>@sms_package.validity,:sms_used=>0,:is_owner=>true)
      else
        AssignedPackage.create(:sms_package_id=>@sms_package.id,:enable_sendername_modification=>@sms_package.enable_sendername_modification,:sendername=>@sms_package.settings[:sms_settings][:sendername],:sms_count=>@sms_package.message_limit,:validity=>@sms_package.validity,:sms_used=>0,:is_owner=>true)
      end
      flash[:notice] = "SMS Package created successfully."
      unless @owner.nil?
        redirect_to @owner
      else
        redirect_to master_settings_path
      end
    else
      render :new
    end
  end

  def edit
    unless @owner.nil?
      assigned_package = @owner.assigned_packages.first(:conditions=>{:sms_package_id=>params[:id],:is_owner=>true})
    else
      assigned_package = AssignedPackage.find(:first,:conditions=>{:assignee_id=>nil,:assignee_type=>nil,:sms_package_id=>params[:id],:is_owner=>true})
    end
    @sms_package = SmsPackage.find(assigned_package.present? ? assigned_package.sms_package_id : nil)
  end

  def update
    unless @owner.nil?
      assigned_package = @owner.assigned_packages.first(:conditions=>{:sms_package_id=>params[:id],:is_owner=>true})
    else
      assigned_package = AssignedPackage.find(:first,:conditions=>{:assignee_id=>nil,:assignee_type=>nil,:sms_package_id=>params[:id],:is_owner=>true})
    end
    @sms_package = SmsPackage.find(assigned_package.present? ? assigned_package.sms_package_id : nil)
    if @sms_package.update_attributes(params[:sms_package])
      assigned_package.update_attributes(:enable_sendername_modification=>@sms_package.enable_sendername_modification,:sendername=>params[:sms_package][:settings][:sms_settings][:sendername],:sms_count=>@sms_package.message_limit,:validity=>@sms_package.validity)
      flash[:notice] = "SMS Package modified successfully."
      unless @owner.nil?
        redirect_to @owner
      else
        redirect_to master_settings_path
      end
    else
      render :edit
    end
  end

  def package_list
    unless @owner.nil?
      @assigned_packages = @owner.assigned_packages.all(:include=>:sms_package)
    else
      @assigned_packages = AssignedPackage.find(:all, :conditions=>{:assignee_id=>nil,:assignee_type=>nil,:is_owner=>true}, :include=>:sms_package)
    end
    render :partial=>'package_list'
  end

  def assigned_list
    @sms_package = SmsPackage.find(params[:id])
    if @owner.nil?
      @assigned_row = @sms_package.assigned_packages.first(:conditions=>{:assignee_id=>nil,:assignee_type=>nil})
      @assigned_packages = AssignedPackage.find(:all, :conditions=>{:sms_package_id=>@sms_package.id,:assignee_id=>ClientSchoolGroup.active.all.collect(&:id),:assignee_type=>'SchoolGroup',:is_owner=>false}, :include=>:assignee)
    else
      @assigned_row = @owner.assigned_packages.first(:conditions=>{:sms_package_id=>@sms_package.id})
      if owner_type == "client_school_group"
        assigned_multischools = AssignedPackage.find(:all, :conditions=>{:sms_package_id=>@sms_package.id,:assignee_id=>@owner.multi_school_groups.collect(&:id),:assignee_type=>'SchoolGroup',:is_owner=>false}, :include=>:assignee)
        assigned_schools = AssignedPackage.find(:all, :conditions=>{:sms_package_id=>@sms_package.id,:assignee_id=>@owner.schools.collect(&:id),:assignee_type=>'School',:is_owner=>false}, :include=>:assignee)
        @assigned_packages = assigned_multischools + assigned_schools
      else
        @assigned_packages = AssignedPackage.find(:all, :conditions=>{:sms_package_id=>@sms_package.id,:assignee_id=>@owner.schools.collect(&:id),:assignee_type=>'School',:is_owner=>false}, :include=>:assignee)
      end
    end
  end

  def assign_package
    @sms_package = SmsPackage.find(params[:id])
    if @owner.nil?
      @assigned_row = @sms_package.assigned_packages.first(:conditions=>{:assignee_id=>nil,:assignee_type=>nil})
      @available_assignees = ClientSchoolGroup.active.all
    else
      @assigned_row = @owner.assigned_packages.first(:conditions=>{:sms_package_id=>@sms_package.id})
      @available_assignees = @owner.schools.all(:conditions=>{:is_deleted=>false})
    end
    if request.post?
      @assigned_package = AssignedPackage.new(params[:assigned_package])
      @assigned_package.sms_package_id = @sms_package.id
      @assigned_package.sms_used = 0
      @assigned_package.sendername = @assigned_row.sendername unless @assigned_row.enable_sendername_modification
      if @assigned_package.save
        if @assigned_package.sms_count
          @assigned_row.update_attributes(:sms_used=>(@assigned_row.sms_used + @assigned_package.sms_count))
        end
        flash[:notice] = "SMS Package assigned successfully."
        unless @owner.nil?
          assigned_path = "assigned_list_#{owner_type}_sms_package_path"
          redirect_to send(assigned_path,@owner,@sms_package)
        else
          redirect_to assigned_list_sms_package_path(@sms_package)
        end
      else
        if @owner.present?
          if @assigned_package.assignee_type=="SchoolGroup"
            @available_assignees = @owner.multi_school_groups.all(:conditions=>{:is_deleted=>false})
          end
        end
      end
    else
      @assigned_package = AssignedPackage.new
    end
  end

  def update_assignee_list
    if params[:assignee_type]=="School"
      @available_assignees = @owner.schools.all(:conditions=>{:is_deleted=>false})
    else
      @available_assignees = @owner.multi_school_groups.all(:conditions=>{:is_deleted=>false})
    end
    render :update do|page|
      page.replace_html "assignee_list",:partial=>"assignee_list"
    end
  end

  def edit_assigned
    @sms_package = SmsPackage.find(params[:id])
    @assigned_row = admin_user_session.school_group.present? ? admin_user_session.school_group.assigned_packages.first(:conditions=>{:sms_package_id=>@sms_package.id}) : @sms_package.assigned_packages.first(:conditions=>{:assignee_type=>nil})
    if request.put?
      @assigned_package = @owner.assigned_packages.first(:conditions=>{:sms_package_id=>@sms_package.id,:is_owner=>false})
      message_count = @assigned_package.sms_count
      if @assigned_package.update_attributes(params[:assigned_package])
        @assigned_row.update_attributes(:sms_used=>(@assigned_row.sms_used + (@assigned_package.sms_count.to_i - message_count.to_i) ))
        flash[:notice] = "SMS package modified successfully."
        if @assigned_row.assignee == @owner
          redirect_to @owner
        else
          if admin_user_session.school_group.nil?
            redirect_to assigned_list_sms_package_path(@sms_package)
          else
            redirect_to send("assigned_list_#{admin_user_session.school_group.class.name.underscore}_sms_package_path",admin_user_session.school_group,@sms_package)
          end
        end
      end
    else
      @assigned_package = @owner.assigned_packages.first(:conditions=>{:sms_package_id=>@sms_package.id,:is_owner=>false},:include=>:assignee)
    end
  end

  def remove_package
    @sms_package = SmsPackage.find(params[:id])
    @assigned_package = @owner.assigned_packages.first(:conditions=>{:sms_package_id=>@sms_package.id})
    @assigned_row = admin_user_session.school_group.present? ? admin_user_session.school_group.assigned_packages.first(:conditions=>{:sms_package_id=>@sms_package.id}) : @sms_package.assigned_packages.first(:conditions=>{:assignee_type=>nil})
    unused_sms = @owner.unused_sms(@sms_package.id)
    @assigned_row.update_attributes(:sms_used => (@assigned_row.sms_used - unused_sms))
    if @assigned_package.destroy
      @owner.delete_associated_packages(@sms_package.id)
      flash[:notice] = "SMS package removed successfully."
      if admin_user_session.school_group.nil?
        redirect_to assigned_list_sms_package_path(@sms_package)
      else
        redirect_to send("assigned_list_#{admin_user_session.school_group.class.name.underscore}_sms_package_path",admin_user_session.school_group,@sms_package)
      end
    end
  end

  def destroy
    @sms_package = SmsPackage.find(params[:id])
    unless @owner.nil?
      assigned_package = @owner.assigned_packages.first(:conditions=>{:sms_package_id=>params[:id],:is_owner=>true})
    else
      assigned_package = AssignedPackage.find(:first,:conditions=>{:assignee_id=>nil,:assignee_type=>nil,:sms_package_id=>params[:id],:is_owner=>true})
    end
    if assigned_package.present?
      if @sms_package.destroy
        flash[:notice] = "SMS Package deleted successfully."
      end
    else
      flash[:notice] = "You are not allowed to perform the intended action."
    end
    unless @owner.nil?
      redirect_to @owner
    else
      redirect_to master_settings_path
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

end
