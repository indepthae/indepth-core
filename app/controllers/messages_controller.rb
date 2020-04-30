class MessagesController < ApplicationController
  before_filter :login_required
  before_filter :check_permission_for_broadcast, :only=>:create_broadcast
  require 'lib/override_errors'
  helper OverrideErrors
  filter_access_to :all, :except=>:message_settings
  filter_access_to [:message_settings]
  
  def index
    @message_threads = MessageThread.for_user(@current_user).paginate(:page =>params[:page], :per_page => 10)
    @thread = params[:thread_id].present? ? MessageThread.find(params[:thread_id]) : (@message_threads.present? ? @message_threads.first : nil) 
    if @thread
      @thread_id = @thread.id 
      get_messages(@thread)
      mark_read @thread if params[:thread_id].present?
    end
    respond_to do |format|
      format.html {}
      format.js { render :action => 'index_a' }
    end
  end
  
  def new
    @message_thread = MessageThread.new
    @msgs=@message_thread.messages.build
    @msgs.message_attachments.build    
    respond_to do |format|
      format.js { render :action => 'new_form' }
    end
  end
  
  def show_message_box
    render :update do |page|
      page.replace_html 'message_cont', :partial => 'layouts/messages', :locals => {:messages_count => @current_user.unread_messages_count}
    end
  end
  
  def update_message_scroll
    @thread = MessageThread.find params[:thread_id]
    if params[:type].present? and params[:type] == 'broadcast_resp'
      @messages = @thread.load_sub_thread(params[:recipient_id],@current_user.id).paginate(:page => params[:page], :per_page => 10).reverse
      @sub_thread = true if @messages.present?
      @recipient_id = params[:recipient_id]
    else
      @messages = @thread.active_messages(:order=>'created_at desc').paginate(:page => params[:page], :per_page => 10).reverse
    end
    respond_to do |format|
      format.html {}
      format.js { render :action => 'message_update_scroll' }
    end
  end
  
  def create
    @message_thread = MessageThread.new(params[:message_thread])
    attach_arr = []
    @message_attachments_attributes = @message_thread.messages.first.try(:message_attachments_attributes)
    if @message_attachments_attributes.present?
      @message_attachments_attributes.each_pair do |att_id,attachment|
        attach_arr << attachment_valid?(attachment)              
      end
    end
    @attachment_valid = attach_arr.include?( false )
    if (@attachment_valid == false) and @message_thread.save  
        flash[:notice]=t('reminder.flash1') 
        render :js => "window.location = '/messages?thread_id=#{@message_thread.id}'"        
    else
        flash[:notice]="Cannot be saved "
        render :update do |page|
          page.replace_html 'new_message_container', :partial => 'new'
          render :js => "MakeMessageBox()"
        end                 
    end
    
  end
  
  def create_message
    @msg = Message.new(params[:message])
    attach_arr = []   
    @message_attachments_attributes = @msg.try(:message_attachments_attributes)
    if @message_attachments_attributes.present?
      @message_attachments_attributes.each_pair do |att_id,attachment|
        attach_arr << attachment_valid?(attachment)
      end 
    end  
    @attachment_valid = attach_arr.include?( false )
    if (@attachment_valid == false) and @msg.save
      @msg.reload
      @thread = @msg.message_thread
      @thread.touch        
    end   
    render :partial => 'message_strip'        
   end               
  
  def update_thread
    @message_threads = MessageThread.apply_filter(params[:filter]).paginate(:page => params[:page], :per_page => 10, 
      :order=>'message_threads.created_at')
    @thread = @message_threads.first
    if @thread
      get_messages(@thread)
      @thread_id = @thread.id
    end
    @filter = params[:filter]
    if params[:page].present?
      render :action => 'index_a'
    else
      refresh_page
    end
  end
  
  def update_recipients
    @thread = MessageThread.find params[:thread_id]
    @recipients = @thread.group_recipients(params[:page])
    render :action => 'recipient_update'
  end
  
  def apply_actions
    action = params[:act]
    if action == 'delete'
      begin
        @thread = MessageThread.find params[:thread_id] if params[:thread_id].present?
        if params[:options].present? and params[:options] == 'hard'
          @thread.destroy
          render :text=> "success_hard"
        else
          if params[:type].present? and params[:type]=='broadcast_resp'
            @thread.delete_sub_thread_for(@current_user,params[:recipient_id])
          else
            @thread.delete_for @current_user if @thread
          end
          render :text=> "success"
        end
      rescue ActiveRecord::ActiveRecordError
        render :text=> "failed"
      end
    end
  end
  
  def update_conversation
    @thread = MessageThread.find(params[:thread_id])
    @messages = @thread.active_messages(:order=>'created_at desc').paginate(:page => params[:page], :per_page => 10).reverse
    @thread_id = @thread.id
    build_message
    if params[:type].present? and params[:type] == 'group_update'
      recipient = MessageRecipient.find params[:recipient_id]
      @messages = @thread.load_sub_thread(recipient.recipient_id,@current_user.id).paginate(:page => params[:page], :per_page => 10).reverse
      @sub_thread = true if @messages.present?
      sub_thread_ids = @messages.collect(&:id) if @sub_thread
      @recipient_id = recipient.recipient_id
      @responses = @thread.group_responses
      @recipient_list = true unless @responses.present?
      @recipients_count = @thread.recipients_count
      mark_read_subthread(sub_thread_ids)
      refresh_group_message
    else
      if @thread.is_group_message_for @current_user.id
        @responses = @thread.group_responses
        @recipient_list = true unless @responses.present?
        @recipients_count = @thread.recipients_count
        load_first_response if @responses.present?
        @sub_thread = true if @messages.present?
        refresh_group_message
      else
        @filter = params[:filter]
        @message_threads = @filter.present?  ? 
          (MessageThread.apply_filter(@filter).paginate(:page => params[:page], :per_page => 10, :order=>'message_threads.created_at')) :
          (MessageThread.for_user(@current_user).paginate(:page => params[:page], :per_page => 10, :order=>'message_threads.created_at'))
        if @thread.is_group_message
          @messages = @thread.load_sub_thread(@thread.creator_id,@current_user.id).paginate(:page => params[:page], :per_page => 10).reverse
          @sub_thread = true if @messages.present?
        end
        @thread_id = params[:thread_id]
        mark_read @thread
        render :update do |page|
          page.replace_html "thread_#{@thread.id}", :partial=>'thread_strip'
          page.replace_html 'message_conversation' ,:partial=>'conversations'
          if @current_user.unread_messages_count > 0
            page.replace_html 'msg-coun', :text=>@current_user.unread_messages_count
            page.replace_html 'unread_count_thread', :text=>"#{@current_user.unread_messages_count} Unread"
          else
            page.replace_html 'message-link-img', :text=>''
          end
        end
      end
    end
  end
  
  def switch_tabs
    context = params[:section]
    @thread = MessageThread.find params[:thread_id]
    build_message
    if context == 'response'
      @responses = @thread.group_responses
      load_first_response if @responses.present?
      render :update do |page|
        page.replace_html 'thread_listing_main', :partial =>'responses'                                               
        page.replace_html 'message_conversation' ,:partial=>'group_conversations'
      end
    else
      @recipients = @thread.group_recipients
      @recipient_list = true
      @messages = @thread.broadcast_messages.paginate(:page => params[:page], :per_page => 10)
      @sub_thread = true if @messages.present?
      render :update do |page|
        page.replace_html 'thread_listing_main', :partial =>'recipients'
        page.replace_html 'message_conversation' ,:partial=>'group_conversations'
      end
    end
  end
  
  def create_broadcast
    @user = current_user
    if request.post?
      @message_thread=MessageThread.new(params[:message_thread])
      @batch = params[:select_batch][:batch] if params[:select_batch]
      @parent_batch = params[:select_parents_batch][:batch] if params[:select_parents_batch]
      @dept = params[:select_department][:department] if params[:select_department]
      recipients=params[:recipients_employees]+params[:recipients_students]+params[:recipients_parents]
      is_valid=@message_thread.valid?
      if recipients.blank?
        is_valid = false
        @message_thread.errors.add(:recipients_presence,"#{t('select_recipient')}")
      end
      @message_attachment_attributes=@message_thread.messages.first.try(:message_attachments_attributes)
      if @message_attachment_attributes.present?
        @message_attachment_attributes.each_pair do |att_id,attachment|
            unless attachment_valid?(attachment)
                is_valid = false
                @message_thread.errors.add(:attachment_support,"#{t('attachment_not_supporting')}")
            end
        end
      end   
      
      if is_valid
        recipients_array =[]
        recipients_array += comma_string_to_integer_array(params[:recipients_employees])
        recipients_array += comma_string_to_integer_array(params[:recipients_students])
        student_ids=comma_string_to_integer_array(params[:recipients_parents])
        recipients_array+=get_parent_ids_from_student_ids(student_ids)
        @message_thread.messages.first.recipient_list = recipients_array
        @message_thread.save
      end
      if @message_thread.errors.empty?  
        Delayed::Job.enqueue(
          DelayedMessageThreadJob.new(
            :thread_id=> @message_thread.id,
            :recipient_ids => recipients_array,
            :attachment => params[:attachments]
          ),
          {:queue=> "messages"}
        )
        
        respond_to do |format|
          flash[:notice]=t('broadcast_will_be_generated');
          format.js  {
            render :update do |page|
                page.redirect_to :controller => "messages", :action => "create_broadcast"
            end
          }
          format.html {
          redirect_to :back    
          }
        end
        
      else
        get_departments_batches_and_parents()
        retain_selected_recipients()
        @message_thread.build_messages        

      end
    else
      @message_thread=MessageThread.new
      @message_thread.build_messages
      get_departments_batches_and_parents()
    end
  end
  
  def render_messages
    @message_thread = MessageThread.new
    @message_thread.build_messages
    render :update do |page|
      page.replace_html 'messages_leg', :partial => 'layouts/messages', :object =>@message_thread
    end
  end
  
  def message_settings
    @employee_permissions = MessageSetting.get_permissions('employee').config_value || []
    @student_permissions = MessageSetting.get_permissions('student').config_value || []
    @parent_permissions = MessageSetting.get_permissions('parent').config_value || []
    @administrator_permissions = MessageSetting.get_permissions('administrator').config_value  || []
    if request.post?
      e_p = params[:employee_permissions].keys if params[:employee_permissions]
      s_p = params[:student_permissions].keys if params[:student_permissions]
      p_p = params[:parent_permissions].keys if params[:parent_permissions]
      a_p = params[:administrator_permissions].keys if params[:administrator_permissions]
      MessageSetting.update_permissions(:employee_permissions=>e_p,:student_permissions=>s_p,:parent_permissions=>p_p,:administrator_permissions=>a_p)
      flash[:notice]= "#{t('message')} #{t('settings')} #{t('saved')}"
      redirect_to :action=>'message_settings'
    end
  end
  
  def to_employees
    if params[:dept_id] == ""
      render :update do |page|
        page.replace_html "to_employees", :text => ""
      end
      return
    end
    @to_employees = MessageThread.get_employees(params[:dept_id],@current_user)
    @to_employees.delete @current_user.id
    @to_all_employees = (params[:dept_id] == 'all')
    render :update do |page|
      if @to_all_employees
        page.replace_html 'to_employees', :text=>''
        page.replace_html 'recipient-list', :partial => 'recipient_list_all_employees', :object => [@to_all_employees,@to_employees]
      else
        page.replace_html 'to_employees', :partial => 'to_employees', :object => @to_employees
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
    @to_students = MessageThread.get_students(params[:batch_id],@current_user)
    @to_students.delete @current_user.id
    @to_all_students = (params[:batch_id] == 'all')
    render :update do |page|
      if @to_all_students
        page.replace_html 'to_students', :text=>''
        page.replace_html 'recipient-list1', :partial => 'recipient_list_all_students', :object => [@to_all_students,@to_students]
      else
        page.replace_html 'to_students', :partial => 'to_students', :object => @to_students
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
    @to_parents = MessageThread.get_parents(params[:batch_id],@current_user)
    @to_parents.delete @current_user.id
    @to_all_parents = (params[:batch_id] == 'all')
    render :update do |page|
      if @to_all_parents
        page.replace_html 'to_parents', :text=>''
        page.replace_html 'recipient-list2', :partial => 'recipient_list_all_parents', :object => [@to_all_parents,@to_parents]
      else
        page.replace_html 'to_parents', :partial => 'to_parents', :object => @to_parents
      end
    end
  end
  
  def update_recipient_list
    if params[:recipients_employees]
      recipients_array = params[:recipients_employees].split(",").collect{ |s| s.to_i }
      @recipients_employees = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list', :partial => 'recipient_list_employees'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end
  
  def update_recipient_list1
    if params[:recipients_students]
      recipients_array = params[:recipients_students].split(",").collect{ |s| s.to_i }
      @recipients_students = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list1', :partial => 'recipient_list_students'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end
  
  def update_recipient_list2
    if params[:recipients_parents]
      recipients_array = params[:recipients_parents].split(",").collect{ |s| s.to_i }
      @recipients_parents = User.active.find_all_by_id(recipients_array).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list2', :partial => 'recipient_list_parents'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end
  
  def recipient_search_autocomplete
    query = params[:query]
    unless query.include? "_"
      @students,@employees,@admins = search_recipients(query)
    end
    render :partial => "search_ajax"
  end
  
  def check_parent
    get_students_and_parents
    render :update do |page|
      if @student_ids.include? params[:student_id].to_i and @parent_ids.include? params[:student_id].to_i
        page.replace_html 'parent_select', :partial => 'parent_select', :locals => {:type => 'normal'}
      elsif !@student_ids.include? params[:student_id].to_i and @parent_ids.include? params[:student_id].to_i
        page.replace_html 'parent_select', :partial => 'parent_select', :locals=> {:type=>'only_parent'}
      else
        page.replace_html 'parent_select', :text => ''
      end
    end
  end
  
  private
  
  def get_permissions(user)
    MessageSetting.get_permissions(user.user_type.downcase).try(:config_value)
  end
  
  def get_name_board(name,tag,label)
    "<div class='name_board'>"+label+"<div class='name_and_tag'><div class='entity_name'>"+name+"</div><div class='tag_line'>"+tag+"</div></div></div>"
  end
  
  def mark_read(thread)
    message_ids = thread.message_ids
    MessageRecipient.update_all("is_read = true", ['message_id in (?) and is_read = ? and recipient_id = ?',message_ids,false, @current_user.id])
  end
  
  def mark_read_subthread(message_ids)
    MessageRecipient.update_all("is_read = true", ['message_id in (?) and is_read = ? and recipient_id = ?',message_ids,false, @current_user.id])
  end
  
  def comma_string_to_integer_array(string)
    return [] if string.nil?
    return string.split(',').map { |char| char.to_i}
  end
  
  def get_departments_batches_and_parents
    @user=current_user
    @departments,@batches,@parents_for_batch = Message.get_departments_batches_and_parents(@user)
  end
  
  def get_students_and_parents
    @student_ids = MessageThread.get_students('all',@current_user)
    @parent_ids  = MessageThread.get_parents('all',@current_user)
  end
  
  def retain_selected_recipients
    recipients_array=[]
    if params[:select_department] and params[:select_department][:department] == 'all'
      @to_employees = MessageThread.get_employees('all',@current_user)
      @to_employees.delete nil
      @to_all_employees = true
    else
      unless params[:recipients_employees].blank?
        recipients_array += params[:recipients_employees].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
        @recipients_employees = User.active.find(params[:recipients_employees].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },
          :order=>"first_name ASC")
      end
    end
    if params[:select_parents_batch] and params[:select_parents_batch][:batch] == 'all'
      @to_parents = MessageThread.get_parents('all',@current_user)
      @to_parents.delete nil
      @to_all_parents = true
    else
      unless params[:recipients_parents].blank?
        recipients_array += params[:recipients_parents].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
        @recipients_parents = User.active.find(params[:recipients_parents].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },
          :order=>"first_name ASC")
      end
    end
    if params[:select_batch] and params[:select_batch][:batch] == 'all'
      @to_students = MessageThread.get_students('all',@current_user)
      @to_students.delete nil
      @to_all_students = true
    else
      unless params[:recipients_students].blank?
        recipients_array += params[:recipients_students].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i }
        @recipients_students = User.active.find(params[:recipients_students].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },
          :order=>"first_name ASC")
      end
    end
  end
  
  def get_parent_ids_from_student_ids(student_ids)
    students=Student.find(:all,:conditions=>["user_id in (?)",student_ids])
    parent_ids=[]
    students.each do |student|
      parent_ids<<student.immediate_contact.user_id unless student.immediate_contact.nil?
    end
    return parent_ids
  end
  
  def render_message_box
    respond_to do |format|
      format.html {}
      format.js { render :action => 'message_box' }
    end
  end
  
  
  def refresh_group_message
    render :update do |page|
      page.replace_html 'message_threads', :partial =>'group_threads' if @responses.present?
      page.replace_html 'message_conversation' ,:partial=>'group_conversations'
    end
  end
  
  def refresh_page
    render :update do |page|
      page.replace_html 'message_threads' ,:partial=>'threads'
      if @thread.present?
        if @thread.is_group_message
          page.replace_html 'message_conversation' ,:partial=>'group_conversations'
        else
          page.replace_html 'message_conversation' ,:partial=>'conversations'
        end
      else
        page.replace_html 'message_conversation' ,:text=>''
      end
    end
  end
  
  def check_permission_for_broadcast
    status = true
    if @current_user.parent? or @current_user.student?
      status = false
    else
      status = @current_user.can_message?
    end
    unless status
      flash[:notice] = "#{t('flash_msg4')} ."
      redirect_to :controller=>:user ,:action=>:dashboard and return
    end
  end
  
  def include_for_thread
    MessageThread.include_for_thread
  end
  
  def get_messages(thread)
    @recipient_only_gt = @thread.recipient_only_thread?
    if thread.is_group_message and !thread.is_group_message_for(@current_user.id)
      @messages = thread.load_sub_thread(thread.creator_id,@current_user.id).paginate(:page => params[:page], :per_page => 10).reverse
      @sub_thread = true if @messages.present?
    else
      @messages = thread.active_messages(:order=>'created_at desc').paginate(:page => params[:page], :per_page => 10).reverse unless thread.is_group_message
    end
    if @recipient_only_gt
      @recipients_count = @thread.recipients_count
      @recipient_list = true
      @messages = @thread.broadcast_messages.paginate(:page => params[:page], :per_page => 10)
      @sub_thread = true
    end
    build_message
  end
  
  def load_first_response
    @recipient_id = @responses.first.recipient_id
    @messages = @thread.load_sub_thread(@recipient_id,@current_user.id).paginate(:page => params[:page], :per_page => 10).reverse
    mark_read_subthread(@messages.collect(&:id))
    @sub_thread = true if @messages
  end
  
  def build_message
    @message = @thread.present? ?  @thread.messages.new() : Message.new
    @message.build_child
  end
  
  def get_recipients
    @recipient_list = true unless @responses.present?
    @recipients_count = @thread.recipients_count
  end
  
  def search_recipients(query)
    MessageSetting.search_recipients(query,@current_user)
  end
  
  def attachment_valid?(params)
    MessageAttachment.is_valid(params)
  end
  
end
