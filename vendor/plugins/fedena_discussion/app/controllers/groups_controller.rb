class GroupsController < ApplicationController
  before_filter :login_required
  before_filter :load_group,:only=>[:edit,:update,:show,:members,:destroy]
  before_filter :check_group_access, :only=>[:members,:show]
  before_filter :check_group_edit_access, :only=>[:edit,:update,:destroy]
  filter_access_to :all

  def index
    @mygroups=current_user.member_groups
    group_posts=GroupPost.find(:all, :conditions=>["group_id IN (?)",@mygroups.map{|group| group.id}]).collect{|group_post| group_post.id}
    @comments=GroupPostComment.find(:all,:order=>"`group_post_comments`.id DESC", :conditions=>["group_post_id IN (?)",group_posts]).paginate(:page => params[:page], :per_page => 10)
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

  def to_employees
    unless params[:dept_id] == ""
      department = EmployeeDepartment.find(params[:dept_id])
      employees = department.employees.sort_by{|a| a.full_name.downcase}
      @to_users = employees.map { |s| s.user.id unless s.user.nil? }
      @to_users.delete nil
      render :update do |page|
        page.replace_html 'to_users', :partial => 'to_users', :object => @to_users
      end
    else
      render :update do |page|
        page.replace_html "to_users", :text => ""
      end
    end
  end

  def to_students
    unless params[:batch_id] == ""
      batch = Batch.find(params[:batch_id])
      students = batch.students.sort_by{|a| a.full_name.downcase}
      @to_users = students.map { |s| s.user.id unless s.user.nil? }
      @to_users.delete nil
      render :update do |page|
        page.replace_html 'to_users2', :partial => 'to_users', :object => @to_users
      end
    else
      render :update do |page|
        page.replace_html "to_users2", :text => ""
      end
    end
  end

  def to_schools
    unless params[:dept_id] == ""
      school = School.find params[:id]
      @departments = school.employee_departments.active(:order=>"name asc")
      @batches = school.batches.active
      render :update do |page|
        page.replace_html 'depts_and_courses', :partial => 'depts_and_courses'
      end
    else
      render :update do |page|
        page.replace_html "dept_and_courses", :text => ""
      end
    end
  end

  def update_recipient_list
    recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
    @recipients = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
    @group=Group.find(params[:id],:include=>:members)
    render :update do |page|
      page.replace_html 'recipient-list', :partial => 'recipient_list', :locals=>{:group=>@group, :recipients=>@recipients}
    end
  end

  def update_recipient_list1
    recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
    @recipients = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
    partial = @recipients.empty? ? nil : 'recipient_list1'
    render :update do |page|
      page.replace_html 'recipient-list', :partial => partial, :locals=>{:recipients=>@recipients}
    end
  end

  def new
    @user = current_user
    @group = @user.groups.build
    @group_member=@group.group_members.build
    load_data
  end

  def edit
    @user = current_user
    @group_admins=@group.admin_members.sort_by{|a| a.full_name.downcase}
    @group_non_admin_members=@group.non_admin_members.sort_by{|a| a.full_name.downcase}
    load_data
  end

  def create
    @user = current_user
    @group = @user.groups.build(params[:group])
    @group.member_ids = params[:recipients].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
    if @group.save
      flash[:notice] = t('group_created_successfully')
      redirect_to group_path(:id=>@group.id)
    else
      load_data
      @recipients = params[:recipients] if params[:recipients].present?
      render :new
    end
  end
  
  def update
    @group_admin=@group.group_members.find(:all, :conditions=>{:is_admin => true})
    @group_other_members=@group.group_members.find(:all, :conditions=>{:is_admin => false})
    @group.member_ids = params[:recipients].split(',').reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
    if @group.update_attributes(params[:group])
      flash[:notice] = t('group_updated_successfully')
      redirect_to group_path(:id=>@group.id)
    else
      @group_admins=@group.admin_members.sort_by{|a| a.full_name.downcase}
      @group_non_admin_members=@group.non_admin_members.sort_by{|a| a.full_name.downcase}
      load_data
      render :action=>"edit"
    end
  end

  def destroy
    @group.destroy
    flash[:notice] = t('group_delete')
    redirect_to :action => "index"
  end

  def switch_between_admin_and_normal
    @group_member=GroupMember.find(:first,:conditions=>["user_id = ? and group_id =? ", params[:user_id],params[:group_id]])
    if @group_member.is_admin?
      @group_member.update_attributes(:is_admin=> false)
    else
      @group_member.update_attributes(:is_admin=> true)
    end
    flash[:notice] = t('group_updated_successfully')
    redirect_to :action => "edit", :id=>@group_member.group_id
  end

  def show
    @group_posts=@group.group_posts.find(:all,:order=>"`group_post_comments`.id DESC,`group_posts`.id DESC",:joins=>"LEFT OUTER JOIN group_post_comments ON group_post_comments.group_post_id = group_posts.id ").uniq.paginate( :page => params[:page], :per_page => 10)
    @group_post_comments=GroupPostComment.find(:all,:order=>"id DESC", :conditions=>["group_post_id IN (?)",@group_posts.map{|group_post| group_post.id}])
    @new_post=@group.group_posts.build
    @file=@new_post.group_files.build
  end

  def recent_posts
    @groups=current_user.member_groups
    @group_posts = GroupPost.paginate(:all,:select => "DISTINCT group_posts.id,group_posts.*",:order=>"`group_posts`.id DESC",:joins=>"LEFT OUTER JOIN group_post_comments ON group_post_comments.group_post_id = group_posts.id ", :conditions=>["group_id IN (?)",@groups.map{|group| group.id}], :page => params[:page], :per_page => 10)
  end

  def members
    if (params[:filter_group_members] == nil || params[:filter_group_members] == "All")
      @group_members=@group.members.all
      flash[:notice]=t('no_members') unless @group_members.present?
    elsif (params[:filter_group_members] == "Student")
      @group_members=@group.members.find(:all,:conditions=>{:student=>true})
      flash[:notice]=t('no_student_members') unless @group_members.present?
    else
      @group_members=@group.members.find(:all,:conditions=>{:student=>false})
      flash[:notice]=t('no_employee_members') unless @group_members.present?
    end
  end


  private
  def load_group
    @group=Group.find(params[:id])
  end

  def check_group_access
    if !(current_user.member_groups.map{|group| group.id}.include?(@group.id) or current_user.admin?)
      flash[:notice] = t('no_permission')
      redirect_to :action=>'index' and return
    end
  end

  def check_group_edit_access
    unless (current_user.id==@group.user_id or current_user.admin? or current_user.privileges.include?(Privilege.find_by_name("GroupCreate"))) or @group.group_members.find_all_by_is_admin(true).collect(&:user_id).include?(current_user.id)
      flash[:notice] = t('no_permission')
      redirect_to :action=>'index' and return
    end
  end


  def load_data
    @departments = EmployeeDepartment.active_and_ordered
    @batches = Batch.active
  
  end

end
