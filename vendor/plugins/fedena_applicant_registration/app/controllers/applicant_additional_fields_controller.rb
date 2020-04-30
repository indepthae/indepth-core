class ApplicantAdditionalFieldsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :protect_other_student_data, :only =>[:view_addl_docs]

  def index
    @course = RegistrationCourse.find(params[:registration_course_id])
    @addl_fields = ApplicantAddlFieldGroup.find(:all,:conditions=>{:registration_course_id=>params[:registration_course_id]})
  end

  def new
    @addl_fields=ApplicantAddlField.all
    @addl_field_group=ApplicantAddlFieldGroup.new
    @addl_field=@addl_field_group.applicant_addl_fields.build
    @addl_field_value=@addl_field.applicant_addl_field_values.build
  end

  def create
    @addl_field_group=ApplicantAddlFieldGroup.new(params[:applicant_addl_field_group])
    if params[:add_asset_field]
      @addl_field.asset_field_values.build
    elsif params[:remove_asset_field]
    else
      @addl_field_group.registration_course_id =  params[:registration_course_id]
      if  @addl_field_group.save
        flash[:notice]="#{t('category_save')}"
        redirect_to :action=>:index and return
      end
    end
    render :action => 'new'
  end

  def show
    @addl_field_grp=ApplicantAddlFieldGroup.find(params[:id])
  end

  def edit
    @addl_field_group=ApplicantAddlFieldGroup.find params[:id]
    @addl_fields=@addl_field_group.applicant_addl_fields.all
    render :action => 'new'
  end

  def update
    @addl_field_group=ApplicantAddlFieldGroup.find params[:id]
    @addl_fields=@addl_field_group.applicant_addl_fields.all
    if @addl_field_group.update_attributes(params[:applicant_addl_field_group])
      flash[:notice]="#{t('category_edit')}"
      redirect_to :action=>"index" and return
    else
      render :action => 'new'
    end
  end

  def destroy
    @school_asset=ApplicantAddlFieldGroup.find params[:id]
    flash[:notice]= @school_asset.destroy ? "#{t('addl-group-delete')}" : "#{@school_asset.errors.full_messages.join(',')}"
    redirect_to :action=>:index
  end

  def toggle
    @grp =  ApplicantAddlFieldGroup.find(params[:id])
    @grp.update_attributes(:is_active=>!@grp.is_active)
    redirect_to registration_course_applicant_additional_fields_path(params[:registration_course_id])
  end

  def toggle_field
    @field =  ApplicantAddlField.find(params[:id])
    course = @field.applicant_addl_field_group.registration_course_id
    @field.update_attributes(:is_active=>!@field.is_active)
    redirect_to registration_course_applicant_additional_field_path(course,params[:group_id])
  end

  def change_order
    @cls = params["c"].present? ? ApplicantAddlField.find(params[:id]) : ApplicantAddlFieldGroup.find(params[:id])
    @cls.move(params[:order])
    render (:update) do |page|
      page.reload
    end
  end

  def view_addl_docs
    @privilege = @current_user.privileges.map{|p| p.name}
    @student = Student.find(params[:id])
    @docs = StudentAddlAttachment.paginate(:page => params[:page],:per_page => 10, :conditions =>{:student_id => params[:id]})
  end

  def download
    @doc =  StudentAddlAttachment.find(params[:id])
    #    send_file @doc.attachment.path
    unless FedenaSetting.s3_enabled?
      send_file @doc.attachment.path
    else
      redirect_to @doc.attachment.url(:original,false)
    end
  end

  def delete_doc
    StudentAddlAttachment.find(params[:id]).destroy
    flash[:notice] = "#{t('doc_deleted')}"
    redirect_to :controller => "applicant_additional_fields", :action => "view_addl_docs", :id => params[:id2]
  end

end
