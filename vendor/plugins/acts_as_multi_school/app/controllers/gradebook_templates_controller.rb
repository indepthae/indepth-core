class GradebookTemplatesController <  MultiSchoolController

  filter_access_to :all, :attribute_check=>true, :load_method => lambda { admin_user_session }
  
  def index
    init_templates
    @templates = Gradebook::Reports::Template.templates
  end
  
  def reset
    init_templates
    @gradebook_template = Gradebook::Reports::Template.reset(params[:name])
    respond_to do |format|
      format.js  { render 'reset'}
      format.html { redirect_to :action => :index}
    end
  end
  
  def activate
    @gradebook_template = GradebookTemplate.find_by_name(params[:name])
    @gradebook_template.update_attribute('is_active' , params[:activate])
    init_templates
    render :partial=>"template_list", :locals => {:template => @gradebook_template.template}
  end
  
  private
  
  def init_templates
    Gradebook::Reports::Template.init
  end
  
end