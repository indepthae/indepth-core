class FormSubmissionsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def show
#    @form = Form.find(params[:id],:conditions=>["form_fields.field_type <> ?",'hr'],
#      :include => {:form_template=>{:form_fields => :form_field_options }},
#      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
    @form = Form.find(params[:id], :conditions => ["form_fields.field_type != 'hr'"],
                                    :joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                             LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                             LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                      :include => {:form_template=>{:form_fields => :form_field_options }},
                      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @fields = @form.form_template.form_fields.no_hr #.all(:conditions=>["field_type <> ?",'hr'])
    filter = (params[:filter].is_a? String) ? JSON.parse(params[:filter]) : params[:filter]
    @filters = filter.to_json if filter.present?
    @form_submissions = FormSubmission.get_response_hash(@form.id,{:page=>params[:page],:per_page=>20},false,filter)
    @form_submissions = @form_submissions.paginate(:page=>params[:page],:per_page=>20) unless FedenaSetting.elasticsearch_enabled?
    if request.xhr?
      render :update do |page|
        page.replace_html "reports", :partial => 'response_list'
      end
    end
  end

  def filter
#    @form = Form.find(params[:id],:conditions=>["form_fields.field_type <> ?",'hr'],
#      :include => {:form_template=>{:form_fields => :form_field_options }},
#      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
    @form = Form.find(params[:id], :conditions => ["form_fields.field_type <> ?",'hr'],
                                    :joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                             LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                             LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                      :include => {:form_template=>{:form_fields => :form_field_options }},
                      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
    
    @fields = @form.form_template.form_fields.no_hr #.all(:conditions=>["field_type <> ?",'hr'])
    @filters = params[:filter].to_json
    @form_submissions = FormSubmission.filter(@form.id,{:page=>params[:page],:per_page=>20},params[:filter])
    if request.xhr?
      render :update do |page|
        page.replace_html "reports", :partial => 'response_list'
      end
    end
  end

  def responses
#    @form = Form.find(params[:id],
#      :include => {:form_template=>{:form_fields => :form_field_options }},
#      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
    @form = Form.find(params[:id], :conditions => ["form_fields.field_type <> ?",'hr'],
                                    :joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                             LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                             LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                      :include => {:form_template=>{:form_fields => :form_field_options }},
                      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
                    
    @fields = @form.form_template.form_fields.no_hr
    @form_submissions = FormSubmission.get_user_response_hash(@form.id,current_user).paginate(:page=>params[:page],:per_page=>20)
    if request.xhr?
      render :update do |page|
        page.replace_html "responses", :partial => 'responses_list'
      end
    end
  end

  def new
    @form = Form.find(params[:form_submission][:form_id])
    unless(current_user.form_submissions.all(:conditions=>{:form_id => @form.id}).present?)
      form_submission = current_user.form_submissions.build(params[:form_submission])      
      form_submission.response = params[:form].to_json
      @form = form_submission.verify_submission #(params[:files])
      unless @form.errors.present?
        form_submission.save
        if params[:files].present?
          params[:files].each do |k,v|
            file_attachment = FormFileAttachment.new(:form_field_file_id => k,:attachment => v['value'])
            file_attachment.save
            params[:form][:file][k][:value] = file_attachment.id
          end
        end
        flash[:notice] = t('flash-1')
        redirect_to forms_path
      else
        redirect_to form_path(@form)
      end
    else
      flash[:notice] =  t('flash-2')
      redirect_to forms_path
    end
  end

  def form_submissions_csv
    form = Form.find(params[:id])
    filter = (params[:filter].is_a? String) ? JSON.parse(params[:filter]) : params[:filter]
    csv_string = FormSubmission.get_csv_data(params[:id],filter)
    filename = "#{form.name}--#{Time.now.to_i}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def download
    @document = FormFileAttachment.find(params[:id])
    if File.exist?(@document.attachment.path)
      send_file @document.attachment.path
    else
      flash[:notice] = "#{t('flash-4')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def analysis
#    @form = Form.find(params[:id])
    @form = Form.find(params[:id], :conditions => ["form_fields.field_type <> ?",'hr'],
                                    :joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                             LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                             LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                                    :include => {:form_template=>{:form_fields => :form_field_options }},
                                    :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
                    
    if(@form.is_feedback)
      @fields = @form.form_template.form_fields.no_hr #.sort_by { |x| x.placement_order }
      @analysis_hash = FormSubmission.get_analysed_hash(@form,@fields) unless @form.is_targeted
      @targets = @form.form_targets
    else
      flash[:notice] = "#{t('flash13')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def consolidated_report
#    @form = Form.find(params[:id])
    @form = Form.find(params[:id], :conditions => ["form_fields.field_type <> ?",'hr'],
                                    :joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                             LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                             LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                                    :include => {:form_template=>{:form_fields => :form_field_options }},
                                    :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @fields = @form.form_template.form_fields.no_hr
    if @form.is_targeted
      @report = []
      @form.form_targets.each do |target|
        @report << {"#{target.full_name}" => FormSubmission.get_analysed_hash(@form,@fields,target)}
      end
    end
    @report = @report.paginate(:per_page=>20,:page=>params[:page])
    if request.xhr?
      render :update do |page|
        page.replace_html "reports", :partial => 'consolidated'
      end
    end
  end

  def get_target_analysis
#    @form = Form.find(params[:id],:conditions=>["form_fields.field_type <> ?",'hr'],
#      :include => {:form_template=>{:form_fields => :form_field_options }},
#      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
    
    @form = Form.find(params[:id], :conditions => ["form_fields.field_type <> ?",'hr'],
                                    :joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                             LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                             LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                      :include => {:form_template=>{:form_fields => :form_field_options }},
                      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @target = params[:target_id]
    @fields = @form.form_template.form_fields.no_hr #.sort_by { |x| x.placement_order }
    @analysis_hash = FormSubmission.get_analysed_hash(@form,@fields,@target) if @form.is_targeted and @target.present?
    @targets = @form.form_targets    
    render :update do |page|
      page.replace_html "single_analysis", :partial => 'single_analysis' 
    end    
  end
  
end