class ExportStructure < ActiveRecord::Base
  validates_presence_of :model_name,:query,:template,:csv_header_order
  validates_uniqueness_of :model_name

  serialize :query
  serialize :csv_header_order
  
  has_one :data_export

  def retrieve
    model_name.camelize.constantize.send(make_query.first,make_query.second.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo})
  end

  def make_query
    [query.keys.first,query[query.keys.first]]
  end
end
