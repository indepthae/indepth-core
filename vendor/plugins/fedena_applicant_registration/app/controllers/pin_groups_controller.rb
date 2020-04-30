class PinGroupsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  # GET /pin_groups
  # GET /pin_groups.xml
  def index
    @pin_groups = PinGroup.paginate :per_page=>20,:page => params[:page], :order => 'id DESC'

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pin_groups }
    end
  end

  # GET /pin_groups/1
  # GET /pin_groups/1.xml
  def show
    @pin_group = PinGroup.find(params[:id])
    unless params[:search].nil?
      params[:search].merge(:pin_group_id_equals => @pin_group.id)
    else
      params[:search] = {:pin_group_id_equals => @pin_group.id}
    end
    @results  = PinNumber.search(params[:search])
    @pin_numbers = @results.paginate :per_page=>30,:page => params[:page], :order => 'id DESC'
  end

  
  def search_ajax
    @pin_group = PinGroup.find(params[:pin_group_id])
    @i = ((params[:page].to_i - 1) * 30) if params[:page].present?
    unless params[:search]
      search = {:pin_group_id_equals => params[:pin_group_id]}
      if params[:query].length >= 14
        search = search.merge(:number_equals => params[:query].strip)
      else
        search = search.merge(:number_begins_with => params[:query].strip)
      end
      if params[:option] == "active"
        search = search.merge(:is_active_equals => true)
      elsif params[:option] == "inactive"
        search = search.merge(:is_active_equals => false)
      elsif params[:option] == "registered"
        search = search.merge(:is_registered_equals => true)
      end
    else
      @repeat_search = true
      @search = params[:search]
      search = params[:search]
    end
    @results  = PinNumber.search(search)
    @pin_numbers = @results.paginate :per_page=>30,:page => params[:page], :order => 'id DESC'
    render :update do |page|
      @query = params[:query]
      @option = params[:option]
      page.replace_html 'pin_list',:partial => 'list_pins'
    end
  end
  # GET /pin_groups/new
  # GET /pin_groups/new.xml
  def new
    @pin_group = PinGroup.new
    @courses = RegistrationCourse.active
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pin_group }
    end
  end

  # GET /pin_groups/1/edit
  def edit
    @courses = RegistrationCourse.active
    @pin_group = PinGroup.find(params[:id])
  end

  # POST /pin_groups
  # POST /pin_groups.xml
  def create
    @pin_group = PinGroup.new(params[:pin_group])

    respond_to do |format|
      if @pin_group.save
        flash[:notice] = t('flash1')
        format.html { redirect_to(@pin_group) }
        format.xml  { render :xml => @pin_group, :status => :created, :location => @pin_group }
      else
        @courses = RegistrationCourse.active
        format.html { render :action => "new" }
        format.xml  { render :xml => @pin_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pin_groups/1
  # PUT /pin_groups/1.xml
  def update
    @pin_group = PinGroup.find(params[:id])
    @courses = RegistrationCourse.active
    unless params[:pin_group][:course_ids].present?     
      @pin_group.errors.add("course_ids","can't be blank")
      render :edit and return
    end

    respond_to do |format|
      if @pin_group.update_attributes(params[:pin_group])
        if params[:pin_group][:is_active]=="1"
          @pin_group.pin_numbers.update_all("is_active=true")
        else
          @pin_group.pin_numbers.update_all("is_active=false")
        end
        flash[:notice] = t('flash2')
        format.html { redirect_to(@pin_group) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pin_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pin_groups/1
  # DELETE /pin_groups/1.xml
  def deactivate_pin_group
    @pin_group = PinGroup.find(params[:id])
    if @pin_group.is_active?
      @pin_group.update_attributes(:is_active => false)
      PinNumber.update_all("is_active= false","pin_group_id = #{@pin_group.id}")
    else
      @pin_group.update_attributes(:is_active => true)
      PinNumber.update_all("is_active= true","pin_group_id = #{@pin_group.id}")
    end
    flash[:notice] = t('flash3')
    redirect_to pin_groups_path
  end

  def deactivate_pin_number
    @pin_number = PinNumber.find(params[:id])
    @pin_group = @pin_number.pin_group
    if @pin_number.is_active?
      @pin_number.update_attributes(:is_active => false)
      if @pin_group.pin_numbers.count(:conditions=>{:is_active=>true})== 0 and @pin_group.is_active
        @pin_group.update_attributes(:is_active => false)
      end
    else
      @pin_number.update_attributes(:is_active => true)
      if @pin_group.pin_numbers.count(:conditions=>{:is_active=>true}) > 0 and @pin_group.is_active == false
        @pin_group.update_attributes(:is_active => true)
      end
    end
    flash[:notice] = t('flash4')
    redirect_to @pin_group
  end
end
