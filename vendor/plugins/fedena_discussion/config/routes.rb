ActionController::Routing::Routes.draw do |map|

  map.resources :groups, :member=>{:switch_between_admin_and_normal=>[:get,:post],:members=>[:get,:post]}, :collection=>{ :index=>:get,:recent_posts=>[:get,:post]} do |group|
    group.resources :group_posts, :except=>[:index], :member=>{:member_destroy=>[:get,:post],:show_image=>[:get,:post], :file_destroy=>[:get,:post], :download_attachment=>[:get,:post]} do |group_post|
      group_post.resources :group_post_comments,:member=>{:more=>:post, :destroy=>:post }
    end
  end
end
