class GroupPostComment < ActiveRecord::Base
  belongs_to :group_post
  belongs_to :user
  
  validates_presence_of :comment_body, :message => :is_empty
end
