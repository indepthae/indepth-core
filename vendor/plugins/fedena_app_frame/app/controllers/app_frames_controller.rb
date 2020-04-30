class AppFramesController < ApplicationController
  before_filter :login_required
  before_filter :oauth2_provider_plugin_required
  filter_access_to :all
  # GET /app_frames
  # GET /app_frames.xml
  def index
    @app_frames = AppFrame.find(:all, :order => "name ASC").paginate(:page => params[:page],:per_page => 30)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @app_frames }
    end
  end

  # GET /app_frames/1
  # GET /app_frames/1.xml
  def show
    @app_frame = AppFrame.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @app_frame }
    end
  end

  # GET /app_frames/new
  # GET /app_frames/new.xml
  def new
    @app_frame = AppFrame.new
    @clients =  Oauth2::Provider::OauthClient.find(:all, :conditions => {:verified => true})

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @app_frame }
    end
  end

  # GET /app_frames/1/edit
  def edit
    @app_frame = AppFrame.find(params[:id])
    @clients =  Oauth2::Provider::OauthClient.find(:all, :conditions => {:verified => true})
  end

  # POST /app_frames
  # POST /app_frames.xml
  def create
    @app_frame = AppFrame.new(params[:app_frame])
    @clients =  Oauth2::Provider::OauthClient.find(:all, :conditions => {:verified => true})

    respond_to do |format|
      if @app_frame.save
        flash[:notice] = t('success')
        format.html { redirect_to(app_frames_path) }
        format.xml  { render :xml => @app_frame, :status => :created, :location => @app_frame }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @app_frame.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /app_frames/1
  # PUT /app_frames/1.xml
  def update
    @app_frame = AppFrame.find(params[:id])
    @clients =  Oauth2::Provider::OauthClient.find(:all, :conditions => {:verified => true})

    respond_to do |format|
      if @app_frame.update_attributes(params[:app_frame])
        flash[:notice] = t('success_update')
        format.html { redirect_to(app_frames_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @app_frame.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /app_frames/1
  # DELETE /app_frames/1.xml
  def destroy
    @app_frame = AppFrame.find(params[:id])
    @app_frame.destroy

    respond_to do |format|
      flash[:notice] = t('success_delete')
      format.html { redirect_to(app_frames_url) }
      format.xml  { head :ok }
    end
  end

  def app_frame
    @app_frame = AppFrame.find(params[:id])
    
    respond_to do |format|
      if @app_frame.privilege_list.include? current_user.user_type.downcase
        format.html
      else
        flash[:notice] = t('not_allowed')
        format.html { redirect_to(app_frames_url)}
      end
    end
  end

  private
  
  def oauth2_provider_plugin_required
    unless(Oauth2::Provider rescue nil)
      flash[:notice] = t('not_allowed')
      redirect_to :controller => 'user', :action => 'dashboard' 
    end
  end
  
end
