class GroupPostCommentsController < ApplicationController
  before_filter :login_required
  filter_access_to :create
  filter_access_to :destroy,:attribute_check => true,:load_method => lambda { GroupPostComment.find(params[:id]) }
  def create
    @group_post=GroupPost.find(params[:group_post_id])
    @group_post_comment=@group_post.group_post_comments.build(params[:group_post_comment])
    @group_post_comment.user_id=current_user.id
    if @group_post_comment.save
      @group_post_comments=@group_post.group_post_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
      respond_to do |format|
        format.html{redirect_to :back}
        format.js
      end
    else
      render(:update) do |page|
        page.replace_html :er, :partial => 'error_msg_display'
      end
    end
  end

  def destroy
    @group_post_comment = GroupPostComment.find(params[:id])
    @group_post=@group_post_comment.group_post
    @group_post_comment.destroy
    @group_post_comments=@group_post.group_post_comments.all(:order=>"updated_at DESC").paginate( :page => params[:page], :per_page => 5)
    respond_to do |format|
      format.html{redirect_to group_post_path(:id=>@group_post_comment.group_post_id)}
      format.js
    end
  end

end
