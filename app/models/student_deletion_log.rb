class StudentDeletionLog < ActiveRecord::Base
  serialize :dependency_messages
end
