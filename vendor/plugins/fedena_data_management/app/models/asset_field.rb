class AssetField < ActiveRecord::Base
  
  validates_presence_of :field_name, :field_type

  has_many :asset_field_options,:dependent => :destroy
  accepts_nested_attributes_for :asset_field_options, :allow_destroy => true

  belongs_to :school_asset
  
  def make_hash_default_name
    case field_type
    when 'belongs_to'
      field_name.downcase.gsub(' ','_')+"_id"
    when 'has_many'
      field_name.downcase.gsub(' ','_')+"_ids"
    else
      field_name.downcase.gsub(' ','_')
    end
  end
end
