class BuildingsController < ApplicationController

  before_filter :login_required
  before_filter :has_no_allocations, :only => [:destroy]
  before_filter :find_building, :only => [:edit,:update,:show,:destroy]
  filter_access_to :all
  
  def index
    @buildings = Building.paginate(:page => params[:page], :per_page => 10, :include => :classrooms, :order => "buildings.created_at DESC")
  end

  def new
    @building = Building.new
    @classroom = @building.classrooms.build
  end

  def create
    @building = Building.new(params[:building])
    if @building.save
      flash[:notice] = "#{t('building_added')}"
      redirect_to :action => "index"
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    if @building.update_attributes(params[:building]) 
      flash[:notice] = "#{t('building_edited')}"
      redirect_to :action => "index"
    else
      render :action => "edit"
    end
  end
  
  def show
    @classrooms = @building.classrooms.paginate(:page => params[:page],:per_page => 10)
  end

  def destroy
    if @allocations.count > 0
      flash[:notice] = "#{t('allocation_exist')}"
    else
      @building.destroy
      flash[:notice] = "#{t('building_deleted')}"
    end
    redirect_to buildings_path
  end

  private

  def has_no_allocations
    @building =  Building.find(params[:id])
    classrooms = @building.classrooms.collect{|c| c.id }
    @allocations = AllocatedClassroom.find(:all,:conditions =>["classroom_id IN (?)",classrooms])
  end

  def find_building
    @building = Building.find(params[:id])
  end
end




























