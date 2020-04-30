class RemarkBanksController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  
  def index
    @remark_banks =  RemarkBank.paginate(:include => :remark_templates, :per_page => 10, :page => params[:page],:order => "name ASC")
  end
  
  def show
    @remark_bank = RemarkBank.find_by_id(params[:id])
    @remark_templates = @remark_bank.remark_templates.paginate( :per_page => 10, :page => params[:page])
    if request.xhr?
      render :update do |page|
        page.replace_html 'attributes', :partial => 'remark_templates'
      end
    end
  end
  
  def new
    @remark_bank = RemarkBank.new
    @remark_template = @remark_bank.remark_templates.build
    get_keys
  end
  
  def create
    @remark_bank = RemarkBank.new(params[:remark_bank])
    if @remark_bank.save
      flash[:notice] = "Remark bank saved successfully"
      redirect_to :action => 'index'
    else
#      @remark_template = @remark_bank.remark_templates.build
      get_keys
      render 'new'
    end
  end
  
  def destroy
    @remark_bank = RemarkBank.find_by_id(params[:id])
    if @remark_bank.destroy
      flash[:notice] = "Remark Bank deleted successfully"
      redirect_to :action => 'index'
    else
      flash[:notice] = "Cant delete remark bank"
      redirect_to :action => 'show', :id => params[:id]
    end
  end
  
  def edit
    @remark_bank = RemarkBank.find_by_id(params[:id])
    @remark_templates = @remark_bank.remark_templates
    get_keys
  end
  
  def update
    @remark_bank = RemarkBank.find_by_id(params[:id])
    if @remark_bank.update_attributes(params[:remark_bank])
      flash[:notice] = "Remark Bank updated successfully"
      redirect_to :action => 'show', :id => params[:id]
    else
      get_keys
      render :action => :edit
    end
  end
  
  private
  
  def get_keys
    @keys = RemarkTemplate.get_student_keys
    @keys=@keys.sort_by{|key,val| val.downcase}
  end
  
end
