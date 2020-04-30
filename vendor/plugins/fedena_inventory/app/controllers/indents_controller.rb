class IndentsController < ApplicationController
  before_filter :login_required
  before_filter :manager_required
  filter_access_to :all
  before_filter :set_precision

  def index
    current_employee_record = @current_user.employee_record
    manager_of_employees = User.find(:all, :joins => :employee_entry, :conditions => ["employees.reporting_manager_id = ? AND employee = ?", @current_user.id, true])
    manager_of_employees << @current_user
    @reporting_manager = current_employee_record.reporting_manager unless @current_user.admin? and !@current_user.employee_record.present?
    if @current_user.privileges.include?(Privilege.find_by_name('Inventory')) || @current_user.privileges.include?(Privilege.find_by_name('InventoryManager')) || @current_user.admin?
      @indents = Indent.active.find(:all,:conditions => ["(indents.indent_no LIKE ? AND indents.status LIKE ? )","#{params[:indent_no_like]}%","#{params[:status_like]}%"]).paginate :page=>params[:page],:per_page => 20
    elsif @current_user.employee
      @indents= Indent.active.find(:all,:conditions => ["(indents.indent_no LIKE ? AND indents.status LIKE ?) AND (indents.user_id IN (?))","#{params[:indent_no_like]}%","#{params[:status_like]}%",manager_of_employees.map{|e| e.id}]).paginate :page=>params[:page],:per_page => 20
    end
    respond_to do |format|
      format.html
      format.xml  { render :xml => @indents }
    end
  end

  def archived_indents
    if @current_user.employee and not  @current_user.privileges.include?(Privilege.find_by_name('InventoryManager'))
      current_employee_record = @current_user.employee_record.reporting_manager
      @reporting_manager = @current_user
      manager_of_employees = User.find_all_by_reporting_manager_id(@current_user.id)
      manager_of_employees <<  @current_user
      @indents= Indent.inactive.paginate :page=>params[:page],:conditions => ["(indents.indent_no LIKE ? OR indents.status LIKE ? ) AND (indents.user_id IN (?))","#{params[:search]}%","#{params[:search]}%",manager_of_employees.map{|e| e.id}],:per_page => 20
    elsif  @current_user.privileges.include?(Privilege.find_by_name('InventoryManager')) || @current_user.admin?
      @indents = Indent.inactive.paginate :page=>params[:page],:include=>[:user, :manager], :conditions => ["(indents.indent_no LIKE ? OR indents.status LIKE ? )","#{params[:search]}%","#{params[:search]}%"],:per_page => 20
    end
    respond_to do |format|
      format.html
      format.xml  { render :xml => @indents }
    end
  end

  
  def new
    if (@current_user.employee? and (@current_user.employee_record.nil? or @current_user.employee_record.reporting_manager_id.nil?)) or (@current_user.admin? and !current_user.employee_record.present?)
      flash[:notice] = t('warn_notice_indent')
      redirect_to(indents_url) 
    else
      @store_items= StoreItem.active
      @store_items_load = Array.new
      @indent = Indent.new
      @indent_item = @indent.indent_items.build
      @last_indent =Indent.last.indent_no unless Indent.last.nil?
      @stores = Store.active

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @indent }
      end
    end
  end

  def update_item
    if params[:item_id].present?
      @i =  params[:i] 
      @up_by = params[:up_by].to_i
      @store_item = StoreItem.find_by_id params[:item_id]
      @price = @store_item.unit_price
      @qty = @store_item.quantity
      @batch_no = @store_item.batch_number
    end
  end

  def create
    @indent = Indent.new(params[:indent])
    respond_to do |format|
      
      if @indent.save
        flash[:notice] = 'Indent was successfully created.'
        format.html { redirect_to(@indent) }
        format.xml  { render :xml => @indent, :status => :created, :location => @indent }
      else
        @store_items = StoreItem.active
        @store_items_load = @indent.store.nil? ? Array.new : @indent.store.store_items.active
        @last_indent =Indent.last.indent_no unless Indent.last.nil?
        @stores = Store.active
        format.html { render :action => "new" }
        format.xml  { render :xml => @indent.errors, :status => :unprocessable_entity }

    	end
    end
  end

  def edit
    if  @current_user.employee? and (@current_user.employee_record.nil? or @current_user.employee_record.reporting_manager_id.nil?)
      flash[:notice] = t('warn_notice_indent')
      redirect_to(indents_url)
    else
      @indent = Indent.active.find(params[:id])
      @store_items= StoreItem.active
      @store_items_load = @indent.store.store_items.active
      @stores = Store.active
    end
  end

  def update
    @indent = Indent.active.find(params[:id])
    respond_to do |format|
      if @indent.update_attributes(params[:indent])
        flash[:notice] = 'Indent was successfully updated.'
        format.html { redirect_to(@indent) }
        format.pdf { render :layout => false }
      else
        @store_items= StoreItem.active
        @store_items_load = @indent.store.store_items.active
        @stores = Store.active
        format.html { render :action => "edit" }
      end
    end
  end
  def search_items
    items = StoreItem.find(:all, :conditions=>["item_name LIKE ? AND store_id = ?", "#{params[:query]}%", params[:store_id]])
    render :json=>{'query'=>params["query"],'suggestions'=>items.collect{|s| s.item_name},'data'=>items.collect(&:id)  }
  end

  def show
    @indent = Indent.active.find(params[:id])
    @total = 0
    @indent.indent_items.each do |i|
      @total  += i.required *  i.price + (i.required * i.price * i.store_item.tax * 0.01)
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @indent }
    end
  end

  def indent_pdf
    @indent = Indent.active.find(params[:id])
    @total = 0
    @indent.indent_items.each do |i|
      @total  += i.required *  i.price + (i.required * i.price * i.store_item.tax * 0.01)
    end
    render :pdf=>'indent_pdf'
  end

  def acceptance
    @indent = Indent.active.find(params[:id])
    @store_items = StoreItem.active
    @store_items_load = @indent.store.store_items.active
    if request.post?
      if params[:indent][:status].present?
        if params[:indent][:status] == "Issued"
          @indent.raise_purchase_order = params[:indent][:raise_purchase_order]
          acceptance_result = @indent.accept_indent(params[:indent])
          @indent.accept
          if acceptance_result == false
            render :acceptance
          else
            flash[:notice] = acceptance_result
            redirect_to indents_path
          end
        elsif params[:indent][:status] == "Rejected"
          reject_result = @indent.reject_indent(params[:indent])
          if reject_result == false
            render :acceptance
          else
            flash[:notice] = reject_result
            redirect_to indents_path
          end
        end
      else
        @indent.errors.add('status',"can't be blank")
        render :acceptance
      end
    end
  end



  def destroy
    @indent = Indent.active.find(params[:id])
    if @indent.can_be_deleted?
      @indent.indent_items.map{|ii| ii.update_attributes(:is_deleted => true)}
      @indent.update_attributes(:is_deleted => true)
      flash[:notice] = 'Indent was successfully deleted.'
    else
      flash[:warn_notice]="<p>Indent is in use and cannot be deleted</p>"
    end
    respond_to do |format|
      format.html { redirect_to(indents_url) }
      format.xml  { head :ok }
    end
  end
  
  

  private
  def manager_required
    user = current_user
    unless user.admin? and !user.employee_record.present?
      employee = user.employee_record
      unless (employee.nil?)
        manager = employee.reporting_manager
        if manager.nil?
          flash[:notice] = "Indents can not be raised without manager"
          redirect_to inventories_path
        end
      else
        flash[:notice] = "Employee record not found for current user"
        redirect_to inventories_path
      end
    end
  end
end

