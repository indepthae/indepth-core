class AssetEntry < ActiveRecord::Base
  
  serialize :dynamic_attributes
  
  belongs_to :school_asset

  before_save :assign_asset_fields_to_dynamic_attributes

  default_scope :includes=>:school_asset

  def after_initialize
    make_dynamic_attribute_methods
    assign_dynamic_attribute_to_asset_fields
  end
  def asset_field_names
    @asset_field_names ||= school_asset.asset_field_names
  end
  def default_field
    send asset_field_names.default
  end
  
  def make_dynamic_attribute_methods
    unless self.asset_field_names.nil?
      asset_field_names.each do |k,val|
        self[k]=nil
        if val["field_type"] == "belongs_to"
          self[val["related"]]=nil
        elsif  val["field_type"] == "has_many"
          self[val["related"]]=[]
        end
      end
    end
  end

  def assign_dynamic_attribute_to_asset_fields
    if dynamic_attributes.is_a? Hash
      asset_field_names.each do |k,val|
        if val["field_type"] == "belongs_to"
          value = dynamic_attributes[k] || dynamic_attributes[val["field_name"].downcase.gsub(' ','_')+"_id"]
          self[k] = value
          self[val["related"]]= AssetFieldOption.find_by_id(value)
        elsif  val["field_type"] == "has_many"
          value = ((dynamic_attributes[k]) || dynamic_attributes[val["field_name"].downcase.gsub(' ','_')+"_ids"] || [])
          self[k] = value
          self[val["related"]] = AssetFieldOption.find_all_by_id(value)
        else
          value = dynamic_attributes[k] || dynamic_attributes[val["field_name"].downcase.gsub(' ','_')]
          self[k] = value
        end
      end
    end
  end

  def assign_asset_fields_to_dynamic_attributes
    self.dynamic_attributes=Hash.new
    unless asset_field_names.nil?
      asset_field_names.each do |k,val|
        case val["field_type"]
        when "belongs_to"
          dynamic_attributes["#{k}"] = (send "#{k}").to_i
        when "has_many"
          dynamic_attributes["#{k}"] = ((send "#{k}").nil? ? [] : (send "#{k}").map{|i| i.to_i})
        else
          dynamic_attributes["#{k}"] = send "#{k}"
        end
      end
    end
  end
  def update_dynamic_attributes(params)
    unless asset_field_names.nil?
      asset_field_names.keys.each do |k|
        send "#{k}=", params["#{k}"]
      end
      save
    else
      false
    end
  end
  def set_asset_fields_to_dynamic_attributes(params)
    unless asset_field_names.nil?
      asset_field_names.keys.each do |k|
        send "#{k}=", params["#{k}"]
      end
    end
  end
end
