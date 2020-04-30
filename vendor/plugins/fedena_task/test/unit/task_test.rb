require File.expand_path(File.dirname(__FILE__) + './../test_helper')

class TaskTest < ActiveSupport::TestCase
  should_validate_presence_of :title
  should_validate_presence_of :description
  should_validate_presence_of :status
  should_validate_presence_of :due_date

  should_have_many :task_comments
  should_have_many :task_assignees
  should_belong_to :user


  context 'a new task' do
    setup do
      @task = Factory.build(:task)
    end

    should 'be new record' do
      assert @task.new_record?
    end

    should 'be valid' do
      assert @task.valid?
    end

    should 'not save without any data' do
      assert_invalid Task.new
    end

    should 'accept only Assigned as status' do
      status = "Assigned"
      unless @task.status == status
        assert_invalid @task
        assert @task.errors.invalid?(:status)
      end
    end

    should 'not accept past due date' do
      @task.due_date = Date.today - 5.days
      if @task.due_date < Date.today
        assert_invalid @task
        assert @task.errors.invalid?(:due_date)
      end
    end
  end

  context 'a task assigned to a user ' do
    setup do
      @task_creator = Factory(:test_employee01)
      @task_assignee = Factory(:employee_user)
      @another_user = Factory(:admin_user)
      @task = Factory.create(:task,:user=>@task_creator)
      @task.assignees = [@task_assignee]

    end
    should 'be viewable for task creator' do
      assert @task.can_be_viewed_by?(@task_creator)
    end
    should 'be viewable for task assignee' do
      assert @task.can_be_viewed_by?(@task_assignee)
    end
    should 'not be viewable for any other user' do
      assert ! @task.can_be_viewed_by?(@another_user)
    end
    should 'be edited by task creator' do
      assert @task.task_can_be_edited_by?(@task_creator)
    end
    should ' not be edited for task assignee' do
      assert ! @task.task_can_be_edited_by?(@task_assignee)
    end
    should 'not be edited for any other user' do
      assert ! @task.task_can_be_edited_by?(@another_user)
    end
    should 'be downloaded by task creator' do
      assert @task.can_be_downloaded_by?(@task_creator)
    end
    should 'be downloaded by task assignee' do
      assert @task.can_be_downloaded_by?(@task_assignee)
    end
    should 'not be downloaded by any other user' do
      assert ! @task.can_be_downloaded_by?(@another_user)
    end
    should 'be deleted by task creator' do
      assert @task.task_can_be_deleted_by?(@task_creator)
    end
    should 'not be deleted by task assignee' do
      assert ! @task.task_can_be_deleted_by?(@task_assignee)
    end
    should 'not be deleted by any other user' do
      assert ! @task.task_can_be_deleted_by?(@another_user)
    end
  end
end
