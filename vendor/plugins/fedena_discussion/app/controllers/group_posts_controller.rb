class GroupPostsController < ApplicationController
  before_filter :login_required
  before_filter :load_group_post,:only=>[:destroy,:show,:list_post_comments]
  filter_access_to :create,:attribute_check => true,:load_method => lambda { Group.find(params[:group_id]) }
  filter_access_to :destroy,:attribute_check => true,:load_method => lambda { GroupPost.find(params[:id]) }
  def create
    @group=Group.find(params[:group_id])
    @new_post=@group.group_posts.build(params[:group_post])
    @new_post.user_id=current_user.id
    if @new_post.save
      flash[:notice] = t('post_created')
      redirect_to :controller=>"group_posts", :action => "show", :id=>@new_post.id
    else
      @group_posts=@group.group_posts.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 7)
      if params[:group_post][:group_files_attributes].nil?
        @file=@new_post.group_files.build
      end

      render "groups/show"
    end
  end

  def destroy
    # if @group_post.user_id == current_user.id or @group_post.group.user_id == current_user.id or current_user.admin?
    GroupPost.find(params[:id]).destroy
    flash[:notice] = t('post_deleted')
    redirect_to group_path(:id=>@group_post.group) and return
  end

  def show
    if(current_user.admin?  or current_user.member_groups.map{|group| group.id}.include?(@group_post.group.id))
      @group_post_comments = @group_post.group_post_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
      @group_post_comment=@group_post.group_post_comments.build
    else
      flash[:notice] = t('no_permission')
      redirect_to :action=>'index', :controller=>"groups"
    end
  end

  def download_attachment
    if params[:style].to_s == "small"
      file=GroupFile.find(params[:id])
      send_data File.read(file.doc.path(:small)), :type => file.doc_content_type, :disposition => 'inline'
    else
      file=GroupFile.find(params[:id])
      send_file file.doc.path, :type => file.doc_content_type, :disposition => 'inline'
    end
  end

  def show_image
    file=GroupFile.find(params[:id])
    send_data File.read(file.doc.path(:small)), :type => file.doc_content_type, :disposition => 'inline'
  end

  def list_post_comments
    @group_post_comments = @group_post.group_post_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
    render :update do |page|
      page.replace_html 'ajax', :partial=>"group_posts/comments",:locals=>{:group_post_comments=>@group_post_comments, :group_post=>@group_post}
    end
  end


  private
  def load_group_post
    @group_post = GroupPost.find(params[:id])
  end
end
