authorization do

  role :own_user_profile do
    has_permission_on :admin_users, :to=>[:show,:change_password,:edit,:update] do
      if_attribute :id => is {user.id}
    end
  end

  role :view_user_profile do
    has_permission_on :admin_users, :to=>[:show, :profile]
  end

  role :view_own_user_profile do
    has_permission_on :admin_users, :to=>[:show,:profile] do
      if_attribute :id => is {user.id}
    end
  end

  role :view_group_users_profile do
    has_permission_on :admin_users, :to=>[:show,:profile] do
      if_attribute :id => is_in {user.school_group.school_group_users.collect(&:admin_user_id)}
    end
  end

  role :manage_additional_settings do
    has_permission_on :additional_settings, :to=>:settings_list
    has_permission_on :additional_settings, :to=>[:new,:create,:edit,:update,:destroy,:check_smtp_settings] do
      if_attribute :owner => is {user.school_group}
      if_attribute :owner => is_in {user.school_group.schools}
      if_attribute :owner => is_in {user.multi_school_groups }
    end
  end

  role :manage_plugin_settings do
    has_permission_on :plugin_settings, :to=>:settings
  end

  role :manage_school do
    has_permission_on :schools,:to=>[:index,:new,:create,:search]
    has_permission_on :schools, :to=>[:show,:profile,:edit,:update,:destroy,:domain,:add_domain,:delete_domain,:make_domain_primary,:show_sms_messages,:show_sms_logs] do
      if_attribute :school_group => is {user.school_group}
    end
  end

  role :school_stats_view do
    has_permission_on :school_stats,:to=>[:live_statistics,:live_statistics_ajax, :live_statistics_attendance,:live_statistics_report,:list_live_entities,:modify_user_live_entities,:statistics,:dashboard,:bookmark_paginate,:bookmark_destroy,:bookmark] do
      if_attribute :school_stats_accessable? => is {true}
    end
  end

  role :manage_gradebook_templates do
    has_permission_on :gradebook_templates, :to=>[:index, :reset, :activate] do
      if_attribute :can_manage_gb_templates? => is {true}
    end
  end

  role :school_login_access do
    has_permission_on :schools, :to => :admin_login do
      if_attribute :self_record => is_in {user.loginable_schools}
      if_attribute :assess_truth => is {user.type == 'MasterSupportUser'}
    end
  end
  
  role :multi_school_admin do
    includes :own_user_profile
    includes :view_group_users_profile
    includes :manage_additional_settings
    includes :manage_school
    includes :manage_plugin_settings
    includes :school_stats_view
    includes :manage_gradebook_templates
    includes :school_login_access
    
    has_permission_on :admin_users, :to=>[:index,:new,:create]
    has_permission_on :admin_users, :to=>[:destroy] do
      if_attribute :higher_user_id => is {user.id}
    end

    has_permission_on :multi_school_groups, :to=>[:show,:profile,:domain,:add_domain,:delete_domain] do
      if_attribute :id => is {user.school_group.id}
    end

    has_permission_on :multi_school_groups, :to=>[:edit_profile] do
      if_attribute :parent_group_id => is {nil}
      if_attribute :id => is {user.school_group.id}
    end

    has_permission_on :payment_gateways, :to=>[:index,:show] do
      if_attribute :self_record => is {user.school_group}
      if_attribute :self_record => is_in {user.school_group.schools}
    end

    has_permission_on :payment_gateways, :to=>[:new,:create,:edit,:update,:destroy] do
      if_attribute :self_record => is {user.school_group}
    end

    has_permission_on :payment_gateways, :to=>[:assign_gateways] do
      if_attribute :self_record => is_in {user.school_group.schools}
    end

    has_permission_on :sms_packages, :to=>[:new,:create,:edit,:update,:destroy,:assigned_list,:assign_package] do
      if_attribute :self_record => is {user.school_group}
    end

    has_permission_on :sms_packages, :to=>[:remove_package] do
      if_attribute :self_record => is_in {user.school_group.schools}
    end

    has_permission_on :sms_packages, :to=>[:edit_assigned,:package_list] do
      if_attribute :self_record => is {user.school_group}
      if_attribute :self_record => is_in {user.school_group.schools}
    end

    has_permission_on :available_plugins, :to=>[:show, :plugin_list] do
      if_attribute :associated => is {user.school_group}
      if_attribute :associated => is_in {user.school_group.schools}
    end
    has_permission_on :available_plugins, :to=>[:new,:create,:edit, :update] do
      if_attribute :associated => is_in {user.school_group.schools}
    end
    
  end
  
  role :master_support_user do
    includes :manage_gradebook_templates
    has_permission_on :support_engines,:to=>[:task_list,:task_details,:task_details,:run_task,:task_status,:view_log]
  end
  
end
