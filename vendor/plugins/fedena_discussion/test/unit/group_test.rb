require File.expand_path(File.dirname(__FILE__) + "./../test_helper")

class GroupTest < ActiveSupport::TestCase

  should_belong_to :user
  should_have_many :group_members, :dependent => :destroy
  should_have_many :group_posts
  should_have_many :members
  should_validate_presence_of :group_name, :message => " is required."
  should_ensure_length_in_range :group_name, (0..30)



  context 'a new group' do
    setup do
      @masteradmin=Factory.create(:master_admin_user)
      @admin=Factory.create(:admin_user)
      @group = Factory.build(:group)
      @group.user = @masteradmin
      @group.members = [@admin]
    end

    should ' no save without any values' do
      assert_invalid Group.new
    end

    should ' be valid' do
      assert @group.valid?
    end
  end

  context 'masteradmin' do
    setup do
      @masteradmin=Factory.create(:master_admin_user)
      @admin=Factory.create(:admin_user)
      @group = Factory.build(:group)
      @group.user = @masteradmin
      @group.members = [@admin]
    end
    
    should ' be able to create group - masteradmin' do
      assert @group.save
    end

    should ' be the group admin after creation' do
      @group.save
      assert @group.group_members.find(:first,:conditions=>"user_id = #{@masteradmin.id}").is_admin?
    end
    
  end

  context 'admin' do
    setup do
      @masteradmin=Factory.create(:master_admin_user)
      @admin=Factory.create(:admin_user)
      @group = Factory.build(:group)
      @group.user = @admin
      @group.members = [@admin]
    end

    should ' be able to create post - admin' do
      assert @group.save
    end
  end


  context 'groupadmin' do
    setup do
      @masteradmin=Factory.create(:master_admin_user)
      @admin=Factory.create(:admin_user)
      @group = Factory.build(:group)
      @group.user = @masteradmin
      @group.members = [@admin]
    end

    should ' must be the group creator by default' do
      @group.save
      assert @group.group_members.find(:first,:conditions=>"user_id = #{@masteradmin.id}").is_admin?
    end
  end

  context 'groupmember' do
    setup do
      @masteradmin=Factory.create(:master_admin_user)
      @admin=Factory.create(:admin_user)
      @group = Factory.build(:group)
      @group.user = @masteradmin
      @group.members = [@admin]
    end

#    should 'recieve a message ' do
#      @group.save
#      Thread.current[:current_school_id] = @admin.school_id
#      assert @admin.check_reminders==1
#    end
  end

    
end
