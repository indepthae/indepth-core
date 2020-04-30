class TasksController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:except => [:index,:show,:download_attachment,:list_created_tasks,:list_assigned_tasks,:assigned_to]
  filter_access_to [:index,:show,:download_attachment,:list_created_tasks,:list_assigned_tasks,:assigned_to],:attribute_check => true, :load_method => lambda { current_user.parent? ? (current_user.guardian_entry.current_ward.user) : (current_user) }

  def index
    if current_user.parent?
      @user = current_user.guardian_entry.current_ward.user
    else
      @user = current_user
    end
    @tasks = @user.tasks.paginate :per_page=>5,:page => params[:tasks_page], :order => 'created_at DESC'
    @assigned_tasks = @user.assigned_tasks.paginate :per_page => 5, :page => params[:assigned_page], :order => 'created_at DESC'
  end

  def new
    @user = current_user
    @task = @user.tasks.build
    load_data
    @users = User.active.all
    
  end

  def create
    @user = current_user
    params[:task][:assignee_ids] = params[:recipients].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
    @task = @user.tasks.build(params[:task])
    @task.status = "Assigned"
    if @task.save
      flash[:notice] = "#{t('task_creation_successful')}"
      redirect_to :action => "index"
    else
      load_data
      @recipients = params[:recipients]
      render :new
    end
  end


  def edit
    @user = current_user
    @task = @user.tasks.find(params[:id])
    @users = User.active.all
    load_data
    @recipients = User.find(@task.assignees).sort_by{|a| a.full_name.downcase}
  end

  def update
    @user = current_user
    @task = @user.tasks.find(params[:id])
    @users = User.active.all
    @task.status = params[:status]
    params[:task][:assignee_ids] = params[:recipients].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
    if @task.update_attributes(params[:task])
      flash[:notice] = "#{t('task_updation_successful')}"
      redirect_to :action => "index"
    else
      @recipients = User.find(@task.assignees)
      @batches = Batch.active
      @departments = EmployeeDepartment.active_and_ordered
      @users = User.active.all
      render :edit
    end
  end

  def show
    @current_user = current_user
    @task = Task.find(params[:id],:include=>:task_comments)
    @comments = @task.task_comments.dup
    @task_comment=@task.task_comments.build
    if @current_user.parent?
      unless @task.can_be_viewed_by?(@current_user.guardian_entry.current_ward.user)
        flash[:notice] = "#{t('no_permission_to_view_task')}"
        redirect_to :action => "index"
      end
    else
      unless @task.can_be_viewed_by?(@current_user)
        flash[:notice] = "#{t('no_permission_to_view_task')}"
        redirect_to :action => "index"
      end
    end
  end

  def destroy
    @task =  Task.find(params[:id])
    if @task.task_can_be_deleted_by?(current_user)
      @task.destroy
      flash[:notice] = "#{t('task_deletion_successful')}"
    else
      flash[:notice] = "#{t('no_permission_to_delete_task')}"
    end
    redirect_to :controller => 'tasks', :action => 'index'
  end

  def download_attachment
    @task = Task.find(params[:id])
    if current_user.parent?
      if @task.can_be_downloaded_by?(current_user.guardian_entry.current_ward.user)
        send_file (@task.attachment.path)
      else
        flash[:notice] = "#{t('no_permission_to_download_file')}"
        redirect_to :action => "index"
      end
    else
      if @task.can_be_downloaded_by?(current_user)
        send_file (@task.attachment.path)
      else
        flash[:notice] = "#{t('no_permission_to_download_file')}"
        redirect_to :action => "index"
      end
    end
  end

  def toggle_status
    @task = Task.find(params[:id])
    if @task.task_can_be_edited_by?(current_user)
      if @task.status == "Assigned"
        @task.status = "Completed"
      elsif @task.status == "Completed"
        @task.status = "Assigned"
      end
      if @task.save
        flash[:notice] = "#{t('status_updated_successfully')}"
      else
        flash[:notice] = "#{@task.errors.full_messages.join(',')}"
      end
      redirect_to task_path(:id=>@task)
    end
  end

  def list_employees
    unless params[:id] == ''
      @employees = Employee.find(:all, :conditions=>{:employee_department_id => params[:id]},:order=>"id DESC")
    else
      @employees = []
    end
    render(:update) do |page|
      page.replace_html 'select_employees', :partial=> 'list_employees'
    end
  end


  def select_employee_department
    @user = current_user
    @departments = EmployeeDepartment.active_and_ordered
    render :partial=>"select_employee_department"
  end

  def select_users
    @user = current_user
    users = User.active.find(:all, :conditions=>"student = false")
    @to_users = users.map { |s| s.id unless s.nil? }
    render :partial=>"to_users", :object => @to_users
  end

  def select_student_course
    @user = current_user
    @batches = Batch.active
    render :partial=> "select_student_course"
  end

  def to_schools
    if params[:dept_id] == ""
      render :update do |page|
        page.replace_html "dept_and_courses", :text => ""
      end
      return
    end
    school = School.find params[:id]
    @departments = school.employee_departments.active(:order=>"name asc")
    @batches = school.batches.active
    render :update do |page|
      page.replace_html 'depts_and_courses', :partial => 'depts_and_courses'
    end
  end

  def to_employees
    if params[:dept_id] == ""
      render :update do |page|
        page.replace_html "to_users", :text => ""
      end
      return
    end
    department = EmployeeDepartment.find(params[:dept_id])
    employees = department.employees(:include=>:user).sort_by{|a| a.full_name.downcase}
    @to_users = employees.map { |s| s.user }.compact||[]
    render :update do |page|
      page.replace_html 'to_users', :partial => 'to_users', :object => @to_users
    end
  end

  def to_students
    if params[:batch_id] == ""
      render :update do |page|
        page.replace_html "to_users2", :text => ""
      end
      return
    end
    batch = Batch.find(params[:batch_id])
    students = batch.students(:include=>:user).sort_by{|a| a.full_name.downcase}
    @to_users = students.map { |s| s.user }.compact||[]
    render :update do |page|
      page.replace_html 'to_users2', :partial => 'to_users', :object => @to_users
    end
  end

  def update_recipient_list
    recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
    @recipients = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
    render :update do |page|
      page.replace_html 'recipient-list', :partial => 'recipient_list'
    end
  end

  def list_created_tasks
    if current_user.parent?
      @user = current_user.guardian_entry.current_ward.user
    else
      @user = current_user
    end
    if (params[:filter_tasks] == nil || params[:filter_tasks] == "All")
      @tasks = @user.tasks.paginate :per_page=>5,:page => params[:tasks_page], :order => 'created_at DESC'
    elsif (params[:filter_tasks] == "Due Date")
      @tasks = @user.tasks.all(:conditions => {:status => "Assigned"}).paginate :per_page=>5,:page => params[:tasks_page], :order => 'due_date ASC'
    else
      @tasks = @user.tasks.all(:conditions=>{:status=>params[:filter_tasks]}).paginate(:per_page=>5,:page => params[:tasks_page], :order => 'created_at DESC')
    end
    render(:update) {|page| page.replace_html 'list_created_tasks',:partial=> 'list_tasks'}
  end

  def list_assigned_tasks
    if current_user.parent?
      @user = current_user.guardian_entry.current_ward.user
    else
      @user = current_user
    end
    if (params[:filter_assigned_tasks] == nil || params[:filter_assigned_tasks] == "All")
      @assigned_tasks = @user.assigned_tasks.paginate :per_page => 5, :page => params[:assigned_page], :order => 'created_at DESC'
    elsif (params[:filter_assigned_tasks] == "Due date")
      @assigned_tasks = @user.assigned_tasks.all(:conditions => {:status => "Assigned"}).paginate :per_page=>5,:page => params[:assigned_page], :order => 'due_date ASC'
    else
      @assigned_tasks = @user.assigned_tasks.all(:conditions=>{:status=>params[:filter_assigned_tasks]}).paginate(:per_page=>5,:page => params[:assigned_page], :order => 'created_at DESC')

    end
    render(:update) {|page| page.replace_html 'list_assigned_tasks',:partial=> 'list_assigned_tasks'}
  end


  def load_data
    @departments = EmployeeDepartment.active_and_ordered
    @batches = Batch.active
  end

  def assigned_to
    @task = Task.find(params[:id])
    if current_user.parent?
       if @task.can_be_viewed_by?(@current_user.guardian_entry.current_ward.user)
        @assignees = @task.assignees.paginate(:order=>"first_name ASC",:per_page=>10,:page=>params[:page])
      else
        flash[:notice] = "#{t('no_permission_to_view_task')}"
        redirect_to :action => "index"
      end
    else
      if @task.can_be_viewed_by?(@current_user)
        @assignees = @task.assignees.paginate(:order=>"first_name ASC",:per_page=>10,:page=>params[:page])
      else
        flash[:notice] = "#{t('no_permission_to_view_task')}"
        redirect_to :action => "index"
      end
    end
  end


end
