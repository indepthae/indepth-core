require 'test_helper'

class GroupFileTest < ActiveSupport::TestCase

  should_belong_to :group
  should_belong_to :user
  should_belong_to :group_post
  should_validate_presence_of :doc_file_name

end
