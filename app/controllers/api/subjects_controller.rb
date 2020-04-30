class Api::SubjectsController < ApiController
  filter_access_to :all

  def index
    @xml = Builder::XmlMarkup.new
    batch_name=params[:search][:batch_name_equals] || params[:search][:batch_name_eq]
    course_code= params[:search][:batch_course_code_equals] || params[:search][:batch_course_code_eq]
    @subjects = Subject.search(params[:search]).all(:joins=>:batch,:conditions => {:is_deleted => false,:batches=>{:is_active=>true}})
    respond_to do |format|
      unless params[:search].present? and batch_name.present? and course_code.present?
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      else
        format.xml  { render :subjects }
      end
    end
  end

  def show
    @xml = Builder::XmlMarkup.new
    @user = User.first(:conditions => ["username LIKE BINARY(?)",params[:id]])
    if @user.student?
      @student = @user.student_record
      @subjects = @student.batch.subjects.all(:conditions => {:is_deleted => false,:elective_group_id=>nil})
      @subjects+=@student.subjects.all(:conditions=>{:is_deleted=>:false})
    elsif @user.employee?
      @employee = @user.employee_record
      @subjects = @employee.subjects.all(:joins=>:batch,:conditions=>{:is_deleted=>:false,:batches=>{:is_active=>true}})
    elsif @user.admin?  #this condition is for backward compatiability
      @employee=@user.employee_record
      @subjects = @employee.subjects.all(:joins=>:batch,:conditions=>{:is_deleted=>:false,:batches=>{:is_active=>true}})
    end
    respond_to do |format|
      unless @user.nil?
        format.xml  { render :subjects }
      else
        render "single_access_tokens/500.xml", :status => :bad_request  and return
      end
    end
  end
end
