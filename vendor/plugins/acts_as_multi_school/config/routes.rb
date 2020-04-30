ActionController::Routing::Routes.draw do |map|
  map.resources :school_stats,:collection=>{:list_live_entities=>[:get,:post],:modify_user_live_entities=>[:post],:live_statistics_ajax=>[:get],:live_statistics_attendance=>[:get],:dashboard=>[:get],:bookmark=>[:post],:bookmark_paginate=>[:get,:post]},:member=>{:bookmark_destroy=>[:get]}
  map.school_statistics_live '/schools/statistics/live_statistics', :controller=>:school_stats, :action=>:live_statistics
  map.school_statistics_live_report '/schools/statistics/live/*stat_path', :controller=>:school_stats, :action=>:live_statistics_report
  map.school_statistics '/schools/statistics/:section/*stat_path', :controller=>:school_stats, :action=>:statistics
  map.resources :schools,:member=>{:add_domain=>:post,:delete_domain=>:get, :make_domain_primary=>:post, :profile=>:get,:domain=>:get, :admin_login => :get}, :collection=>{:search=>:get} do |school|
    school.resource :available_plugin, :member=>{:plugin_list=>:get}
    school.resources :payment_gateways, :only=>[:index,:show], :collection=>{:assign_gateways=>[:get,:post]}
    school.resources :sms_packages,:collection=>{:package_list=>:get},:member=>{:edit_assigned=>[:get,:put],:remove_package=>[:get,:post]}
  end
  map.login_admin_users '/login', :controller=>:admin_users, :action=>:login
  map.logout_admin_users '/logout', :controller=>:admin_users, :action=>:logout
  map.forgot_password_admin_users '/forgot_password', :controller=>:admin_users, :action=>:forgot_password
  map.resources :admin_users,:except=>[:index], :collection=>{:find_stats=>[:get,:post],:update_details=>[:get,:post],:install_updates=>[:get,:post]}, :member=>{:change_password=>[:get, :put],:profile=>:get,:reset_password=>[:get,:post],:set_new_password=>[:get,:post]}

  map.resources :multi_school_groups,:member=>{:edit_profile=>[:get,:put],:add_domain=>:post,:delete_domain=>:get,:domain=>:get, :assign_plugins=>[:get,:post], :plugin_list=>:get,:profile=>:get, :assign_schools=>[:get,:put]} do |msg|
    msg.resource :available_plugin, :member=>{:plugin_list=>:get}
    msg.resources :admin_users, :only=>[:index]
    msg.resources :payment_gateways,:collection=>{:assign_gateways=>[:get,:post]}
    msg.resources :sms_packages,:member=>{:assigned_list=>:get,:assign_package=>[:get,:post],:edit_assigned=>[:get,:put],:remove_package=>[:get,:post]},:collection=>{:package_list=>:get}
    msg.resources :schools, :only=>[], :collection=>{:list_schools=>:get}
  end

#  map.resources :payment_gateways,:collection=>{:assign_gateways=>[:get,:post]}

  map.resource :additional_setting, :path_prefix=>':owner_type/:owner_id/:type', :member=>{:settings_list=>:get,:check_smtp_settings=>[:get,:post]},:except => [:show]
  map.resource :plugin_setting, :only=>[],:collection=>{:settings=>[:get,:post]}
  
  map.resources :support_engines, :only=>[] ,:member=>{:task_list=>[:get,:post], :view_log=>[:get,:post]}, :collection=>{:task_details=>[:get,:post], :task_status=>[:get,:post], :verify_task=>[:get,:post], :run_task=>[:get,:post]}
  map.resources :gradebook_templates, :only => [:index], :collection=> {:reset => :post, :activate => :post}
end
