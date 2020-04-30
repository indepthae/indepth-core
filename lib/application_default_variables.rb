module ApplicationDefaultVariables
  def self.included(base)
    base.class_eval do
      before_filter :set_host
    end
  end

  def set_host
    Fedena.present_user=current_user
    Fedena.present_student_id=session[:student_id]
    Fedena.hostname="#{request.protocol}#{request.host_with_port}"
    Fedena.rtl=RTL_LANGUAGES.include? I18n.locale.to_sym
    config = Configuration.get_sort_order_config_value
    Fedena.sort_order_config = config.config_value
  end
end