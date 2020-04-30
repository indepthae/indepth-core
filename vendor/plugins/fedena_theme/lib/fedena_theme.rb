# ForadianTestPlugin
require 'action_view/helpers/asset_tag_helper'

class FedenaTheme
  COLORS = {1 => {:color => "#701288",:accent_color => "#4e0d5f",:border_color => "#8d41a0",:sort_order => 16},
            2 => {:color => "#39a6ef",:accent_color => "#2874a7",:border_color => "#61b8f2",:sort_order => 24},
            3 => {:color => "#006290",:accent_color => "#004465",:border_color => "#3381a6",:sort_order => 26},
            4 => {:color => "#071d54",:accent_color => "#05143b",:border_color => "#394a76",:sort_order => 28},
            5 => {:color => "#17833f",:accent_color => "#105b2c",:border_color => "#459c65",:sort_order => 38},
            6 => {:color => "#44a81b",:accent_color => "#2f7513",:border_color => "#69b949",:sort_order => 44},
            7 => {:color => "#e8af00",:accent_color => "#a27a00",:border_color => "#edbf33",:sort_order => 1},
            8 => {:color => "#e87800",:accent_color => "#a25400",:border_color => "#ed9333",:sort_order => 3},
            9 => {:color => "#e54c00",:accent_color => "#a03500",:border_color => "#ea7033",:sort_order => 6},
            10 => {:color => "#e92b00",:accent_color => "#a31e00",:border_color => "#ed5533",:sort_order => 5},
            11 => {:color => "#dd0023",:accent_color => "#9a0018",:border_color => "#e4334f",:sort_order => 8},
            12 => {:color => "#ab0000",:accent_color => "#770000",:border_color => "#bc3333",:sort_order => 9},
            13 => {:color => "#4b1700",:accent_color => "#341000",:border_color => "#6f4533",:sort_order => 13},
            14 => {:color => "#303030",:accent_color => "#222222",:border_color => "#595959",:sort_order => 42},
            15 => {:color => "#212226",:accent_color => "#17181b",:border_color => "#4d4e51",:sort_order =>49},
            16 => {:color => "#d39a0b",:accent_color => "#936b08",:border_color => "#dcae3c",:sort_order => 2},
            17 => {:color => "#f54300",:accent_color => "#ab2f00",:border_color => "#f76933",:sort_order => 4},
            18 => {:color => "#9f5f15",:accent_color => "#6f420f",:border_color => "#b27f44",:sort_order => 7},
            19 => {:color => "#9c0000",:accent_color => "#6d0000",:border_color => "#b03333",:sort_order => 10},
            20 => {:color => "#8d3800",:accent_color => "#622700",:border_color => "#a46033",:sort_order => 11},
            21 => {:color => "#862a00",:accent_color => "#5e1d00",:border_color => "#9e5533",:sort_order => 12},
            22 => {:color => "#3d0601",:accent_color => "#2b0401",:border_color => "#643834",:sort_order => 14},
            23 => {:color => "#dc0085",:accent_color => "#9a005d",:border_color => "#e3339d",:sort_order => 15},
            24 => {:color => "#570050",:accent_color => "#3d0038",:border_color => "#793373",:sort_order => 17},
            25 => {:color => "#1b0153",:accent_color => "#13013a",:border_color => "#493475",:sort_order => 18},
            26 => {:color => "#4c240a",:accent_color => "#351907",:border_color => "#70503b",:sort_order => 19},
            27 => {:color => "#220000",:accent_color => "#180000",:border_color => "#4e3333",:sort_order => 20},
            28 => {:color => "#0b0b3b",:accent_color => "#080829",:border_color => "#3c3c62",:sort_order => 21},
            29 => {:color => "#6675b9",:accent_color => "#475281",:border_color => "#8591c7",:sort_order => 22},
            30 => {:color => "#4b71b9",:accent_color => "#344f81",:border_color => "#6f8dc7",:sort_order => 23},
            31 => {:color => "#2d83cf",:accent_color => "#1f5b90",:border_color => "#579cd9",:sort_order => 25},
            32 => {:color => "#123b79",:accent_color => "#0d2954",:border_color => "#416294",:sort_order => 27},
            33 => {:color => "#38a5dc",:accent_color => "#27739a",:border_color => "#60b7e3",:sort_order => 29},
            34 => {:color => "#35a2ba",:accent_color => "#257182",:border_color => "#5db5c8",:sort_order => 30},
            35 => {:color => "#2061ac",:accent_color => "#164478",:border_color => "#4d81bd",:sort_order => 31},
            36 => {:color => "#223895",:accent_color => "#182768",:border_color => "#4e60aa",:sort_order => 32},
            37 => {:color => "#2f1e89",:accent_color => "#211560",:border_color => "#594ba1",:sort_order => 33},
            38 => {:color => "#194e90",:accent_color => "#113665",:border_color => "#4771a6",:sort_order => 34},
            39 => {:color => "#383e5b",:accent_color => "#272b40",:border_color => "#60657c",:sort_order => 35},
            40 => {:color => "#43aa57",:accent_color => "#2f773d",:border_color => "#69bb79",:sort_order => 36},
            41 => {:color => "#2e9948",:accent_color => "#206b32",:border_color => "#58ad6d",:sort_order => 37},
            42 => {:color => "#2b8992",:accent_color => "#1e6066",:border_color => "#55a1a8",:sort_order => 39},
            43 => {:color => "#435875",:accent_color => "#2f3d52",:border_color => "#697991",:sort_order => 40},
            44 => {:color => "#575b67",:accent_color => "#3d4048",:border_color => "#797c85",:sort_order => 41},
            45 => {:color => "#77b200",:accent_color => "#537c00",:border_color => "#92c133",:sort_order => 43},
            46 => {:color => "#1c681c",:accent_color => "#144914",:border_color => "#498649",:sort_order => 45},
            47 => {:color => "#134d2a",:accent_color => "#0d361d",:border_color => "#427155",:sort_order => 46},
            48 => {:color => "#092f05",:accent_color => "#062103",:border_color => "#3a5937",:sort_order => 47},
            49 => {:color => "#041f07",:accent_color => "#031605",:border_color => "#364c39",:sort_order => 48}}
  FONTS ={1 =>{:text => "Arial", :value => "Arial"},2 =>{:text => "Verdana", :value => "Verdana, Arial"},3 =>{:text => "Comic Sans MS", :value => "Comic Sans MS, Arial"},4 =>{:text => "Georgia", :value => "Georgia, Times new Roman"},5 => {:text => "Times new Roman", :value => "Times new Roman"},6 => {:text => "Trebuchet MS", :value => "Trebuchet MS, Arial"},7 => {:text => "Garamond", :value => "Garamond, Times new Roman"}}
  unloadable

  def self.general_settings_form
    "configuration/theme_select"  
  end

  def self.available_themes
    directory = "#{Rails.public_path}/themes"
    themes = Dir.entries(directory).select {|entry| File.directory? File.join(directory,entry) and !(entry =='.' || entry == '..') }
    return [['Default', 'default']]+themes.collect { |theme| [theme.titleize, theme] }
  end

  def self.selected_theme
    Configuration.get_config_value("Color")
  end

  def self.selected_font
    Configuration.get_config_value("Font")
  end

  def self.selected_font_value
    val = selected_font
    FONTS[val.to_i][:text]
  end

  def self.selected_color_value
    val = selected_theme
    COLORS[val.to_i][:color]
  end
  
end


