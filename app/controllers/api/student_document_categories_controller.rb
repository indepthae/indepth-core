# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class Api::StudentDocumentCategoriesController < ApiController
  filter_access_to :all
  
  def index    
    begin
      @xml = Builder::XmlMarkup.new
      @categories = StudentAttachmentCategory.fetch_all
      respond_to do |format|
        format.xml 
      end
    rescue
      render "single_access_tokens/500.xml", :status => :bad_request  and return
    end
  end
  
  def create
    begin
      @xml = Builder::XmlMarkup.new
      @category = StudentAttachmentCategory.new({:attachment_category_name => params[:name]})
      @category.save
      view_to_render = @category.errors.present? ? :error : :category
      respond_to do |format|
        format.xml {render view_to_render}
      end
    rescue
      render "single_access_tokens/500.xml", :status => :bad_request  and return
    end
  end
  
  def edit
    begin
      @xml = Builder::XmlMarkup.new
      @category = StudentAttachmentCategory.find_by_id(params[:id])
      if @category.present?
        @category.update_attributes({:attachment_category_name => params[:name]})        
        view_to_render = @category.errors.present? ? :error : :category
      else
        view_to_render = :error        
      end
      respond_to do |format|
        format.xml {render view_to_render}
      end
    rescue
      render "single_access_tokens/500.xml", :status => :bad_request  and return
    end
  end
end
