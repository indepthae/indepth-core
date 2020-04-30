class Palette < ActiveRecord::Base

  has_many :user_palettes, :dependent=>:destroy
  has_many :palette_queries, :dependent=>:destroy
  belongs_to :user

  validates_presence_of :name, :model_name
  validates_uniqueness_of :name


  #########################################################

  

  attr_accessor :params, :key
  
  def after_initialize
    self.params = {}
  end

  def retrieve!(p={})
    @params = p
    @result = []
    return @result unless current_query.present?
    current_query.each do |q| 
      query = parse_query! q
      payload = model_name.constantize
      payload = payload.send :search, query[:search].extract_options! if query.keys.include? :search
      query.each do |k,val|
        @result = 0.0 if k == :sum and @result.is_a? Array
        unless k == :search
          @result += case k
          when :all, :count
            payload.send k, val.extract_options!
          when :sum
            payload.send k, val.first, val.extract_options!
          end
        end
      end
    end
    @result.uniq! if @result.is_a? Array
    @result
  end

  def get_result (p={})
    retrieve! p
    if @result.is_a? Array
      result_array
    elsif @result.is_a? Fixnum or @result.is_a? Float
      result_text
    else
      nil
    end
  end

  def user_roles (users=[:admin],&block)
    palette_query = palette_queries.build(:user_roles=>users.to_a)
    palette_query.instance_eval(&block) if block_given?
    palette_query
  end

  def current_user
    Authorization.current_user
  end

  

  def allowed_roles
    allowed_roles = []
    palette_queries.each do|q|
      q.user_roles.each do|r|
        allowed_roles << r
      end
    end
    return allowed_roles
  end

  def self.allowed_palettes
    user_roles = Authorization.current_user.role_symbols
    allowed_palettes = Palette.compatible_palettes(Palette.all,user_roles)
    return allowed_palettes
  end

  def self.compatible_palettes(palettes,user_roles)
    compatible_palettes=[]
    palettes.each do|palette|
      if palette.plugin.nil? or FedenaPlugin.can_access_plugin?(palette.plugin)
        allowed_roles = palette.allowed_roles
        compatible_palettes << palette unless (allowed_roles & user_roles).empty?
      end
    end
    return compatible_palettes
  end

  def self.tzone_start_time(sel_date)
    start_time = sel_date.to_date.to_time
    local_tzone_start_time = start_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find_by_id(time_zone.config_value)
        if zone.present?
          if zone.difference_type=="+"
            local_tzone_start_time = start_time - zone.time_difference
          else
            local_tzone_start_time = start_time + zone.time_difference
          end
        end
      end
    end
    return local_tzone_start_time
  end

  def self.tzone_end_time(sel_date)
    end_time = (sel_date.to_date + 1.days).to_time - 1
    local_tzone_end_time = end_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find_by_id(time_zone.config_value)
        if zone.present?
          if zone.difference_type=="+"
            local_tzone_end_time = end_time - zone.time_difference
          else
            local_tzone_end_time = end_time + zone.time_difference
          end
        end
      end
    end
    return local_tzone_end_time
  end

  def user_palette_position(user)
    self.user_palettes.select{|user_palette| user_palette.user_id== user.id}.first.position
  end

  def user_palette_column(user)
    self.user_palettes.select{|user_palette| user_palette.user_id== user.id}.first.column_number
  end
  
  private

  def result_text
    method_text = "#{name}_palette_text"
    if model_name.constantize.methods.include? method_text
      model_name.constantize.send method_text, @result
    else
      "<h3>#{@result}</h3>".html_safe
    end
  end

  def result_array
    method_text = "#{name}_palette_text"
    data_text = []
    if model_name.constantize.method_defined? method_text
      unless @result.empty?
        
        @result.each{|row| data_text << row.send(method_text)}
      else
        data_text << blank_palette_text
      end
    else
      @result.each{|row| data_text << row.to_s}
    end
    data_text
  end

  def blank_palette_text
    if model_name == "FinanceTransaction"
      currency = Configuration.currency
      "<div class='subcontent-header'>
      <span class='header-left'>#{t('total_income')} (#{currency}) : </span><span class='header-right'>#{FedenaPrecision.set_and_modify_precision(0)}</span>
      </div>
      <div class='subcontent-header'>
      <span class='header-left'>#{t('total_expense')} (#{currency}) : </span><span class='header-right'>#{FedenaPrecision.set_and_modify_precision(0)}</span>
      </div>"
    else
      "<div class='subcontent-header no_data'>#{t('no_data')}</div>".html_safe
    end
  end
  
  def param (key)
    params[key]
  end

  def current_query
    current_query = nil
    palette_queries.each do |palette_query|
      if (palette_query.user_roles & current_user.role_symbols).present?
        current_query = palette_query.query
        break
      end
    end
    current_query
  end

  def parse_query! (query)
    query = dump query
    query.each do |k,val|
      query_options = val.extract_options!
      parse_query_conditions!(query_options)
      query[k]<<query_options
    end
    query
  end

  def parse_query_conditions!(cond)
    case cond.class.to_s
    when "Array"
      cond.each_with_index do |e,i|
        if e.is_a? PaletteQuery::Later
          m = e.method_string
          palette_params = m.scan(/\(([^\)]+)\)/)
          if palette_params
            palette_params.flatten.each do|p|
              if p=="cr_date"
                if param(p.to_sym)
                  m = m.gsub("#{p}","'#{param(p.to_sym)}'")
                end
              end
            end
          end
          cond[i] = instance_eval(m)
        elsif e.is_a? Symbol
          cond[i] = param(e)
        end
      end
    when "Hash"
      cond.each do |k,v|
        case v.class.to_s
        when "Hash"
          parse_query_conditions!(cond[k])
        when "Symbol"
          cond[k]= param(v)
        when "PaletteQuery::Later"
          cond[k]= instance_eval(v.method_string)
        when "Array"
          parse_query_conditions!(cond[k])
        end
      end
    end unless cond.nil?
  end

  def dump (p)
    Marshal.load(Marshal.dump(p))
  end
    
end

