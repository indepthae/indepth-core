ActionController::Routing::Routes.draw do |map|
  map.resources :form_builder, :only => [:index]
  map.resources :form_submissions, :only => [:new,:show], :member => {
    :analysis => [:post,:get],
    :consolidated_report => [:post,:get],
    :get_target_analysis => [:post,:get],
    :filter => [:get,:post],
    :download => [:post,:get],
    :form_submissions_csv => [:post,:get],
    :responses => [:post,:get],
    :show => [:get,:post]
  }

  map.resources :form_templates, :except=> [:show],:member => {
    :preview => [:get,:post],
    :add_field => [:get],
    :add_option => [:get,:post],
    :field_settings => [:get,:post],
    :remove_field => [:get]
  }

  map.resources :forms, :only => [:index, :show, :edit, :update, :destroy], :collection => {
    :form_submit => [:get,:post],
    :feedback_forms => [:get,:post],
    :manage => [:get,:post],
    :manage_filter => [:get,:post],
    :new_form_submission => [:get,:post],
    :to_employees => [:get,:post],
    :to_students => [:get,:post],
    :to_target_employees => [:get,:post],
    :to_target_students => [:get,:post],
    :update_member_list => [:get,:post],
    :update_target_list => [:get,:post]
  }, :member => {
    :close => [:post],
    :preview => [:get,:post],
    :edit_response => [:get,:post],
    :publish => [:get,:post],
    :update_response => [:get,:post]
  }
end