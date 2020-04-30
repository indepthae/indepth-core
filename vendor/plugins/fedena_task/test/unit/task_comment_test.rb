require File.expand_path(File.dirname(__FILE__) + './../test_helper')

class TaskCommentTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  should_validate_presence_of :description
  should_validate_presence_of :user_id
  should_validate_presence_of :task_id

  should_belong_to :task
  should_belong_to :user


  context 'a new comment' do
    setup do
      @task_comment = Factory.build(:task_comment)
    end

    should 'be new record' do
      assert @task_comment.new_record? 
    end

    should 'be valid' do
      assert @task_comment.valid?
    end

    should 'not save without any data' do
      assert_invalid TaskComment.new
    end

    should 'not save task without description' do
      @task_comment.description = nil
      assert_invalid @task_comment
    end

    context 'a comment submited by a user to a task' do
      setup do
        @task_creator = Factory(:test_employee01)
        @task_assignee1 = Factory(:employee_user)
        @task_comment_creator = @task_assignee1
        @another_user = Factory(:admin_user)

        @task = Factory.create(:task,:user=>@task_creator)
        @task.assignees = [@task_assignee1,@task_creator]

        @task_comment = Factory.create(:task_comment,:user=>@task_comment_creator,:task=>@task)
      end
      should 'be downloadable for task assignee' do
        assert @task_comment.can_be_downloaded_by?(@task_assignee1)
      end
      should 'be downloadable for task creator' do
        assert @task_comment.can_be_downloaded_by?(@task_creator)
      end
      should 'be downloadable for comment creator' do
        assert @task_comment.can_be_downloaded_by?(@task_comment_creator)
      end
      should 'not be downloadable for any other user' do
        assert ! @task_comment.can_be_downloaded_by?(@another_user)
      end
      should 'be deletable for task creator' do
        assert @task_comment.can_be_deleted_by?(@task_creator)
      end

      should 'be deletable for comment creator' do
        assert @task_comment.can_be_deleted_by?(@task_comment_creator)
      end
      should 'not be deletable for task assignee' do
        assert ! @task.task_can_be_deleted_by?(@task_assignee)
      end
      should 'not be deletable for other user' do
        assert ! @task_comment.can_be_deleted_by?(@another_user)
      end
    end
  end
end