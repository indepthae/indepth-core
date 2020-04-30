class UserGroupsController < ApplicationController
  lock_with_feature  :user_groups_enhancement
  before_filter :find_department_and_batch, :only => [:create_user_group, :add_member, :edit_user_group]
  before_filter :find_group, :only => [:show_user_group, :destroy_user_group, :add_member, :edit_user_group]
  before_filter :check_status, :only => [:show_user_group]
  filter_access_to :all

  def index
    @groups=UserGroup.paginate(:per_page => 15, :page => params[:page], :order => 'name ASC')
  end

  def create_user_group
    if request.post?
      @group=UserGroup.new(params[:group])
      if @group.save
        add_to_delayed_job if !@group.status
        flash[:notice] = "#{t('group_created')}"
        render :update do|page|
          page.redirect_to :action => 'index'
        end
      else
        render :update do |page|
          page << "document.body.scrollTop = document.documentElement.scrollTop = 0;"
          page.replace_html 'error_box', :partial => 'error'
        end
      end

    end
  end

  def to_students
    if params[:batch_id] == ""
      render :update do |page|
        page.replace_html "to_students", :text => ""
      end
      return
    end
    @to_all_students = (params[:batch_id] == 'all')
    @to_students = UserGroup.get_students(params[:batch_id]) unless @to_all_students
    render :update do |page|
      if @to_all_students
        page.replace_html 'to_students', :text=>''
        page.replace_html 'member-list', :partial => 'member_list_all_students', :object => @to_all_students
      else
        page.replace_html 'to_students', :partial => 'to_students', :object => @to_students
      end
    end
  end

  def to_employees
    if params[:dept_id] == ""
      render :update do |page|
        page.replace_html "to_employees", :text => ""
      end
      return
    end
    @to_all_employees = (params[:dept_id] == 'all')
    @to_employees = UserGroup.get_employees(params[:dept_id]) unless @to_all_employees
    render :update do |page|
      if @to_all_employees
        page.replace_html 'to_employees', :text=>''
        page.replace_html 'member-list1', :partial => 'member_list_all_employees', :object => @to_all_employees
      else
        page.replace_html 'to_employees', :partial => 'to_employees', :object => @to_employees
      end
    end
  end

  def to_parents
    if params[:batch_id] == ""
      render :update do |page|
        page.replace_html "to_parents", :text => ""
      end
      return
    end
    @to_all_parents = (params[:batch_id] == 'all')
    @to_parents = UserGroup.get_parents(params[:batch_id]) unless @to_all_parents
    render :update do |page|
      if @to_all_parents
        page.replace_html 'to_parents', :text=>''
        page.replace_html 'member-list2', :partial => 'member_list_all_parents', :object => @to_all_parents
      else
        page.replace_html 'to_parents', :partial => 'to_parents', :object => @to_parents
      end
    end
  end


  def update_member_list
    if params[:members_students]
      @members_students = sort_users(params[:members_students])
      render :update do |page|
        page.replace_html 'member-list', :partial => 'member_list_students'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def update_member_list1
    if params[:members_employees]
      @members_employees = sort_users(params[:members_employees])
      render :update do |page|
        page.replace_html 'member-list1', :partial => 'member_list_employees'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def update_member_list2
    if params[:members_parents]
      @members_parents = sort_users(params[:members_parents])
      render :update do |page|
        page.replace_html 'member-list2', :partial => 'member_list_parents'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def show_user_group
    order= 'users.first_name ASC'  
    @employee_members = @group.user_groups_users.paginate(:conditions => {:target_type => "employee"}, :per_page => 10, :page => params[:employee_page], :include => :user, :order => order) unless @group.all_members["employee"]
    @student_members = @group.user_groups_users.paginate(:conditions => {:target_type => "student"}, :per_page => 10, :page => params[:student_page], :include => :user, :order => order) unless @group.all_members["student"]
    @parent_members = @group.user_groups_users.paginate(:conditions => {:target_type => "parent"}, :per_page => 10, :page => params[:parent_page], :include => :user, :order => order) unless @group.all_members["parent"]
  end

  def destroy_user_group
    if @group.destroy
      flash[:notice] = "#{t('group_deleted')}"
    else
      flash[:notice] = "#{t('group_not_deleted')}"
    end
    redirect_to :action => "index"
  end

  def remove_member
    @group = UserGroup.find(params[:group_id])
    if params[:all]=="true"
      @group.delete_all(params[:type])
      flash[:notice]= "#{t('user_removed')}"
    else
      user_group_user = @group.user_groups_users.first(:conditions => {:user_id => params[:id], :target_type => params[:target_type]})
      user_group_user.destroy if user_group_user.present?
      flash[:notice]= "#{t('user_removed')}"
    end    
    redirect_to :action => "show_user_group", :id => @group.id
  end

  def edit_user_group
    @members_students, @to_all_students = get_users("student")
    @members_employees, @to_all_employees = get_users("employee")
    @members_parents, @to_all_parents = get_users("parent")
    if request.post?
      unless params[:add_member]
        if @group.update_attributes(:name => params[:group][:name])
          add_to_delayed_job if !@group.status
          flash[:notice] = "#{t('group_update')}"
          render :update do|page|
            page.redirect_to :action => "index"
          end
        else
          render :update do |page|
            page << "document.body.scrollTop = document.documentElement.scrollTop = 0;"
            page.replace_html 'error_box', :partial => 'error'
          end
        end
      else
        add_to_delayed_job if !@group.status
        flash[:notice] = "#{t('group_update')}"
        render :update do|page|
          page.redirect_to :action => "index"
        end
      end
    end
  end


  private

  def add_to_delayed_job
    @group.update_attributes(:status => true)
    Delayed::Job.enqueue(DelayedUserGroupCreation.new(:group_id => @group.id,
        :student_ids => params[:members_students],
        :employee_ids => params[:members_employees], 
        :parent_ids => params[:members_parents],
        :action => params[:action]),
      {:queue => "user_group"});
  end  

  def find_department_and_batch
    @departments,@batches,@parents_for_batch = UserGroup.get_departments_batches_and_parents
  end

  def find_group
    @group = UserGroup.find(params[:id])
  end
  
  def get_users(type)
    to_all = @group.all_members[type]
    if @group.all_members[type] == true
      members = "all"
    else
      members = @group.user_groups_users.all(:select => ["user_id,users.first_name"], :conditions => {:target_type => type}, :joins => :user, :order => "LOWER(first_name) ASC").map(&:user_id).join(",")
    end  
    return  members, to_all
  end  
  
  def check_status
    find_group
    if @group.status
      redirect_to :action => "index"
    end  
  end
  
  def sort_users(users)
    recipients_array = users.split(",").collect{ |s| s.to_i }
    members = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}.collect(&:id).join(",")
  end    

end
