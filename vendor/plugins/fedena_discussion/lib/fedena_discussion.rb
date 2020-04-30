# FedenaDiscussion
require 'dispatcher'
module FedenaDiscussion
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_discussion do
      ::User.instance_eval { include UserExtension }
      ::Student.instance_eval { include StudentExtension }
    end
  end

  def self.dependency_delete(student)
    student.user.groups.destroy_all
    student.user.group_members.destroy_all
  end
  
  module UserExtension
    def self.included(base)
      base.instance_eval do
        has_many :groups, :dependent => :destroy
        has_many :group_members, :dependent => :destroy
        has_many :group_posts
        has_many :group_post_comments
        has_many :group_files
      end
    end
    
    def member_groups
      if self.admin? or self.privileges.include?(Privilege.find_by_name("GroupCreate"))
        groups=Group.all
      else
        group_ids=GroupMember.find(:all, :conditions=>{:user_id=>self.id})
        groups=Group.find(:all,:conditions=>["id IN (?)",group_ids.map{|group| group.group_id}])
      end
    end
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Employee" or record.class.to_s == "Student"
        return true if record.user.group_members.present?
        return true if record.user.groups.present?
        return true if record.user.group_files.present?
        return true if record.user.group_posts.present?
        return true if record.user.group_post_comments.present?
      end
    end
    return false
  end

  module StudentExtension
    def self.included(base)
      base.instance_eval do
        DependencyHook.make_dependency_hook(:fedena_discussion_dependency, :student, :warning_message => :discussion_activity_present ) do
          self.discussion_dependencies
        end
      end
    end

    def discussion_dependencies
      return false if self.user.group_members.present? or self.user.groups.present? or self.user.group_files.present? or self.user.group_posts.present? or self.user.group_post_comments.present?
      return true
    end
  end
end