class SchoolGroupUser < ActiveRecord::Base
  belongs_to :school_group
  belongs_to :admin_user
  belongs_to :multi_school_group , :foreign_key=>:school_group_id
  belongs_to :multi_school_admin , :foreign_key=>:admin_user_id, :dependent=>:destroy
  accepts_nested_attributes_for :multi_school_admin
end
