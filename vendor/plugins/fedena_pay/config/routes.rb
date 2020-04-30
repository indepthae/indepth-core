ActionController::Routing::Routes.draw do |map|
  map.resources :online_payments, :controller => "payment_settings",:except=>[:show],:collection => {:transactions => [:get,:post],:settings => [:get,:post],:return_to_fedena_pages => [:get,:post],:show_transaction_details => [:get],:payment_initialize => [:get,:post],:change_gateway => [:get,:post],:initialize_payment => [:get,:post],:complete_payment => [:get]}
  map.feed 'online_payments/', :controller=>'payment_settings',:action=>'index'

  map.resources :custom_gateways, :except=>[:show], :member=>{:manage_accounts=>[:get,:post],:change_financial_year=>[:get,:post],:update_accounts=>[:post]}
  map.resources :student_fees,:member=>{:all_fees=>[:get],:initialize_all_fees_payment=>[:post],:initialize_pay_all_fees=>[:post], :change_gateway => [:get,:post]}
  map.resources :payment_api, :collection=>{:online_transaction_list=>[:get],:transaction_process=>[:get],:reconciliate_single_transaction=>[:get],:reconciliate_transaction=>[:post]}
  map.resources :paytm_payments, :collection => {:get_all_fees_list => :get, :get_all_fees => :get, :pay_student_pending_all_fee => [:post], :pay_student_pending_collection_fee => [:post], :status_check => :get}
  map.process_pay_all_fees 'student_fees/:id/process_pay_all_fees/:identification_token', :controller=>'student_fees',:action=>'procees_pay_all_fees'
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.

end
