class SchoolAsset < ActiveRecord::Base
  validates_uniqueness_of :asset_name
  validates_presence_of :asset_name

  has_many :asset_entries, :dependent => :destroy
  has_many :asset_fields, :dependent => :destroy
  accepts_nested_attributes_for :asset_fields, :allow_destroy => true
  default_scope :includes=>:asset_fields

  def validate
    undestroyed_task_asset = 0
    asset_fields.each { |t| undestroyed_task_asset += 1 unless t.marked_for_destruction? }    
    errors.add_to_base "#{t('school_assets.asset_field_cant_blank')}" if undestroyed_task_asset < 1
  end
     
  def asset_field_names
    return @asset_field_names if @asset_field_names
    hsh=ActiveSupport::OrderedHash.new(asset_fields.first. make_hash_default_name) unless asset_fields.first.nil?
    related_options=[]
    asset_fields.each do |af|
      case af.field_type  
      when 'belongs_to'
        hsh["asset_field_#{af.id}"]=af.attributes
        hsh["asset_field_#{af.id}"].merge!({"related"=>af.field_name.downcase.gsub(' ','_')})
        related_options=af.asset_field_options.map{|ae| [ae.default_field,ae.id]}
        hsh["asset_field_#{af.id}"].merge!({"related_options"=>related_options})
      when 'has_many'
        hsh["asset_field_#{af.id}"]=af.attributes
        hsh["asset_field_#{af.id}"].merge!({"related"=>af.field_name.downcase.gsub(' ','_')+"s"})
        related_options=af.asset_field_options.map{|ae| [ae.default_field,ae.id]}
        hsh["asset_field_#{af.id}"].merge!({"related_options"=>related_options})
      else
        hsh["asset_field_#{af.id}"]=af.attributes
      end
    end
    @asset_field_names=hsh
  end
  
  def asset_entry_name(entry_id)
    return "#{self.asset_name} #{self.asset_entries.collect(&:id).index(entry_id)+1}"
  end
  
end
