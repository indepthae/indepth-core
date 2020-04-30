ActionController::Routing::Routes.draw do |map|
  
    map.resources :tasks,:member=>{:download_attachment=>:get} do |tasks|
      tasks.resources :task_comments,:member=>{:download_attachment=>:get}
  
  end
end
