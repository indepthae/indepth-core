class IaIndicator < ActiveRecord::Base
  validates_presence_of :name,:indicator,:max_mark
  validates_uniqueness_of :indicator,{:scope=>:ia_group_id}
  validates_format_of :indicator,:with => /^[A-Z]{0,1}$/,:message=>"should be valid single character(Capital Letter)",:allow_blank=>true
  #  validates_format_of :indicator,:with => /^[a-zA-Z]{0,1}$/,:message=>"should be valid single character",:allow_blank=>true
  validates_numericality_of :max_mark,:allow_blank =>true
  has_many :ia_scores
  belongs_to :ia_group
end
