class StudentDocumentCategoriesController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  #  before_filter :is_modifiable?, :only => [:edit,:destroy]
  
  def index
    @categories = StudentAttachmentCategory.fetch_all # default.to_a + StudentAttachmentCategory.all
  end
  
  def new
    @category = StudentAttachmentCategory.new
    @initial = true
    respond_to do |format|
      format.js { render :action => "new"}
    end
  end
  
  def create    
    @category = StudentAttachmentCategory.new(params[:student_attachment_category])
    if @category.save
      @saved = true
      @categories = StudentAttachmentCategory.fetch_all #default.to_a + StudentAttachmentCategory.all
      flash.now[:notice] = t('category_added',:name => "#{@category.attachment_category_name}")
    else
      @errors = true
    end
    respond_to do |format|
      format.js { render :action => "new"}
    end
  end
  
  def edit    
    @category ||= StudentAttachmentCategory.find(params[:id])        
    respond_to do |format|
      format.js { render :action => "edit"}
    end
  end
  
  def update 
    @category ||= StudentAttachmentCategory.find(params[:id])
    if @category.update_attributes(params[:student_attachment_category])
      @saved = true
      flash.now[:notice] = t('category_saved',:name => "#{@category.attachment_category_name}")
    else
      @errors = true
    end
    respond_to do |format|
      format.js { render :action => "update"}
    end
  end
  
  def confirm_destroy
    @category = StudentAttachmentCategory.find(params[:id])        
    @categories =  StudentAttachmentCategory.fetch_all({"exclude_ids" => @category.category_id.to_a }) #default.to_a + StudentAttachmentCategory.all(:conditions => ["id not in (?)",@category.id])
    @initial = true
    respond_to do |format|
      format.js {render :action => 'destroy'}
    end
  end
  
  def destroy
    @category = StudentAttachmentCategory.find(params[:id])    
    if @category.present? 
      @category.has_documents? ? @category.perform_destroy(params[:delete_option],params[:category]) : @category.destroy
      unless @category.errors.present?
        @deleted = true
        flash.now[:notice] = t('category_deleted',:name => "#{@category.attachment_category_name}")
      else
        @errors = true
        flash.now[:notice] = t('failed_to_delete_category',:name => "#{@category.attachment_category_name}")
      end
      @categories = StudentAttachmentCategory.fetch_all({"exclude_ids" => @category.category_id.to_a}) #default.to_a + StudentAttachmentCategory.all(:conditions => ["id not in (?)",@category.id])
    else
      @errors = true
      flash.now[:notice] = t('failed_to_delete_category',:name => "#{@category.attachment_category_name}")
    end    
    respond_to do |format|
      format.js
    end
  end
    
end