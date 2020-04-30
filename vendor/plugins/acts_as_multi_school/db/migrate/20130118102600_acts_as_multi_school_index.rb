class ActsAsMultiSchoolIndex < ActiveRecord::Migration
  def self.up
	add_index :school_domains, [:linkable_id,:linkable_type]
	add_index :additional_settings, [:owner_id,:owner_type]
	add_index :additional_settings, [:owner_id, :owner_type, :type], :name=>:index_of_owner_on_setting_type
	add_index :additional_settings, [:id,:type]
	add_index :available_plugins, [:associated_id,:associated_type]
	add_index :admin_users, [:type]
	add_index :admin_users, [:id,:type]
	add_index :admin_users, [:type,:is_deleted]
	add_index :admin_users, [:username]
	add_index :school_groups, [:type]
	add_index :school_groups, [:id,:type]
	add_index :school_groups, [:type,:is_deleted]
	add_index :school_groups, [:type,:parent_group_id]
	add_index :school_groups, [:type,:parent_group_id,:is_deleted], :name=>:index_of_parent_group_on_active_group
	add_index :school_group_users, [:school_group_id]
	add_index :school_group_users, [:admin_user_id]
	add_index :schools, [:school_group_id,:is_deleted]
	add_index :schools, [:is_deleted]
  end

  def self.down
	remove_index :school_domains, [:linkable_id,:linkable_type]
	remove_index :additional_settings, [:owner_id,:owner_type]
	remove_index :additional_settings, [:owner_id, :owner_type, :type]
	remove_index :additional_settings, [:id,:type]
	remove_index :available_plugins, [:associated_id,:associated_type]
	remove_index :admin_users, [:type]
	remove_index :admin_users, [:id,:type]
	remove_index :admin_users, [:type,:is_deleted]
	remove_index :admin_users, [:username]
	remove_index :school_groups, [:type]
	remove_index :school_groups, [:id,:type]
	remove_index :school_groups, [:type,:is_deleted]
	remove_index :school_groups, [:type,:parent_group_id]
	remove_index :school_groups, [:type,:parent_group_id,:is_deleted]
	remove_index :school_group_users, [:school_group_id]
	remove_index :school_group_users, [:admin_user_id]
	remove_index :schools, [:school_group_id,:is_deleted]
	remove_index :schools, [:is_deleted]
  end
end
