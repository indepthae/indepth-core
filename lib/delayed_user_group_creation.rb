class DelayedUserGroupCreation
  def initialize(*args)
    opts = args.extract_options!
    @group_id = opts[:group_id]
    @student_ids = opts[:student_ids]
    @employee_ids = opts[:employee_ids]
    @parent_ids = opts[:parent_ids]
    @action = opts[:action]
  end
  
  def perform
    if @action == "create_user_group"
      UserGroup.add_members(@group_id, @student_ids, @employee_ids, @parent_ids)
    elsif @action == "edit_user_group"
      UserGroup.update_members(@group_id, @student_ids, @employee_ids, @parent_ids)
    end  
  end

end