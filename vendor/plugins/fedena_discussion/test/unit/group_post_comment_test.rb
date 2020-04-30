require File.expand_path(File.dirname(__FILE__) + "./../test_helper")

class GroupPostCommentTest < ActiveSupport::TestCase


  should_belong_to :group_post
  should_belong_to :user
  should_validate_presence_of :comment_body, :message => "is empty"

  context 'masteradmin' do
    setup do
      @masteradmin=Factory.create(:master_admin_user)
      @admin=Factory.create(:admin_user)
      @group = Factory.build(:group)
      @group.members = [@admin]
      @group.save
      @group_post = Factory.build(:group_post)
      @group_post.group = @group
      @group.save
      @comment = Factory.build(:group_post_comment)
    end

    should 'be able to create comment' do
      @comment.user = @masteradmin
      assert @comment.save
    end

  end

    context 'group members ' do
    setup do
      @masteradmin=Factory.create(:master_admin_user)
      @admin=Factory.create(:admin_user)
      @group = Factory.build(:group)
      @group.members = [@admin]
      @group.save
      @group_post = Factory.build(:group_post)
      @group_post.group = @group
      @group.save
      @comment = Factory.build(:group_post_comment)
    end

    should 'be able to comment' do
      @comment.user = @admin
      assert @comment.save
    end

  end




end
