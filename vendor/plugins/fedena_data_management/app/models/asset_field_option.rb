class AssetFieldOption < ActiveRecord::Base
  belongs_to :asset_field
  validates_presence_of :option
  def default_field
    option
  end
end
