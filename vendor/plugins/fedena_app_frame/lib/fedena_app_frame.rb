class FedenaAppFrame
  module MenuOverride
    def self.included(base)
      base.alias_method_chain :show_all_features,:app_frames
    end

    def show_all_features_with_app_frames
      link_cat = MenuLinkCategory.find_by_id(params[:cat_id])
      if link_cat.name == "apps"
#        app_links =  Rails.cache.fetch("user_app_links_#{current_user.id}"){
          u_roles = current_user.role_symbols
          allowed_apps = AppFrame.all.select{|a| !(a.privilege_list.map{|s| s.to_sym} & u_roles == [])}
#          allowed_apps
#        }
        render :partial=>"app_frames/app_links", :locals=>{:menu_links=>allowed_apps}
      else
        show_all_features_without_app_frames
      end
    end

  end

end