require File.expand_path(File.dirname(__FILE__) + "./../test_helper")

class GroupsControllerTest < ActionController::TestCase

  context 'user not logged in ' do
    should 'be redirected to login' do
      get :index,{:school_id=>0}
      assert_redirected_to root_url
    end
  end

  context 'masteradmin' do
    setup do
      @masteradmin = Factory.create(:master_admin_user)
      @admin = Factory.create(:admin_user)
      login_as @masteradmin
      @group = Factory.build(:group)
      @group.user = @masteradmin
      @group.save
    end

    should 'render index' do
      get :index,{:school_id=>0}
      assert_response :success
      assert_template :index
    end

    should 'render new' do
      get :new,{:school_id=>0}
      assert_response :success
      assert_template :new
      assert_template :partial=>"depts_and_courses"
    end

    should 'render edit' do
      get :edit,{:school_id=>0,:id=>@group.id}
      assert_response :success
      assert_template :edit
    end

 
  end


end
