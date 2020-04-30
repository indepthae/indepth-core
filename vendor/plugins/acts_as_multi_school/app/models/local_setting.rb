# To change this template, choose Tools | Templates
# and open the template in the editor.

class LocalSetting < AdditionalSetting

  SETTING_FIELDS = {:select=>[:language,:time_zone,:country], :text=>[:admin_email],:drop_down => [:theme,:font]}

  before_save :set_types

  def set_types
    self.settings["select"]["time_zone"] = self.settings["select"]["time_zone"].to_i
    self.settings["select"]["country"] = self.settings["select"]["country"].to_i
  end

  def fetch_language
    options = []
    AVAILABLE_LANGUAGES.each do |locale, language|
      options << [language, locale]
    end
    options.sort_by { |o| o[0] }
  end

  def fetch_time_zone
    return TimeZone.all.map{|t| ["#{t.name}(#{t.code}) - GMT#{t.difference_type}#{Time.at(t.time_difference).gmtime.strftime('%R')}",t.id]}
  end

  def fetch_country
    return Country.all.map {|c| [c.name, c.id]}
  end

  def fetch_theme
    if self.owner.allowed_plugins.include?("fedena_theme")
      FedenaTheme::COLORS
    else
      return [['Default', '12']]
    end
  end

  def fetch_font
    if self.owner.allowed_plugins.include?("fedena_theme")
      FedenaTheme::FONTS
    else
      return [['Default', '1']]
    end
  end

  def get_language
    lang = ""
    AVAILABLE_LANGUAGES.each do |locale, language|
      lang = language if self.settings["select"]["language"] == locale
    end
    return lang
  end

  def get_time_zone
    t = TimeZone.find_by_id(self.settings["select"]["time_zone"])
    return "#{t.name}(#{t.code}) - GMT#{t.difference_type}#{Time.at(t.time_difference).gmtime.strftime('%R')}" unless t.nil?
    nil
  end

  def get_country
    c = Country.find_by_id(self.settings["select"]["country"])
    return c.name unless c.nil?
    nil
  end

  def get_font
    unless self.settings.nil?
      return self.settings["drop_down"].present? ? self.settings["drop_down"]["font"] : nil
    end
    return nil
  end

  def get_font_value
    val = get_font
    if (self.owner.available_plugin && self.owner.available_plugin.plugins.include?("fedena_theme") ) || ( owner.try(:allowed_plugins) && owner.allowed_plugins.include?("fedena_theme"))
      return val.present? ? FedenaTheme::FONTS[val.to_i][:text] : FedenaTheme::FONTS[1][:text]
    else
      return val.present? ? 'Default' : nil
    end
    
  end

  def get_theme
    unless self.settings.nil?
      return self.settings["drop_down"].present? ? self.settings["drop_down"]["theme"] : nil
    end
    return nil
  end

  def get_theme_value
    val = get_theme
    if (self.owner.available_plugin && self.owner.available_plugin.plugins.include?("fedena_theme") ) || ( owner.try(:allowed_plugins) && owner.allowed_plugins.include?("fedena_theme"))
      return val.present? ? FedenaTheme::COLORS[val.to_i][:color] : FedenaTheme::COLORS[12][:color]
    else
      return val.present? ? 'Default' : nil
    end
  end
end
