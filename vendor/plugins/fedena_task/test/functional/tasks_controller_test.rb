require 'test_helper'

class TasksControllerTest < ActionController::TestCase
  context 'with user logged in' do
    setup do
      @user = Factory.create(:test_employee01)
      @another_user = Factory.create(:employee_user)
      @user.privileges << Factory.create(:privilege)
      login_as @user
      @assignee = Factory.create(:employee_user)
      @task = Factory.create(:task,:user => @user)
        
    end

    should 'render index' do
      get :index
      assert_response :success
      assert_template :index
    end

    should 'render new' do
      get :new, {:user_id => @user.id}
      assert_response :success
      assert_template :new
    end
    
    should 'render edit' do
      get :edit, {:user_id => @user.id,:id =>@task.id}
      assert_response :success
      assert_template :edit
    end
    
    should 'render show' do
      get :show, {:id => @task.id,:user_id => @user.id}
      assert_response :success
      assert_template :show
    end


    should 'redirect to index if correct parameters are give in new form' do
      post :create, {
        :task => Factory.attributes_for(:task),
        :user => @user.id
      }
      assert_redirected_to :action => 'index'
    end

    should 'render new if wrong parameters are give in new form' do
      post :create, {
        :user => @user.id
      }
      assert_template :new
    end

    should 'render edit template if wrong parameters are given in edit form' do
      post :update, { :user=>@user.id,
        :id => @task.id
      }
      assert_template :edit
    end

    should 'redirect to index if correct parameters are give in edit form' do
      post :update, {
        :user => @user.id,
        :id => @task.id,
        :task => Factory.attributes_for(:task)
      }
      assert_redirected_to :action => 'index'
    end

    should 'redirect to index if task is destroyed' do
      delete :show, {
        :id=>@task.id
      }
      assert_redirected_to :action => 'index'
    end

    
  end
end
