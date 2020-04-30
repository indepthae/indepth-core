require File.expand_path(File.dirname(__FILE__) + "./../test_helper")

class GroupPostTest < ActiveSupport::TestCase

  should_belong_to :group
  should_belong_to :user
  should_have_many :group_post_comments, :dependent => :destroy
  should_have_many :group_files, :dependent => :destroy
  should_validate_presence_of :post_title, :message => " can't be blank "
  should_ensure_length_in_range :post_title, (0..30)
  should_validate_presence_of :post_body, :message => " can't be blank "
  

  context 'masteradmin' do
    setup do
      @masteradmin=Factory.create(:master_admin_user)
      @admin=Factory.create(:admin_user)
      @group = Factory.build(:group)
      @group.members = [@admin]
      @group.save
      @group_post = Factory.build(:group_post)
      @group_post.group = @group
    end

    should 'be able to create post' do
      @group_post.user = @masteradmin
      assert @group_post.save
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
    end

    should 'be able to create post ' do
      @group_post.user = @admin
      assert @group_post.save
    end

#    should ' be notified after post ' do
#      @group_post.user = @masteradmin
#      @group_post.save
#      Thread.current[:current_school_id] = @admin.school_id
#      assert @admin.check_reminders==2
#    end
  end
 
end
