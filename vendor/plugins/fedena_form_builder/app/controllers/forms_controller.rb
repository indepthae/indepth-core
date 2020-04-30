class FormsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
    admin = (current_user.admin or current_user.privileges.map(&:name).include? 'FormBuilder')    
    if params[:id].present? and admin      
      @forms = Form.paginate(:page=>params[:page],:per_page=>12,:conditions => "form_template_id = #{params[:id]}")
    else
      if current_user.parent        
        student = current_user.guardian_entry.current_ward.user_id
        @forms = Form.paginate(:page=>params[:page],:per_page=>12,
          :joins=>'LEFT JOIN `forms_users` ON `forms_users`.form_id = `forms`.id LEFT JOIN `users` ON `users`.id = `forms_users`.user_id',
          :select => "distinct forms.*",
          :conditions=>"forms_users.user_id = #{student} and forms.is_feedback is false and is_parent IN (0,2) and is_closed = false or is_public = true",
          :order=>'forms.updated_at DESC')
      elsif current_user.student
        @forms = Form.paginate(:select => "distinct forms.*",
          :include => :form_submissions,
          :conditions => ['is_closed = ? and ((is_feedback = ? and is_parent IN (?,?) and forms_users.user_id = ?) or is_public = ?)',
            false,false,1,2,current_user.id, true],
          :joins=>'LEFT JOIN `forms_users` ON `forms_users`.form_id = `forms`.id LEFT JOIN `users` ON `users`.id = `forms_users`.user_id',
          :page=>params[:page],:per_page=>12, :order=>'forms.updated_at DESC')
      else
        @forms = Form.paginate(:select => "distinct forms.*", :include => :form_submissions,
          :conditions => ['is_closed = ? and ((is_feedback = ? and forms_users.user_id = ?) or is_public = ?)',
            false,false,current_user.id, true],
          :joins=>'LEFT JOIN `forms_users` ON `forms_users`.form_id = `forms`.id LEFT JOIN `users` ON `users`.id = `forms_users`.user_id',
          :page=>params[:page],:per_page=>12, :order=>'forms.updated_at DESC')
      end
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "manage_forms_list", :partial => 'manage_forms_list' if params[:id].present?
        page.replace_html "forms_list", :partial => 'forms_list' unless params[:id].present?
      end
    end    
  end

  def feedback_forms
    @forms = []
    if current_user.parent
      student = current_user.guardian_entry.current_ward.user_id
#      @forms << Form.find(:all,:include=>'viewers',:conditions=>"forms_users.user_id = #{student} and forms.is_feedback is true and is_parent = 0 and is_closed = false",:order=>'forms.updated_at DESC')
#      @forms << Form.find(:all,:include=>'viewers',:conditions=>"forms_users.user_id = #{student} and forms.is_feedback is true and is_parent = 2 and is_closed = false",:order=>'forms.updated_at DESC')
      @forms = Form.paginate(:page=>params[:page],:per_page=>12,
          :joins=>'LEFT JOIN `forms_users` ON `forms_users`.form_id = `forms`.id LEFT JOIN `users` ON `users`.id = `forms_users`.user_id',
          :select => "distinct forms.*",
          :conditions=>"forms_users.user_id = #{student} and forms.is_feedback is true and is_parent IN (0,2) and is_closed = false",
          :order=>'forms.updated_at DESC')

    elsif current_user.student
#      @forms << current_user.forms.feedback_forms.all(:conditions => ['is_parent = ? or is_parent=?',1,2])
      @forms = Form.paginate(:select => "distinct forms.*",
          :include => :form_submissions,
          :conditions => ['is_closed = ? and (is_feedback = ? and is_parent IN (?,?) and forms_users.user_id = ?)',
            false,true,1,2,current_user.id],
          :joins=>'LEFT JOIN `forms_users` ON `forms_users`.form_id = `forms`.id LEFT JOIN `users` ON `users`.id = `forms_users`.user_id',
          :page=>params[:page],:per_page=>12, :order=>'forms.updated_at DESC')
    else
#      @forms = current_user.forms.feedback_forms
      @forms = Form.paginate(:select => "distinct forms.*", :include => :form_submissions,
          :conditions => ['is_closed = ? and (is_feedback = ? and forms_users.user_id = ?)',
            false,true,current_user.id],
          :joins=>'LEFT JOIN `forms_users` ON `forms_users`.form_id = `forms`.id LEFT JOIN `users` ON `users`.id = `forms_users`.user_id',
          :page=>params[:page],:per_page=>12, :order=>'forms.updated_at DESC')
    end
