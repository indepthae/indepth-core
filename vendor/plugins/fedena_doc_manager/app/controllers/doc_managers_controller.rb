class DocManagersController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  before_filter :fetch_collection, :only => [:index,:my_docs,:privileged_docs,:recent_docs,:favorite_docs,:shared_docs]
  after_filter  :update_modified, :only => [:add_iframe_files]

  def my_docs
    @action = "my_docs"
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html 'bread_crumb', :partial => 'breadcrumbs'
      page.replace_html 'pane', :partial => "my_docs"
    end
  end

  def recent_docs
    @action = "recent_docs"
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html 'bread_crumb', :partial => 'breadcrumbs'
      page.replace_html 'pane', :partial => "recent_docs"
    end
  end

  def favorite_docs
    @action = "favorite_docs"
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html 'bread_crumb', :partial => 'breadcrumbs'
      page.replace_html 'pane', :partial => "favorite_docs"
    end
  end  

  def shared_docs
    @action = "shared_docs"
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html 'bread_crumb', :partial => 'breadcrumbs'
      page.replace_html 'pane', :partial => "shared_docs"
    end
  end

  def user_docs
    @action = "user_docs"
    render :update do |page|
      unless @current_user.student?
        page.replace_html 'bread_crumb', :partial => 'breadcrumbs'
        page.replace_html 'pane', :partial => "user_docs"
      end
    end
  end

  def privileged_docs
    @action = "privileged_docs"
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html 'bread_crumb', :partial => 'breadcrumbs'
      page.replace_html 'pane', :partial => "privileged_docs"
    end
  end

  def favorite
    if params[:type] == 'folder'
      @folder = Folder.find(params[:id])
      flash[:notice] = @folder.favorite_modify(current_user)
      @folder=nil
    elsif params[:type] == 'document'
      @document = Document.find(params[:id])
      flash[:notice] = @document.favorite_modify(current_user)
    end
    fetch_collection
    favorite_docs
  end

  def user_docs_ajax
    suggest = []
    unless params[:query] == nil
      if params[:query].length>= 3
        students = Student.find(:all,:conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}", "#{params[:query]}" ],:order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}])
        archivedstudents = ArchivedStudent.find(:all,:conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}", "#{params[:query]}" ],:order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}])
        employees = Employee.find(:all,:conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR employee_number = ? OR (concat(first_name, \" \", last_name) LIKE ? ))","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}", "#{params[:query]}" ],:order => "employee_department_id asc,first_name asc",:include=>"employee_department")
        archivedemployees = ArchivedEmployee.find(:all,:conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR employee_number = ? OR (concat(first_name, \" \", last_name) LIKE ? ))","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}", "#{params[:query]}" ],:order => "employee_department_id asc,first_name asc",:include=>"employee_department")
      else
        students = Student.find(:all,:conditions => ["admission_no = ? " ,"#{params[:query]}"],:order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}])
        archivedstudents = ArchivedStudent.find(:all,:conditions => ["admission_no = ? " ,"#{params[:query]}"],:order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}])
        employees = Employee.find(:all,:conditions => ["employee_number = ? ", "#{params[:query]}"],:order => "employee_department_id asc,first_name asc",:include=>"employee_department")
        archivedemployees = ArchivedEmployee.find(:all,:conditions => ["employee_number = ? ", "#{params[:query]}"],:order => "employee_department_id asc,first_name asc",:include=>"employee_department")
      end
    end
    if (students.empty? and employees.empty? and archivedstudents.empty? and archivedemployees.empty? )
      suggest = [t('no_suggestions')]
    end
    render :json=>{'query'=>params["query"],'suggestions'=>(suggest+students.collect{|s| s.full_name + ' - ' + s.admission_no}+archivedstudents.collect{|s| s.full_name + ' - ' + s.admission_no} + employees.collect{|e| e.full_name + ' - ' + e.employee_number}+ archivedemployees.collect{|e| e.full_name + ' - ' + e.employee_number}),'data'=>(students.collect(&:user_id)+employees.collect(&:user_id)+archivedstudents.collect(&:user_id)+archivedemployees.collect(&:user_id))  }
  end

  def update_userspecific_docs
    @action = "user_docs"
    @user = User.find(params[:user_id])
    folders = AssignableFolder.find_user_docs(@user)
    @collection = folders.paginate(:page =>params[:page],:per_page => 12) if folders.present?
    flash[:warning]= @collection.present? ?  nil : "#{t('warning_no_folders_or_documents')}"
    render :update do |page|
      page.replace_html 'bread_crumb', :partial => 'breadcrumbs'
      page.replace_html 'userspecific_docs_area', :partial => 'doc_list'
    end
  end

  def search_docs_ajax
    @action = 'search'
    results = []
    @query = params[:query] if params[:query].present?
    if @query.length >= 1
      results << Folder.search_docs(current_user,@query)
      results << Document.search_docs(current_user,@query)
      @collection = results.flatten.uniq.paginate(:page =>page(params[:page],results.flatten.size),:per_page => 12) if results.present?
      #      @query = params[:query]
    end
    render :update do |page|
      flash[:warning]= @collection.present? ?  nil : "#{t('warning_no_folders_or_documents')}"
      page.replace_html 'navigator', :partial => 'non_active'
      page.replace_html 'bread_crumb', :partial => 'breadcrumbs'
      page.replace_html 'docs_pane', :partial => 'doc_list'
    end
  end
  
  def add_iframe_files
    @user = User.find(params[:user_id]) if params[:user_id].present?
    @action = params[:action_text]
    @folder = Folder.find(params[:id])
    @document = @folder.documents.build
    @error = false
    count = 0
    if request.post?
      if params[:document_attributes].present?
        params[:document_attributes].each_pair do |k,v|
          @document = current_user.child_documents.new(v)
          if v[:name].present? == v[:attachment].present? and v[:name].present?
          else
            @error = true
            @document.errors.add_to_base(t('document_name_blank')) unless v[:name].present?
            @document.errors.add_to_base(t('file_field_blank')) unless v[:attachment].present?
            break
          end
          count = count + 1 if v[:attachment].present?
        end
      end
      if count.zero?
        @document.errors.add_to_base(t('no_document'))
        @error = true
      else
        params[:document_attributes].each_pair do |k,v|
          @document = @folder.documents.build(v)
          unless @document.valid?
            @error = true
            break
          end
        end
      end
      unless (count.zero? && @error) or (@error)
        params[:document_attributes].each_pair do |k,v|
          @document = @folder.documents.build(v)
          if v["attachment"].present?
            @document.save
            if @folder.class.to_s == "AssignableFolder" and @document
              @user.docs = @user.docs << @document
              @saved = true
            end
            flash[:notice] = t('flash9')
          end
        end
      else
        @collection = @folder.documents.paginate(:page =>page(params[:page],@folder.documents.size),:per_page => 12) if @folder.documents.present?
        flash[:warning]= @collection.present? ?  nil : "#{t('warning_no_folders_or_documents')}"
        @action = params[:action_text]
      end
    end
    respond_to do |form|
      form.html { render :layout => false }
    end
  end

  def add_files
    @user_id = params[:user_id]
    @page = params[:page]
    @action = params[:action_text]
    @folder = Folder.find(params[:id])
    @document = @folder.documents.build
    render :update do |page|
      page.replace_html 'add_files', :partial => 'add_files'
    end
  end

  def delete_checked
    @query = params[:query] if params[:query].present?
    folder = Folder.find(params[:id]) if params[:id].present?
    unless folder.present?      
      flash[:notice] = Folder.delete_checked(params[:folder_ids],current_user) if params[:folder_ids].present?
    end
    if params[:document_ids].present?
      if params[:action_text] == 'shared_docs'
        if folder.present? and folder.user_id == current_user.id
          flash[:notice] = Document.delete_checked(params[:document_ids],current_user)
        elsif folder.present? and folder.user_id != current_user.id
          flash[:notice] = t('flash11')
        else
          flash[:notice] = Document.delete_checked(params[:document_ids],current_user)
        end
      else
        flash[:notice] = Document.delete_checked(params[:document_ids],current_user)
      end      
    end
    unless folder.present?
      fetch_collection
      case params[:action_text]
      when "my_docs"
        my_docs
      when "privileged_docs"
        privileged_docs
      when "user_docs"
        user_docs
      when "recent_docs"
        recent_docs
      when "favorite_docs"
        favorite_docs
      when "shared_docs"
        shared_docs
      when "search"
        search_docs_ajax
      end
    else
      redirect_to show_folder_path(:id => folder,:action_text=>params[:action_text],:page=>params[:page],:user_id => params[:user_id])
    end
  end

  private

  def page(page_cnt,size)
    page_cnt.present? and size.nonzero? ? page_cnt.to_i <= (size/12 + (size%12==0 ? 0 : 1)) ? page_cnt.to_i : (size / 12 ) + (size%12==0 ? 0 : 1) : 1
  end

  def fetch_collection
    if params[:action_text].present? or action_name !='index'
      @action = action_name unless action_name == "index"
      @action = params[:action_text] if params[:action_text].present? and params[:action_text]!='search'
      @action = 'search' if params[:action_text] == 'search'
    else
      @action = "my_docs"
    end

    @query = params[:query].present? ? params[:query] : ''

    if((@action=="user_docs" and !(current_user.admin or current_user.privileges.map(&:name).include?("DocumentManager"))) or (@action == 'user_docs'and current_user.student))
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end

    if (@action == "privileged_docs" or @action == "user_docs")
      @collection = current_user.folder_list(@action).flatten.paginate(:per_page=>12,:page => params[:page])
    else
      unless(params[:action_text] == 'search')
        @collection = current_user.document_list(@action).model_paginate(:per_page=>12,:page=>params[:page])
      else
        results = []
        results << Folder.search_docs(current_user,@query) if @query.length > 0
        results << Document.search_docs(current_user,@query) if @query.length > 0

        @collection = results.flatten.uniq.paginate(:page =>page(params[:page],results.flatten.size),:per_page => 12) if results.present?
      end
    end
  end

  def update_modified
    if(@document.folder.nil?)
      @document.update_attribute('updated_at',DateTime.now) if @saved
    else(@document.folder.type == "AssignableFolder")
      @document.folder.update_attribute('updated_at',DateTime.now) if @saved
    end
  end

end
