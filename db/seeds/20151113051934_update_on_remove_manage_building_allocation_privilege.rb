priv = Privilege.find_by_name('ManageBuildingAndAllocation')
if priv.present?
  if (MultiSchool rescue false)
    user_privileges_sql = "Delete from `privileges_users` where `privilege_id` = #{priv.id}"
    RecordUpdate.connection.execute(user_privileges_sql)
  end
  priv.destroy
end