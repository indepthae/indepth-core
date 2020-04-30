module DataPalettesHelper
  def include_i18n_calendar_javascript
    cur_lang = I18n.locale.to_s
    loc_path = "#{RAILS_ROOT}/public/javascripts/jquery_datepicker/locale/#{cur_lang}.js"
    if File.exist?(loc_path)
      content_for :head do
        javascript_include_tag "jquery_datepicker/locale/#{cur_lang}.js"
      end
    else
      content_for :head do
        javascript_include_tag "jquery_datepicker/locale/en.js"
      end
    end
  end
end
