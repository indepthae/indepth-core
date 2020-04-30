class UserGroupsUser < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :user_group
  belongs_to :member, :polymorphic => true
  
  named_scope :is_student,:conditions => {:target_type => "student"}
  named_scope :is_employee,:conditions => {:target_type => "employee"}
  named_scope :is_parent,:conditions => {:target_type => "parent"}
  

end  
