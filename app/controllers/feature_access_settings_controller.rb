class FeatureAccessSettingsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    unless FeatureAccessSetting.all.present?
      FeatureAccessSetting.initialize_settings()
    end
    @features = FeatureAccessSetting.all
  end
  
  def create
    @result = FeatureAccessSetting.save_settings(params[:feature_access_settings][:field_info])
    unless @result.blank?
      @errors=true
      render(:update) do |page|
        page.replace_html   'form-errors', :partial=>"errors"
      end
    else
      render(:update) do |page|
        page.replace_html   'form-errors', :text=>"<p class='flash-msg'> #{t('feature_settings_saved')}</p>"
      end
    end
  end
  
end
