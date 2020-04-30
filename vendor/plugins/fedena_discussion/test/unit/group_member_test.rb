require 'test_helper'

class GroupMemberTest < ActiveSupport::TestCase

  should_belong_to :group
  should_belong_to :user

end
