class PluginSettingsController < MultiSchoolController
  filter_access_to :all
  def settings
    @av_plugin = admin_user_session.allowed_plugins
    if @av_plugin.present?
      unless (@av_plugin.include?("fedena_google_sso") or @av_plugin.include?("fedena_azure"))
        flash[:notice] = "Sorry, you are not allowed to access that page."
        redirect_to admin_user_session.school_group
      end
    else
      flash[:notice] = "Sorry, you are not allowed to access that page."
      redirect_to admin_user_session.school_group
    end
  end
end
