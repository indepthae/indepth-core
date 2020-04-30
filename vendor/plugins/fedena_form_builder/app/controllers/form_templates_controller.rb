class FormTemplatesController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    @form_templates = FormTemplate.active.paginate(:page=>params[:page],:per_page=>12)
    if request.xhr?
      render :update do |page|
        page.replace_html "form_templates_list", :partial => 'form_templates_list'
      end
    end
  end

  def new
    @form_template = current_user.form_templates.build #FormTemplate.new
  end

  def create    
    @form_template = current_user.form_templates.build(params[:form_template])    
    unless @form_template.save
    end
    @publish = params[:publish]
    render :update do |page|
      page.replace_html 'errors_pane', :partial => 'submit_result', :object => {:form_template => @form_template,:publish => @publish}
    end
  end

  def edit
#    @form_template = FormTemplate.find(params[:id],
#      :include => {:form_fields => :form_field_options },
#      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @form_template = FormTemplate.find(params[:id],
                        :joins=>"LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                 LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                        :include => {:form_fields => :form_field_options },
                        :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @fields = @form_template.form_fields.order('placement_order')
    @fields_count = {}
    @fields.map(&:field_type).uniq.collect{ |a| @fields_count[a] = 0}
  end

  def update
    #    p params[:form_template][:id]
#    @form_template = FormTemplate.find(params[:form_template][:id],
#      :include => {:form_fields => :form_field_options },
#      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @form_template = FormTemplate.find(params[:form_template][:id])    
    flag = false

    unless @form_template.update_attributes(params[:form_template])

      if @form_template.errors.present?
        @form_template.errors.each do |a,b|
          if( a.split('.')[1]!='base')
            flag = true
          end
        end
        if(@form_template.changed.include? 'name')
          @form_template = current_user.form_templates.build(@form_template.reject_ids(params[:form_template]))
          @form_template.save
          @publish = params[:publish]
        end
      else
        @publish = params[:publish]
      end
    else
      @publish = params[:publish]
    end
    render :update do |page|
      page.replace_html 'errors_pane', :partial => 'submit_result', :object => {:form_template => @form_template,:publish => @publish}
    end
  end

  def destroy
    @form_template = FormTemplate.find(params[:id])
    if @form_template.can_edit_or_delete?
      @form_template.destroy
      flash[:notice] = t('flash-1')
    else
      @form_template.update_attribute(:is_deleted,true)
      flash[:notice] = t('flash-2')
    end
    redirect_to form_templates_path
  end

#  def show
#    @form_template = FormTemplate.find(params[:id])
#    @fields = @form_template.form_fields.sort_by {|x| x.placement_order}
#  end

  def preview
#    @form_template = FormTemplate.find(params[:id],
#      :include => {:form_fields => :form_field_options },
#      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @form_template = FormTemplate.find(params[:id],
                        :joins=>"LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                 LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                        :include => {:form_fields => :form_field_options },
                        :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
                      
    @fields = @form_template.form_fields.order('placement_order') #.sort_by {|x| x.placement_order}
  end

  def add_field
    if(params[:id]!='undefined')
      @form_template = current_user.form_templates.build
      @field = @form_template.newfield(params[:id]) # FormField.new(params[:id])
    end
    render :update do |page|
      page.replace_html 'dragged_fields', :partial => 'build_field', :object => @field unless params[:id]=='undefined'
    end
  end

  def add_option
    @field_type = params
    render :update do |page|
      page.replace_html "new_option_#{params[:ts]}", :partial => 'new_option', :object => @field_type
    end
  end

  def field_settings
    @params = params
    render :update do |page|
      page.replace_html 'field_settings', :partial => 'field_settings', :object => @params
    end
  end

end
