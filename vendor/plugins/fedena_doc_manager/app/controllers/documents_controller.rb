class DocumentsController < ApplicationController
  before_filter :login_required
  before_filter :get_document, :only => [:favorite,:edit,:update,:remove,:destroy,:download,:edit_privileged_document]
  after_filter  :update_modified, :only => [:create,:update]
  filter_access_to :all
  filter_access_to :show,:edit,:update,:download,:remove,:destroy,:attribute_check => true,:load_method => lambda {Document.find(params[:id])}

  def favorite
    flash[:notice] = @document.favorite_modify(current_user)
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html @document.class.to_s.first+params[:id], :partial => 'doc_managers/col_id'
    end
  end

  def new
    @document = current_user.documents.build
    @departments = EmployeeDepartment.active_and_ordered
    @batches = Batch.active
  end

  def edit
    @action = params[:action_text]
    @departments = EmployeeDepartment.active_and_ordered
    @batches = Batch.active
    @query = params[:query]
    @folder_id = params[:folder_id] if params[:folder_id].present?
    if @document.present?
      @members = @document.user_ids.join(",")
    else
      flash[:notice] = t('flash7')
      redirect_to :controller=> "user", :action=> "dashboard"
    end
  end

  def update
    @action = params[:action_text]
    @batches = Batch.active
    @departments = EmployeeDepartment.active_and_ordered
    @members = @document.user_ids.join(",")
    params[:document_attributes].each_pair do |k,v|
      @document.update_attributes(v)
      if @document.save
        @document.user_ids= params[:members].split(",").reject{|a| a.strip.blank?}.collect{|s| s.to_i}
        @saved = true
        flash[:notice] = "#{t('flash1')}"
        if(params[:folder_id].present?)
          redirect_to doc_managers_path(:page => params[:page], :action_text => @action, :folder_id => params[:folder_id], :user_id => params[:user_id], :query => params[:query])
        else
          redirect_to doc_managers_path(:page => params[:page], :action_text => @action, :user_id => params[:user_id], :query => params[:query])
        end
      else
        render 'edit'
      end
    end
  end

  def remove
    @document.destroy
    render :update do |page|
      page.remove('doc'+params[:id])
    end
  end

  def destroy
    @action = params[:action_text]
    @folder = @document.folder if @document.folder.present?
    @user = User.find_by_id(params[:user_id])
    @query = params[:query] if params[:query].present?
    flash[:notice] = @document.destroy_document(current_user)
    if @folder.present?
      if @folder.class.to_s == "AssignableFolder"
        search_box = true
        documents = @user.docs.find_all_by_folder_id(@folder)
        @collection = documents.paginate(:page => page(params[:page],documents.size),:per_page => 12)
      else
        @collection = @folder.documents.paginate(:page =>page(params[:page],@folder.documents.size),:per_page => 12) if @folder.documents.present?
        flash[:warning] ="#{t('warning_no_folders_or_documents')}" unless @folder.documents.present?
      end
    else
      if (@action == "privileged_docs" or @action == "user_docs")
        @collection = current_user.folder_list(@action).flatten.paginate(:per_page=>12,:page => params[:page])
      else
        @collection = current_user.document_list(@action).model_paginate(:per_page=>12,:page=>params[:page])
      end
    end
    flash[:warning] = @collection.present? ? nil : "#{t('warning_no_folders_or_documents')}"
    text = flash[:notice].nil? ? nil : "<p class=\"flash-msg\">#{flash[:notice]}</p>"
    render :update do |page|
      page.replace_html 'flash-msg', :text => text
      page.replace_html 'bread_crumb', :partial => 'doc_managers/breadcrumbs'
      page.replace_html 'docs_pane', :partial => 'doc_managers/search_box' if search_box
      unless search_box.present?
        page.replace_html 'docs_pane', :partial => 'doc_managers/doc_list'
      else
        page.replace_html 'userspecific_docs_area', :partial => 'doc_managers/doc_list'
      end
    end
  end

  def download
    if File.exist?(@document.attachment.path)
      if @document.is_allowed(current_user)
        send_file @document.attachment.path
      else
        flash[:notice] = "#{t('flash11')}"
        redirect_to :controller => "user", :action => "dashboard"
      end
    else
      flash[:notice] = "#{t('flash12')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def update_member_list
    if params[:members]
      @members = User.active.find_all_by_id(params[:members].split(",").collect{ |s| s.to_i }, :order => "first_name ASC")
      render :update do |page|
        page.replace_html 'member-list', :partial => 'member_list'
      end
    else
      redirect_to :controller=> "user", :action=> "dashboard"
    end
  end

  def to_employees
    @departments = EmployeeDepartment.active_and_ordered
    unless params[:dept_id].present?
      render :update do |page|
        page.replace_html "to_users", :text => nil
      end
    else
      @to_users = Employee.find(:all,:select=>"user_id, first_name, middle_name,last_name",:conditions=> ["user_id <> ? and employee_department_id = ?",current_user.id,params[:dept_id]], :order => "first_name ASC").compact
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

  def create
    @departments = EmployeeDepartment.active_and_ordered
    @batches = Batch.active
    @document = Document.check_and_save(params[:document_attributes],current_user,params[:members])
    unless @document.errors.present?
      @saved = true
      flash[:notice] = "#{t('flash9')}"
      redirect_to doc_managers_path
    else
      @members = params[:members]
      render "new"
    end
  end

  def add_privileged_document
    @batches = Batch.active
    @action = params[:action_text]
    @folder = PrivilegedFolder.find(params[:id])
    @departments = EmployeeDepartment.active_and_ordered
    @document = @folder.documents.build
    @error = false
    @query = params[:query] if params[:query].present?
    count = 0
    if request.post?
      if params[:document_attributes].present?
        params[:document_attributes].each_pair do |k,v|
          @document = current_user.child_documents.new(v)
          if v[:name].present? == v[:attachment].present? and v[:name].present?
            file_size = v[:attachment].size rescue false
            unless file_size==false
              if file_size > Document.new.attachment.instance_variable_get('@max_file_size')
                @error = true
                @document.errors.add_to_base(t('doc_size'))
                break
              end
            end
          else
            @error = true
            @document.errors.add_to_base(:document_name_blank) unless v[:name].present?
            @document.errors.add_to_base(:file_field_blank) unless v[:attachment].present?
            break
          end
          count = count + 1 if v[:attachment].present?
        end
      end
      if count.zero?
        @document.errors.add_to_base(:no_document)
        @error = true
      end
      if (params[:public] == "false") and (params[:members].to_s.length==0)
        @error = true
        @document.errors.add_to_base(:no_members)
      end
      unless (count.zero? && @error) or (@error)
        params[:document_attributes].each_pair do |k,v|
          @document = @folder.documents.build(v)
          if v["attachment"].present?
            if @document.save
              if params[:public]== "false"
                @document.user_ids = params[:members].split(",").collect{ |s| s.to_i }
              elsif params[:public] == "true"
                @document.user_ids = ''
              end
              flash[:notice] = t('flash9')
              redirect_to doc_managers_path(:page => params[:page], :action_text => @action, :folder_id => @document.folder.id, :query => @query)
            else
              @members = params[:members]
              render "add_privileged_document"
            end
          end
        end


      else
        @members = params[:members]
        render "add_privileged_document"
      end
    end
  end
  def edit_privileged_document
    @action = params[:action_text]
    @batches = Batch.active
    @query = params[:query]
    @departments = EmployeeDepartment.active_and_ordered
    @members = @document.user_ids.join(",")
    if params[:public] == 'true'
      params[:document_attributes].each_pair do |k,v|
        @document.update_attributes(v)
        if @document.save
          @document.user_ids = ''
          flash[:notice] = "#{t('flash1')}"
          redirect_to doc_managers_path(:page => params[:page], :action_text => @action, :folder_id => @document.folder.id, :user_id => params[:user_id], :query => params[:query])
        else
          render 'edit_privileged_document'
        end
      end
    elsif params[:public] == 'false'
      params[:document_attributes].each_pair do |k,v|
        @document.update_attributes(v)
        if @document.save
          @document.user_ids= params[:members].split(",").collect{|s| s.to_i}
          flash[:notice] = "#{t('flash1')}"
          redirect_to doc_managers_path(:page => params[:page], :action_text => @action, :folder_id => @document.folder.id, :user_id => params[:user_id], :query => params[:query])
        else
          render 'edit_privileged_document'
        end
      end
    end
  end

  def add_document_fields
    @document = current_user.documents.build
    render :update do |page|
      page.insert_html :bottom,'add', :partial=> 'document_fields'
    end
  end

  private

  def get_document
    @document = Document.find(params[:id])
  end

  def page(page_cnt,size)
    page_cnt.present? and size.nonzero? ? page_cnt.to_i <= (size/12 + (size%12==0 ? 0 : 1)) ? page_cnt.to_i : (size / 12 ) + (size%12==0 ? 0 : 1) : 1
  end

  def update_modified
    if(@document.folder.nil?)
      @document.update_attribute('updated_at',DateTime.now) if @saved
    else(@document.folder.type == "AssignableFolder")
      @document.folder.update_attribute('updated_at',DateTime.now) if @saved
    end
  end
end
