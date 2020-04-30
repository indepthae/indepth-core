# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.
require 'fileutils'
class Api::StudentDocumentsController < ApiController
  filter_access_to :all
  
  def documents
    begin
      @xml = Builder::XmlMarkup.new
      @student = Student.find_by_admission_no(params[:id], :include => {:student_attachments => :student_attachment_categories}) if params[:id].present?
      @student ||= Student.find_by_admission_no(params[:admission_no], :include => {:student_attachments => :student_attachment_categories}) if params[:admission_no].present?
      if @student.present?
        @categories = StudentAttachmentCategory.fetch_all        
        @student_documents = @student.student_attachments(:include => :student_attachment_categories, :order => "created_at desc" )
        @document_groups = StudentAttachment.documents_group(@student_documents)        
        view_to_render = :documents
      else
        view_to_render = :error
      end
      respond_to do |format|
        format.xml { render view_to_render }
      end
    rescue
      render "single_access_tokens/500.xml", :status => :bad_request  and return  unless @student.present?
    end
  end
  
  def create
    begin
      @xml = Builder::XmlMarkup.new
      @admission_no = params[:admission_no]
      @student = Student.find_by_admission_no(@admission_no, :include => :batch)
      if @student.present?
        @document = @student.student_attachments.build({:batch_id => @student.batch, :attachment_name => params[:document_name], :uploader_id => current_user.id})
        @document.attachment = params[:document] if params[:document].present? and params[:document].class.to_s=="Tempfile"      
        @category = StudentAttachmentCategory.fetch(params[:category_id]) #if params.keys.include?(:category_id)
        @document.is_registered = (@category.present? && @category.registered)
        if @category.present? and @document.save
          @document.student_attachment_category_ids = params[:category_id].to_s if @category.present? && !@category.new_record?
          view_to_render = :document
        else
          view_to_render = :error
        end
      else
        view_to_render = :error
      end
      respond_to do |format|
        format.xml { render view_to_render}
      end  
    rescue
      render "single_access_tokens/500.xml", :status => :bad_request  and return  
    end
  end
  
  def edit
    begin
      @xml = Builder::XmlMarkup.new
      @document = StudentAttachment.find(params[:id],:include => :student_attachment_categories)
      @category = StudentAttachmentCategory.fetch(@document.is_registered ? 'registered' : @document.student_attachment_categories.first)
      if @document.present?
        data = Hash.new
        data["attachment_name"] = params[:document_name] if params.keys.include?("document_name")
        data["category"] = params[:category_id] if params.keys.include?("category_id")
        @document.update_document(data)
        if params[:category_id].present? and params[:category_id] != @category.category_id
          @new_category = StudentAttachmentCategory.fetch(params[:category_id])
          @category = @new_category
        end
        if @category.present? and !@document.errors.present?
          view_to_render = :document
        else
          @edit_error = true
          view_to_render = :error                  
        end
      else
        @edit_error = true
        view_to_render = :error
      end
      respond_to do |format|
        format.xml { render view_to_render}
      end  
    rescue
      render "single_access_tokens/500.xml", :status => :bad_request  and return  
    end
  end
  
  def destroy    
    begin
      @xml = Builder::XmlMarkup.new
      @document = StudentAttachment.find_by_id(params[:id], :include => :student_attachment_categories)
      if @document.present? and @document.destroy
        @category = @document.student_attachment_categories.present? ? @document.student_attachment_categories.first : StudentAttachmentCategory.default(@document.is_registered)
        view_to_render = :delete      
      else
        @delete_error = true
        view_to_render = :error
      end
      respond_to do |format|
        format.xml { render view_to_render}
      end      
    rescue
      render "single_access_tokens/500.xml", :status => :bad_request  and return  
    end
  end
end
