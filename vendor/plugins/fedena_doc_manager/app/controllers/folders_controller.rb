class FoldersController < ApplicationController
  before_filter :login_required
  before_filter :get_folder, :only => [:favorite,:show]
  after_filter  :update_modified, :only => [:update,:update_privileged,:update_userspecific]
  filter_access_to :all
  filter_access_to :show,:edit,:update,:download,:remove,:destroy,:attribute_check => true,:load_method => lambda {Folder.find(params[:id])}

  def favorite
    flash[:notice] = @folder.favorite_modify(current_user)
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html @folder.class.to_s.first+params[:id], :partial => 'doc_managers/col_id'
    end
  end

  def update_member_list
    if params[:members]
      @members = User.active.find_all_by_id(params[:members].split(",").collect{ |s| s.to_i }, :order => "first_name ASC")
      partial = @members.empty? ? nil : 'member_list'
      render :update do |page|
        page.replace_html 'member-list', :partial => partial
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def update_upload_member_list
    if params[:members]
      @members = User.active.find_all_by_id(params[:members].split(",").collect{ |s| s.to_i }, :order => "first_name ASC")
      partial = @members.empty? ? nil : 'upload_privileged_member_list'
      render :update do |page|
        page.replace_html 'member-list', :partial => partial
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def update_dept_list
    if params[:depts]
      @depts = EmployeeDepartment.find_all_by_id(params[:depts].split(",").collect{ |s| s.to_i }, :order => "name ASC")
      render :update do |page|
        if @depts.empty?
          page.replace_html 'dept-course-heading', :partial => 'blank' if params[:flag]
          page.replace_html 'dept-list', :partial => 'blank'
        else
          page.replace_html 'dept-course-heading', :partial => 'dept_course_heading'
          page.replace_html 'dept-list', :partial => 'dept_list'
        end
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def update_course_list
    if params[:courses]
      @courses = Course.find(params[:courses].split(",").collect{ |s| s.to_i })
      render :update do |page|
        if @courses.empty?
          page.replace_html 'dept-course-heading', :partial => 'blank' if params[:flag]
          page.replace_html 'course-list', :partial => 'blank'
        else
          page.replace_html 'dept-course-heading', :partial => 'dept_course_heading'
          page.replace_html 'course-list', :partial => 'course_list'
        end
      end
    else
      redirect_to :controller=>"user", :action=> "dashboard"
    end
  end

  def new
    if params[:folder_type].to_s.downcase == "shareable"
      @folder = ShareableFolder.new
      @batches = Batch.active
      @departments = EmployeeDepartment.active_and_ordered
      @folder.documents.build(:user_id => current_user.id)
      @departments = EmployeeDepartment.active_and_ordered
      @batches = Batch.active
    else
      flash[:notice] = "#{t('flash5')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def create
    if params[:folder_type].to_s.downcase == "shareable"
      @folder = ShareableFolder.new(params[:shareable_folder])
      @departments = EmployeeDepartment.active_and_ordered
      @folder.user_id = current_user.id
      @departments = EmployeeDepartment.active_and_ordered
      @batches = Batch.active
      if @folder.save
        @folder.user_ids = params[:members].split(",").reject{|a| a.strip.blank?}.collect{|s| s.to_i}
        flash[:notice] = "#{t('flash1')}"
        redirect_to doc_managers_path
      else
        @members = params[:members] if params[:members].present?
        render "new"
      end
    else
      flash[:notice] = "#{t('flash5')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def new_privileged
    if params[:folder_type].to_s.downcase == "privileged"
      @folder = PrivilegedFolder.new
      @departments = EmployeeDepartment.active_and_ordered
      @folder.user_id = current_user.id
      @departments = EmployeeDepartment.active_and_ordered
    else
      flash[:notice] = "#{t('flash5')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def create_privileged
    if params[:folder_type].to_s.downcase == "privileged"
      @folder = PrivilegedFolder.new(params[:privileged_folder])
      @departments = EmployeeDepartment.active_and_ordered
      @folder.user_id = current_user.id
      @departments = EmployeeDepartment.active_and_ordered
      if @folder.save
        @folder.user_ids = params[:members].split(",").collect{ |s| s.to_i }
        flash[:notice] = "#{t('flash3')}"
        redirect_to doc_managers_path
      else
        @members = params[:members] if params[:members].present?
        render "new_privileged"
      end
    else
      flash[:notice] = "#{t('flash5')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def new_userspecific
    if params[:folder_type].to_s.downcase == "userspecific"
      @folder = AssignableFolder.new
      @folder.user_id = current_user.id
      @categories = FolderAssignmentType.all
      @active_userspecific_folders = AssignableFolder.active.sort_by {|x| x.name.downcase}
      @inactive_userspecific_folders = AssignableFolder.inactive.sort_by {|x| x.name.downcase}
    else
      flash[:notice] = "#{t('flash5')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def create_userspecific
    if params[:folder_type].to_s.downcase == "userspecific"
      @folder = AssignableFolder.new(params[:assignable_folder])
      @folder.user_id = current_user.id
      @folder.category = params[:category] if params[:category].present?
      @active_userspecific_folders = AssignableFolder.active.sort_by {|x| x.name.downcase}
      @inactive_userspecific_folders = AssignableFolder.inactive.sort_by {|x| x.name.downcase}
      @categories = FolderAssignmentType.all
      if @folder.save
        @folder.category_ids = params[:category]
        flash[:notice] = "#{t('flash2')}"
        redirect_to new_userspecific_folder_path
      else
        render "new_userspecific"
      end
    else
      flash[:notice] = "#{t('flash5')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def edit
    @action = params[:action_text]
    @query = params[:query]
    @departments = EmployeeDepartment.active_and_ordered
    @folder = ShareableFolder.find(params[:id])
    @batches = Batch.active
    @departments = EmployeeDepartment.active_and_ordered
    @batches = Batch.active
    if @folder.present? and @folder.user_id == current_user.id and params[:folder_type] == "shareable"
      @members = @folder.user_ids.join(",")
      @documents = @folder.documents
    else
      flash[:notice] = "#{t('flash6')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def update
    @action = params[:action_text]
    @departments = EmployeeDepartment.active_and_ordered
    @folder = ShareableFolder.find(params[:id])
    @departments = EmployeeDepartment.active_and_ordered
    @batches = Batch.active
    if params[:folder_type].to_s.downcase == "shareable"
      @folder.update_attributes(params[:shareable_folder])
      if @folder.save
        @folder.user_ids = params[:members].split(",").reject{|a| a.strip.blank?}.collect{|s| s.to_i}
        @saved = true
        flash[:notice] = "#{t('flash9')}"
        redirect_to :controller => "doc_managers", :action => :index, :page => params[:page], :action_text => @action, :query => params[:query]
      else
        @members = @folder.user_ids.join(",")
        @documents = @folder.documents
        render 'edit'
      end
    else
      flash[:notice] = "#{t('flash6')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def edit_privileged
    @action = params[:action_text]
    @departments = EmployeeDepartment.active_and_ordered
    @folder = PrivilegedFolder.find(params[:id])
    @query = params[:query]
    @departments = EmployeeDepartment.active_and_ordered
    if @folder.present? and params[:folder_type] == "privileged"
      @members = @folder.user_ids.join(",")
    else
      flash[:notice] = "#{t('flash6')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def update_privileged
    @action = params[:action_text]
    @departments = EmployeeDepartment.active_and_ordered
    @folder = PrivilegedFolder.find(params[:id])
    @departments = EmployeeDepartment.active_and_ordered
    if params[:folder_type] == "privileged"
      @folder.update_attributes(params[:privileged_folder])
      if @folder.save
        @folder.user_ids = params[:members].split(",").reject{|a| a.strip.blank?}.collect{|s| s.to_i}
        @saved = true
        flash[:notice] = "#{t('flash11')}"
        redirect_to :controller => "doc_managers", :action => :index, :page => params[:page], :action_text => @action, :query => params[:query]
      else
        @members = @folder.user_ids.join(",")
        render 'edit_privileged'
      end
    else
      flash[:notice] = "#{t('flash6')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def edit_userspecific
    @action = params[:action_text]
    @folder = AssignableFolder.find(params[:id])
    if @folder.present? and params[:folder_type] == "userspecific"
      @categories = FolderAssignmentType.all
      @active_userspecific_folders = AssignableFolder.active.sort_by {|x| x.name.downcase}
      @inactive_userspecific_folders = AssignableFolder.inactive.sort_by {|x| x.name.downcase}
    else
      flash[:notice] = "#{t('flash6')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def update_userspecific
    @action = params[:action_text]
    @folder = AssignableFolder.find(params[:id])
    if params[:folder_type] == "userspecific"
      @folder.update_attributes(params[:assignable_folder])
      @folder.category = params[:category] if params[:category].present?
      @categories = FolderAssignmentType.all
      @active_userspecific_folders = AssignableFolder.active.sort_by {|x| x.name.downcase}
      @inactive_userspecific_folders = AssignableFolder.inactive.sort_by {|x| x.name.downcase}
      if @folder.save
        @folder.category_ids = params[:category]
        flash[:notice] = "#{t('flash10')}"
        redirect_to new_userspecific_folder_path
      else
        render 'edit_userspecific'
      end
    end
  end

  def show
    @action = params[:action_text]
    @query = params[:query] if params[:query].present?
    if @folder.class.to_s == "AssignableFolder"
      @user = User.find(params[:user_id])
      collection = @user.docs.find_all_by_folder_id(@folder.id,:order=>'name')
    elsif @folder.class.to_s == "PrivilegedFolder"
      collection = @folder.find_priv_docs(current_user)
    else
      if(@action == 'recent_docs')
        collection = @folder.documents.sort_by { |x| x.updated_at }.reverse
      else
        collection = @folder.documents.sort_by { |x| x.name.downcase }
      end
    end
    @collection = collection.paginate(:page =>params[:page],:per_page => 12) if collection.present?
    flash[:warning]= @collection.present? ? nil : "#{t('warning_no_folders_or_documents')}"
    render :update do |page|
      page.replace_html 'bread_crumb', :partial => 'doc_managers/breadcrumbs'
      page.replace_html 'docs_pane', :partial => 'doc_managers/doc_list' unless @folder.class.to_s == "AssignableFolder"
      page.replace_html 'userspecific_docs_area', :partial => 'doc_managers/doc_list' if @user.present?
    end
  end

  def destroy
    @action = params[:action_text]
    @query = params[:query]
    folder = Folder.find(params[:id])
    if folder.delete_allowed(current_user)
      if folder.present? and request.xhr?
        flash[:notice]= folder.destroy_folder(current_user)
        if (@action == "privileged_docs" or @action == "user_docs")
          @collection = current_user.folder_list(@action).flatten.paginate(:per_page=>12,:page => params[:page])
        else
          unless(@action == 'search')
            @collection = current_user.document_list(@action).model_paginate(:per_page=>12,:page=>params[:page])
          else
            results = []
            results << Folder.search_docs(current_user,@query) if @query.length > 0
            results << Document.search_docs(current_user,@query) if @query.length > 0
            @collection = results.flatten.uniq.paginate(:page =>page(params[:page],results.flatten.size),:per_page => 12) if results.present?
          end
        end
        flash[:warning]= @collection.present? ? nil : "#{t('warning_no_folders_or_documents')}"
        text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
        render :update do |page|
          page.replace_html 'flash-msg', :text => text
          page.replace_html 'bread_crumb', :partial => 'doc_managers/breadcrumbs'
          page.replace_html 'docs_pane', :partial => 'doc_managers/doc_list'
        end
      elsif folder.present? and folder.class.to_s=="AssignableFolder"
        flash[:notice] = folder.destroy_folder(current_user)
        @categories = FolderAssignmentType.all
        @active_userspecific_folders = AssignableFolder.active.sort_by {|x| x.name.downcase}
        @inactive_userspecific_folders = AssignableFolder.inactive.sort_by {|x| x.name.downcase}
        redirect_to new_userspecific_folder_path
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def destroy_privileged
    @action = params[:action_text]
    folder = PrivilegedFolder.find(params[:id])
    if folder.delete_allowed(current_user)
      if folder.present? and request.xhr?
        flash[:notice] = folder.destroy_folder(current_user)
        @collection = current_user.folder_list(@action).flatten.paginate(:per_page=>12,:page => params[:page])
        text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
        render :update do |page|
          page.replace_html 'flash-msg', :text => text
          page.replace_html 'bread_crumb', :partial=>'doc_managers/breadcrumbs'
          page.replace_html 'docs_pane', :partial=> 'doc_managers/doc_list'
        end
      end
    end
  end

  def to_employees
    unless params[:dept_id].present?
      render :update do |page|
        page.replace_html "to_users", :text => nil
      end
    else
      @to_users = Employee.find(:all,:select=>"user_id, first_name,middle_name,last_name",:conditions=> ["user_id <> ? and employee_department_id = ?",current_user.id,params[:dept_id]], :order => "first_name ASC").compact
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
      @to_users = Student.find_all_by_batch_id(params[:batch_id],:select => "user_id, first_name,middle_name,last_name", :conditions => ["user_id <> ?",current_user.id], :order => "first_name ASC").compact
      render :update do |page|
        page.replace_html 'to_users2', :partial => 'to_users', :object => @to_users
      end
    end
  end

  private
  def get_folder
    @folder=Folder.find(params[:id])
  end

  def page(page_cnt,size)
    page_cnt.present? and size.nonzero? ? page_cnt.to_i <= (size/12 + (size%12==0 ? 0 : 1)) ? page_cnt.to_i : (size / 12 ) + (size%12==0 ? 0 : 1) : 1
  end

  def update_modified
    @folder.update_attribute('updated_at',DateTime.now) if @saved
  end
end