#    @forms = @forms.flatten.uniq.sort_by {|obj| obj.updated_at}.reverse.paginate(:page=>params[:page],:per_page=>12)
    
    if request.xhr?
      render :update do |page|        
        page.replace_html "forms_list", :partial => 'forms_list'
      end
    end  
  end

  def manage
    admin = (current_user.admin or current_user.privileges.map(&:name).include? 'FormBuilder')
    @forms = Form.paginate(:page=>params[:page],:per_page=>12, :order => "updated_at DESC")
    if request.xhr?
      render :update do |page|
        page.replace_html "manage_forms_list", :partial => 'manage_forms_list'
      end
    end
  end
  
  def manage_filter
    
    @form_type = params[:form_type]
    case params[:form_type]
    when '1'
      @forms = Form.paginate(:page=>params[:page],:per_page=>12, :conditions=>'is_feedback = true', :order => "updated_at DESC")
    when '2'
      @forms = Form.paginate(:page=>params[:page],:per_page=>12, :conditions=>'is_public = true and is_feedback = false', :order => "updated_at DESC")
    when '3'
      @forms = Form.paginate(:page=>params[:page],:per_page=>12, :conditions=>'is_public = false and is_feedback = false', :order => "updated_at DESC")
    else
      @forms = Form.paginate(:page=>params[:page],:per_page=>12, :order => "updated_at DESC")
    end 
    if request.xhr?
      render :update do |page|
        page.replace_html "manage_forms_list", :partial => 'manage_forms_list'
      end
    end
  end
  
  def publish
    @form_template = FormTemplate.find(params[:id])
    @batches = Batch.active.all(:order=>'code ASC')
    @departments = EmployeeDepartment.active.all(:order=>'name ASC')
    if request.post?
      @form = @form_template.forms.build(params[:form])
      @form.user_id = current_user.id
      targets = params[:form][:targets].split(',')
      @form.is_targeted = params[:form][:is_targeted] or targets.present?
      if @form.save
        @form.viewer_ids = params[:form][:members].split(',')
        @form.form_target_ids = targets if targets.present?
        Delayed::Job.enqueue(DelayedFormReminderJob.new(@form,Fedena.hostname))
        redirect_to preview_form_path(@form)
      else
        render :publish
      end
    else
      @form = @form_template.forms.build(:user_id=>current_user.id)
    end
  end

  def close
    @form = Form.find(params[:id])
    response = @form.close
    flash[:notice] =  (response == 1) ? t('flash-1') : t('flash-2')
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html "form_#{params[:id]}", :partial => 'close_div'
    end
  end

  def show
#    @form = Form.find(params[:id],
#                      :include => {:form_template=>{:form_fields => :form_field_options }},
#                      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @form = Form.find(params[:id],:joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                             LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                             LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                                   :include => {:form_template=>{:form_fields => :form_field_options }},
                                   :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @form_template = @form.form_template
    @fields = @form_template.form_fields.order('placement_order')
    @targets = @form.net_targets(current_user)
    if(@form.allowed_to_submit?(current_user))
    else
      if(@form.is_already_submitted?(current_user))
        flash[:notice] =  t('flash-4')
      else
        flash[:notice] =  t('flash-5')
      end
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def new_form_submission
    if params[:form_submission].present? and params[:form_submission][:form_id].present?

