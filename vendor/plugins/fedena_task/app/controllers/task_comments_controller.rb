class TaskCommentsController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:except => [:download_attachment]
  filter_access_to [:download_attachment],:attribute_check => true, :load_method => lambda { current_user.parent? ? (current_user.guardian_entry.current_ward.user) : (current_user) }

  def download_attachment
    @comment = TaskComment.find(params[:id])
    if current_user.parent?
      if @comment.can_be_downloaded_by?(current_user.guardian_entry.current_ward.user)
        send_file (@comment.attachment.path)
      else
        flash[:notice] = "#{t('no_permission_to_download_file')}"
        redirect_to tasks_path
      end
    else
      if @comment.can_be_downloaded_by?(current_user)
        send_file (@comment.attachment.path)
      else
        flash[:notice] = "#{t('no_permission_to_download_file')}"
        redirect_to tasks_path
      end
    end
  end

  def create
    @task_comment = TaskComment.new(params[:task_comment])
    @task_comment.user = current_user
    # @task = @task_comment.task
    begin
#      @task = (current_user.assigned_tasks+current_user.tasks).find(@task_comment.task_id).first
      @task = (current_user.assigned_tasks+current_user.tasks).detect{|e| e.id == @task_comment.task_id}
    rescue ActiveRecord::RecordNotFound => e
      flash[:notice] = "#{t('flash_msg4')} ."
      logger.info "[FedenaRescue] AR-Record_Not_Found #{e.to_s}"
      log_error e
      redirect_to :controller=>:user ,:action=>:dashboard and return
    end
    if @task_comment.save
      flash[:notice]="#{t('update_creation_successful')}"
      redirect_to task_path(:id=>@task)
    else
      @comments = @task.task_comments
      render 'tasks/show'
    end
  end

  def destroy
    @user = current_user
    @comment = TaskComment.find(params[:id])
    if @comment.can_be_deleted_by?(@user)
      TaskComment.destroy(params[:id])
      flash[:notice] = "#{t('task_comment_deleted_successfully')}"
    end
    render :update do |page|
      page.reload
    end
  end

end
