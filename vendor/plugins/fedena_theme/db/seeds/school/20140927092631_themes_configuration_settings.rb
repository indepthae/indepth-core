Configuration.find_or_create_by_config_key(:config_key => "EnableTheme" ,:config_value => "1")
cur_theme = Configuration.find_by_config_key("CurrentTheme")
cur_theme.destroy unless cur_theme.nil?
Configuration.find_or_create_by_config_key(:config_key => "Color",:config_value => "12")
Configuration.find_or_create_by_config_key(:config_key => "Font" ,:config_value => "1")