#      @form = Form.find(params[:form_submission][:form_id],
#                        :include => {:form_template=>{:form_fields => :form_field_options }},
#                        :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

      @form = Form.find(params[:form_submission][:form_id],
                        :joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                 LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                 LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                        :include => {:form_template=>{:form_fields => :form_field_options }},
                        :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

      @form_template = @form.form_template
#      @fields = @form_template.form_fields
      @fields = @form_template.form_fields.order('placement_order')
      if(@form.allowed_to_submit?(current_user))
        form_submission = current_user.form_submissions.build(params[:form_submission])
        form_submission.response = params[:form].to_json
        @form = form_submission.verify_submission(params[:files])
        form_submission.response = JSON.parse(params[:form].to_json)
        unless @form.errors.present?
          if current_user.parent
            form_submission.ward_id = current_user.guardian_entry.current_ward.user_id
          end
          if params[:files].present?
            params[:files].each do |k,v|
              file_attachment = FormFileAttachment.new(:form_field_file_id => k,:attachment => v['value'])
              file_attachment.save
              form_submission.response['file'][k]['value'] = file_attachment.id
            end
          end
          form_submission.save
          flash[:notice] = t('flash-6')
          redirect_to feedback_forms_forms_path if @form.is_feedback
          redirect_to forms_path if !@form.is_feedback          
        else
          @response = params[:form]
          @targets = @form.net_targets(current_user)
          render :show
        end
      else         
        flash[:notice] =  t('flash-8')
        redirect_to :controller=> "user", :action=> "dashboard"
      end
    else
      flash[:notice] =  t('flash-8')
      redirect_to :controller=> "user", :action=> "dashboard"
    end
  end

  def destroy
    @form = Form.find(params[:id])
    @form.destroy
    flash[:notice] =  t('flash-3')
    redirect_to manage_forms_path
  end

  def edit
    @form = Form.find(params[:id])
    @batches = Batch.active.all(:order=>'code ASC')
    @departments = EmployeeDepartment.active.all(:order=>'name ASC')
    vids = @form.viewer_ids
    @members = vids.join(',')
    @students = User.find_all_by_id(vids,:conditions=>{:student => true}).map(&:id).join(',')
    @submitted_members = @form.form_submissions.map(&:user_id).join(',')
    @targets = @form.form_targets.map(&:id).join(',') if @form.is_targeted
    @submitted_targets = @form.form_submissions.all(:group=>:target).map(&:target).join(',') if @form.is_targeted
    @disabled = @form.disabled? ? false : true
  end

  def update
    @form = Form.find(params[:id])
    @batches = Batch.active.all(:order=>'code ASC')
    @departments = EmployeeDepartment.active.all(:order=>'name ASC')
#    @form.update_attributes(params[:form])
    original_viewer_ids = @form.viewer_ids    
    @submitted_targets = @form.form_submissions.all(:group=>:target).map(&:target).join(',') if @form.is_targeted
    @submitted_members = @form.form_submissions.map(&:user_id)    
    if @form.update_attributes(params[:form]) #@form.save
      members = []
      members << params[:form][:members].split(',')
      members << @submitted_members
      @form.form_target_ids = params[:form][:targets].split(',') if @form.is_targeted
      @form.viewer_ids = members.flatten.uniq
      new_viewer_ids = params[:form][:members].split(',').collect{ |s| s.to_i }
      new_recipients = new_viewer_ids - (original_viewer_ids & new_viewer_ids)
      Delayed::Job.enqueue(DelayedFormReminderJob.new(@form,Fedena.hostname,new_recipients)) if (new_recipients.present? and (@form.is_feedback or !@form.is_public))
      redirect_to preview_form_path(@form)
    else
      @targets = params[:form][:targets].split(',')
      @disabled = @form.disabled? ? false : true
      render :edit
    end
  end

  def update_member_list
    if params[:members]
      @members = User.active.find_all_by_id(params[:members].split(",").collect{ |s| s.to_i }, :order => "first_name ASC")
      @disabled_members = params[:disabled_members]
      render :update do |page|
        page.replace_html 'member-list', :partial => 'member_list'
      end
    else
      redirect_to :controller=> "user", :action=> "dashboard"
    end
  end

  def to_employees
    @departments = EmployeeDepartment.all(:conditions => {:status=>true},:order=>"name ASC")
    unless params[:dept_id].present?
      render :update do |page|
        page.replace_html "to_users", :text => nil
      end
    else
      @to_users = Employee.find(:all,:select=>"user_id, first_name, middle_name,last_name",:conditions=> ["employee_department_id = ?",params[:dept_id]], :order => "first_name ASC").compact
      render :update do |page|
        page.replace_html 'to_users', :partial => 'to_users', :object => @to_users
      end
    end
  end

  def to_students
    unless params[:batch_id].present?
      render :update do |page|
        page.replace_html "to_users2", :text => nil
      end
    else
      @to_users = Student.find_all_by_batch_id(params[:batch_id],:select => "user_id, first_name,middle_name,last_name",  :order => "first_name ASC").compact
      render :update do |page|
        page.replace_html 'to_users2', :partial => 'to_users2', :object => @to_users
      end
    end
  end

  def update_target_list
    if params[:targets]
      @targets = User.active.find_all_by_id(params[:targets].split(",").collect{ |s| s.to_i }, :order => "first_name ASC")
      render :update do |page|
        page.replace_html 'target-list', :partial => 'target_list'
      end
    else
      redirect_to :controller=> "user", :action=> "dashboard"
    end
  end

  def to_target_employees
    @departments = EmployeeDepartment.all(:conditions => {:status=>true},:order=>"name ASC")
    unless params[:dept_id].present?
      render :update do |page|
        page.replace_html "to_targets", :text => nil
      end
    else
      @to_targets = Employee.find(:all,:select=>"user_id, first_name, middle_name,last_name",:conditions=> ["employee_department_id = ?",params[:dept_id]], :order => "first_name ASC").compact
      render :update do |page|
        page.replace_html 'to_targets', :partial => 'to_targets', :object => @to_targets
      end
    end
  end

  def to_target_students
    unless params[:batch_id].present?
      render :update do |page|
        page.replace_html "to_targets2", :text => nil
      end
    else
      @to_targets = Student.find_all_by_batch_id(params[:batch_id],:select => "user_id, first_name,middle_name,last_name", :order => "first_name ASC").compact
      render :update do |page|
        page.replace_html 'to_targets2', :partial => 'to_targets2', :object => @to_targets
      end
    end
  end
  
  def edit_response
    @submission = FormSubmission.find(params[:id])
    @form = @submission.form
    flag = false
    if @form.allowed_to_edit? current_user      
      @form_template = @form.form_template
      @fields = @form_template.form_fields #.sort_by {|x| x.placement_order}
      @response = @submission.response 
      render :edit_response
    else
      flash[:notice] =  t('flash-4')
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end
  
  def update_response
    if params[:form_submission].present? and params[:form_submission][:form_id].present?
      @form = Form.find(params[:form_submission][:form_id])
      @form_template = @form.form_template
      @fields = @form_template.form_fields.all(:order=>"placement_order")
      form_submission = FormSubmission.find(params[:id])
      old_response = form_submission.response
      form_submission.response = params[:form].to_json
      @form = form_submission.verify_submission(params[:files])
      form_submission.response = JSON.parse(params[:form].to_json)
      unless @form.errors.present?        
        ## code to save any updated files
        if params[:files].present?
          file_fields = @form_template.form_field_files
          file_fields.each do |ff|
            if params[:files]["#{ff.id}"].present?
              if old_response['file']["#{ff.id}"]['value'].present?
                old_attachment = FormFileAttachment.find_by_id(old_response['file']["#{ff.id}"]['value'])
                if old_attachment.present?
                  old_attachment.attachment = params[:files]["#{ff.id}"]['value']
                  old_attachment.save
                  params[:form][:file]["#{ff.id}"] = old_response['file']["#{ff.id}"]
                end
              else
                file_attachment = FormFileAttachment.new(:form_field_file_id => ff.id,:attachment => params[:files]["#{ff.id}"][:value])
                file_attachment.save
                params[:form][:file]["#{ff.id}"][:value] = file_attachment.id
              end
            else
              params[:form][:file][:"#{ff.id}"] = old_response['file']["#{ff.id}"]
            end
          end
        else
          params[:form][:file] = old_response['file']
        end
        form_submission.response = params[:form].to_hash
        form_submission.save
        flash[:notice] = t('flash-6')
        redirect_to forms_path
      else
        @response = params[:form]
        render :edit_response
      end
    else
      flash[:notice] =  t('flash-8')
      redirect_to :controller=> "user", :action=> "dashboard"
    end
  end
  
  def preview
    @form = Form.find(params[:id],
      :include => {:form_template=>{:form_fields => :form_field_options }},
      :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")

    @form = Form.find(params[:id],
                        :joins=>"LEFT OUTER JOIN `form_templates` ON `form_templates`.id = `forms`.form_template_id
                                 LEFT OUTER JOIN `form_fields` ON form_fields.form_template_id = form_templates.id
                                 LEFT OUTER JOIN `form_field_options` ON form_field_options.form_field_id = form_fields.id",
                        :include => {:form_template=>{:form_fields => :form_field_options }},
                        :order=>"form_fields.placement_order ASC,form_field_options.placement_order ASC")
    @form_template = @form.form_template
    @fields = @form_template.form_fields.order('placement_order')
  end
end
