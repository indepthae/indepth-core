class StudentDocumentsController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except => [:documents] 
  filter_access_to [:documents], :attribute_check=>true, :load_method => lambda { Student.find(params[:id]) }
  filter_access_to [:download], :attribute_check=>true, :load_method => lambda { StudentAttachment.find(params[:id],:include => :student).student }
  protect_from_forgery
  
  before_filter :fetch_student, :only =>[:documents, :new, :create]
  
  def new
    @category = StudentAttachmentCategory.find_by_id(params[:category_id]) if params[:category_id].present? and params[:category_id] != 'registered'
    @category ||= StudentAttachmentCategory.default(params[:category_id].present? && params[:category_id] == 'registered')
    @document = StudentAttachment.new
    @initial = true
    respond_to do |format|
      format.js
    end
  end
  
  def create    
    @document = @student.student_attachments.build(params[:student_attachment])
    @category = StudentAttachmentCategory.find_by_id(params[:student_attachment][:category]) if params[:student_attachment][:category].present? and params[:student_attachment][:category] != 'registered'
    @category ||= StudentAttachmentCategory.default(params[:student_attachment][:category].present? && params[:student_attachment][:category] == 'registered')
    if @document.set_and_save(@student)
      @saved = true
      order_by = "DATE(`student_attachments`.created_at) desc"
      non_default_document_ids = StudentAttachment.all(:conditions => {:student_id => @student.id},:select => "student_attachments.id", :joins => :student_attachment_records).map(&:id).join(',') if @category.new_record?
      id_not_in_condition = "and student_attachments.id not in (#{non_default_document_ids}) " if non_default_document_ids.present?
      @documents = @category.new_record? ? StudentAttachment.all(:conditions => ["student_id = ? and is_registered = ? #{id_not_in_condition.present? ? id_not_in_condition : ''}",@student.id,@category.registered], :order => order_by) : @category.student_attachments.all(:conditions => {:student_id => @student}, :order => order_by)      
      flash.now[:notice] = t('document_added',:name => "#{@document.attachment_name}")
    else
      @errors = true
    end
    respond_to do |format|
      format.js { render :action => "new"}
    end
  end
  
  def edit
    exclusions = Hash.new
    exclusions['exclude_ids'] = params[:category_id].to_a if params[:category_id].present?
    @categories = StudentAttachmentCategory.fetch_all(exclusions)
    @category = StudentAttachmentCategory.find_by_id(params[:category_id]) if params[:category_id].present? and params[:category_id] != 'registered'
    @category ||= StudentAttachmentCategory.default(params[:category_id].present? && params[:category_id] == 'registered')
    @document = StudentAttachment.find(params[:id])
    @initial = true
    respond_to do |format|
      format.js
    end
  end
  
  def update
    @category = StudentAttachmentCategory.fetch(params[:student_attachment][:category])
    @document = StudentAttachment.find(params[:id])
    @student_id = @document.student_id
    old_category_ids = @document.student_attachment_category_ids
    old_category_id = old_category_ids.present? ? old_category_ids.last : (@document.is_registered ? 'registered' : nil)    
    @document.category = old_category_id unless @category.present?
    @document.update_document(params[:student_attachment])    
    @categories = StudentAttachmentCategory.fetch_all #default.to_a + StudentAttachmentCategory.all
    if @document.errors.present?
      @errors = true
    else
      if @category.present? and @category.category_id != old_category_id
        non_default_document_ids = StudentAttachment.all(:conditions => {:student_id => @student_id},:select => "student_attachments.id", :joins => :student_attachment_records).map(&:id).join(',')
        order_by = "DATE(`student_attachments`.created_at) desc"
        @new_category = @category || StudentAttachmentCategory.default(params[:student_attachment][:category].present? && params[:student_attachment][:category] == 'registered')
        id_not_in_condition = "and id not in (#{non_default_document_ids})" if non_default_document_ids.present?
        @new_documents = @new_category.new_record? ? StudentAttachment.all(:conditions => ["student_id = ? and is_registered = ? #{id_not_in_condition.present? ? id_not_in_condition : ''} ", @student_id, @new_category.registered], :order => order_by) :  @new_category.student_attachments.all(:conditions => {:student_id => @document.student_id }, :order => order_by)
#        @category = nil
        @category = StudentAttachmentCategory.fetch(old_category_id)
        @documents = @category.new_record? ? StudentAttachment.all(:conditions => ["student_id = ? and is_registered = ? #{id_not_in_condition.present? ? id_not_in_condition : ''} ", @student_id, @category.registered], :order => order_by) : @category.student_attachments.all(:conditions => {:student_id => @document.student_id }, :order => order_by)
        flash.now[:notice] = t('document_moved',:name => "#{@document.attachment_name}",:old_category => "#{@category.attachment_category_name}",:new_category => "#{@new_category.attachment_category_name}")
      else
        @category = StudentAttachmentCategory.fetch(old_category_id)
        flash.now[:notice] = t('document_updated',:name => "#{@document.attachment_name}")
      end
      @saved = true
    end
    respond_to do |format|
      format.js { render :action => "edit"}
    end
  end
  
  def documents
    @categories = StudentAttachmentCategory.fetch_all
    @student_documents = @student.student_attachments(:include => :student_attachment_categories, :order => "created_at desc" )
    @documents_group = StudentAttachment.documents_group(@student_documents)
  end
  
  def destroy
    @document = StudentAttachment.find(params[:id],:include => :student)
    @category = @document.student_attachment_categories.last || StudentAttachmentCategory.default(@document.is_registered)
    @student = @document.student
    @document.destroy
    order_by = "DATE(`student_attachments`.created_at) desc"
    non_default_document_ids = StudentAttachment.all(:conditions => {:student_id => @student.id},:select => "student_attachments.id", :joins => :student_attachment_records).map(&:id).join(',') if @category.new_record?
    id_not_in_condition = "and id not in (#{non_default_document_ids})" if non_default_document_ids.present?
    @documents = @category.new_record? ? StudentAttachment.all(:conditions => ["student_id = ? and is_registered = ? #{id_not_in_condition.present? ? id_not_in_condition : ''}", @student.id, @category.registered], :order => order_by) : @category.student_attachments.all(:conditions => {:student_id => @student.id}, :order => order_by ) unless @document.errors.present?
    flash.now[:notice] =  @document.errors.present? ? t('failed_to_delete_document') : t('document_deleted', :name => @document.attachment_name, :category_name => @category.attachment_category_name)
    respond_to do |format|
      format.js
    end
  end
  
  def download
    @document = StudentAttachment.find(params[:id])
    if File.exist?(@document.attachment.path)
      file_ext = @document.attachment_file_name.split('.').last
      file_name_ext = @document.attachment_name.split('.').last
      file_name = "#{@document.attachment_name}" if file_name_ext.present? and file_ext.present? and file_ext == file_name_ext
      file_name ||= "#{@document.attachment_name}.#{file_ext}" if file_name_ext.present? and file_ext.present? and file_ext != file_name_ext
      file_name ||= "#{@document.attachment_name}"
      send_file @document.attachment.path,
        :filename => file_name,
        :type => @document.attachment_content_type,
        :disposition => 'attachment'
    else
      flash[:notice] = t('not_found')
      redirect_to :controller => "user", :action => "dashboard"
    end
  end
  
  private
  def fetch_student
    student_id = params[:id]
    @student = Student.find(student_id)
  end
end